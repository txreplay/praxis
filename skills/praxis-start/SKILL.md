---
name: praxis-start
description: Set the active ticket and prepare the git environment. Use when the user invokes "/praxis-start" followed by a ticket ID (e.g., /praxis-start KEY-30636). Updates .current, syncs from the provider, creates a worktree or classic branch (user's choice), and displays ticket status.
---

# /praxis-start <TICKET_KEY>

Set the active ticket and prepare the working environment.

## Argument

`TICKET_KEY` required (e.g., `KEY-30636`). Child ticket ID (not the epic).

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Find the ticket locally

Look for a `{TICKET_KEY}-*.md` file in `{tracking_dir}/*/`.

- **Found**: deduce epic and folder from parent directory.
- **Not found**: suggest `/praxis-new` with the parent epic. Stop.

### 2. Update `.current`

Write `{tracking_dir}/.current` with epic (deduced from folder, or `null` if standalone), ticket, folder.

### 3. Sync from provider

Fetch the ticket. Update status/comments if changed. Update `Dernière MAJ`. Update epic file per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file).

### 4. Propose "In Progress" transition

If provider status maps to `todo`, ask confirmation then transition to `active`.

### 5. Prepare the git environment

**Reset to an up-to-date `main` first**, per [common.md — Starting a ticket: git baseline](../references/common.md#starting-a-ticket--git-baseline). Dirty working tree → stop and ask.

Then **ask the user**: "Worktree isolé ou branche classique ?"

#### Option A: Worktree
1. Verify not already in a worktree
2. `EnterWorktree` with `name` = ticket key lowercase
3. On failure → fall back to option B

#### Option B: Classic branch
1. Suggest branch name: `fix/{ticket-key-lowercase}-{slug}`
2. `git fetch origin main && git checkout -b {name} origin/main`

### 6. Update Branch field

`git branch --show-current` → update `Branche` in ticket Infos table.

### 7. Propose the session rename

Per [common.md — Session rename](../references/common.md#session-rename). Display only, never execute.

### 8. Surface relevant lessons

If `{tracking_dir}/lessons.md` exists → score and show the top relevant lessons per [praxis-learn — Review mode](../praxis-learn/SKILL.md#review-mode---review). Skip silently if none scores ≥ 1.

### 9. Resume point

The ticket file is the handoff between sessions (one session per phase: cadrage, implementation, review loop). Rebuild the resume point from it, not from memory:

- **Progression** table (À faire / En cours / Terminé / Blocages)
- last 5 **Avancement** entries and every **Décisions** row
- PR state when the Infos table has one: `gh pr view <n> --json state,reviewDecision,mergeable,statusCheckRollup` → open review threads not yet answered count as work to do
- open questions listed in the epic file (« Questions ouvertes »)

### 10. Display summary

Show: ticket (KEY + title), epic, status, branch, worktree path, the resume point of step 9, relevant lessons, session rename command.

Suggest the next skill from the state, one line:
- no commit on the branch and no plan → `/plan` (or `/fix` for a small ticket)
- plan with unfinished phases, or commits without PR → `/praxis-ship`
- PR open → answer the review, then `/praxis-ship` again for the re-review commit, or `/watch-ats-prs watch <pr>` to be notified
- everything merged → `/praxis-done`
