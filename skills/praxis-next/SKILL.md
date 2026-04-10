---
name: praxis-next
description: Analyze current state and suggest the next action. Use when the user invokes "/praxis next" or seems unsure what to do next. Reads .current, ticket progression, git state, and recommends the next step.
---

# /praxis next

Auto-detect the next action based on current state.

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load config

Per [common.md — Loading the provider](../references/common.md#loading-the-provider) (config only).

### 1. Gather state

Collect (fail silently on each):
- **Praxis**: `.current` exists? Ticket file? Progression? `lessons.md` count?
- **Git**: branch, uncommitted changes, commits ahead of main, PR exists?
- **Code**: TODOs/FIXMEs in recently modified files

### 2. Decision tree

First match wins:

| Condition | Recommendation |
|-----------|---------------|
| No `praxis.json` | "Copier le template: `cp {praxis_dir}/praxis.example.json ./praxis.json`" |
| No `.current` | "`/praxis new <EPIC>` ou `/praxis bug <TICKET>`" |
| `.current` but ticket file missing | "`/praxis sync`" |
| Ticket status `done`/`review` | Find next ticket → `/praxis start {NEXT}` or "Tous terminés" |
| Ticket status `blocked` | "Ticket bloqué. Résoudre le blocage ou `/praxis start {AUTRE}` pour un autre ticket" |
| Uncommitted changes | "`/commit`" |
| All items "À faire" | "`/praxis triage`" |
| Items "En cours", none "Terminé" | "Continuer l'implémentation ou `/praxis check`" |
| Partial coverage | "`/praxis check` — {X}/{Y} couverts" |
| All covered, no PR | "Créer un PR, puis `/praxis post` + `/praxis done`" |
| All covered, PR exists, still `active` | "`/praxis done`" |
| Fallback | Show state summary |

### 3. Display

```
## Praxis — Next step

**Ticket** : {KEY} — {title} | **Statut** : {status} | **Progression** : {X}/{Y}

→ {recommendation + command}
```

If relevant lessons exist → append: `{N} lesson(s) — /praxis learn --review`
