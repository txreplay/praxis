---
name: praxis-start
description: Set the active ticket and prepare the git environment. Use when the user invokes "/praxis-start" followed by a ticket ID (e.g., /praxis-start KEY-30636). Syncs from the provider, creates a worktree or classic branch (user's choice; .current only for the classic branch), and displays ticket status.
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

### 2. `.current` — deferred

Written at step 6, and only for a classic branch: see [common.md — Active ticket resolution](../references/common.md#active-ticket-resolution).

### 3. Sync from provider

Fetch the ticket. Update status/comments if changed. Update `Dernière MAJ`. Update epic file per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file).

### 4. Propose "In Progress" transition

If provider status maps to `todo`, ask confirmation then transition to `active`.

### 5. Prepare the git environment

Already in a worktree → option A, no question. Else **ask the user**: "Worktree isolé ou branche classique ?"

Start from an up-to-date `main` per [common.md — Starting a ticket: git baseline](../references/common.md#starting-a-ticket--git-baseline) — the worktree variant never touches the main checkout. Dirty working tree → stop and ask.

#### Option A: Worktree
Per [common.md — Git worktree management](../references/common.md#git-worktree-management): stay in the current worktree or `EnterWorktree` with `name` = ticket key lowercase, then create the ticket's branch `fix/{ticket-key-lowercase}-{slug}` from `origin/main`. On failure → ask before option B.

#### Option B: Classic branch
1. Suggest branch name: `fix/{ticket-key-lowercase}-{slug}`
2. `git fetch origin main && git checkout -b {name} origin/main`

### 6. Update Branch field and `.current`

`git branch --show-current` → update `Branche` in ticket Infos table.

Option B only: write `{tracking_dir}/.current` with epic (deduced from folder, or `null` if standalone), ticket, folder. Option A never writes it.

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
