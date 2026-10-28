#!/usr/bin/env bash
# Orchestrator doorbell: exits as soon as reports.md has a report newer than R-<n>, or after an hour as a heartbeat.
# The orchestrator runs it in the background (Claude Code: Bash run_in_background); its exit wakes the orchestrator.
n=${1:?usage: wait-report.sh <number of the last report read, 0 for none>}
R=${REPORTS:-{{TEAM_DIR}}/reports.md}
end=$(( $(date +%s) + ${HEARTBEAT:-3600} ))
while :; do
  last=$(grep -oE '^## R-[0-9]+' "$R" 2>/dev/null | tail -1 | grep -oE '[0-9]+$')
  if [ -n "$last" ] && [ $((10#$last)) -gt "$n" ]; then grep -E '^## R-[0-9]+' "$R" | tail -1; exit 0; fi
  [ "$(date +%s)" -ge "$end" ] && { echo "heartbeat: no new report after R-$n"; exit 0; }
  sleep 20
done
