#!/usr/bin/env bash
# One developer tick: the developer agent works on the active directive, then the work branch is pushed as a backup.
# Lives outside the team folder on purpose: the sandboxed developer can write there, and this runs unsandboxed.
# The timer fires a few minutes after each tick ends, so skips stay silent and cheap (no agent call).
set -uo pipefail

# ---- config (filled in at setup) ---------------------------------------------------------------
TEAM={{TEAM_DIR}}          # coordination folder: board.md, reports.md, developer.md, logs/
WT={{WORKTREE}}            # where the developer works (a git worktree or the repo itself)
OPS={{OPS_DIR}}            # this script, wait-report.sh, board.sha, cooldown_until
BRANCH={{BRANCH}}          # the work branch; the script refuses to run on any other
DEV_AGENT={{DEV_AGENT}}    # codex | claude
DEV_MODEL={{DEV_MODEL}}    # empty = the CLI's default model
DEV_EFFORT={{DEV_EFFORT}}  # empty = the CLI's default reasoning effort
CAP={{CAP_H}}h             # hard cap per run; the service's TimeoutStartSec is this plus 15 min
PUSH={{PUSH}}              # 1 = push $BRANCH to origin after every run (backup), 0 = don't
# -----------------------------------------------------------------------------------------------

export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin"

stamp() { date '+%F %T'; }

# Anything the sandboxed developer can't do for itself but needs before each run: start a private test
# database, export its port and password, put a runtime on PATH. Keep it idempotent and quiet.
# Example (a private Postgres cluster, so the tests' drop-and-recreate fixtures can't touch anyone else's):
#   pg_ctl -D "$HOME/dev/pg-team" status >/dev/null 2>&1 || pg_ctl -D "$HOME/dev/pg-team" -l "$HOME/dev/pg-team.log" -w start \
#     -o "-p 54330 -c listen_addresses=127.0.0.1" >/dev/null && echo "$(stamp) started postgres"
#   export TEST_PGPORT=54330
ensure_env() {
  :
}

[ -e "$TEAM/PAUSE" ] && exit 0
# After a failed run (auth, model capacity, crash) wait 15 min instead of retrying every minute.
# After a usage-limit error wait 3 h: vendors sometimes reset early, and a retry that's still limited fails at once.
[ "$(date +%s)" -lt "$(cat "$OPS/cooldown_until" 2>/dev/null || echo 0)" ] && exit 0

if [ "$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null)" != "$BRANCH" ]; then
  echo "$(stamp) worktree is not on $BRANCH: not running"; exit 0
fi

# Waiting on the orchestrator (last report DONE/BLOCKED/QUESTION) and the board hasn't moved: nothing to do.
board_sha=$(sha256sum "$TEAM/board.md" | cut -d' ' -f1)
last_status=$(grep -E '^## R-[0-9]+' "$TEAM/reports.md" 2>/dev/null | tail -1 | awk -F' · ' '{print $3}')
if [ "$board_sha" = "$(cat "$OPS/board.sha" 2>/dev/null)" ] && [[ "$last_status" =~ ^(DONE|BLOCKED|QUESTION)$ ]]; then
  exit 0
fi
echo "$board_sha" > "$OPS/board.sha"
ensure_env

PROMPT="Developer tick for the {{PROJECT}} project. Read $TEAM/developer.md and follow it; if it is empty, start with $TEAM/developer_onboarding.md. Your rules and the active directive are in $TEAM/board.md. Before you stop, append your report to $TEAM/reports.md."

run_developer() {
  case "$DEV_AGENT" in
    codex)
      # --sandbox can't be combined with --approve-for-me; the workspace-write sandbox is the default for exec.
      # Escalations (git commits, Windows interop) are reviewed automatically. The owner's .rules allowlist is
      # ignored and the app connectors are off, so the developer can't merge or deploy through them.
      timeout "$CAP" codex exec \
        -C "$WT" --add-dir "$TEAM" \
        --approve-for-me -c sandbox_workspace_write.network_access=true \
        --ignore-rules --disable apps \
        ${DEV_MODEL:+-m "$DEV_MODEL"} ${DEV_EFFORT:+-c model_reasoning_effort="$DEV_EFFORT"} \
        -o "$TEAM/logs/developer-last.md" \
        "$PROMPT"
      ;;
    claude)
      # Auto mode approves routine actions and refuses risky ones. With text output the log gets only the
      # final message, not the files the developer read.
      (cd "$WT" && timeout "$CAP" claude -p "$PROMPT" \
        --add-dir "$TEAM" --permission-mode auto \
        ${DEV_MODEL:+--model "$DEV_MODEL"} ${DEV_EFFORT:+--effort "$DEV_EFFORT"}) \
        | tee "$TEAM/logs/developer-last.md"
      ;;
    *)
      echo "$(stamp) unknown DEV_AGENT '$DEV_AGENT'"; return 2
      ;;
  esac
}

# A usage-limit message from this run's output. Codex prints it as an ERROR line; Claude Code's wording varies.
hit_usage_limit() {
  case "$DEV_AGENT" in
    codex)  grep -q "^ERROR: .*hit your usage limit" ;;
    claude) grep -qiE "usage limit|hit your limit|limit reached" ;;
  esac
}

echo "$(stamp) tick start (board ${board_sha:0:8}, last report: ${last_status:-none})"
reports_before=$(grep -cE '^## R-[0-9]+' "$TEAM/reports.md" 2>/dev/null)
log_before=$(wc -l < "$TEAM/logs/developer.log" 2>/dev/null || echo 0)
run_developer
rc=$?
echo "$(stamp) $DEV_AGENT exit $rc"
if [ "$rc" -ne 0 ]; then
  if tail -n +$((log_before + 1)) "$TEAM/logs/developer.log" | hit_usage_limit; then
    echo $(( $(date +%s) + 10800 )) > "$OPS/cooldown_until"
    echo "$(stamp) usage limit: cooldown 3 h"
  else
    echo $(( $(date +%s) + 900 )) > "$OPS/cooldown_until"
    echo "$(stamp) cooldown 15 min"
  fi
  # No report from this run: forget the board hash, so the skip check doesn't wait for a board change to retry.
  [ "$(grep -cE '^## R-[0-9]+' "$TEAM/reports.md" 2>/dev/null)" = "$reports_before" ] && rm -f "$OPS/board.sha"
fi

if [ "$PUSH" = 1 ]; then
  if git -C "$WT" push -q -u origin "$BRANCH:$BRANCH"; then
    echo "$(stamp) pushed $(git -C "$WT" rev-parse --short HEAD)"
  else
    echo "$(stamp) push failed"
  fi
fi
exit 0
