---
name: praxis-done
description: Close the active ticket with pre-flight verification. Use when the user invokes "/praxis-done" with or without a ticket ID. Runs gates (clean tree, AC coverage, build, TODOs), transitions status on the provider, and moves to the next ticket.
---

# /praxis-done [TICKET_KEY] [--status=review|done]

Close work on a ticket after pre-flight verification.

## Arguments

- `TICKET_KEY`: optional. Resolution per [common.md](../references/common.md#active-ticket-resolution).
- `--status`: `review` (default) or `done`.

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Resolve the ticket

Locate ticket file. Read current progression.

### 2. Pre-flight gates

| Gate | Command | PASS | WARN | BLOCK |
|------|---------|------|------|-------|
| Clean tree | `git status --porcelain` | empty | — | any output → "Commiter d'abord" |
| AC coverage | Progression section | all Terminé (or empty) | partial → ask to continue | none covered (with items present) |
| Build | detect + run (see below) | passes | failures → ask if pre-existing | — |
| TODOs | scan `git diff --name-only main...HEAD` | none | found → ask if intentional | — |

**Build detection**: if `nx.json` → `pnpm exec nx run-many --target=typecheck,lint --projects={affected}`; if `package.json` with scripts → `pnpm run typecheck && pnpm run lint`; else skip.

Display gate summary. Any BLOCK → stop. WARN only → ask confirmation. All PASS → proceed.

### 3. Transition on the provider

Ask confirmation: "Transitionner {TICKET_KEY} vers {target} ?" Then use provider's **Transition a ticket** command.

### 4. Update local tracking

Ticket: update status, add to **Avancement**, update `Dernière MAJ`.
Epic: per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file). Skip if `epic` is `null`.

### 5. Propose lesson capture

If ticket has **Décisions** entries → suggest `/praxis-learn` to promote to cross-ticket lessons.

### 6. Move to next ticket

Look in epic for next `todo` or `active` ticket → update `.current`, suggest `/praxis-start`.
If no next ticket → "Tous les tickets de l'epic sont terminés ou en revue."
If standalone (`epic: null`) → skip.

### 7. Summary

Display: closed ticket, new status, next ticket, epic progress (X/Y).
