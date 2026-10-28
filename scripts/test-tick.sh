#!/usr/bin/env bash
# Tests a filled developer-tick.sh with a fake developer CLI, in a throwaway folder. Nothing real is touched:
# no agent call, no push, no timer. Usage: test-tick.sh <path to developer-tick.sh> [codex|claude ...]
# Default agents: both. Exit 0 when every case passes.
set -uo pipefail
TICK=${1:?usage: test-tick.sh <path to developer-tick.sh> [codex|claude ...]}; shift
AGENTS=("$@"); [ ${#AGENTS[@]} -eq 0 ] && AGENTS=(codex claude)
BRANCH=$(sed -nE 's/^BRANCH=([^[:space:]]+).*/\1/p' "$TICK")
[ -n "$BRANCH" ] && [[ "$BRANCH" != *'{{'* ]] || { echo "fill BRANCH in $TICK first"; exit 2; }

fails=0
check() { if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; fails=$((fails + 1)); fi; }

for agent in "${AGENTS[@]}"; do
  S=$(mktemp -d); trap 'rm -rf "$S"' EXIT
  mkdir -p "$S/team/logs" "$S/ops" "$S/bin"
  git init -q "$S/wt" && git -C "$S/wt" checkout -q -b "$BRANCH" \
    && git -C "$S/wt" -c user.name=t -c user.email=t@t commit -q --allow-empty -m x
  printf '# board\n' > "$S/team/board.md"
  printf '## R-001 · D-001 · DONE · x\n' > "$S/team/reports.md"
  : > "$S/team/logs/developer.log"
  sed -e "s|^TEAM=[^ ]*|TEAM=$S/team|" -e "s|^WT=[^ ]*|WT=$S/wt|" -e "s|^OPS=[^ ]*|OPS=$S/ops|" \
      -e "s|^DEV_AGENT=[^ ]*|DEV_AGENT=$agent|" -e "s|^PUSH=[^ ]*|PUSH=0|" \
      -e "s|^export PATH=\"|export PATH=\"$S/bin:|" -e 's|^ensure_env() {|ensure_env() { return 0|' \
      "$TICK" > "$S/tick.sh"
  case "$agent" in
    codex)  limit_msg="ERROR: You’ve hit your usage limit. Upgrade or try again at Nov 3rd" ;;
    claude) limit_msg="You've hit your limit · resets 3pm" ;;
  esac
  fake() { printf '#!/usr/bin/env bash\n%s\n' "$1" > "$S/bin/$agent"; chmod +x "$S/bin/$agent"; }
  run() { bash "$S/tick.sh" >> "$S/team/logs/developer.log" 2>&1; }
  lines() { wc -l < "$S/team/logs/developer.log"; }
  cool() { echo $(( $(cat "$S/ops/cooldown_until" 2>/dev/null || echo 0) - $(date +%s) )); }

  echo "$agent:"
  fake "echo \"$limit_msg\"; exit 1"; run
  c=$(cool)
  check "1 usage limit -> 3 h cooldown, board hash forgotten" '[ "$c" -gt 10700 ] && [ ! -e "$S/ops/board.sha" ]'
  n=$(lines); run
  check "2 within the cooldown -> silent skip" '[ "$(lines)" = "$n" ]'
  echo 0 > "$S/ops/cooldown_until"; fake 'echo "ERROR: Selected model is at capacity."; exit 1'; n=$(lines); run
  c=$(cool)
  check "3 cooldown over, same board, last report DONE -> retried; other error -> 15 min" \
    'tail -n +$((n + 1)) "$S/team/logs/developer.log" | grep -q "tick start" && [ "$c" -gt 800 ] && [ "$c" -le 900 ]'
  echo 0 > "$S/ops/cooldown_until"; fake "printf '## R-002 · D-002 · DONE · x\n' >> '$S/team/reports.md'; exit 1"; run
  check "4 failed run that wrote a report keeps the board hash" '[ -e "$S/ops/board.sha" ]'
  echo 0 > "$S/ops/cooldown_until"; n=$(lines); run
  check "5 next tick: DONE and board unchanged -> silent skip" '[ "$(lines)" = "$n" ]'
  : > "$S/team/PAUSE"; printf '# board v2\n' > "$S/team/board.md"; n=$(lines); run
  check "6 PAUSE -> silent skip even with a changed board" '[ "$(lines)" = "$n" ]'
  rm -f "$S/team/PAUSE"; fake 'echo working; exit 0'; run
  check "7 changed board -> runs, success sets no cooldown" '[ "$(tail -n 3 "$S/team/logs/developer.log" | grep -c "exit 0")" = 1 ] && [ "$(cool)" -le 0 ]'
  rm -rf "$S"; trap - EXIT
done
[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
