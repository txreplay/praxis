---
name: praxis-deploy
description: Use when work must land on the shared deployment branch of praxis.json › deploy (a test environment) — "mets sur <env>", "merge sur <env>", "cherry-pick <env>", "push <env>", "tout est sur <env> ?", or after review fixes the QA team must re-test. Do NOT use to push a feature branch or to open a PR (/praxis-ship).
argument-hint: "[branch|pr=<n>|sha…] [--check]"
---

# /praxis-deploy [branch|pr=<n>|sha…] [--check]

Put a branch on the shared deployment branch without overwriting anyone, then confirm the deploy actually landed. Default source: the current branch.

## Config

`praxis.json › deploy`:

```json
"deploy": {
  "branch": "staging",
  "workflow": "deploy-staging",
  "url": "https://staging.example.com/",
  "propagation": "~2 min, then a hard reload"
}
```

Below, `{branch}`, `{workflow}`, `{url}` come from there. Missing section → ask the user.

## Iron rules

- **`{branch}` is shared and force-pushed by others.** Always start from a fresh `origin/{branch}`; never push `--force`. A rejected push means someone moved the branch: fetch and redo, never override.
- **Merge, not cherry-pick**, unless the user asks for specific commits. A merge surfaces conflicts once and pushes fast-forward on top of what is there.
- **Never chain a piped checkout with `&&`** — `git checkout x 2>&1 | tail -2 && git merge …` merges on the wrong branch when the checkout fails (the pipe's exit code is `tail`'s). One command per line, check each exit code.
- **No Claude session link lands on `{branch}`**: `git log --format=%B origin/{branch}..HEAD | grep -nE 'Claude-Session|claude\.ai/code'` must print nothing — we never force-push there, so a trailer that lands cannot be removed.
- **Push is a human gate**: show what will land, ask « Je push {branch} ? », then push.

## Steps

### 0. Resolve the source

No argument → current branch. `pr=<n>` → `gh pr view <n> --json headRefName`. SHAs → cherry-pick mode (confirm). `--check` → report only: `git fetch origin {branch}`, `git cherry origin/{branch} <branch>` (`+` = missing, `-` = present), `git log origin/{branch} --oneline --grep=<TICKET_KEY>`. Stop.

### 1. Fresh branch in a throwaway worktree

```bash
git fetch origin {branch} main
git worktree list | grep -E '\[{branch}\]' || true   # informative, never touched
WT=$(mktemp -d /tmp/deploy-wt.XXXX)
git worktree add "$WT" origin/{branch}              # detached, always fresh
```

### 2. Combine

`git -C "$WT" merge --no-edit <source-branch>` (or `cherry-pick <sha…>`). Conflicts → stop, show the files, resolve **with the user**, then run typecheck and the tests of the touched projects **in `$WT`**.

Show what lands: `git -C "$WT" log --oneline origin/{branch}..HEAD`, plus other developers' commits on `{branch}` not on main: `git -C "$WT" log --oneline --no-merges origin/main..origin/{branch} | grep -v "$(git config user.name)"`.

### 3. Push

Ask « Je push {branch} ? ». Then `git -C "$WT" push origin HEAD:{branch}`. Rejected → `git fetch origin {branch}`, `git -C "$WT" merge origin/{branch}`, push again. Never `--force`, never `--force-with-lease`. Cleanup: `git worktree remove "$WT"`.

### 4. Deploy watch

`gh run list --branch {branch} --workflow {workflow} --limit 3 --json headSha,status,conclusion,url` — watch in the background until the run for **your** SHA completes.

- `success` → « déployé, {propagation} », URL `{url}`.
- `failure` → name the job and the error, say whether the previous run already failed, **wait for the go**.
- `cancelled` → neither green nor red.

### 5. Tracking & report

Praxis (`.current`): Avancement `- {date} : poussé sur {branch} ({merge sha}) — déploiement {run url} {verdict}`.

```markdown
## {branch} — {source}
Merge {sha} sur origin/{branch} ({n} commits) · déploiement {✅ / ❌ / ⏳} · QA : {url} après {HH:mm}
Aussi présent sur {branch} (autres devs) : {list or —}
```

## Common mistakes

| Symptom | Cause |
|---|---|
| Other people's commits vanished | force-push of a stale local branch |
| `fatal: '{branch}' is already used by worktree` | local branch held by a worktree — the throwaway worktree avoids it |
| Merge happened on the feature branch | piped checkout chained with `&&` |
| « Pas déployé » 30 s after the push | run not finished, propagation, no hard reload |
| Feature deployed but invisible | flag off on that environment — name the flag |
