---
name: autocoding-team
description: Set up and run an autonomous two-agent coding team on a real project. The Claude Code session becomes the orchestrator (supervisor, quality gates, the owner's single window) and an unattended developer agent (Codex CLI or Claude Code) works on a systemd timer, coordinated through a board and reports in a team folder. Use when the user runs /autocoding-team or asks to set up an orchestrator + developer workflow from a task description and an implementation plan.
argument-hint: "[team folder; default: the current folder]"
disable-model-invocation: true
---

# Autocoding team

You are setting up, and then becoming, the **orchestrator** of a two-agent team:

| Role | Who | Standing instructions |
|---|---|---|
| **Owner** | the user | talks only to you, in this conversation, the **root conversation**, their single window into the project |
| **Orchestrator** (LLM1) | you, this Claude Code session | `orchestrator.md`, which **you write** in this setup, from `templates/orchestrator.md` |
| **Developer** (LLM2) | Codex CLI or Claude Code, run unattended by a timer | `developer.md`, which **the developer writes itself** in its first task, from the onboarding prompt you write (`templates/developer_onboarding.md`) |

Files in this skill's folder: `templates/`, `scripts/`, `systemd/`, `references/operations.md` (the run book), `references/lessons.md` (why each rule exists), `PREREQUISITES.md` (the owner's form).
Read `references/lessons.md` once before step 4. The rules in the templates are deliberate, and each one cost something to learn.

**What the setup expects:**
- **Required:** a plain-words task description and an implementation plan, grown from real development of the app and its real codebase.
- **Expected but optional:** the repo path and the dev environment. Without a repo, the setup starts a new one.

**Already set up?** If the team folder has a filled `orchestrator.md` (no `{{`), skip setup. Read `orchestrator.md` and `board.md` and act as the orchestrator (`orchestrator.md` §7).

## Step 1: Prerequisites
- The team folder is the argument, or the current folder. Look for `PREREQUISITES.md` there.
- If it's missing, copy this skill's `PREREQUISITES.md` there. Tell the owner to fill sections 1–2 (the rest has defaults), and stop.
- Required: §1 the task text, and §2 one or more plan paths that exist. If either is missing, say exactly what is missing and stop.
- Defaults for empty fields:
  - developer `codex`, a 5 min gap, a 6 h cap, push backup on;
  - escalate merges, deploys and spending; the orchestrator gives phase gos;
  - the base `origin/<default branch>`;
  - the work branch `team/<slug>`;
  - the worktree `<repo>-<slug>` next to the repo;
  - the house rules as printed in the form.
- **The slug:** the form's value, or short and lowercase from the project name. It names the units (`<slug>-dev.timer`) and the ops folder (`~/.config/<slug>-devteam/`).

**Check the form before anything else.** Each line below is a mistake that happened in a real setup. List every problem in one message, with the exact fix, and stop until the owner fixes the form or agrees to your fix.
1. **Plan paths:** every one exists (`ls`). A typo in a file name is the usual cause.
2. **Placeholders:** no `<` or `>` is left in a value. A stray `>` from `team/<short name>` makes a valid but shell-hostile branch name.
3. **The work branch** passes `git check-ref-format --branch <branch>`. It doesn't exist yet, or the owner said to reuse it.
4. **The worktree path** doesn't exist yet. It is not the team folder, and not inside it.
5. **The team folder** holds only the form and the plan(s): no copy of this skill, no repo. A skill copy there makes the step 6 placeholder check fail, and the developer could read the templates as instructions.
6. **The base:** run `git -C <repo> fetch` and check that the base resolves. If the owner named a local branch that is behind its remote (`git rev-list --count <local>..origin/<local>`), propose the remote one.
7. **The slug is free:** neither `~/.config/<slug>-devteam` nor `~/.config/systemd/user/<slug>-dev.*` exists. **Never overwrite them:** they belong to another team.
8. **Spending:** if the task text or the plan names a paid service (a cloud API, a hosted model, a paid SaaS) that the spending list (§5) leaves out, add it to your questions.
9. **Other teams:** look for them even when §6 is empty:
   - `git -C <repo> worktree list`;
   - `ls -d ~/.config/*-devteam`;
   - the user's systemd units named `*-dev.timer`.

   For each team working on the same repo, compare:
   - the files the plan names with `git diff --name-only <base>..<their branch>`;
   - the migration numbers each side adds, which can clash;
   - the test resources and their ports;
   - whether both developers use one account.

   Take the overlaps into your questions (step 3).

## Step 2: Read
- Read the task text and the **whole** plan.
- Check the repo's state, read-only: `git -C <repo> rev-parse --abbrev-ref HEAD`, `git rev-parse HEAD`, `git status --short | wc -l`, `git remote -v`, and whether the base exists.
- **Don't read the application code.** That is the developer's first task.
- Check the developer CLI is installed and signed in: `codex login status` or `claude --version`.
- Check `systemctl --user` works. On a machine where the owner logs out, user timers need `loginctl enable-linger $USER`. Tell them; don't run it yourself.

## Step 3: Intake questions (one batch)
Ask everything in one message, numbered, each with your recommendation, so the owner can answer "1 yes, 2 …". Cover only what is unclear or worth confirming:
1. **How we talk:** you are their only entry point, and the developer never hears from them directly. Confirm.
2. **Authority:** you give phase gos; merges, deploys and spending go to them. Confirm, or note their changes.
3. **Push backup** of the work branch after every run (needs a remote).
4. **Spikes and spending:** what counts as spending (paid APIs, live accounts), and whether paid spikes are allowed at all.
5. **Gaps between the task text and the plan:** features in one but not the other, contradictions, text that looks like litter. Quote both sides.
6. **Test isolation**, if the tests could damage shared resources (fixtures that drop and recreate databases, fixed ports). Propose a private instance that `ensure_env` starts.
7. **Protected checkout:** if the main checkout is dirty, confirm that nobody touches it and the work happens in a worktree.
8. **Other teams** (from step 1, check 9):
   - **The base:** branch from the main line and settle conflicts at merge time, or stack on the other team's branch. Give the overlapping files and a recommendation.
   - **Migration numbers:** who renumbers.
   - **The shared usage limit.**

   Record the answers in both teams' notes: in your board, and as a line for the owner to pass to the other orchestrator.

Log every answer in the board's decision log, dated, in the owner's words. Map short answers to the options you offered; never stretch one into a new permission.

## Step 4: Write the team files
In the team folder:

| File | From | Notes |
|---|---|---|
| `orchestrator.md` | `templates/orchestrator.md` | Appendix A = the task text **verbatim**; §11 = the plan's phases |
| `board.md` | `templates/board.md` | D-001 is the developer's onboarding; the phase table comes from the plan |
| `developer_onboarding.md` | `templates/developer_onboarding.md` | the prompt that makes the developer write `developer.md` |
| `progress.txt` | `templates/progress.txt` | one line per phase, in plain words |
| `<plan file>` | the owner's plan | copy it in if it lives elsewhere; it is frozen from now on |
| `reports.md`, `developer.md` | empty | the developer's |
| `memory/developer/`, `tools/`, `logs/` | empty folders | `logs/developer.log` as an empty file |

**Tailor, don't fill mechanically.** The templates are the skeleton. The plan supplies the specifics: the phases, the risky areas, the patterns to reuse, the UI languages, the test resources. Write them as a careful human would for this project.

**Placeholders** (every `{{…}}` must be gone afterwards):

| Placeholder | Value |
|---|---|
| `PROJECT`, `PROJECT_UPPER`, `SLUG`, `DATE` | the name, the name in capitals, the slug, today |
| `TASK_ONE_LINE`, `TASK_VERBATIM` | a one-line summary; §1 exactly as written |
| `TEAM_DIR`, `OPS_DIR` | absolute paths (`OPS_DIR` = `$HOME/.config/<slug>-devteam`) |
| `PLAN_FILE`, `PLAN_PATH` | the plan's file name in the team folder; its absolute path |
| `WORKTREE`, `BRANCH`, `BASE` | where the developer works, the work branch, the base commit (short SHA plus where it came from) |
| `DEV_AGENT`, `DEV_AGENT_NAME`, `DEV_MODEL`, `DEV_EFFORT` | `codex`/`claude`, "Codex CLI"/"Claude Code", the model and effort, or empty |
| `GAP_MIN`, `CAP_H`, `PUSH` | the minutes, the hours, `1`/`0` |
| `PLACES`, `PLACES_FOR_DEVELOPER` | bullet lists: the main checkout (protected or not), the worktree, the team folder, the dev env |
| `PROTECTED_CHECK`, `PROTECTED_BASELINE`, `PROTECTED_RULE` | the main-checkout check, baseline (HEAD plus the `status --short` line count) and rule. Remove the line if nothing is protected |
| `OWNER_RULES`, `OWNER_RULES_FOR_DEVELOPER` | the house rules from §6, numbered on from the template's last rule. Remove the line if there are none |
| `AUTHORITY_QUOTE` | the owner's delegation in their words, dated |
| `PAID_SERVICES`, `OFF_LIMITS` | from §5 (`OFF_LIMITS` reads ", including …", or is empty) |
| `RISKY_AREAS`, `REUSE_PATTERNS` | from the plan: what deserves mutation checks and a personal read (money, permissions, quotas, tenancy, secrets…); the existing patterns the plan names (`REUSE_PATTERNS` reads " (…)" or is empty) |
| `PHASES`, `PHASE_ROWS`, `PHASE_LINES` | the plan's phases as §11 bullets, board table rows, and progress lines |
| `UI_LANGS`, `TEST_RESOURCES`, `BACKUP_STATE`, `SETUP_DECISIONS`, `WAITING` | as named |

**Agent markers:** lines starting with `[codex]` or `[claude]` apply to one developer agent. Keep the chosen agent's lines without the marker, and delete the other's.

**Your memory:** write a pointer in your auto-memory directory for this folder. The entry says: "I am the orchestrator here; read `orchestrator.md`, then `board.md`, first on every invocation." Add one entry about the owner, if you learned something worth keeping. Don't copy rules that are already in `orchestrator.md`.

## Step 5: The machinery
**Show the owner the commands that act outside the team folder before you run them.** These are their repo, their `~/.config`, and their systemd.
1. **The worktree:** `git -C <repo> worktree add -b <branch> <worktree> <base>`. It doesn't touch the main checkout's files.
   - **From scratch:** `git init <path>`, an initial commit on `<branch>`, and a remote only if the owner wants the backup (`gh repo create --private`, with their OK).
2. **The ops folder:**
   - check once more that `<ops>` and `~/.config/systemd/user/<slug>-dev.*` don't exist; if they do, stop. They are another team's;
   - `mkdir -p <ops>`;
   - copy `scripts/developer-tick.sh` and `scripts/wait-report.sh` there, fill their placeholders, and `chmod +x` them;
   - write the agreed test isolation into `ensure_env`.
3. **The units:** fill `systemd/dev.timer` and `systemd/dev.service` into `~/.config/systemd/user/<slug>-dev.timer` and `<slug>-dev.service`, then `systemctl --user daemon-reload`. **Don't enable the timer yet.**
4. **Test resources:** create the private instance if one was agreed. The sandbox can't start services, so `ensure_env` starts them before each run.

## Step 6: Verify (report each result to the owner)
1. `bash -n` on both filled scripts.
2. `<skill>/scripts/test-tick.sh <ops>/developer-tick.sh`: every case passes. It uses a fake agent in a temp folder.
3. `systemd-analyze --user verify ~/.config/systemd/user/<slug>-dev.service ~/.config/systemd/user/<slug>-dev.timer`.
4. `grep -rn '{{' <team> <ops>` and `grep -rnE '^\[(codex|claude)\]' <team>` both find nothing.
5. **A smoke run of the real CLI** (it costs a few thousand tokens; say so), from an empty folder:
   - `codex exec --skip-git-repo-check -s read-only "Reply with the single word OK."`, or
   - `claude -p "Reply with the single word OK." --permission-mode auto`.

   It proves the sign-in and the model. Then the worktree is on `<branch>`, and the protected checkout is unchanged.

## Step 7: Hand over
Tell the owner, in a few lines:
- what you set up, and where;
- what happens next: the developer does D-001 (environment, baseline, `developer.md`) and reports R-001; you review it, then issue the Phase 0 doc step;
- the two commands to start everything:
  ```
  systemctl --user enable --now <slug>-dev.timer
  /loop Orchestrator tick: follow <team>/orchestrator.md §7
  ```
  The first runs in their terminal; you may run it on their OK. The second they type here.
- that `progress.txt` is their glanceable status, and every tick's reply starts with it in full;
- that they can pause everything with `touch <team>/PAUSE`.

From then on, `orchestrator.md` §7 drives every tick, and `references/operations.md` is your run book. After R-001 is accepted, record the test baseline and any known flakes under "Now" in the board.
