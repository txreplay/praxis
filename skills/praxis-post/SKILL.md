---
name: praxis-post
description: Post a progress comment on the active ticket. Use when the user invokes "/praxis post" with or without a ticket ID. Generates a comment in French from local advancement, previews it, and posts after explicit confirmation.
---

# /praxis post [TICKET_KEY]

Generate and post a progress comment from local advancement.

## Argument

Optional. Resolution per [common.md](../references/common.md#active-ticket-resolution).

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Read the ticket file

Extract: **Avancement** (what was done), **Progression** (remaining/blockers), **Pull Request** link.

### 2. Generate the comment

**In French**, free-form, concise. Include: recent work, remaining items, blockers, PR link.
No file paths or internal implementation details. No technical metadata.

### 3. Preview — MANDATORY

**Always** display the full comment and ask for confirmation before posting.

### 4. Post

Use the provider's **Post a comment** command.

### 5. Propose transition

If status is `active` and a PR exists → suggest `/praxis done`.
