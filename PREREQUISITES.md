# Autocoding team: prerequisites

Fill this in, put it in a new empty folder (the **team folder**), open Claude Code in that folder and run `/autocoding-team`.
Claude becomes the orchestrator. It reads this form and your plan, asks you its questions, then sets everything up.

Sections 1 and 2 are required. Everything else has a default: leave a field empty to take it.
See `examples/PREREQUISITES.example.md` in the skill for a filled-in example.

## 1. The task, in plain words (required)
What you want done, in your own words. It is copied **verbatim** into the orchestrator's instructions and wins over the plan on intent.

```
<your text>
```

## 2. The implementation plan (required)
Path:

A plan grown from real development of the app and its real code: decisions, design, phases, verification. The orchestrator sequences it; the developer implements it.
No plan yet? Write one first, for example in Claude Code's plan mode inside the repo. The orchestrator works best with a plan that was checked against the code.

## 3. Places (expected, optional)
- Repo (main checkout):
- Protect the main checkout? (it has uncommitted work, or nobody should touch it): yes
- Base branch or commit:
- Work branch: `team/<short name>`
- Worktree path (where the developer works): `<repo>-<short name>`, next to the repo
- Dev environment (runtimes, databases, tools the tests need):
- Shared resources the tests could damage (a database the fixtures drop and recreate, fixed ports):

Starting from scratch? Leave the repo empty and give a path for the new one here:

## 4. The developer
- Agent: `codex` (tested) or `claude` (supported, not yet run unattended by the author)
- Model and reasoning effort: the CLI's defaults
- Gap between runs: 5 min
- Run cap: 6 h

## 5. Authority
- The orchestrator gives phase gos and accepts or rejects work: yes
- Escalated to you: merges, deploys, spending
- Push the work branch as a backup after every run: yes
- Paid services and live accounts that count as spending:
- Off limits (production hosts, other servers, accounts):

## 6. House rules (defaults; edit freely)
- Docs and memory first, code after.
- No over-engineering.
- Legacy is removed outright, no shims.
- The UI never shows technical names. UI languages:
- Anything else:
