---
name: praxis-review-pr
description: Review a GitHub PR and produce GitHub-ready review comments with file, line, and markdown. Handles re-reviews after fixes and groups of related PRs. Use when the user asks to review a PR by number, URL, or chat link ("review pr 123", "review-pr #456", "fais une review de la pr 789", "la pr X a été corrigée, refais une review").
argument-hint: "<pr-number|github-url|chat-url> [more-prs] [scope=frontend|backend|all] [full]"
---

**YOU ARE EXECUTING THE `/praxis-review-pr` SKILL.** Follow ALL instructions below step by step. Think carefully. Follow CLAUDE.md rules.

## References

- [review-evidence.md](../references/review-evidence.md) — ticket context, reachability, executed exploits, remedies, evidence discipline, agent reconciliation, comment hygiene, user-facing strings. **Every finding must satisfy it.**
- [templates/pr-comments.md](templates/pr-comments.md) — output format and evidence bar
- **Project review guide** — `praxis.json › review.guide` when set. Its sections are authoritative for project facts: stack, domain routing, review bots and known noise, i18n rules (locale roots, source of truth, escape marker), test tiers. Read the sections the diff touches.

## Non-negotiable rules

- **READ-ONLY on the user's checkout** — never modify a file, never `git checkout` there, never apply a fix. The deliverable is a review, not a patch.
- **A throwaway worktree is allowed, and is how you earn the right to assert a mutation.** `git worktree add /tmp/wt-<pr> <sha>`, run the suite and the mutations there, paste the failing test and its output, then **delete the worktree and say so**.
- **NEVER post, approve, or request changes without explicit user confirmation** (step 10), even when the review finds nothing.
- **ALWAYS pass `--repo owner/name`** to every `gh` call — `gh` silently defaults to the cwd remote.
- **Review comments are written in French.** Code, identifiers and code blocks stay as-is.
- **Every finding carries evidence** — a source line read, a type resolved, a runtime result. Library behaviour is checked against the installed version in `node_modules`. Unproven findings are dropped, not softened.
- **USE AGENTS** for exploration and analysis; you orchestrate, aggregate and arbitrate. Reading the diff or a specific file yourself is expected when verifying a claim or pinning a line.

## Tool Strategy

| subagent_type | Use for |
|---------------|---------|
| `explore-codebase` | Code pattern search, convention comparison |
| `frontend-code-reviewer` | Frontend quality analysis |
| `backend-code-optimizer` | Backend quality analysis |
| `explore-docs` | Library/API documentation lookup |

The project guide may route a domain to a project-specific agent; fall back to the generic ones when it is unavailable and say so.

---

## 0. PARSE ARGUMENTS

`$ARGUMENTS` may be a bare number, `#123`, a GitHub URL, a chat message URL, several of those, or free text wrapping them.

1. **Chat URL** → read the message through the chat connector (read-only), extract the GitHub PR URL. No PR link → say so and ask.
2. **Every PR reference.** `https://github.com/OWNER/REPO/pull/N` → `OWNER/REPO` + `N`. Bare `N` → `gh repo view --json nameWithOwner -q .nameWithOwner`.
3. **Repo per PR.** A URL wins over the cwd; a repo named in prose wins over everything.
4. **Flags** — `scope=` forces the scope; `full` forces the complete pipeline.
5. **Re-review intent** — `re-review`, `refais`, `à nouveau`, `corrigé`, `adressé`, `addressed`, `fixed`, `followup`. Step 2 detects it anyway.

More than one reference → **multi-PR mode** (step 8). A reference that cannot be resolved → **ask**.

---

## 1. FETCH PR & CONTEXT

```bash
gh pr view <N> --repo <REPO> --json title,body,author,baseRefName,headRefName,state,isDraft,mergeable,additions,deletions,changedFiles,commits
gh pr diff <N> --repo <REPO> --name-only
gh pr diff <N> --repo <REPO>
gh pr checks <N> --repo <REPO> 2>/dev/null | head -30
```

Save title, author, base/head, head SHA, changed files, **full diff** (source of truth for line numbers), CI status.

**Read what is already on the PR** — never repeat it:

```bash
gh api "repos/<REPO>/pulls/<N>/comments?per_page=100" --jq '.[] | {user: .user.login, path, line, body: .body[:200]}'
gh api "repos/<REPO>/issues/<N>/comments?per_page=100" --jq '.[] | {user: .user.login, body: .body[:200]}'
```

Never `--paginate` repo-wide comment endpoints. Bots and other reviewers may already cover findings: drop duplicates, build on adjacent ones. The guide lists the project's bots and known noise.

**Read the target repo's conventions** — `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md` (local files when checked out, else `gh api "repos/<REPO>/contents/<file>" --jq .content | base64 -d`). They are review criteria.

**Ticket, spec, mock** — per review-evidence.md, before judging intent.

Flag up front: `MERGED`/`CLOSED` → ask whether to continue; draft → lower bar for nits; red CI → name the failing checks and check they are not pre-existing on the base.

---

## 2. RE-REVIEW MODE (conditional)

```bash
ME=$(gh api user -q .login)
gh api "repos/<REPO>/pulls/<N>/reviews" --jq "[.[] | select(.user.login==\"$ME\")] | .[-1] | {id, commit_id, submitted_at, state}"
```

No previous review → step 3. Otherwise:

1. `gh api "repos/<REPO>/compare/<previous_commit_id>...<head_sha>" --jq '.files[] | {filename, status, additions, deletions}'`
2. Status each previous comment by reading the current code: ✅ Résolu · ⚠️ Partiel (say what remains) · ❌ Non adressé · 💬 Répondu (read the argument; if they are right, say so and drop it).
3. Steps 3–7 **on the delta only**.

Output leads with the follow-up table. Posting: reply inside existing threads (`gh api "repos/<REPO>/pulls/<N>/comments/<id>/replies" -f body=…`); only unresolved or new findings become new inline comments.

---

## 3. SCOPE & EFFORT

**Filter the noise**: lockfiles, snapshots, build artefacts, generated configs. A PR that commits generated files the repo forbids committing → Important finding.

**Categorize** with the guide's domain routing when present; otherwise backend (`apps/api/**`, `apps/server/**`, `apps/nest*/**`, `libs/back/**`, `server/**`), frontend (`apps/front/**`, `apps/web/**`, `libs/front/**`, `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`), database (`*.prisma`, `migrations/**`), other.

**Calibrate**, after filtering:

| Size | Pipeline |
|------|----------|
| Small — ≤5 files, ≤150 lines | 1 domain reviewer + your own verification; no exploration round |
| Normal — up to ~50 files | Steps 4–5 |
| Large — beyond | Thematic batches; **state which batches were covered and which were not** |

`full` forces the complete pipeline. Announce the mode in one line.

```markdown
## PR #<N> — <titre>

**Base**: <base> ← **Head**: <head> · **Auteur**: <author>
**Scope**: <domaines> · **CI**: <status> · **Mode**: <léger|complet|par lots>
**Fichiers**: <count> (+<add> −<del>) · <n> fichier(s) généré(s) ignoré(s)
```

---

## 4. EXPLORE (PARALLEL)

All applicable agents in **one message**; skipped in small mode.

- **Frontend**: `explore-codebase` × 2 — correctness (null safety, types, hook deps, edge cases) on the files + diff; existing patterns and conventions to compare against.
- **Backend**: `explore-codebase` × 2 — correctness (error handling, null safety, architecture); similar existing patterns.
- **Conditional**: schema changes → `explore-codebase` on the schema and migrations; external library → `explore-docs`; behaviour depending on runtime config, env, i18n or a feature flag → `explore-codebase` tracing the **actual runtime value** at every call site (high-yield: most silent bugs are a value differing from what the code assumes at one call site).

Add the guide's stack facts to every prompt (e.g. which frameworks are *not* used, so an agent's defaults do not leak in).

---

## 5. DEEP ANALYSIS (PARALLEL)

| Condition | Agent |
|---|---|
| Frontend files | `frontend-code-reviewer` (or the guide's domain agent) — files, exploration context, diff; Critical/Important/Nice-to-have with exact paths and lines; verify library behaviour against the installed version |
| Backend files | `backend-code-optimizer` (or the guide's domain agent) — same instruction |

Tell agents to **prove** each claim and to report verified non-issues. On every review, systematically:

- **Test coverage** — changed behaviour covered? Name the missing case. Bug fix with a regression test that fails without the fix? Tests still exercising the real path? New shared code skipping the tests and stories its neighbours have?
- **Comment hygiene** and **user-facing strings** — per review-evidence.md, with the guide's i18n facts.

---

## 6. RECONCILE AGENT OUTPUT

Per review-evidence.md › Reconcile agent output, then › Evidence discipline on every surviving finding.

---

## 7. MAP FINDINGS TO DIFF LINES

1. Exact line in the diff, right side, checked against hunk headers.
2. Line outside the diff → review **body** under « Hors-diff / suivi », never inline.
3. Classify: `Bug` · `Issue` · `Nit` · `Question`.
4. Separate blocking from pre-existing debt the author walked past.

---

## 8. CROSS-PR CONSISTENCY (multi-PR mode)

Each PR gets steps 1–7, then a cross-cutting pass: contract alignment (field names, types, optionality, casing), endpoint paths and verbs, enums and defaults, error contract, deploy order and backward compatibility.

```markdown
### Cohérence inter-PR

> **Contrat désaligné : `<champ>`**
> - PR #<A> `path` L<n> — émet `<type>`
> - PR #<B> `path` L<n> — attend `<type>`
> <conséquence concrète>
```

---

## 9. PRESENT THE REVIEW (terminal)

Format and evidence bar in [templates/pr-comments.md](templates/pr-comments.md).

```markdown
## PR Review: #<N> — <titre>

**<x> Critical | <x> Important | <x> Nice-to-have | <x> Questions**

### Critical
> **`path/to/file.ts` L<line>**
>
> **Bug :** <titre court>
>
> <ce qui ne va pas, la preuve, la conséquence>
>
> **Suggestion :**
> ```ts
> // correctif proposé
> ```

### Important / Nice-to-have / Questions
<même forme, Issue: / Nit: / Question:>

### Positive
- <3 à 5 points concrets, spécifiques à cette PR>
```

Concise — this is read on GitHub. Concrete code in suggestions. Questions are for real ambiguity.

---

## 10. CONFIRM & POST

**Never post anything before the user explicitly says so.**

| Findings | Event |
|----------|-------|
| ≥1 Critical | `REQUEST_CHANGES` |
| 0 Critical, ≥1 Important | `COMMENT` |
| Only nits / questions | `COMMENT` |
| Nothing at all | `APPROVE` |

`AskUserQuestion`, recommendation first « (Recommandé) »: recommended · alternatives · post nothing. `APPROVE` is never automatic.

Build the payload with a script in the scratchpad (heredocs break on multi-line markdown):

```js
// <scratchpad>/build-review.mjs — run with `node <scratchpad>/build-review.mjs`
import { writeFileSync } from 'node:fs'
const payload = {
  commit_id: '<head_sha>',
  body: '<résumé + section Hors-diff / suivi>',
  event: '<COMMENT|REQUEST_CHANGES|APPROVE>',
  comments: [{ path: '<repo-relative>', line: 24, side: 'RIGHT', body: '<markdown>' }],
}
writeFileSync('<scratchpad>/review.json', JSON.stringify(payload))
```

```bash
gh api "repos/<REPO>/pulls/<N>/reviews" -X POST --input <scratchpad>/review.json
```

Multi-line: `"start_line": <n>, "start_side": "RIGHT"`. `suggestion` blocks only when they replace exactly the commented range, indentation included — and only once run (review-evidence.md).

Verify: `gh api "repos/<REPO>/pulls/<N>/comments?per_page=100" --jq 'length'`; report the review URL and the count. A comment rejected for being outside the diff moves to the body and the review is resubmitted — never dropped.

---

## 11. WRAP-UP

Suggest renaming the session (user-side command): `/rename review pr <auteur> #<numéro>` — multi-PR: `/rename review pr <feature> #<A> #<B>`.
