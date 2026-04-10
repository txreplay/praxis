---
name: praxis-new
description: Initialize local tracking for an epic and all its child tickets. Use when the user invokes "/praxis new" followed by an epic ID (e.g., /praxis new HUB-30635). Fetches the epic and its children via the configured provider, creates a folder with one markdown file per ticket + an epic summary file.
---

# /praxis new <EPIC_KEY>

Create the local tracking structure for an epic.

## Argument

`EPIC_KEY` required (e.g., `HUB-30635`). Epic identifier in the provider.

## References

- [common.md](../references/common.md) — status model, paths, conventions
- [templates.md](../references/templates.md) — file templates
- [providers/](../references/providers/) — provider commands (loaded dynamically)

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Check for existing folder

Look for a `{EPIC_KEY}-*` folder in `{tracking_dir}/`.

- **Found**: suggest `/praxis sync`. Stop.
- **Not found**: continue.

### 2. Fetch the epic

Use the provider's **Fetch a ticket** command. Extract: summary, description, status, comments. Scan for linked URLs per [common.md — URL scanning](../references/common.md#url-scanning).

### 3. Fetch child tickets

Use the provider's **List children of an epic** command. For each child, fetch details and scan for URLs.

### 4. Create the folder

Slugify the epic summary per [common.md — Slugification](../references/common.md#slugification).

Folder: `{tracking_dir}/{EPIC_KEY}-{slug}/`

### 5. Create the files

Use [templates.md](../references/templates.md). Map provider status → Praxis status → FR display per [common.md](../references/common.md#status-model-provider-agnostic).

**Rules:**
- Provider content (description, comments): **original language**
- Our content: **in French**
- Comments format: `**author (date)** : content`
- Missing links: `—`

### 6. Initialize `.current`

```json
{
  "epic": "{EPIC_KEY}",
  "ticket": "{first active ticket, else first todo ticket}",
  "folder": "{folder name}"
}
```

### 7. Summary

Display: folder created, file count, active ticket. Suggest `/praxis start {TICKET_KEY}`.
