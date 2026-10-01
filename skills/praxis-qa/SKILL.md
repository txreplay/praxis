---
name: praxis-qa
description: Use when a change must be checked in a real browser against the ticket and the design — "qa local", "qa <env>", "teste en local", "vérifie sur <env>", after a deploy to a shared environment, or as the QA stage of /praxis-ship. Do NOT use for unit tests, nor to write E2E tests.
argument-hint: "[<qa target>] [app=<app>] [TICKET_KEY]"
---

# /praxis-qa [<qa target>] [app=…] [TICKET_KEY]

Walk the running app through the ticket's acceptance criteria and the design, in the browser, and leave a verdict the reviewer and the QA team can reuse.

## References

- [common.md](../references/common.md) — config, active ticket, tracking
- `praxis.json › ship` — `qa_targets` (first = default), `test_context` (the test account / tenant to use)
- The overlay's `## praxis-qa` section — **the project's apps**: stack, local port, Node version, serve command, "this is my build" probe, proxy route, URLs per target, useful routes, how a deploy is checked, common mistakes. Without it, ask the user for the URL and the serve command before opening the browser.

## Iron rules

- **A page in error does not accuse the code.** Preflight first (proxy, port, build origin, backend called); only then judge the UI.
- **Always the test context of `ship.test_context`.** The user handles authentication: on a login page, stop and ask them to log in — never type credentials.
- **The design is re-captured at the start of every run**, never compared from memory.
- **Every verdict has a proof**: a screenshot, a network request, or a console line.

## 0. Scope

- Ticket: argument → `{tracking_dir}/.current` → branch name. Read the ticket file: AC, Décisions, design links, flag. No tracking → ask for the AC list first.
- Flags read by the diff must have a **known** state on the target (Décisions or the user). Unknown → ask now.

## 1. Preflight

**Which app?** From `git diff --name-only origin/main...HEAD` and the overlay's app table. Everything below is keyed on it.

**Local target**

| Check | How | Fix |
|---|---|---|
| Runtime version | `node -v` (or the stack's equivalent) vs the overlay | switch version |
| Local proxy | the overlay's proxy check | start it |
| Who listens | `lsof -nP -iTCP:<ports> -sTCP:LISTEN` then `ps -o pid,etime,command -p <pids>` | A server for **the right app and mode** already up → reuse it. Another mode, or a second instance on a shifted port → report and **ask** before killing (another session may own it). |
| Server | the overlay's serve command, in the background with output to a file, only if nothing suitable listens | wait for the port line |
| Build origin | the overlay's "this is my build" probe in the page | absent = a deployed or stale build, not yours |
| Backend called | `read_network_requests` → which host answers | a residual local env file can silently redirect; ask the user to check it |

**Shared target** — the deploy must have landed: the overlay's (or `praxis.json › deploy`) workflow run for a SHA containing your commits (`git merge-base --is-ancestor <your sha> <run sha>`), `completed/success`; then the propagation delay and a **hard reload**. An old UI on the first load is not a bug.

**Flags** — to test the OFF path, ask the user to toggle the flag on the target — never assume it can be, never edit flag code to simulate it. Not toggleable → the OFF path is « non testé », not « OK ».

Never open `localhost:<port>` directly when the overlay names a proxied domain: different origin, no session.

## 2. Design capture

For each design node linked in the ticket: `mcp__Figma__get_metadata` on the parent section (node ids higher than the linked ones were added after the cadrage), then `mcp__Figma__get_screenshot`. Note the capture time.

## 3. Walkthrough (claude-in-chrome)

Invoke the `claude-in-chrome` skill, load the browser tools in **one** `ToolSearch` call. Per acceptance criterion:

1. Navigate, act, observe, screenshot.
2. Compare with the capture: layout, copy, and **every state** drawn — empty, loading, error, disabled (with its tooltip), success feedback.
3. Mutations: after each write, this page **and the pages the user arrives from** show the new data without a manual reload (the network shows the refetch).
4. Console: `read_console_messages` filtered on `error|warn` — anything new versus a page outside the diff is a finding.
5. Flag OFF path: identical to `main`, or « non testé ».

Stop and ask after 2–3 failed browser actions — never loop on a page that does not respond.

## 4. Report

```markdown
## QA {target} — {TICKET_KEY} · {date HH:mm} · design capturé {HH:mm}

| # | Critère | Verdict | Preuve | Écart design |
|---|---|---|---|---|
| 1 | … | ✅ / ❌ / ⚠️ | capture / requête / console | — / description |

**Bloquant** : … · **Non bloquant** : … · **Hors périmètre constaté** : …
Preflight : proxy ✅ · port {n} ✅ · build local ✅ · backend {host} · flag `{name}` = {state}
```

With praxis tracking: Avancement `- {date} : QA {target} — {x}/{y} AC OK, {n} écarts`; blocking findings into Progression › Blocages.

On a shared target, a draft **displayed only** for the QA team: what to test, where (URL + test context), steps, flag to enable, known limitations. Short, French, no first names outside developers.

## Common mistakes

Read the overlay's table first. Generic ones:

| Symptom | Cause |
|---|---|
| 502 on the proxied domain | proxy down, or the dev server still warming up on the first hit — reload |
| Old UI, nothing you change shows up | a second server on another port, the proxy routes the first one |
| Login page | opened `localhost:<port>` directly |
| Feature invisible on a shared target | deploy not landed, propagation, no hard reload, or flag off |
| Front calls a remote backend while testing a backend change | residual local env file |
