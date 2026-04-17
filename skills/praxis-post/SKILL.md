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

### 3. Preview — MANDATORY 🛑

**Always** display the FULL comment content inline (not just a path, not a summary) and explicitly ask: "Je poste ? / Validate to send?"

⚠️ A user message like "/praxis post" or "poste un commentaire" is a **drafting request**, NOT an authorization to send. You MUST wait for a separate explicit confirmation ("ok", "poste", "valide", "envoie") before running the post command.

### 4. Post — only after explicit validation

Only once the user has explicitly validated the drafted content: use the provider's **Post a comment** command. Never skip step 3, even if the user seems to want speed or auto mode is active.

### 5. Propose transition

If status is `active` and a PR exists → suggest `/praxis done`.
