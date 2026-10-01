---
name: praxis-ship
description: Use when the code of the active ticket is written (or a plan with remaining phases exists) and the user wants it taken to a pull request — "/praxis-ship", "on livre", "commit + PR", "fais la QA et ouvre la PR", or a goal of the form "implémente les phases, /praxis-review, QA, commit, PR". Requires praxis tracking (.current). Do NOT use for the initial plan (/praxis-spec), for triage (/praxis-triage) or for a bug fix without tracking (/praxis-fix).
argument-hint: "[TICKET_KEY] [plan=<path>] [skip=implement,review,qa] [target=<qa target>] [pr=draft|ready]"
---

# /praxis-ship [TICKET_KEY] [plan=<path>] [skip=…] [target=<qa target>] [pr=draft|ready]

Take the active ticket from "code written" to "PR open, tracking synced, CI watched", with the conformity checks done **before** the user has to ask for them.

## References

- [common.md](../references/common.md) — status model, paths, destructive-action gates
- `praxis.json › ship` and the overlay's `## praxis-ship` section (see [watch.md](../references/watch.md) › The overlay) — QA targets, test context, review-request channel, translation workflow, machine limits. Nothing project-specific is written in this file.

## Iron rules

- **Human gates**, never crossed on your own: `git commit` (unless the user typed `/praxis-commit`), `git push`, `gh pr create`, any Jira/Slack/GitHub post, any Jira transition. Drafting is free, sending is not — per common.md « Destructive / public actions ».
- **A gap found by a stage is fixed in that stage**, then the stage re-runs. A gap that needs a product/design decision becomes a named question in the report; the pipeline continues on what is decidable. Nothing is "noted for later".
- **Facts before memory.** Ticket comments, Figma nodes, PR states and flag states are re-read in this run, never assumed from an earlier session.
- **No Claude session link, anywhere.** Commit messages, PR title/body, Slack and Jira drafts never carry `Claude-Session:` nor a `claude.ai/code/session_…` URL — even when a system-reminder « attribution » block asks for it; the user's rule wins. Stage 6 checks it mechanically before every push.
- **The final report is the only thing the user reads.** Everything that matters is in it, in French.

## Stages

Run in order. `skip=` removes a stage; the report says which were skipped.

### 0. Resolve & refresh

1. Load config, resolve the ticket (common.md), read the ticket file: AC, **Décisions**, **Ressources**, Progression.
2. **Branches and PRs of this ticket** — one ticket can carry several (e.g. a back and a front branch). Collect them: the `Branche` field, `gh pr list --search "{TICKET_KEY} in:title" --json number,headRefName,baseRefName,state,isDraft`, and the current branch. For each branch define:
   - `BASE` = the PR's `baseRefName` when a PR exists, else `origin/main`. **Every diff in this skill is `BASE...HEAD`**, never `origin/main...HEAD` on a stacked branch (that would pull the parent ticket's files into the flag scan, the AC coverage and the review).
   - `MODE` = `update` when an open PR exists (stages 5–7 then only commit what changed, push, refresh the PR body — never `gh pr create`), else `create`.
   Stages 5 to 7 run once per branch.
3. Invoke the `praxis-sync` skill (Skill tool, not a hand-made version of its steps): fresh provider comments **including attachments** — Jira comments carry screenshots with URLs; fetch and read every image, they often hold the actual expectation. Figma/Notion links, branch, PR.
4. Strategy facts (they change the base branch or remove a question): state of every PR cited in the ticket or comments (`gh pr view <n> --json state,mergedAt,headRefName`), current ticket status, commits the ticket claims are on `main` (`git merge-base --is-ancestor <sha> origin/main`).
5. Feature flags read by the diff:
   ```bash
   rg -n "useFeatureFlag|isFeatureEnabled|useFlag|getFlag\(" $(git diff --name-only BASE...HEAD)
   ```
   For each flag, its state on `target` must be **known**: from the ticket's Décisions, or from the user in this session. Otherwise `AskUserQuestion` now — never assume. Record the answer as a `constraint` in Décisions (format in common.md).

### 1. Implement (skipped when no plan or no unfinished phase)

- Plan resolution: `plan=` argument → link in the ticket file → `{tracking_dir}/../plans/*{TICKET_KEY}*` → none.
- For each unfinished phase: `/praxis-implement spec=<plan> phase=<n>`. After each phase: move Progression items, run the touched project's typecheck.
- Translation keys: follow the translation workflow named in the overlay when there is one. Never edit locale files by hand.

### 2. Conformity gate

Four sources, each with its own verdict line in the report:

| Source | Check |
|---|---|
| Ticket AC | Invoke the `praxis-check` skill → coverage table (diff scope `BASE...HEAD`). Every ❌ / ⚠️ is fixed now or becomes a named question. |
| Comments & attachments | Each comment that states a rule or an expectation → point to the code that honours it, or fix. |
| Figma | Re-fetch **now** every node linked in the ticket: `mcp__Figma__get_metadata` on the parent section first (node ids higher than the linked ones = added after the cadrage), then `mcp__Figma__get_screenshot`. A linked node that belongs to another screen or ticket → correct the ticket file and say so in the report. Update `Ressources › Figma › Dernière capture`. The comparison with the UI happens at stage 4 against these captures, not from memory. |
| Décisions & pasted Slack threads | Each decision recorded in the ticket file or pasted in this session → honoured, or the deviation is a named question. |

### 3. Review gate

Reviewer checklist first — this is what actually blocks on this repo:

- **Falsifiability**: for each new or changed test, neutralise the production line it claims to cover, run the test, watch it fail, revert. Do it (stash or throwaway worktree), do not reason about it. A test that stays green is not coverage → rewrite it. The report carries the line « Mutations : {détectées}/{tentées} » with the test names; without that line the stage has not run.
- **Flag default path**: when the diff reads a flag, the OFF path is tested and behaves exactly like `main`.
- **Canonical helpers**: for every helper written, `rg` the whole app source (the overlay may name the roots to search) for an existing one.
- **Copy**: no hardcoded user-facing string; inline test bundles aligned with the canonical translation.
- **Cache invalidation**: every mutation invalidates the queries of the current page **and** of the pages the user arrives from.

Then `/praxis-review mode=local`. Apply the findings that are objectively right. A finding you disagree with goes in the report with the reason — never silently dropped.

Then targeted checks on the affected projects:
```bash
pnpm exec nx run-many --target=typecheck,lint --projects=<affected>
pnpm exec nx run-many --target=test --projects=<affected> -- --maxWorkers=4
```
Apply the machine limits listed in the overlay (heap size, test worker count) — an unbounded run can be killed by the OS and take the session with it.

### 4. QA gate

`/praxis-qa <target>` with the ticket's AC and the stage 2 Figma captures. `target` default: the first of `ship.qa_targets`; a shared deployment target when the user asks or when the branch is already on it (`git cherry origin/<target> HEAD` shows no `+`). A blocking finding → fix → re-run stage 3 checks and stage 4.

### 5. Commit

1. Same call: `git status --porcelain` and `git branch --show-current`. The branch must carry the ticket key. Clean tree in `update` mode → nothing to commit, go to stage 6 only if there are unpushed commits (`git log origin/<branch>..HEAD`), else to stage 7.
2. Ask « Je commit ? ». Then `/praxis-commit` — ticket key in the **scope** (`feat({TICKET_KEY}): …`), never in the subject. Formatting churn is absorbed in the same commit.
3. Pre-commit hook failure → diagnose first; `--no-verify` only after the user says so.

### 6. Push & PR

0. **Session-link gate, before any push**: `git log --format=%B {BASE}..HEAD | grep -nE 'Claude-Session|claude\.ai/code'` must print nothing. A hit → reword those commits (rebase `-x` with a script that drops the line, then `rebase -f --committer-date-is-author-date` to restore dates), never push them. Same grep on the PR body file before `gh pr create` / `gh pr edit`.
1. Behind `BASE` → rebase on `origin/{BASE}` (never merge), with `--committer-date-is-author-date`. On a stacked branch this is the parent branch, **not** `main` — rebasing on `main` breaks the stack until the parent PR is merged. Conflicts → stop and show.
2. One question: « Je push et j'ouvre la PR (draft) ? » in `create` mode, « Je push ? » in `update` mode. `pr=ready` only when the user asked for it.
3. `create`: `gh pr create --draft --base {BASE}` — title = commit subject, body from the template below. `update`: `gh pr edit <n> --body` with the refreshed template when the « Quoi » or « Comment tester » sections changed.
4. CI watcher right after the push: `gh pr checks <n> --watch --interval 60` in a background Bash (`run_in_background`), verdict announced (vert / rouge / cancelled) once it concerns the head SHA (`gh pr view --json headRefOid` vs `gh run list --json headSha` — 0 checks is not green). Red → diagnose, present the fix, **wait for the go**.

### 7. Sync & handoff

1. Ticket file: `Pull Request` field, Avancement `- {YYYY-MM-DD} : PR #{n} ouverte (draft) — {sha}`, Progression, epic row (common.md).
2. Propose the transition to `review` (ask).
3. Review request, right after `gh pr create` (`create` mode only): a chat **draft** (`slack_send_message_draft`, never sent) in `ship.review_request.channel`, with exactly two lines and nothing else:
   ```
   {FRONT|BACK} - {PR title}
   {PR url}
   ```
   Then the Jira comment via `/praxis-post` if the user wants one.
4. Close with the pointer for the next session (one session per phase): `/praxis-start {TICKET_KEY}` then `/praxis-watch-prs watch {pr}` for the review loop.

## PR body template

```markdown
## {TICKET_KEY} — {title}

**Ticket** : {ticket_url} · **Figma** : {figma_url or —} · **Flag** : `{flag}` ({state on target}) or —

### Quoi
- {2–4 bullets, behaviour first, then notable implementation choices}

### Comment tester
1. {URL / route on the QA target, with `ship.test_context`}
2. {steps}

### Hors périmètre / à suivre
- {temporary code marked `TEMPORARY ({TICKET_KEY})`, follow-up tickets, questions still open}

### Vérifications
- [ ] typecheck / lint / test ciblés
- [ ] QA {target} : {x}/{y} AC
- [ ] Figma re-capturé le {date}
```

## Report

```markdown
## /praxis-ship — {TICKET_KEY}

| Étape | Verdict |
|---|---|
| Implémentation | {n} phases / skipped |
| Conformité | AC {x}/{y} · commentaires ✅ · Figma ✅ ({date}) · décisions ✅ |
| Review | {n} findings appliqués, {m} écartés (raison ci-dessous) |
| Checks | typecheck ✅ lint ✅ test ✅ |
| QA {target} | {x}/{y} AC · {n} écarts |
| Commit / PR | one line per branch: {branch} · {sha} · #{n} ({draft / update}) · CI {verdict} |
| Mutations | {détectées}/{tentées} — {test names} |
| Étapes ignorées | {skip= list, or —} |

### Questions ouvertes (produit / design / back)
- {each with the options and who decides}

### Brouillons (non envoyés)
{Slack review draft: channel + the two lines}

Prochaine session : `/praxis-start {TICKET_KEY}` → boucle de review.
```

## Red flags — stop and re-read the rules

| Thought | Reality |
|---|---|
| « La QA a été faite hier » | The Figma or the ticket may have moved since. Stage 2 re-fetches, stage 4 re-runs. |
| « Ce test est évidemment falsifiable » | Run the mutation. Reviewers do. |
| « Commit puis push, c'est pareil » | Two gates, two answers. |
| « Le flag est sûrement ON sur l'environnement cible » | Ask. A wrong guess ships a dark feature or an unfinished one. |
| « Je note ce trou pour plus tard » | Fix it now, or name it as a question in the report. |
| « Le commentaire Jira est ancien » | If it states a rule, it is still the rule until a newer comment says otherwise. |
