---
name: praxis-bug
description: Initialize lightweight tracking for a standalone ticket (not part of an epic). Use when the user invokes "/praxis-bug" followed by a ticket ID (e.g., /praxis-bug KEY-31982). Creates tracking, sets up git, runs triage, and surfaces lessons — all in one step.
---

# /praxis-bug <TICKET_KEY>

Create lightweight tracking for a standalone ticket and start working.

## Argument

`TICKET_KEY` required (e.g., `KEY-31982`). Ticket identifier in the provider.

## References

- [common.md](../references/common.md) — status model, paths, conventions
- [templates.md](../references/templates.md) — file templates

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Check for existing tracking

Look for `{TICKET_KEY}-*.md` in `{tracking_dir}/`. If found → suggest `/praxis-sync`. Stop.

### 2. Fetch and create tracking

Fetch ticket via provider. Slugify summary per [common.md — Slugification](../references/common.md#slugification). Create folder `{tracking_dir}/{TICKET_KEY}-{slug}/` and one ticket file using [templates.md](../references/templates.md). **No epic file.**

### 3. `.current` (classic branch only)

Written at step 4.6 when the user picks a classic branch; a worktree never writes it:

```json
{ "epic": null, "ticket": "{TICKET_KEY}", "folder": "{TICKET_KEY}-{slug}" }
```

### 4. Transition and git setup

1. If status is `todo` → ask to transition to `active`
2. Already in a worktree → worktree, no question. Else ask: worktree or classic branch
3. Start from an up-to-date `main` per [common.md — Starting a ticket: git baseline](../references/common.md#starting-a-ticket--git-baseline) — the worktree variant never touches the main checkout. Dirty working tree → stop and ask.
4. Worktree: per [common.md — Git worktree management](../references/common.md#git-worktree-management) — stay or `EnterWorktree` with ticket key lowercase, then branch `fix/{ticket-key}-{slug}` from origin/main. On failure → ask before a classic branch
5. Branch: suggest `fix/{ticket-key}-{slug}`, fetch + checkout from origin/main
6. Update `Branche` field in ticket Infos; classic branch → write `.current` (step 3)
7. Propose the session rename per [common.md — Session rename](../references/common.md#session-rename) — display only, never execute

### 5. Triage

Count AC, estimate impacted files, suggest size (S/M/L) and workflow per the logic in `/praxis-triage`.

### 6. Surface lessons

If `{tracking_dir}/lessons.md` exists → score and show top relevant lessons per the logic in `/praxis-learn --review`.

### 7. Summary

Display: ticket, branch, triage result, relevant lessons, session rename command. Suggest: `/fix` or `/tdd`.
