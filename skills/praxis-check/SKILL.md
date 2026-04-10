---
name: praxis-check
description: Verify whether code changes cover the acceptance criteria of the active ticket. Use when the user invokes "/praxis check" with or without a ticket ID. Compares implemented code with acceptance criteria and local progression, generates a coverage report.
---

# /praxis check [TICKET_KEY]

Verify acceptance criteria coverage against implemented changes.

## Argument

Optional. Resolution per [common.md](../references/common.md#active-ticket-resolution).

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load config

Per [common.md — Loading the provider](../references/common.md#loading-the-provider) (config only, no provider commands needed).

### 1. Read acceptance criteria

From the ticket file's **Description**: user story, scope, acceptance criteria. From **Progression**: current state.

### 2. Analyze changes

- `git diff main...HEAD` + `git log --oneline main...HEAD`
- Scan modified files to understand what was implemented

### 3. Detect PR

Per [common.md — Detecting branch and PR](../references/common.md#detecting-branch-and-pr).

### 4. Evaluate coverage

For each acceptance criterion, assign:
- ✅ **Covered**: implemented and/or tested
- ⚠️ **Partially covered**: incomplete or untested
- ❌ **Not covered**: no implementation found
- 🔄 **Not verifiable**: impossible to determine from code alone

### 5. Report

Display: criteria list with statuses, current progression, coverage score `{X}/{Y}`.

### 6. Update files

Ticket: update **Progression**, add to **Avancement**: `{YYYY-MM-DD} : Vérification couverture — {X}/{Y} critères couverts`.
Epic: update per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file). Skip if `epic` is `null`.

### 7. Next steps

If gaps → suggest files to modify, tests to add.
If all covered → suggest `/praxis post` then `/praxis done`.
