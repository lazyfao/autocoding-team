# Operations: the run book

For the orchestrator, after setup. `<slug>`, `<team>` and `<ops>` are the values chosen at setup: the unit prefix, the team folder, and `~/.config/<slug>-devteam`.

## The pieces
| Piece | Where | What it does |
|---|---|---|
| Timer | `~/.config/systemd/user/<slug>-dev.timer` | starts the service a minute after the timer starts, then N min after each run **ends** |
| Service | `~/.config/systemd/user/<slug>-dev.service` | oneshot; runs the tick script; appends all output to `<team>/logs/developer.log` |
| Tick script | `<ops>/developer-tick.sh` | gates (PAUSE, cooldown, branch, skip), `ensure_env`, one agent run, cooldown on failure, push |
| Watcher | `<ops>/wait-report.sh <n>` | exits when a report newer than R-n lands, or after 60 min |
| Skip hash | `<ops>/board.sha` | the board hash of the last run; the same hash + a DONE/BLOCKED/QUESTION report = skip |
| Cooldown | `<ops>/cooldown_until` | an epoch; no runs before it |
| Pause | `<team>/PAUSE` | while it exists, no runs |

The ops folder is outside the team folder on purpose: the sandboxed developer can write the team folder, but must not be able to change the script that runs it.

## Everyday commands
```sh
systemctl --user start --no-block <slug>-dev.service    # doorbell: run now (joins a running one, never a second)
systemctl --user status <slug>-dev.timer <slug>-dev.service
systemctl --user list-timers <slug>-dev.timer             # next and last fire
tail -n 20 <team>/logs/developer.log
touch <team>/PAUSE   /   rm <team>/PAUSE                   # stop / allow runs
rm -f <ops>/cooldown_until                                 # end a cooldown now
sha256sum <team>/board.md | cut -d' ' -f1 > <ops>/board.sha   # board edit the developer needn't act on
systemctl --user stop <slug>-dev.service                  # kill a stuck run
```

## The order of a tick's writes
1. Decide everything, then write `board.md` once, at the end.
2. Only then do anything that lets a run start: the doorbell, `rm cooldown_until`, `rm PAUSE`.
3. If the board change is only bookkeeping (a log entry, an owner answer the developer doesn't need), refresh `board.sha`, or the next tick starts a run with nothing to do.

A run that starts between two of your board edits works from the half-written board.

## Liveness
- A run may take hours. It is stuck only when the service is **active** and `developer.log` has not grown for 60 min.
- Ask the developer for a PROGRESS line at each milestone. A run that is killed (by the cap or a limit) then still leaves a trace.

## Failures and limits
- **Any failed run** gets a cooldown: 15 min. If the run wrote no report, the script forgets `board.sha`, so the run is retried after the cooldown, even though the board is unchanged and the last report may be an old DONE.
- **A usage limit** gets 3 h, and the script retries every 3 h until the limit resets. Vendors sometimes reset early, and a retry that is still limited fails at once and costs nothing. Don't `PAUSE` for a limit. Tell the owner once; buying credits to resume sooner is their call.
- **"Model at capacity"** and similar transient vendor errors: the normal 15 min cooldown.
- **Checking a Codex limit without waiting:**
  - `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` records `rate_limits` (`used_percent`, `resets_at` as an epoch) for each run. That is a snapshot from the last run, not live.
  - Live check: `codex exec --skip-git-repo-check -s read-only "Reply with the single word OK."` from an empty folder. It costs about ten thousand tokens when the limit is open, and nothing when it is still hit.
- **Claude Code as developer** shares the owner's Claude allowance with the orchestrator session. One limit stops both.

## Verifying a DONE, mechanically
```sh
git -C <worktree> status --short; git -C <worktree> log --oneline <last-accepted>..HEAD; git -C <worktree> diff --stat <last-accepted>..HEAD
git -C <worktree> ls-remote origin <branch>          # matches local HEAD? else look for "push failed" in the log
git -C <main-checkout> rev-parse HEAD; git -C <main-checkout> status --short | wc -l   # equals the board's baseline
```
Codex only: check that no forbidden command **ran**. Grep the executed-command lines, not the whole log, because the log also echoes the files Codex read, and those include the board's own rules:
```sh
grep -E '^/usr/bin/(ba|z)?sh -lc ' <team>/logs/developer.log | grep -cE '(^|[^[:alnum:]_.-])(ssh|scp|tailscale)([[:space:]]|$)'   # 0
```

## Known flakes
A test that fails under full-suite load and passes alone goes under "Now" in the board, with its evidence. A later full run counts as green only if the known flakes are its only failures *and* that run's report shows each one passing when rerun alone. Your own earlier reruns don't substitute for that run's evidence.

## Phase close
`/code-review medium` on the phase diff, run by the orchestrator: a second model's review. Triage every finding. Send the real ones back as one REWORK with an exact numbered list, and record the rejected ones with a reason. Expect real bugs; in the author's project, the two reviews found 8 and 12 real issues, including a money leak.

## The orchestrator loop
- Start it: `/loop Orchestrator tick: follow <team>/orchestrator.md §7` in the root conversation.
- Every tick's reply starts with the full `progress.txt` in a code block, so the owner can follow along without opening the file. It ends with the new version if the tick changed it.
- Each tick ends by arming `wait-report.sh <last report read>` in the background (if none is running) and a 1800–3600 s fallback wakeup.
- To stop it: stop the wakeup; the timer and developer keep running on their own until `PAUSE`.

## Testing the tick script
After any edit to the tick script, run the fake-developer harness from the skill. It touches nothing real:
```sh
<skill>/scripts/test-tick.sh <ops>/developer-tick.sh            # both agents
```
