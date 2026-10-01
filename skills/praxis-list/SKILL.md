---
name: praxis-list
description: List all tracked epics and tickets with their status. Use when the user invokes "/praxis-list" to see an overview of all tracked work or switch context between epics.
---

# /praxis-list

Show all tracked epics and tickets.

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load config

Per [common.md — Loading the provider](../references/common.md#loading-the-provider) (config only).

### 1. Scan tracking directory

List all folders in `{tracking_dir}/`. For each folder:
- If it contains an epic file (name matches folder) → epic with children
- If it contains only one ticket file → standalone bug
- Read the file(s) to get status and progression

### 2. Display overview

```
## Praxis — Tracked work

⮕ KEY-30635 — Candidate profile [4/6 tickets done]
   ├ KEY-30636 open-profile        ✅ Terminé
   ├ KEY-30637 view-details        ✅ Terminé
   ├ KEY-30638 download-docs       🔄 En cours  ← actif
   ├ KEY-30639 send-email          ⬜ À faire
   ├ KEY-30640 add-network         ⬜ À faire
   └ KEY-30641 preview-attachment  ✅ Terminé

  KEY-31982 — Status filter bug    🔄 En cours (standalone)

  KEY-38603 — CVthèque filtres     ✅ Terminé [6/6]
```

Mark the active ticket (from `.current`) with `← actif`.

### 3. Offer actions

- "Changer de ticket actif ? `/praxis-start {KEY}`"
- "Archiver un epic terminé ? (supprimer le dossier manuellement)"
