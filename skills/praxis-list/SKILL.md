---
name: praxis-list
description: List all tracked epics and tickets with their status. Use when the user invokes "/praxis list" to see an overview of all tracked work or switch context between epics.
---

# /praxis list

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

⮕ HUB-30635 — Candidate profile [4/6 tickets done]
   ├ HUB-30636 open-profile        ✅ Terminé
   ├ HUB-30637 view-details        ✅ Terminé
   ├ HUB-30638 download-docs       🔄 En cours  ← actif
   ├ HUB-30639 send-email          ⬜ À faire
   ├ HUB-30640 add-network         ⬜ À faire
   └ HUB-30641 preview-attachment  ✅ Terminé

  HUB-31982 — Status filter bug    🔄 En cours (standalone)

  HUB-38603 — CVthèque filtres     ✅ Terminé [6/6]
```

Mark the active ticket (from `.current`) with `← actif`.

### 3. Offer actions

- "Changer de ticket actif ? `/praxis start {KEY}`"
- "Archiver un epic terminé ? (supprimer le dossier manuellement)"
