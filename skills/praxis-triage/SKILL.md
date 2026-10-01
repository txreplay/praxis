---
name: praxis-triage
description: Assess ticket complexity and suggest the right implementation workflow. Use when the user invokes "/praxis-triage" with or without a ticket ID.
---

# /praxis-triage [TICKET_KEY]

Assess ticket complexity and suggest the right workflow.

## Argument

Optional. Resolution per [common.md](../references/common.md#active-ticket-resolution).

## References

- [common.md](../references/common.md) — status model, paths, conventions

## Workflow

### 0. Load config

Per [common.md — Loading the provider](../references/common.md#loading-the-provider) (config only).

### 1. Read the ticket

Extract: description, AC, linked resources, current progression.

### 2. Analyze complexity

| Signal | What to check |
|--------|---------------|
| **Spec** | AC count, edge cases, ambiguity, cross-domain concerns |
| **Codebase** | Files/modules impacted, layers involved, shared code affected, existing tests |
| **Dependencies** | Blocked by other tickets? API contract changes? Migrations? |

### 3. Estimate size

| Size | Signals | Typical scope |
|------|---------|---------------|
| **S** | 1-2 AC, 1-3 files, single layer | Bug fix, simple UI change |
| **M** | 3-5 AC, 4-10 files, 2 layers | Feature with frontend + backend |
| **L** | 6+ AC, 10+ files, 3+ layers or shared code | Multi-service feature, migrations |

### 4. Recommend workflow

| Size | Workflow |
|------|----------|
| **S** | `/praxis-start` → `/fix` → `/praxis-check` → `/praxis-done` |
| **M** | `/praxis-start` → `/plan` or `/tdd` → `/praxis-check` → `/praxis-done` |
| **L** | `/praxis-start` → `/brainstorm` → `/plan` → `/implement` → `/praxis-check` → `/review` → `/praxis-done` |

### 5. Report

Display: size, signals summary, recommended workflow, identified risks.

### 6. Update ticket

Add to **Avancement**: `- {YYYY-MM-DD} : Triage — Taille {S/M/L}, {N} fichiers, workflow {type}`
