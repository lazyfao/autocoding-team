# Autocoding team: prerequisites

Fill this in and put it in a new, empty folder: the **team folder**. Then open Claude Code in that folder and run `/autocoding-team`.
Claude becomes the orchestrator. It reads this form and your plan, checks both, asks you its questions, then sets everything up.

**Before you start**
- **The team folder holds only this form and your plan file(s).** Don't copy or clone the skill into it. Install the skill once, outside (see the README), and every team folder uses that copy.
- **The team folder is not where the code lives.** The developer works in a separate git worktree (§3). The team folder only holds the coordination files: the board, the reports, the logs.
- **Replace each `<…>` placeholder completely,** angle brackets included. `team/<short name>` becomes `team/teams`, not `team/teams>`.
- **Use absolute paths.** Every path must exist, except the worktree path, which must **not** exist yet.

Sections 1 and 2 are required. Everything else has a default: leave a field empty to take it.
See `examples/PREREQUISITES.example.md` in the skill for a filled-in example.

## 1. The task, in plain words (required)
What you want done, in your own words. It is copied **verbatim** into the orchestrator's instructions and wins over the plan on intent.

```
<your text>
```

## 2. The implementation plan (required)
Path(s), one per line. Check each one with `ls`; a typo stops the setup.
-

A plan grown from real development of the app and its real code: decisions, design, phases, verification. The orchestrator sequences it; the developer implements it.
No plan yet? Write one first, for example in Claude Code's plan mode inside the repo. The orchestrator works best with a plan that was checked against the code.

## 3. Places (expected, optional)
- Repo (main checkout):
- Protect the main checkout? (it has uncommitted work, or nobody should touch it): yes
- Base branch or commit: `origin/main`
  - Prefer the remote branch. A local `main` can be days behind; the setup fetches first.
- Work branch: `team/<short name>`
  - Letters, digits, `/`, `-` and `_` only.
- Worktree path (where the developer works): `<repo>-<short name>`, next to the repo, for example `/home/me/code/notes-teams`
  - A **new** folder that doesn't exist yet: the setup creates it with `git worktree add`.
  - It is not the team folder and not inside it.
- Dev environment (runtimes, databases, tools the tests need):
- Shared resources the tests could damage:
  - Look at how the test suite sets up: does it drop and recreate databases, flush a cache, or use fixed ports or fixed file paths?
  - List each one with its port. The setup gives this team its own instance (for example, a private Postgres cluster on a free port) and marks yours as off limits.
  - Leaving this empty when the tests do drop things means the developer's test runs can wipe your data, or another team's.

Starting from scratch? Leave the repo empty and give a path for the new one here:

## 4. The developer
- Agent: `codex` (tested) or `claude` (supported, not yet run unattended by the author)
  - Teams on the same account share its usage limits. Two developers on one Codex account run out about twice as fast.
- Slug: `<short name>`
  - Short and lowercase. It names the timer (`<slug>-dev.timer`), the service and the ops folder (`~/.config/<slug>-devteam/`).
  - It must be **unique on this machine**. A slug that's already taken would overwrite another team's timer and scripts. See the taken ones with `ls -d ~/.config/*-devteam`.
- Model and reasoning effort: the CLI's defaults
- Gap between runs: 5 min
- Run cap: 6 h

## 5. Authority
- The orchestrator gives phase gos and accepts or rejects work: yes
- Escalated to you: merges, deploys, spending
- Push the work branch as a backup after every run: yes
- Paid services and live accounts that count as spending:
  - List **every** paid API or cloud service the work may call, **including the one this task integrates.** Add any live account that could be banned or charged.
  - Anything missing from this list may be treated as free.
- Off limits:
  - production hosts and other servers (by name, for example `ssh root@prod`);
  - accounts and cloud resources the developer must not touch;
  - your own databases and ports;
  - other teams' worktrees, branches and databases.

## 6. Other teams on this repo or machine
Is another autocoding team, or other unattended work, running on the same repo or the same machine? For each one, give:
- Team folder and slug:
- Work branch, and the files and migrations it already changed (`git diff --stat <base>..<their branch>`):
- Its test resources (databases, ports) and its developer's account:

The setup checks for overlap: the same files, clashing migration numbers, shared test resources, and a shared usage limit. It raises these in its questions. You then choose whether to branch from the main line and settle conflicts at merge time, or to stack on the other team's branch.

## 7. House rules (defaults; edit freely)
- Docs and memory first, code after.
- No over-engineering.
- Legacy is removed outright, no shims.
- The UI never shows technical names. UI languages:
- Anything else:
