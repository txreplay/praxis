---
name: praxis-plan
description: Break down an epic with no child tickets into user stories, create them on the provider, and initialize local tracking. Use when the user invokes "/praxis-plan" followed by an epic ID that has no sub-tasks yet.
---

# /praxis-plan <EPIC_KEY>

Break down an epic into tickets and create them on the provider + locally.

## Argument

`EPIC_KEY` required. Epic identifier in the provider.

## References

- [common.md](../references/common.md) — status model, paths, conventions
- [templates.md](../references/templates.md) — file templates

## Workflow

### 0. Load provider

Per [common.md — Loading the provider](../references/common.md#loading-the-provider).

### 1. Fetch the epic

Same as `/praxis-new` step 2: fetch via provider, extract info, scan URLs.

### 2. Check for existing children

Use provider's **List children of an epic**.

- **Children found**: suggest `/praxis-new {EPIC_KEY}` instead. Stop.
- **No children**: continue.

### 3. Propose breakdown

Analyze the epic's description and AC. Propose tickets as a numbered list:

```
1. [S] Afficher le profil candidat
   AC: - Nom, prénom, email visibles / - Photo si disponible

2. [M] Télécharger les documents
   AC: - Liste / - Téléchargement unitaire / - Groupé
   Dépend de: #1
```

### 4. Iterate with the user

Ask: "Ce découpage te convient ?" Repeat until validated. One round of feedback at a time.

### 5. Create tickets on the provider

For each validated ticket, use provider's **Create a ticket** command. Set parent/epic link, status `todo`, AC in description. Display each created key.

### 6. Initialize local tracking

Same as `/praxis-new` steps 4-7: create folder, epic file, ticket files, `.current`.

### 7. Summary

Display: ticket count, folder, suggested first ticket → `/praxis-start {KEY}`.
