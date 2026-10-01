# Praxis — Shared Conventions

## Loading the provider

Every skill starts with:

1. Locate `praxis.json` at the project root (walk up from cwd if needed)
2. Read `provider` → load `providers/{provider}.md` from this references directory
3. Read `site` → use for URLs in templates
4. Read `tracking_dir` (default: `.claude/generated/praxis`)
5. Read `ticket_pattern` (default: `[A-Z][A-Z0-9]+-\d+`) — the regex for ticket keys in branches, commits and PR titles
6. Optional sections: `overlay`, `ship`, `watch` (see [watch.md](watch.md)), `review` (`guide`, `checklists`, `report_template` — see `praxis-review`)

If `praxis.json` is missing → ask the user to create one.

**Provider CLI check**: Before any provider command, verify the CLI is installed (e.g., `which jira`). If missing → stop with: "CLI `{provider}` introuvable. Voir le fichier provider pour les instructions d'installation."

## Status model (provider-agnostic)

| Praxis   | Display (FR) |
| -------- | ------------ |
| todo     | À faire      |
| active   | En cours     |
| review   | Revue        |
| done     | Terminé      |
| blocked  | Bloqué       |

Unmapped provider status → keep original.

## Active ticket resolution

Priority order (first that resolves):

1. `TICKET_KEY` argument if provided
2. `{tracking_dir}/.current` → `ticket` field
3. Git branch (`git branch --show-current` → extract `ticket_pattern`)
4. Ask the user

## Paths and conventions

- Tracking dir: `{tracking_dir}` (from `praxis.json`)
- Epic file: `{tracking_dir}/{folder}/{EPIC_KEY}-{slug}.md`
- Ticket file: `{tracking_dir}/{folder}/{TICKET_KEY}-{slug}.md`
- Active ticket: `{tracking_dir}/.current` (JSON: `epic`, `ticket`, `folder`)
- Lessons: `{tracking_dir}/lessons.md`

## Standalone tickets (epic = null)

When `.current` has `"epic": null` (created via `/praxis-bug`):
- **No epic file** — skip all epic file operations
- Folder: `{TICKET_KEY}-{slug}/`
- Single ticket file in the folder

All skills must check `epic` before epic file operations.

## Slugification

1. Remove prefixes in `[...]` (e.g., `[ATS]`, `[Back]`)
2. Lowercase
3. Replace spaces and special characters with hyphens
4. Keep 3-4 significant words max (remove articles, prepositions)
5. Trim leading/trailing hyphens and collapse doubles

## URL scanning

Scan description + comments for:
- Figma: `figma.com/design/`, `figma.com/file/`
- Notion: `notion.so/`

Store discovered URLs in the Infos table.

## Detecting branch and PR

- Branch: `git branch --show-current` → update `Branche` if `—`
- PR: `gh pr view --json url,state` (silent if no PR) → update `Pull Request` if `—`

## Updating the epic file

When a ticket's status, progression, or blockers change:
1. If `epic` is `null` → **skip**
2. Locate epic file in `{tracking_dir}/{folder}/`
3. Update ticket row in **Tickets** table (status, "Reste à faire", "Blocage")

## Starting a ticket — git baseline

**Before creating any worktree or branch** (`/praxis-start`, `/praxis-bug`), always rebase the starting point on an up-to-date `main`. Never branch off whatever happens to be checked out.

1. `git status --porcelain` → if the working tree is dirty, **stop and ask** the user (commit / stash / abandon). Never discard changes.
2. `git checkout main`
3. `git pull origin main`

Only then create the worktree or the branch.

If the session is already inside a worktree (so `main` is checked out elsewhere), do at least `git fetch origin main` and branch from `origin/main`.

## Session rename

Once the git environment is ready, **propose** renaming the session — display the command, never run it (it is a user-side command):

```
/rename {TICKET_KEY} {Titre du ticket}
```

Use the provider title. If it is unclear, too long, or misleading, propose a short French summary of the ticket instead.

## Git worktree management

`EnterWorktree` is a **Claude Code built-in tool** (not a shell command). It creates an isolated git worktree and switches the session into it.

Usage in skills:
- `EnterWorktree` with `name` = ticket key in lowercase (e.g., `key-30636`)
- If it fails (e.g., already in a worktree, or tool unavailable) → fall back to classic branch

To check if currently in a worktree: compare `git rev-parse --show-toplevel` against `git worktree list` entries.

## Décisions section

Created by `/praxis-capture`, after **Progression**:

```markdown
## Décisions

| Date | Type | Décision | Raison |
|------|------|----------|--------|
```

Types: `new_criterion`, `modified_criterion`, `constraint`, `scope_change`, `clarification`

## Ressources section

Created by `/praxis-sync`, after **Commentaires**:

```markdown
## Ressources

### Figma
> {design summary} — Dernière capture : {YYYY-MM-DD HH:mm}

### Notion
> {specs/notes} — Dernière capture : {YYYY-MM-DD HH:mm}
```

Best-effort (skip if MCP unavailable).

## 🛑 Destructive / public actions — always ask first

These actions affect shared state or are user-visible and **must NEVER be executed without explicit, specific authorization from the user**, even in auto mode:

| Action                                         | Required authorization                                  |
| ---------------------------------------------- | ------------------------------------------------------- |
| `jira issue comment add` (provider comment)    | Display the FULL drafted comment, wait for "poste"/"ok" |
| `git push` (any remote)                        | Ask before pushing, even on a feature branch            |
| `gh pr create` / `gh pr merge` / `gh pr close` | Ask before creating or changing any PR                  |
| `jira issue move` / transitions to `done`      | Ask before transitioning to Done/Closed                 |
| Closing / deleting a remote branch             | Ask before any remote deletion                          |

**Drafting ≠ sending.** A user message like "poste un commentaire pour dire X" is a drafting request. You must:
1. Produce the draft
2. Display its full content inline in the chat
3. Ask for explicit validation
4. Execute ONLY after the user says "ok" / "poste" / "valide" / "envoie"

The `/praxis` workflow and auto mode never override these gates.

## Avancement entry formats

Base: `- {YYYY-MM-DD} : {description}`

Prefixed variants:
- `**Décision** — {what}. Raison : {why}.`
- `**Lesson** — {summary} (voir lessons.md)`
- `Triage — Taille {S/M/L}, {N} fichiers, workflow {type}`
- `Vérification couverture — {X}/{Y} critères couverts`
- `Ticket passé en {statut}`
