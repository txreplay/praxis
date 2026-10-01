---
name: praxis-implement
description: 'Implement features from an existing spec file, phase by phase, with parallel exploration and plan validation. Use when user has a spec file and says "implement phase X", "build from spec", "start development", or references a spec path. Requires a spec file as input. Do NOT use for quick changes without a spec (use /praxis-fix) or for creating the plan itself (use /praxis-spec).'
model: opus
argument-hint: spec=<path> phase=<number> [done=<phases>]
---

**YOU ARE EXECUTING THE `/praxis-implement` SKILL.** The user triggered this skill. Follow ALL instructions below step by step. Do NOT treat this as a freeform conversation - execute the skill workflow.

Follow CLAUDE.md rules.

## Ultra Think Strategy

Ultra think before each phase transition:
- After exploration results: reflect on completeness before planning
- Before implementation: consider edge cases, patterns to follow, potential issues
- After validation: ensure the approach aligns with user intent

---

## 1. UNDERSTAND

- Read spec: `$ARGUMENTS.spec`
- Identify phase: `$ARGUMENTS.phase`
- Phases completed: `$ARGUMENTS.done`
- Extract from phase description:
  - **Scope**: backend / frontend / both
  - **Files** to create/modify
  - **Libraries** needed

---

## 2. EXPLORE (PARALLEL)

Follow [exploration.md](../references/exploration.md) for the phase's scope: find where the code lives, launch the agents in one message, then run its post-exploration check. Do NOT proceed with incomplete context.

---

## 3. SHOW PLAN

Display enriched plan:

```markdown
## Phase $ARGUMENTS.phase

### Files to Create
- `path/file` - [purpose]

### Files to Modify
- `path/file:XX` - [what to change]

### Patterns to Reuse (from exploration)
- [existing code patterns found]

### Order
Backend: data & domain -> data access -> business logic -> entry points (the project's layers)
Frontend: Types -> API client -> Data hooks -> Components -> Pages/routes
```

---

## 4. VALIDATE

Ask with AskUserQuestion: "Proceed with implementation?"
- "Implement"
- "Modify"

---

## 5. IMPLEMENT

After validation, implement in appropriate order:

**Backend:** data & domain -> data access -> business logic -> entry points
- Follow the patterns found during exploration (the project's architecture, not a generic one)
- Complete error handling

**Frontend:** Types -> API client -> Data hooks -> Components -> Pages/routes
- The project's i18n for ALL user-facing text
- The project's design-system components before custom markup
- Strict TypeScript (no `any`)

For significant UI, use a frontend-design skill if one is installed.

---

## 6. VERIFY

Run the verification commands per [common.md — Verification commands](../references/common.md#verification-commands), scoped to what changed. If the database schema changed, check the generated migration (nullability, defaults, indexes, rolling-deploy safety).

---

## 7. UPDATE SPEC

Check off completed items in the Execution Plan of the spec file.

---

## Rules

- **EXPLORE FIRST** - Always explore before implementing
- **REUSE** - Existing code/patterns as much as possible
- **VALIDATE** - Always ask before implementing
- **STAY IN SCOPE** - Only the specified phase
