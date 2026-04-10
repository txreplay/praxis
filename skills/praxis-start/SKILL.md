---
name: praxis-start
description: Set the active ticket and prepare the git environment. Use when the user invokes "/praxis start" followed by a ticket ID (e.g., /praxis start HUB-30636). Updates .current, syncs from the provider, creates a worktree or classic branch (user's choice), and displays ticket status.
---

# /praxis start <TICKET_KEY>

Set the active ticket and prepare the working environment.

## Argument

`TICKET_KEY` required (e.g., `HUB-30636`). Child ticket ID (not the epic).

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Find the ticket locally

Look for a `{TICKET_KEY}-*.md` file in `{tracking_dir}/*/`.

- **Found**: deduce epic and folder from parent directory.
- **Not found**: suggest `/praxis new` with the parent epic. Stop.

### 2. Update `.current`

Write `{tracking_dir}/.current` with epic (deduced from folder, or `null` if standalone), ticket, folder.

### 3. Sync from provider

Fetch the ticket. Update status/comments if changed. Update `Dernière MAJ`. Update epic file per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file).

### 4. Propose "In Progress" transition

If provider status maps to `todo`, ask confirmation then transition to `active`.

### 5. Prepare the git environment

**Ask the user**: "Worktree isolé ou branche classique ?"

#### Option A: Worktree
1. Verify not already in a worktree
2. `EnterWorktree` with `name` = ticket key lowercase
3. On failure → fall back to option B

#### Option B: Classic branch
1. Suggest branch name: `fix/{ticket-key-lowercase}-{slug}`
2. `git fetch origin main && git checkout -b {name} origin/main`

### 6. Update Branch field

`git branch --show-current` → update `Branche` in ticket Infos table.

### 7. Display summary

Show: ticket (KEY + title), epic, status, progression, branch, worktree path.
If progression exists → suggest `/praxis check`.
