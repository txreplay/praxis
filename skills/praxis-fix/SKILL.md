---
name: praxis-fix
description: 'Fix bugs, modify existing features, or implement quick isolated changes with deep exploration. Use for any implementation that does not require a full spec file. Auto-detects bug mode (root cause analysis) vs change mode (implementation plan) from description. Do NOT use when a full spec file exists (use /praxis-implement) or for initial feature design (use /praxis-brainstorm).'
model: opus
argument-hint: <issue or task description>
---

**YOU ARE EXECUTING THE `/praxis-fix` SKILL.** The user triggered this skill. Follow ALL instructions below step by step. Do NOT treat this as a freeform conversation - execute the skill workflow.

Follow CLAUDE.md rules for Clean Architecture.

## Ultra Think Strategy

Ultra think before each phase transition:
- After clarification: ensure you fully understand the issue/task
- After exploration results: reflect on completeness before analyzing
- Before implementation: consider edge cases, patterns to follow, potential issues
- After validation: ensure the approach addresses root cause (bug) or requirements (change)

---

## 1. PARSE & DETECT MODE

From: `$ARGUMENTS`

Extract:
- **Mode**: Bug fix or Change? (auto-detect from description)
- **Feature area**: Which part of the app?
- **Layers**: Backend / Frontend / Both / Database?
- **Database env**: Detect from description (prod/dev) - default to DEV

**Bug indicators**: error, crash, broken, doesn't work, wrong behavior, regression, fix
**Change indicators**: add, create, implement, update, modify, change, remove, refactor

---

## 2. CLARIFY

Use AskUserQuestion to clarify before exploration:

### If Bug Mode (if not specified)
- Can you reproduce? Steps to reproduce?
- Expected vs actual behavior?
- When did it start? (recent deploy, config change?)
- Error logs or screenshots?
- Blocking production? Who/what is affected?
- Root cause fix or quick workaround first?

### If Change Mode (if not specified)
- Error messages for user-facing failures?
- Default values for new fields?
- Validation rules? State change triggers?
- UX: success action (toast, redirect)? Error handling? Confirmation dialogs?
- Permissions: who can perform? Data access rules?
- Scope: backend/frontend/both? Database changes?

Do not proceed until the issue/task is fully understood.

---

## 3. EXPLORE (PARALLEL)

Follow [exploration.md](../references/exploration.md): find where the code lives, launch the agents in one message, then run its post-exploration check. Do NOT proceed with incomplete context.

---

## 4. ANALYZE & PLAN

### If Bug Mode

```markdown
## Bug Analysis

### Current Behavior
[What the code currently does]

### Expected Behavior
[What it should do]

### Root Cause
[Why the bug happens - with file:line references]

### Fix Strategy
- `path/to/file:XX` - [specific change]

### Risks & Mitigations
- [Risk]: [Mitigation]
```

### If Change Mode

```markdown
## Implementation Plan

### Changes Required

**Database** (if applicable):
- Migration: [description]

**Backend:**
- `path/to/file:XX` - [specific change]

**Frontend:**
- `path/to/file:XX` - [specific change]

### Patterns to Follow (from exploration)
- [code snippets to replicate]

### Order
1. [step 1]
2. [step 2]
```

---

## 5. VALIDATE (BLOCKING)

**MANDATORY**: You MUST wait for user approval before ANY implementation.

Ask with AskUserQuestion: "Approve this approach?"
- "Implement"
- "Investigate more"
- "Modify approach"

**DO NOT proceed to implementation without explicit user selection.**

---

## 6. IMPLEMENT

**ONLY after user approval**, implement:
1. Backend changes first (Domain -> Application -> Infrastructure -> Presentation)
2. Frontend changes second (Types -> API -> Hooks -> Components -> Pages)

**Rules:**
- Stay in scope - change only what's needed
- Fix root cause, not symptoms (bug mode)
- Follow patterns from exploration
- No hardcoded values
- Complete error handling

For significant UI, use a frontend-design skill if one is installed.

---

## 7. VERIFY

Run the verification commands per [common.md — Verification commands](../references/common.md#verification-commands), scoped to what changed. If the database schema changed, check the generated migration (nullability, defaults, indexes, rolling-deploy safety).

---

## 8. SUMMARY

```markdown
## Complete

### Task
[Original issue/request]

### Root Cause / Approach
[What was wrong / what was built]

### Changes Made
- `path/to/file` - [change]

### Testing Recommendation
- [How to verify]
```

---

## Rules

- **CLARIFY FIRST** - fully understand before exploring
- **EXPLORE SECOND** - never assume, always investigate
- **ROOT CAUSE** (bug mode) - fix the cause, not the symptom
- **VALIDATE IS BLOCKING** - NEVER implement without explicit user approval
- **STAY IN SCOPE** - change only what's needed
