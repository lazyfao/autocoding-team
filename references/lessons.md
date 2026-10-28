# Lessons: why each rule exists

Every rule in the templates came from something that happened in a real run of this workflow: an orchestrator (Claude Code) and an unattended developer (Codex CLI) took a production SaaS through a multi-phase feature migration. Each item below names what happened and the rule it produced.

## Honesty and evidence
1. **Be honest first.** The owner put "First of all - be honest!" at the top of both standing instructions. Report failures with their output. Say "not tested" when it wasn't.
2. **Test claims about the machinery before making them.** The orchestrator told the owner "runs never overlap" without checking. The owner asked "how do you know that?". Transient systemd units then showed what actually happens:
   - a oneshot service never overlaps itself;
   - a start request during a run joins that run;
   - the timer keeps firing after failures.

   Only after that test did the claim go into the instructions.
3. **Evidence over claims, both ways.** The developer's DONE carries commits, the exact commands and literal summary lines. The orchestrator reruns a cheap subset and reads the riskiest hunk itself.

## Talking to the owner
4. **A short answer to a choice maps to the offered options.** The orchestrator asked "accept the risk that only a rule stops the developer from using SSH, or harden it?". The owner answered "i allow using ssh root@…". The orchestrator read it as permission for the developer and started editing the rules. The owner meant "accept". Now: map a short answer to one of the options, and ask in one line if it fits none.
5. **One window.** The owner talks only to the orchestrator, and the decision log in the board is the full record. The developer never gets instructions from the owner directly. So there is one place to look, and no conflicting orders.
6. **A checklist the owner can glance at.** `progress.txt` holds one line per item, `[✓]`/`[>]`/`[ ]`/`[!]`, in plain words. The owner asked for it. It is updated every tick.
7. **Open numbers become settings, not questions.** When the owner wants values (prices, quotas) adjustable, they go into the product's admin area with placeholder seeds. Don't collect them in chat.

## Judging sources and designs
8. **Primary sources first.** The orchestrator trusted a reseller's note ("this model reads about 2K tokens") over the model maker's own docs (a 64K context). The owner asked: "why do you trust a 3rd party more than the model owner and hoster?". The vendor that builds or hosts a thing is the default truth for its own route.
9. **Reject designs that never trigger.** A proposed optimization depended on an optional field the provider might not return, so it would never have fired. Simplified: do the plain full step, then check the result. Ask "when exactly does this fire?" of every conditional design.
10. **Spikes only when absolutely necessary,** zero-cost routes first: docs, earlier measurements, recorded fixtures, free tiers. Escalate a paid spike with its estimate.
11. **Second-model review at every phase close.** `/code-review medium` found 8 and 12 real issues in two phases, including a money leak and an inexact rollback. Tests and mutation checks had passed both times.

## The machinery
12. **Write the board last.** The developer may start the moment the board changes. Clearing a cooldown before the board was final once nearly let a run start on a stale board. Rule: all board edits at the end of the tick, then anything that lets a run start.
13. **Refresh the skip hash after bookkeeping edits.** Otherwise a log-only board change looks like new work, and a full agent run starts with nothing to do.
14. **A failed run without a report must be retried.** The skip check (last report DONE + unchanged board) blocked the retry after a usage limit cut a run off mid-directive: the last report was the *previous* directive's DONE. The script now forgets the board hash when a failed run left no report.
15. **Usage limits: retry every 3 h, don't pause.** Vendors reset early from time to time, and a still-limited retry fails at once, at no cost. Pausing needed a human to notice the reset.
16. **Transient vendor errors ("model at capacity") are not limits.** Use the normal 15 min cooldown.
17. **Check only executed commands for forbidden ones.** A grep for `ssh` over the whole log raised a false alarm. It matched the board's own rule text, which Codex had read and echoed. Grep the executed-command lines only.
18. **Liveness is log growth, not run time.** Real runs took hours; the cap went from about 3 h to 6 h. Stuck means the service is active and the log has been silent for 60 min.
19. **PROGRESS lines at milestones.** A run killed by a limit or the cap left an exact "left off at", and the next run resumed cleanly from it.

## The environment
20. **Isolate test resources.** The repo's test fixtures dropped and recreated fixed database names. Sharing the owner's database server would let parallel runs wipe each other. The team got its own cluster on its own port, which the tick script starts, since the sandbox can't.
21. **Never touch the owner's main checkout.** It held uncommitted work. The developer works in a git worktree, and the orchestrator checks the main checkout's HEAD and status against a recorded baseline at every DONE.
22. **Own runtimes per worktree.** Using the main checkout's virtualenv would test the wrong code: an editable install points at the other tree.
23. **Durable helper folder.** The developer's scripts and evidence go in `<team>/tools/`, not `/tmp`, which a reboot wipes.
24. **Push as a backup after every run,** from the tick script, not by the developer. The developer never pushes, merges or deploys.
25. **Codex specifics** (codex-cli 0.16x):
    - `--sandbox` can't be combined with `--approve-for-me`. The default exec sandbox is workspace-write.
    - Git commits need an escalation, which `--approve-for-me` reviews.
    - `--ignore-rules` and `--disable apps` keep the owner's own allowlist and app connectors (merge, deploy) away from the developer.
26. **Hook findings on untouched code: list once, move on.** Without this rule, design-lint hooks pulled the developer into fixing old code outside the directive.
27. **Known flakes need fresh evidence.** A full run is green only if the known flakes are its only failures and that same report shows them passing alone.
