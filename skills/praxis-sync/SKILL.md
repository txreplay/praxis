---
name: praxis-sync
description: Update local tracking files from the provider, git diff, code TODOs, and linked resources. Use when the user invokes "/praxis sync" with or without a ticket ID. Analyzes code changes to update progression and advancement.
---

# /praxis sync [TICKET_KEY]

Update local tracking with latest provider info, code analysis, and linked resources.

## Argument

Optional. Resolution per [common.md](../references/common.md#active-ticket-resolution).

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Read the ticket file

Locate ticket file. Note current progression and existing avancement entries.

### 2. Sync from provider

Fetch the ticket. Update status, append new comments, update description if changed.

### 3. Fetch linked resources

Check ticket **Infos** for Figma/Notion links (non `—` values).

- **Figma**: use Figma MCP (`get_screenshot`) → 2-3 sentence summary
- **Notion**: use Notion MCP (`notion-fetch`) → extract relevant specs

Store in a `## Ressources` section per [common.md — Ressources section](../references/common.md#ressources-section). Best-effort — skip silently if MCP unavailable.

### 4. Analyze code

- `git diff HEAD` + `git diff --cached`
- Scan for `TODO`, `FIXME`, `HACK`, `XXX`
- Identify: modified files, new tests, TODOs

### 5. Detect branch and PR

Per [common.md — Detecting branch and PR](../references/common.md#detecting-branch-and-pr).

### 6. Update Progression

Compare AC with code. Move items between À faire → En cours → Terminé. Add TODOs to Blocages. **Never remove from "Terminé".**

### 7. Enrich Avancement

Append new entries (format: `- {YYYY-MM-DD} : {description}`). Never modify existing entries. No duplicates.

### 8. Update the epic (if applicable)

Per [common.md — Updating the epic file](../references/common.md#updating-the-epic-file). Skip if `epic` is `null`.

### 9. Metadata

Update `Dernière MAJ` in ticket and epic files.

### 10. Summary

Display: status changes, new avancement entries, blockers, TODOs.
