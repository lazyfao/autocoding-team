# Autocoding team: prerequisites (fictional example)

## 1. The task, in plain words (required)
```
Our notes app has one shared space per account. I want teams:
- an account can create teams and invite people by email;
- a note belongs to a team or stays private;
- team members see and edit the team's notes, nobody else does;
- removing a member keeps the notes they wrote in the team.
No billing changes. The mobile app comes later; web only.
```

## 2. The implementation plan (required)
Path: `~/notes-team/teams_plan.md`
(written in Claude Code plan mode against the repo: decisions, data model, API, UI, migration, phases 0–5, tests)

## 3. Places (expected, optional)
- Repo (main checkout): `~/code/notes`
- Protect the main checkout?: yes (it has my uncommitted work on `feature/search`)
- Base branch or commit: `origin/main`
- Work branch: `team/teams`
- Worktree path: `~/code/notes-teams`
- Dev environment: Python 3.12 venv, Node 20, Postgres 16 on 5432
- Shared resources the tests could damage: the test fixtures drop and recreate `notes_test` on whatever Postgres they point at

## 4. The developer
- Agent: `codex`
- Model and reasoning effort: defaults
- Gap between runs: 5 min
- Run cap: 6 h

## 5. Authority
- The orchestrator gives phase gos and accepts or rejects work: yes
- Escalated to you: merges, deploys, spending
- Push the work branch as a backup after every run: yes
- Paid services and live accounts that count as spending: the email provider (invites), the OpenAI API
- Off limits: `prod.notes.example`, the staging database

## 6. House rules
- Docs and memory first, code after.
- No over-engineering.
- Legacy is removed outright, no shims.
- The UI never shows technical names. UI languages: English, German
- Anything else: every new API route gets a two-account isolation test
