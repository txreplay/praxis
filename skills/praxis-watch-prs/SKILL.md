---
name: praxis-watch-prs
description: Use when the user wants the team's PR review-request channel watched — new requests reviewed via /praxis-review-pr, reviewed PRs tracked for fixes and re-reviewed on new commits, the user's own PRs watched for incoming reviews and for a red main after merge. One pass per invocation, designed for /loop. Triggers — "surveille le channel", "watch prs", "/loop /praxis-watch-prs". Do NOT use for a one-off review (/praxis-review-pr) nor for assigned tickets (/praxis-watch-tickets).
argument-hint: "[status] [stop <pr>] [force <pr>] [watch <pr>…] [unwatch <pr>] [chained]"
---

**YOU ARE EXECUTING THE `/praxis-watch-prs` SKILL.** This is **one pass**, not a daemon. Do the pass, report, stop.

## References

- [common.md](../references/common.md) — config loading, destructive-action gates
- [watch.md](../references/watch.md) — `watch` config, overlay, window, presence gate, state files, next pass
- `references/sources/{watch.prs.source}.md` — how to read the review-request channel

Load config per common.md, then `watch.prs` and the overlay's `## praxis-watch-prs` section per watch.md. Below, `{repo}`, `{channel}`, `{state}` (= `{state_dir}/prs`) come from there. Conversation and review output in French.

## Non-negotiable rules

- **NEVER post anything without explicit user confirmation** — not a review, not a GitHub comment, not an approval, not a chat message. `AskUserQuestion` every time, even when the review is empty.
- **Two carve-outs, and only two: the 👀 reaction** of step 4, and the **chat status reactions** of 1.7 (only when `watch.prs.chat_reactions` is set). The 👀 carries no judgement — it says "someone picked this up". A chat status reaction only mirrors a review the user already confirmed on GitHub. Nothing else inherits these exceptions.
- **NEVER post a message in the chat channel**, and never propose it. Apart from the status reactions of 1.7, the channel is read-only here.
- **Launching a review needs no approval** when the PR is in scope — except stacked PRs (step 3.4).
- **READ-ONLY on the user's checkout.** No file modified, no branch checked out, no fix applied. `gh pr diff` to read the diff.
- **One carve-out for proof: a throwaway git worktree, outside the user's checkout.** A subagent may `git worktree add /tmp/wt-<pr> <sha>`, run the suite and mutations there, and must **delete it when done** and say so. "Here is the one test that falls, and its output" is the version an author accepts without a round-trip.
- **One pass ends.** Never loop internally, never sleep, never poll twice. `/loop` owns the cadence.
- **Never dispatch a review for a PR already in `reviewing`.** A review takes 10–15 min, about one tick: finding one in flight is the normal case. Step 1.0 owns that decision.
- **State lives outside the repo**, under `{state}`.
- **Always pass the full PR URL** (`https://github.com/{repo}/pull/<N>`) to any downstream skill or agent. A bare number resolves against the cwd remote and can silently review the wrong repo.

---

## 0. ARGUMENTS & STATE

| Argument | Effect |
|---|---|
| *(none)* | Normal pass |
| `status` | Print the state table and stop. No chat call, no review, no `gh`. |
| `stop <pr>` | Move `<pr>` to `ignored` with reason `user-request`, permanently. Confirm in one line, stop. |
| `force <pr>` | Review `<pr>` this pass whatever the classification says (bypasses scope, draft, own-PR, stacked, nit-only delta). |
| `watch <pr> [<pr>…]` | Add to `myPRs` (step 1.5). Baseline `lastSeenTs` at the end of the previous pass, not now. Then run the pass. |
| `unwatch <pr>` | Drop `<pr>` from `myPRs` **and** `mergeWatch`. Confirm in one line, stop. |
| `chained` | Invoked by `/praxis-watch`: run the pass, skip §7, hand the report back. |

`cat {state}/state.json`. **No file → first run**: `lastScanTs` = today 00:00 local as a Slack-style ts (`date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 00:00:00" +%s 2>/dev/null || date -d "$(date +%Y-%m-%d) 00:00:00" +%s` + `.000000` — BSD then GNU `date`), empty lists, one line saying the window is today. Schema in Appendix A.

`ME=$(gh api user -q .login)` once per pass. Check the window first (watch.md) — outside it, one line and stop.

---

## 1. PHASE A — WATCHED PRs (runs first)

For every entry in `watched`. This phase only needs `gh`, so it runs even when the chat source is down.

### 1.0 Reviews in flight — settle these before anything else

An entry with `state: "reviewing"` carries a review dispatched by an earlier pass. **Default: leave it alone.** `agent` is the subagent name, `dispatchedAt` the dispatch time.

- **Never diagnose subagent liveness with `TaskList`** — it lists `TaskCreate` tasks, which this skill never writes; it is always empty.
- **An idle notification is not a status report.** It means the agent stopped producing tokens. Most often the agent finished and wrote the review as plain text instead of sending it, so the result exists and is unreachable through messages. Probing it is useless.

| Age of the dispatch | What you do |
|---|---|
| **< 45 min** | Nothing. Keep `reviewing`, log `review en cours (lancée il y a Nmin)`. No re-dispatch, no probe. |
| **≥ 45 min** | Read the transcript (below). Still writing → keep, refresh `dispatchedAt`. Finished but undelivered → recover it. Dead → clear `reviewing`, let the PR fall through to the normal triggers. |

The transcript is the only reliable liveness signal: `~/.claude/projects/<project-slug>/<session-id>/subagents/agent-a<name>-<hash>.jsonl`.

```bash
F=$(ls "$SUB"/agent-a<agent-name>-*.jsonl)
stat -f 'mtime=%Sm size=%z' -t '%H:%M:%S' "$F" 2>/dev/null || stat -c 'mtime=%y size=%s' "$F"   # BSD, then GNU
date +%H:%M:%S
tail -1 "$F" | jq -c '{t: .type, kinds: [.message.content[]?.type]}'
```

| What you see | Reading |
|---|---|
| mtime within ~60 s | **Working.** Leave it. |
| mtime frozen, last entry `{"t":"assistant","kinds":["text"]}` | **Finished, undelivered.** Recover it. |
| mtime frozen, last entry a `tool_use` or a `user` turn | **Stalled or dead.** Clear `reviewing`. |

Recover without re-dispatching — the work is paid for:

```bash
tail -1 "$F" | jq -r '.message.content[] | select(.type=="text") | .text' > "$SP/<pr>-agent-output.md"
awk '/^```json$/{f=1;next} /^```$/{f=0} f' "$SP/<pr>-agent-output.md" > "$SP/<pr>-review.json"
jq -e '{commit_id, event, n: (.comments|length)}' "$SP/<pr>-review.json"
```

Then treat it as a returned review: persist the draft (step 4), staleness check and present (step 5). A review that returns during a later pass arrives as a message: same treatment. Only a returned review clears `reviewing` (→ `pending-approval`, never back to `queued`).

### 1.1 Refresh each PR

- `MERGED` / `CLOSED` → drop from `watched`, one line, delete any `{state}/reviews/<pr>-*.json`.
- `isDraft` true → keep, mark `parked`, skip.
- Head SHA = last entry of `commits`.
- **Ready label** (only when `watch.prs.ready_label` is set): fetch `labels` too. An entry with `labelFlow: true` whose label is **absent** → the author took it back to fix it: mark `parked` (`label-removed`), launch nothing, skip 1.3 except the label probe of 1.3c. A PR announced by hand (`labelFlow` false) never had the label: its absence means nothing.

**Never loop `gh` sequentially over the list** — ten sequential `gh pr view` exceed the two-minute Bash default and lose the pass. Fan out, one atomic write per worker, sorted:

```bash
printf '%s\n' <pr> <pr> … \
  | xargs -P 6 -I{} sh -c 'r=$(gh pr view {} --repo {repo} \
      --json state,isDraft,commits,labels \
      --jq "\"\(.state) draft=\(.isDraft) head=\(.commits|last|.oid) labels=\([.labels[].name]|join(\",\"))\""); \
      printf "%s %s\n" "{}" "$r"' \
  | sort
```

Build the whole line in a variable and print it once: two writes interleave under `-P` and pair numbers with the wrong heads. If an output comes back unpaired, re-measure sequentially rather than guessing. Same for the probes of 1.3b and 1.5: `&` + `wait` or `xargs -P`. A command that must stay sequential gets `timeout: 300000`.

### 1.2 Pending approval takes priority

`pending-approval` → a review exists and was never answered. **Do not re-review.** Load `{state}/reviews/<pr>-<sha>.json`, re-present it (step 5), skip the rest of this PR — unless the head moved since the draft, in which case delete the draft and fall through to 1.3.

### 1.3 Re-review triggers

**a) Debounce.** Re-review when head ≠ `reviewedSha` **and** head == `sha` recorded at the previous pass (the author stopped pushing). Head ≠ both → mid-push: update `sha`, log `en cours de push`, wait.

**b) Author signal** (bypasses the debounce), dated after the last review:

```bash
gh api "repos/{repo}/issues/<N>/comments?per_page=100" --jq '.[] | {user: .user.login, created_at, body: .body[:200]}'
gh api "repos/{repo}/pulls/<N>/comments?per_page=100" --jq '.[] | {user: .user.login, created_at, in_reply_to_id, body: .body[:200]}'
```

Never `--paginate` repo-wide comment endpoints — scope to the PR.

**The request's chat thread is a signal too, and the channel scan never sees it**: a reply in the thread of an earlier message is not returned by the channel history (Phase B). For every entry with a `slackTs`, read the thread through the source adapter (*Read a thread*, `oldest` = `lastThreadTs`, or the dispatch time when absent), fan out like 1.1. Keep the replies newer than `lastThreadTs` that are not from the user — a bot's included: some review bots post the new round in the thread. A reply that mentions the user and asks for another look → author signal, whoever posted it. From the PR author → apply the keywords below. From anyone else → one report line (who, what they ask); a question addressed to the user goes in the notification of step 5. Advance `lastThreadTs` to the newest reply read, after reporting.

Keywords from the **PR author**: `corrigé`, `corrigée`, `fixed`, `adressé`, `addressed`, `c'est bon`, `relance`, `up`, `updated`, `push`, `done`, `ready`. A signal with **no new commit** is not a trigger — log it.

**A commit subject is a signal too** — some authors answer only in the subject line:

```bash
gh api "repos/{repo}/compare/<reviewedSha>...<head>" \
  --jq '.commits[] | select(.author.login=="<author>") | .commit.message | split("\n")[0]'
```

Scan for the keywords plus `answer`, `address`, `review`, `thread`, `feedback`, `nit`. Filter on the author's own commits (a rebase drags in foreign subjects). A subject naming a review is a claim the round must verify.

**c) Ready label put back** (only when `watch.prs.ready_label` is set) — the strongest signal, and the only one the chat never shows: putting the label back notifies the earlier reviewers but posts nothing new in the channel.

```bash
gh api "repos/{repo}/issues/<N>/timeline?per_page=100" \
  | jq --arg l "{ready_label}" --arg t "<reviewedAt>" \
      '[.[] | select((.event=="labeled" or .event=="unlabeled") and .label.name==$l and .created_at > $t)] | last | {event, at: .created_at, by: .actor.login}'
```

Last event `labeled` after `reviewedAt` → trigger (reason `label`), bypasses the debounce, clears `parked`. It also counts without a new commit — the author may have answered in threads only; 1.4 then sizes the round. Last event `unlabeled` → `parked` per 1.1. An entry without `reviewedAt` (never reviewed by us) uses `dispatchedAt` or `lastAction`.

### 1.4 Queue it

A triggered PR enters the queue as a **re-review** with its reason (`debounce` / `signal` / `label`). **A nit alone does not earn a round** — a round costs an agent and one arbitration by hand, and rounds that produce nothing are common:

| What the new commits address | What you do |
|---|---|
| A **Critical** or **Important** still open, from **any** reviewer | Full re-review. Queue it. |
| Only nits, questions, formatting, coverage | **No agent.** Verify the fix yourself (one or two commands), propose a thread reply (needs the user's go-ahead), record the new `reviewedSha`. |
| Nothing raised — a rebase on main, an unrelated file | Update `sha`, no queue, one line. |

`force <pr>` overrides this.

### 1.5 `myPRs` — the user's own PRs, watched for INCOMING reviews

`watched` holds PRs you review; `myPRs` holds PRs the user authored, watched so they learn when somebody reviews *them*. Never reviewed, queued or dispatched. Entries arrive automatically (step 3.1, `source: "slack"`) or by `watch <pr>` (`source: "manual"`).

For each `OPEN` entry (a `MERGED` one moves to `mergeWatch`, a closed one is dropped):

```bash
N=<pr>; T="<lastSeenTs>"
gh api "repos/{repo}/pulls/$N/reviews?per_page=100" \
  | jq --arg t "$T" --arg me "$ME" '.[] | select(.submitted_at > $t and .user.login != $me and .user.type != "Bot") | {kind:"review", user:.user.login, state, at:.submitted_at, body:.body[:400]}'
gh api "repos/{repo}/pulls/$N/comments?per_page=100" \
  | jq --arg t "$T" --arg me "$ME" '.[] | select(.created_at > $t and .user.login != $me and .user.type != "Bot") | {kind:"inline", user:.user.login, at:.created_at, path, line, in_reply_to_id, body:.body[:400]}'
gh api "repos/{repo}/issues/$N/comments?per_page=100" \
  | jq --arg t "$T" --arg me "$ME" '.[] | select(.created_at > $t and .user.login != $me and .user.type != "Bot") | {kind:"issue", user:.user.login, at:.created_at, body:.body[:400]}'
```

Also read the request's chat thread as in 1.3b (`lastThreadTs`): a question asked there, by anyone but the user, is an incoming event like a GitHub comment.

Exclude `$ME` and bots on every axis. Anything found → the `PushNotification` of step 5 (« #N : review de @x (CHANGES_REQUESTED, 3 commentaires) ») and a report entry sized to the event: who, event, count, substance of the blocking points. `lastSeenTs` advances **only after** reporting. Do not offer to answer, fix or push — this is a notification channel.

### 1.6 `mergeWatch` — the user's merged PRs, watched for a RED `main`

A PR green on its branch and `main` green after the merge are two facts: `main` re-runs from the squashed commit, against everything that landed in between, sometimes on a cold cache. When a `myPRs` entry flips to `MERGED`, move it to `mergeWatch` with `mergeCommit`, `mergedAt`, `title`, `notified: []`. Every pass:

```bash
gh api "repos/{repo}/actions/runs?head_sha=<mergeCommit>&per_page=100" \
  --jq '.workflow_runs[] | select(.event=="push" or .event=="merge_group") | {name, event, status, conclusion, url: .html_url, id}'
```

**Query workflow runs filtered on `event`, never the commit's raw check-runs.** GitHub pins scheduled runs to whatever commit was HEAD when the cron fired; a chronically red scheduled E2E suite would read as "your merge broke main". Only `push` / `merge_group` runs are the merge's verdict. `gh pr checks` is not a substitute — it reports the PR's head commit, not the merge commit.

| What the runs say | What you do |
|---|---|
| Any `queued` / `in_progress` | Keep, say nothing loud. A main pipeline takes 20–40 min. |
| All completed, none `failure` / `timed_out` / `cancelled` | **Green.** Drop, one line: `#N mergée — pipeline main verte`. |
| A `failure` / `timed_out` | **Red.** Attribute, notify, report, keep. |
| Nothing conclusive 3 h after `mergedAt` | Drop with a line saying the verdict never came. |

**Attribute before you shout.** Ask the workflow's history, not the commit:

```bash
gh run list --repo {repo} --workflow "<workflow>" --limit 8 --json event,conclusion,createdAt,headSha \
  --jq '.[] | "\(.createdAt) \(.event) \(.conclusion) \(.headSha[:9])"'
```

| History | Verdict |
|---|---|
| Already failing before | **Pré-existant** — say how long, stop there. |
| Green before, red now | **Introduit par ce merge** as far as evidence goes — fetch `gh run view <id> --repo {repo} --log-failed \| tail -60` and quote the error. |
| Never ran on earlier commits | **Inconclusive** — affected-only CI skips most workflows; walk back to the last run or report without attribution. |

Notify once per failing workflow (`notified`), and only when **introduced**. Read only: no re-run, no revert, no fix — not even offered.

### 1.7 Chat status reactions — reconcile every pass

Only when `watch.prs.chat_reactions` is set (watch.md). The review request in the channel carries a reaction that tells its author, and everyone else, where the review stands. Keys and the moment each one applies:

| Key | When |
|---|---|
| `reviewing` | Review dispatched (step 4) |
| `commented` | Our effective verdict is `COMMENTED` |
| `changes_requested` | Our effective verdict is `CHANGES_REQUESTED` |
| `approved` | Our effective verdict is `APPROVED` |

**Effective verdict** = GitHub is the source of truth, not the state file: among `$ME`'s reviews on the PR (`/pulls/<N>/reviews`), the last `APPROVED` or `CHANGES_REQUESTED` one; none, or the last one `DISMISSED` → `COMMENTED` if `$ME` posted any review at all; nothing → no verdict yet. A `COMMENT` posted after a `REQUEST_CHANGES` leaves the block in place on GitHub, so the reaction stays `changes_requested`.

**Every pass**, for each `watched` entry with a `slackTs`, plus each PR posted this pass: compute the expected set (`reviewing` once dispatched, plus the effective verdict's key), add every expected emoji missing from the entry's `chatReactions` through the source adapter (*React to a message*), append it to `chatReactions`. This also catches a review the user posted by hand, outside the skill.

**Reactions accumulate.** The adapter can add a reaction, not remove one: 👀 stays next to the verdict, and a later verdict stacks on an earlier one. Read the state as the most advanced emoji, in the order `approved` > `changes_requested` > `commented` > `reviewing`. The one case this order misreads — `changes_requested` after an earlier `approved` — goes in the report as one line telling the user to remove the stale emoji by hand.

A failed reaction never blocks the pass: one line in the report, the next pass retries it.

---

## 2. PHASE B — CHANNEL SCAN

Read the channel through the source adapter, messages strictly newer than `lastScanTs`. Adapter failure → one line, skip the phase, keep `lastScanTs`; the pass is partial and says so.

Extract `github\.com/{repo}/pull/(\d+)` from every message. Other repos → dropped silently. A relance unfurls an earlier message: dedupe by PR number; a relance on a watched PR counts as an author signal (1.3b). Several PRs in one message → several references. `lastScanTs` advances to the newest message only at step 6.

**Second source — the ready label** (only when `watch.prs.ready_label` is set). An announcement can be missed (bot down, message deleted, posted elsewhere); the label cannot. Once per pass, independent of the chat source — it runs even when the adapter fails:

```bash
gh pr list --repo {repo} --label "{ready_label}" --state open --limit 100 \
  --json number,author,isDraft,title,headRefOid \
  --jq '.[] | "\(.number) \(.author.login) draft=\(.isDraft) head=\(.headRefOid[:9]) \(.title)"'
```

A PR already in `watched`, `myPRs` or `ignored` (same head for `backend-only`) → nothing, 1.x handles it. The label lists PRs from before the state's memory too (a previous session, a state reset), so **ask GitHub what the user already did** before treating one as new — `gh api "repos/{repo}/pulls/<N>/reviews?per_page=100" --jq '[.[] | select(.user.login=="'"$ME"'")] | last | {state, commit_id, submitted_at}'`:

| The user's last review | What you do |
|---|---|
| `APPROVED` at the current head | Nothing, silently. |
| Any review at an older head | Enter `watched` as `awaiting-fix`, `reviewedSha` = its `commit_id`, `reviewedAt` = its `submitted_at`, `labelFlow: true`. 1.3 decides on the next pass. |
| None | A new reference |

Any new reference goes to step 3 for step 3 with `slackTs: null` and `slackUser` unknown (report the GitHub login, recover the handle from the channel later if it shows up). Phase B dedupes the two sources by PR number; the chat message wins when both exist, since it carries `slackTs`.

---

## 3. CLASSIFY

First rule that fires wins.

### 3.1 Hard filters

```bash
gh pr view <N> --repo {repo} --json author,isDraft,state,title,body,baseRefName,url,labels
```

When `watch.prs.ready_label` is set and the PR carries it, record `labelFlow: true` on the entry: its later absence then means "back in correction" (1.1).

| Condition | Outcome |
|---|---|
| `author.login == $ME` | `ignored` (`own-pr`) **and** `myPRs` with `lastSeenTs` = the message time in ISO (`date -u -r <epoch> '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d @<epoch> '+%Y-%m-%dT%H:%M:%SZ'`) and `source: "slack"` |
| `state ≠ OPEN` | `ignored` (`closed`) |
| `isDraft` | `parked`, re-checked each pass |

Both halves of the own-PR rule matter: `ignored` stops the review, `myPRs` starts the watch for the answer.

### 3.2 Message text first

The message contains one of `frontend_markers` (case-insensitive) → in scope, `scope=all`, no diff needed. Other words do not settle it — fall through.

### 3.3 Changed files otherwise

`gh pr diff <N> --repo {repo} --name-only`

| Match | Outcome |
|---|---|
| any `scope_all_globs` | in scope, `scope=all` |
| none of those, but any `scope_contract_globs` | in scope, `scope=contract` — DTO shape, field names, optionality, generated types, error contract; not the internals. **Check the diff first**: a change that leaves the consumer-visible contract untouched is `backend-only`. |
| neither | `ignored` (`backend-only`), record the SHA |

A `backend-only` PR is re-checked if still open and its head moved.

### 3.4 Stacked PRs — ask before launching

`baseRefName ≠ main`, or the body says *stacked on* / *merge that one first* → the diff includes the parent's commits. **Ask** (`AskUserQuestion`): reviewer quand même (default) · attendre le merge de la base (`parked`) · ignorer (`stacked-declined`).

### 3.5 Related PRs

Two or more watched PRs sharing a ticket key → suggest `/praxis-review-pr <url> <url>` for a cross-PR pass in the report. Never launch it.

---

## 4. DISPATCH REVIEWS

**Presence gate first** (watch.md). Away → dispatch nothing, report the queue.

**Budget**: re-reviews first, then new PRs oldest first, `watch.prs.budget` max. Say how many are left. When several reviews come back at once, group the confirmations into one `AskUserQuestion`.

**Record the dispatch before dispatching**: `"state": "reviewing", "agent": "review-<pr>-<HHMM>", "dispatchedAt": "<ISO>"`. Without it, a tick landing mid-review dispatches the same review twice.

**👀 reaction**, same turn:

```bash
gh api -i "repos/{repo}/issues/<N>/reactions" -X POST -f content=eyes | head -1
gh api "repos/{repo}/issues/<N>/reactions" --jq '.[] | select(.content=="eyes" and .user.login=="'"$ME"'") | .id'
```

Store `reactionId` **only on `201`**. `200` means the reaction already existed — the user's own, never to be removed. A failed reaction never blocks the review.

**Chat `reviewing` reaction**, same turn, when `watch.prs.chat_reactions` is set: add it on the request message (`slackTs`) and append it to `chatReactions` (1.7). On a re-review it is usually already there: skip.

**One subagent per PR, all in one message**: `subagent_type: "general-purpose"`, `name: "review-<pr>-<HHMM>"` (never a bare `review-<pr>` — names collide), `run_in_background: false`. Store the name the harness actually returns. A backgrounded subagent's plain text never reaches you — the prompt makes `SendMessage` mandatory; keep that paragraph.

Prompt template:

> Invoke the `praxis-review-pr` skill with arguments: `https://github.com/{repo}/pull/<N> scope=<all|frontend>` (state `scope=contract` → `scope=frontend`).
>
> Follow it through **step 9 (PRESENT THE REVIEW)** and **STOP THERE**. Do NOT execute step 10: post nothing, approve nothing, request no changes, run no `gh api ... -X POST`. You cannot ask the user for confirmation and confirmation is mandatory.
>
> [IF RE-REVIEW] This is a **re-review**. Trigger: <debounce|signal auteur>. Status **every open point on the PR, from every reviewer**: fetch all of `repos/{repo}/pulls/<N>/comments` and `.../issues/<N>/comments`, group threads via `in_reply_to_id`, mark each ✅ Résolu / ⚠️ Partiel / ❌ Non adressé / 💬 Répondu with the current code as evidence.
>
> [IF scope=contract] Review it **as a contract**: DTO field names, types, optionality, enum values, generated types, error contract, backward compatibility for consumers. Not the internals.
>
> You may prove a finding by mutation in a throwaway worktree outside the user's checkout (`git worktree add /tmp/wt-<N> <sha>`); delete it when done and say so. Never touch the user's working tree.
>
> **Deliver your result with `SendMessage({to: "main", ...})` — mandatory, the only channel that works.** Your plain text output is NOT visible to the orchestrator; a review written as your final message reaches nobody. Do not end your turn on a review you have not sent. If the send fails, retry; do not fall back to plain text.
>
> Send exactly, in one message:
> 1. The review in the step 9 markdown format (French).
> 2. The recommended event (`COMMENT` / `REQUEST_CHANGES` / `APPROVE`) with a one-line justification.
> 3. A fenced ```json block with the step 10 payload — **exactly `commit_id`, `body`, `event`, `comments[]`** (`path`/`line`/`side`/`body`). `replies` is not a reviews-API field; replies to existing threads go in a separate `replies` array **outside** the payload, as `{comment_id, body}`. Every inline line must be inside the diff; the rest goes in `body` under « Hors-diff / suivi ».
> 4. The head SHA you reviewed.

**Persist the draft immediately** on return: `{state}/reviews/<pr>-<sha>.json` (+ `.replies.json`), entry → `pending-approval`, drop `agent`, **keep `dispatchedAt`** (the staleness cutoff).

---

## 5. PRESENT, CONFIRM, POST

**Notify** — one `PushNotification` per pass covering, in order: a new red `main` attributed to a merge, reviews awaiting approval, incoming reviews on the user's PRs.

**Present**, per PR:

```markdown
### PR #<N> — <titre> · @<slackUser>
<x> Critical | <x> Important | <x> Nit | <x> Question · **Recommandé : <EVENT>**
[re-review] <n> résolu(s) · <n> partiel(s) · <n> non adressé(s)

<Critical et Important en entier ; nits en une ligne>
```

**Confirm** — one `AskUserQuestion` per PR (or one batch), recommendation first: ≥1 Critical → `REQUEST_CHANGES`; otherwise `COMMENT`; nothing at all → `APPROVE`. Options: recommended · alternative · ne rien poster (stays `pending-approval`) · abandonner (`ignored`, `user-request`). `APPROVE` is never automatic. Content changes → edit the payload file and re-present; never post an edited-in-your-head version.

### Staleness check — AFTER the answer, immediately before POST

The answer can come minutes or a night later, and a PR under review is the most active kind there is. Observed: the check ran clean, the author pushed the fix twenty minutes later, someone approved the next morning, and the review posted on the morning answer re-blocked a fixed and approved PR. **The last `gh` call before `-X POST` is this check.** Cutoff = `dispatchedAt`.

```bash
gh pr view <N> --repo {repo} --json commits --jq '.commits|last|.oid'
T="<dispatchedAt>"
gh api "repos/{repo}/pulls/<N>/reviews?per_page=100" | jq --arg t "$T" '.[] | select(.submitted_at > $t) | {user: .user.login, state, submitted_at}'
gh api "repos/{repo}/pulls/<N>/comments?per_page=100" | jq --arg t "$T" '.[] | select(.created_at > $t) | {user: .user.login, path, line, in_reply_to_id, body: .body[:200]}'
gh api "repos/{repo}/issues/<N>/comments?per_page=100" | jq --arg t "$T" '.[] | select(.created_at > $t and .user.type != "Bot") | {user: .user.login, created_at, body: .body[:200]}'
gh api "repos/{repo}/pulls/<N>/reviews?per_page=100" --jq '.[] | select(.state != "COMMENTED") | {user: .user.login, state, submitted_at}'
```

(`gh api --jq` takes no `--arg` — pipe into `jq`.)

**New commits** — `gh api "repos/{repo}/compare/<commit_id>...<head>" --jq '.files[] | {filename, patch}'`:

| What they changed | What you do |
|---|---|
| Nothing a finding touches | POST with `commit_id` = new head. |
| Some findings fixed | Drop those comments, adjust the body, re-present, ask again. Never post a finding you just saw fixed. |
| Too much to tell | Draft stale: delete, re-queue as re-review (`head-moved`). |

**Someone else reviewed** — same finding → drop yours, reply in their thread with the evidence they lack · findings you missed → not yours to post · an `APPROVED` landed → say it before asking, your `REQUEST_CHANGES` now blocks a cleared PR · the author replied → read it, drop or rephrase what they answered.

**Repairing a stale posted review** (each step needs the go-ahead): reply in each wrong finding's thread naming the reviewed SHA and the fixing SHA, never delete. If the event was `REQUEST_CHANGES`, only the same reviewer's `APPROVE` or a dismissal lifts it — a `COMMENT` saying "je lève mon blocage" does nothing. Offer approve / dismiss / leave the block, verify with `gh pr view <N> --json reviewDecision`.

### Post

```bash
gh api "repos/{repo}/pulls/<N>/reviews" -X POST --input {state}/reviews/<pr>-<sha>.json
gh api "repos/{repo}/pulls/<N>/comments/<comment_id>/replies" -f body="<texte>"   # each reply
```

Re-review: unresolved and new findings only; resolved ones are never re-posted. Report the review URL and the inline count. A comment rejected for being outside the diff moves to the body and the review is resubmitted — never dropped.

### After posting

1. **Remove the 👀 first**: `gh api "repos/{repo}/issues/<N>/reactions/<reactionId>" -X DELETE` — only the id you stored; no `reactionId` = not yours.
2. **Chat verdict reaction** (when `watch.prs.chat_reactions` is set): reconcile this PR per 1.7 right away, before it can leave `watched` — an approved PR is dropped next.
3. `APPROVE` → drop from `watched`. Otherwise → `awaiting-fix`, `reviewedSha` = the SHA posted against, `reviewedAt` = the posting time (the cutoff of 1.3c); delete the draft, drop `dispatchedAt`, `reactionId`, `trigger`.

---

## 6. SAVE STATE & REPORT

Write the state. Advance `lastScanTs` only if Phase B succeeded.

**Nothing happened** → time + standing situation, one PR per line:

```markdown
**HH:MM** — rien de neuf.

- [**#N**](https://github.com/{repo}/pull/N) · @slackUser · `abc1234` — ce qui bloque
- [**#N**](…) · ta PR · mergée à HH:MM · pipeline `main` en cours sur `abc1234`
```

Clickable full URL, `@` + the chat handle (`slackUser`, never derived from the GitHub login; fall back to `author` silently), short SHA, what is blocking.

**Something happened** →

```markdown
## Passe HH:MM

**Canal** : <n> message(s) · <n> nouvelle(s) PR · <n> ignorée(s)
**Suivi** : <n> PR · <n> re-review(s) déclenchée(s) · <n> sans changement
**Reviews** : <n> produite(s) · <n> en cours · <n> en attente de ton accord · <n> en file
**Tes PR** : <n> review(s) reçue(s) · <n> merge(s) sous surveillance CI

<détail par PR>
```

Then, when relevant: related PRs (3.5), PRs dropped this pass, `mergeWatch` verdicts, partial pass. Do not suggest next steps.

## 7. NEXT PASS

Per watch.md › Next pass, with `watch.prs.interval_sec`. Skipped under `chained`.

---

## Appendix A — state schema

`{state_dir}/prs/state.json`

```json
{
  "lastScanTs": "1785486175.599119",
  "watched": {
    "101": {
      "slackTs": "1785478448.604459",
      "title": "…", "author": "gh-login", "slackUser": "jane.doe", "ticket": "KEY-1",
      "scope": "all", "sha": "a1b2c3d", "reviewedSha": "9f8e7d6",
      "state": "awaiting-fix", "lastAction": "2026-07-31T09:12:00Z",
      "chatReactions": ["eyes", "speech_balloon"],
      "reviewedAt": "2026-07-31T09:12:00Z", "labelFlow": true, "lastThreadTs": "1785479012.000100"
    },
    "102": {
      "state": "reviewing", "agent": "review-102-0904", "dispatchedAt": "2026-07-31T09:04:00Z",
      "reactionId": 348812771, "trigger": "signal"
    }
  },
  "ignored": { "103": { "reason": "backend-only", "sha": "1122334", "slackUser": "john.roe" } },
  "myPRs": {
    "104": { "title": "…", "ticket": "KEY-2", "slackTs": "…", "sha": null, "lastSeenTs": "2026-08-03T12:56:32Z", "addedAt": "…", "source": "slack" }
  },
  "mergeWatch": {
    "105": { "title": "…", "mergeCommit": "<full sha>", "mergedAt": "2026-08-03T15:10:55Z", "notified": [] }
  },
  "presence": { "lastAskedAt": "…", "lastAnsweredAt": "…", "lastLatencySec": 132 }
}
```

`state` ∈ `queued` · `reviewing` · `pending-approval` · `awaiting-fix` · `parked`. `agent` exists only while `reviewing`. `dispatchedAt` survives into `pending-approval` (staleness cutoff) and is dropped once posted. `reactionId` exists only when this skill created the reaction (`201`). `chatReactions` lists the emoji names already added on the request message (1.7) — reactions are never removed, so the list only grows. `reviewedAt` is when our last review was posted (1.3c cutoff). `labelFlow` is true once the PR was seen carrying `ready_label`. `lastThreadTs` is the newest reply read in the request's chat thread (1.3b, 1.5), on `watched` and `myPRs` entries alike. `parked` carries an optional `parkedReason` ∈ `draft` · `label-removed` · `stacked-base`. `scope` ∈ `all` · `contract` (a legacy `frontend` value means `contract`). `ignored.reason` ∈ `backend-only` · `own-pr` · `closed` · `stacked-declined` · `user-request`. `source` ∈ `slack` · `manual`. `author` is the GitHub login, `slackUser` the chat handle — never substitute one for the other.

`reviewedSha` is a cache: GitHub (`/pulls/<N>/reviews` filtered on `$ME`) is the source of truth.

## Out of scope

PRs where GitHub requests the user's review without a channel message. That would be a second trigger (`gh search prs --review-requested=@me --repo {repo}`) — a deliberate future addition, not something to add on your own initiative.
