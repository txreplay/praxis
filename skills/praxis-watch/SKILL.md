---
name: praxis-watch
description: Use when the user wants one background session watching both the PR review-request channel and their assigned tickets — "lance la veille", "/loop /praxis-watch", "surveille les PR et mes tickets". One pass per invocation, designed for /loop. Do NOT use for a single watcher on demand (/praxis-watch-prs, /praxis-watch-tickets).
argument-hint: "[state] [prs <args…>] [tickets <args…>]"
---

**YOU ARE EXECUTING THE `/praxis-watch` SKILL.** One pass = one `praxis-watch-prs` pass, then — at most every `watch.tickets.interval_sec` — one `praxis-watch-tickets` pass, then **one** report and **one** next-pass decision.

## References

- [watch.md](../references/watch.md) — config, window, next pass

## Arguments

| Argument | Effect |
|---|---|
| *(none)* | Normal pass |
| `state` (or `status`) | State tables of both watchers (`praxis-watch-prs status`, `praxis-watch-tickets state`). No remote call. Stop. |
| `prs <args…>` | Forward to `praxis-watch-prs` (`watch <pr>`, `stop <pr>`, `force <pr>`, `unwatch <pr>`), then the normal pass |
| `tickets <args…>` | Forward to `praxis-watch-tickets` (`skip <KEY>`, `unskip <KEY>`, `force <KEY>`, `post=auto`), then the normal pass |

## Pass

1. **Window** — one `ToolSearch` call for `ScheduleWakeup,PushNotification`. Outside the window: one line, then step 5.
2. **PRs** — invoke `praxis-watch-prs` (Skill tool) with `chained` plus forwarded args.
3. **Tickets** — `{state_dir}/tickets/state.json` → `lastRunAt` older than `watch.tickets.interval_sec`, absent, or `tickets …` args given → invoke `praxis-watch-tickets` with `chained` plus forwarded args. Otherwise one line « Tickets : prochaine passe à HH:MM ».
4. **Report** — both reports under one `## Passe HH:MM` heading, PRs first. Nothing else.
5. **Next pass** — watch.md › Next pass with `watch.prs.interval_sec`; `noop: true` only when neither watcher changed anything.

## Rules inherited, not relaxed

Every gate of both sub-skills applies: no review, comment, approval, chat message or provider comment without `AskUserQuestion` (except `tickets post=auto`, opt-in per launch); read-only on the checkout; never touch `.current`; state outside the repo. When both passes return questions, ask them in **one** `AskUserQuestion` batch, PRs first.
