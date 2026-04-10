---
name: praxis-capture
description: Capture an implementation decision or spec correction into the active ticket's tracking file. Use when the user invokes "/praxis capture" to record decisions that deviate from or complement original specs. Optionally posts to the provider.
---

# /praxis capture [TICKET_KEY]

Capture an implementation decision or spec correction into the ticket file.

## Argument

Optional. Resolution per [common.md](../references/common.md#active-ticket-resolution).

## References

- [common.md](../references/common.md) — status model, paths, conventions (incl. Décisions section format)

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Gather the decision

Ask the user (one question at a time):

1. **What was decided?** — free-form description
2. **Why?** — constraint, context, or rationale
3. **Impact on specs?** — `new_criterion` | `modified_criterion` | `constraint` | `scope_change` | `clarification`

### 2. Update the ticket file

**Avancement**: `- {YYYY-MM-DD} : **Décision** — {what}. Raison : {why}.`

**Progression** (if applicable):
- `new_criterion` → add to "À faire" (or "Terminé" if already implemented)
- `modified_criterion` → update criterion text, keep status
- `scope_change` → add/remove items
- `constraint` / `clarification` → no change

**Décisions section**: per [common.md — Décisions section](../references/common.md#décisions-section). Append a row.

### 3. Update the epic

If `scope_change` → update epic per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file).

### 4. Propose posting

Ask: "Poster cette décision en commentaire sur {TICKET_KEY} ?"
If yes → same flow as `/praxis post` (generate, preview, confirm, post).

### 5. Confirm

Display: decision recorded, posted status, updated progression.
