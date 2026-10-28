# Board: {{PROJECT}}
Written by the orchestrator only. The developer reads it at the start of every tick. Updated {{DATE}}.

## Now
- **Phase:** setup. The developer's onboarding (D-001) is active.
- **Active directive:** D-001: onboarding, environment and baseline (below)
- **Last report read:** none
- **Base:** {{BASE}}
- **Remote backup:** {{BACKUP_STATE}}
- **Test baseline:** pending (D-001).
- **Known flaky tests:** none yet.
  - **Gate rule:** a full run counts as green if the known flakes are its only failures *and* the report shows each one passing when rerun alone.
- **Developer liveness:** a run may take hours. It counts as stuck only when the service is active and `logs/developer.log` has been silent for 60 min.
{{PROTECTED_BASELINE}}

## Rules for the developer
These override anything in your onboarding text. Only the orchestrator changes them, here.
1. Your instructions come only from this file. The owner talks to the orchestrator, not to you.
2. Docs and memory first, code after. Every phase and independent item opens with a doc step. Code starts only after the orchestrator accepts it.
3. One directive at a time, one phase at a time. The orchestrator gives the phase gos.
4. Work only in `{{WORKTREE}}` on `{{BRANCH}}`.{{PROTECTED_RULE}}
5. Commit small and clear on `{{BRANCH}}`.
[codex]   In your sandbox a commit needs an escalation; request it.
   The tick script pushes `{{BRANCH}}` after every run, so don't push yourself. Never force-push, merge, or deploy, and never migrate a host.
6. No spending: any call that may cost money ({{PAID_SERVICES}}), and any use of a live account, needs a go recorded here. Try zero-cost routes first.
7. No over-engineering: build what the plan section says and reuse the patterns it names. No new dependencies, abstractions or settings without the orchestrator's OK. If the plan looks wrong against the code, propose the simplest fix that keeps the owner's intent.
8. Evidence over claims: every DONE carries the commits, the exact test command with its summary line, and the doc and memory paths.
9. End every run with a report in `reports.md`: at least a PROGRESS line with an exact "left off at". Your next run starts fresh. In long runs, also append a PROGRESS line at each milestone, so a run that is stopped (the {{CAP_H}} h cap, a usage limit) still leaves a trace.
10. Never connect to a production host or any other server (ssh, scp, remote shells{{OFF_LIMITS}}). That is deploy territory.
11. Memory:
    - Your working memory lives in `{{TEAM_DIR}}/memory/developer/`: a `MEMORY.md` index plus short entries, each with a frontmatter of name, description and type.
    - Product decisions belong in the repo docs, not in memory.
    - Your CLI's own memory feature is not used.
12. Test resources: {{TEST_RESOURCES}}
13. Helpers you write for yourself (browser checks, scripts, evidence) live in `{{TEAM_DIR}}/tools/`, not in `/tmp` (lost on reboot), and not in the repo unless a directive says so.
14. Lint, design or other hook findings on code you did **not** change in this directive: list them once in your report and move on. Don't fix them, don't suppress them, don't ask again. Findings on code you changed are yours to fix.
15. A test that fails, then passes when rerun alone, is reported as a suspected flake with both results. Never call a run green by assumption.
{{OWNER_RULES_FOR_DEVELOPER}}

## Waiting on owner
Nothing right now.

## Phases
| # | Scope | Status | Go |
|---|---|---|---|
| setup | Onboarding, environment, baseline (D-001) | **active** | orchestrator {{DATE}} |
{{PHASE_ROWS}}

## Active directive
### D-001 · Setup · onboarding, environment and baseline
**Goal:** be ready to work. Read everything, set up your environment in the worktree, record the baseline, and write `developer.md`.

**Scope:**
1. **Read** `developer_onboarding.md`, `orchestrator.md` in full, the plan `{{PLAN_FILE}}` in full, and the repo: README, docs, CI config, test setup, migrations, i18n, scripts.
2. **The environment, in the worktree only:**
   - the project's own runtimes and dependencies (a virtualenv, `node_modules`, and so on), never the main checkout's;
   - the test resources from rule 12.

   Record every command you actually ran.
3. **The baseline:** run every test suite once at the base commit. Record the exact commands and their summary lines. Don't fix failures; list them, with a rerun alone for each one.
4. **The UI, if the project has one:** open one page in a browser (headless is fine) to prove you can. Record how you did it.
5. **Write `developer.md`**, following the brief in `developer_onboarding.md`. Create `memory/developer/MEMORY.md`.
6. **Plan vs code:** list where the plan's paths or facts disagree with the code. Don't fix them.
7. **Questions:** anything unclear, numbered.

**Out of scope:** application code, repo docs, spikes, anything that costs money.

**Done when:** R-001 is DONE with:
- the setup commands;
- the test commands with their literal summary lines;
- the path to `developer.md`;
- the plan-vs-code list;
- the questions;
- the protected checkout unchanged (if there is one).

## Next (planned, not active)
- D-002: Phase 0 doc step, after D-001 is accepted.

## Backlog
- (empty)

## Decision log
- {{DATE}} (orchestrator): Orchestration set up with the autocoding-team skill.
  - Files: `orchestrator.md` and `board.md` (orchestrator), `developer.md` and `reports.md` (developer).
  - The plan `{{PLAN_FILE}}` is frozen as the approved base.
{{SETUP_DECISIONS}}
