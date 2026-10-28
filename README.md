# autocoding-team

A Claude Code skill that turns one conversation into a small autonomous coding team. You give it:
- a task in plain words;
- an implementation plan grown from your real app and its real code.

Then it sets up:
- **an orchestrator:** the Claude Code session you're talking to. It supervises, gates quality and holds the full picture;
- **an unattended developer:** Codex CLI or Claude Code, started by a systemd timer, doing all the repo work;
- **the plumbing** that lets them work for days: a board, reports, gates, cooldowns, a push backup, and a checklist you can glance at.

```
 you ──chat──▶ ORCHESTRATOR (Claude Code, this conversation)
                  │ writes board.md (rules, one directive)       ▲ reads reports.md
                  ▼                                              │
              systemd timer ──▶ developer-tick.sh ──▶ DEVELOPER (codex exec / claude -p)
                                  (gates, cooldowns, push)        works in a git worktree
```

## The three roles
| Role | Who | Instructions |
|---|---|---|
| **Owner** | you | You talk **only** to the orchestrator, in one conversation: the root conversation is your single window into the project. Every decision you make is logged on the board in your words. |
| **Orchestrator** (LLM1) | Claude Code | The skill writes its standing instructions, `orchestrator.md`, from your task and plan. It sequences the phases, accepts or rejects work against evidence, runs a second-model code review at each phase close, pushes back on over-engineering, and escalates only merges, deploys and spending. |
| **Developer** (LLM2) | Codex CLI (tested) or Claude Code (supported) | The skill writes a prompt (`developer_onboarding.md`) that makes the developer write **its own** standing instructions, `developer.md`, after it has read the plan and the repo. Then it works one directive at a time, docs first, and reports with evidence. |

## What it expects
- **Required:** a plain-words task description and a well-built implementation plan: decisions, design, phases, verification, written against the real codebase (Claude Code's plan mode works well for this).
- **Expected but optional:** the path to the repo and to the dev environment. Without a repo, the skill starts a new one, if you want to begin from scratch this way.

## Requirements
- Linux with systemd user units (tested on WSL2 with systemd). macOS/launchd is not covered.
- [Claude Code](https://claude.com/claude-code) for the orchestrator.
- For the developer, either:
  - [Codex CLI](https://github.com/openai/codex), signed in. Tested: unattended over two days, 27 directives;
  - Claude Code. Supported by the tick script, and smoke-tested headless in auto mode (it edited, committed and reported), but the author hasn't yet run it through a whole project. With Claude in both roles, the orchestrator and the developer share one usage allowance.
- `git`, and `gh` if you want the push backup to a new GitHub repo.

## Install
```sh
git clone https://github.com/lazyfao/autocoding-team ~/autocoding-team
ln -s ~/autocoding-team ~/.claude/skills/autocoding-team
```
Start a new Claude Code session afterwards, so it picks the skill up.

## Start a project
1. Make an empty team folder, for example `~/myproject_team`.
2. Copy `PREREQUISITES.md` into it and fill in at least the task and the plan path. `examples/PREREQUISITES.example.md` shows a filled one.
3. Open Claude Code in that folder and run `/autocoding-team`.
4. Answer its intake questions (one batch).
5. It writes the team files and the machinery, tests them, and hands you two commands:
   ```
   systemctl --user enable --now <slug>-dev.timer
   /loop Orchestrator tick: follow <team>/orchestrator.md §7
   ```
From there, the orchestrator wakes when the developer reports, decides, and writes the next directive. `progress.txt` in the team folder is your glanceable status. `touch <team>/PAUSE` stops the developer.

## What it builds
| In the team folder | Writer | Purpose |
|---|---|---|
| `orchestrator.md` | orchestrator | its standing instructions (role, authority, the tick, gates, the over-engineering watch, your task verbatim) |
| `board.md` | orchestrator | the developer's rules, the one active directive, phases, waiting-on-you, decision log |
| `developer_onboarding.md` | orchestrator | the developer's first read and the brief for writing `developer.md` |
| `developer.md` | developer | the developer's own standing instructions, verified against the repo |
| `reports.md` | developer | append-only reports: ACK / PROGRESS / DONE / BLOCKED / QUESTION, with evidence |
| `memory/developer/`, `tools/` | developer | its working memory and durable helper scripts |
| `progress.txt` | orchestrator | your checklist: `[✓]` done, `[>]` in progress, `[ ]` next |
| `logs/` | tick script | the developer's full log and last message |

Outside it:
- `~/.config/<slug>-devteam/`: the tick script and the report watcher, out of the developer's reach;
- `~/.config/systemd/user/<slug>-dev.{timer,service}`;
- a git worktree on its own branch, so your main checkout and its uncommitted work stay untouched.

**The tick script handles:**
- `PAUSE`;
- a 15 min cooldown after a failure, and a 3 h retry loop after a usage limit (vendors sometimes reset early);
- skipping runs while the developer waits for the orchestrator;
- retrying a run that died before reporting;
- a hook for private test resources;
- the push backup.

`scripts/test-tick.sh` tests all of this with a fake developer.

## Inside the skill
- `SKILL.md`: the setup workflow Claude follows.
- `templates/`: `orchestrator.md`, `board.md`, `developer_onboarding.md`, `progress.txt`.
- `scripts/`: `developer-tick.sh`, `wait-report.sh`, `test-tick.sh`.
- `systemd/`: the timer and service units.
- `references/operations.md`: the run book (doorbell, pause, cooldowns, liveness, limits, verifying a DONE).
- `references/lessons.md`: why each rule exists. Every one came from something that went wrong, or nearly did, in a real multi-day run.

## Principles baked in
- Be honest first: evidence over claims, for both agents.
- Docs and memory first, code after, in every phase.
- No over-engineering: reuse the patterns the plan names, and reject designs that would never trigger.
- One directive at a time. Phase gos from the orchestrator; merges, deploys and spending from you.
- A second-model review (`/code-review`) at every phase close.

## License
MIT
