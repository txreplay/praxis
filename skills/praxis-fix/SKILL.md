---
name: praxis-fix
description: 'Fix bugs, modify existing features, or implement quick isolated changes with deep exploration. Use for any implementation that does not require a full spec file. Auto-detects bug mode (root cause analysis) vs change mode (implementation plan) from description. Do NOT use when a full spec file exists (use /praxis-implement) or for initial feature design (use /praxis-brainstorm).'
model: opus
argument-hint: <issue or task description>
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: |
            if [[ -d "backend" ]]; then
              cd backend && go build ./... 2>&1 | head -10 || true
            fi
          once: true
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
- Permissions: who can perform? RLS policies?
- Scope: backend/frontend/both? Database changes?

Do not proceed until the issue/task is fully understood.

---

## 3. EXPLORE (PARALLEL)

Launch focused agents in a **single message** (parallel execution). Scale agent count to task complexity.

### Complexity Guide

| Scope | Backend agents | Frontend agents |
|-------|---------------|-----------------|
| Single file fix | 1 | 1 |
| Single-layer feature | 2 | 2 |
| Multi-layer feature | 2-3 | 2-3 |
| Cross-cutting / large feature | 3-4 | 3-4 |

### Backend Agents (min 2 when backend in scope, split by concern)

1. **Domain & data flow** - `explore-codebase`: "Find entities, repository interfaces, value objects, and DTOs related to [feature] in backend/internal/domain/ and backend/internal/application/dto/"
2. **Usecases & business logic** - `explore-codebase`: "Find usecases related to [feature] in backend/internal/application/usecases/. Read their Execute methods, dependencies, and error handling"
3. **Handlers & routing** - `explore-codebase`: "Find HTTP handlers and routes related to [feature] in backend/internal/presentation/. Check middleware, validation, response patterns"
4. **Infrastructure & services** - `explore-codebase`: "Find repo implementations, external service adapters, and config related to [feature] in backend/internal/infrastructure/"
5. **Similar patterns** - `explore-codebase`: "Find the most similar existing feature to [feature] in backend/. I need to replicate its patterns"

### Frontend Agents (min 2 when frontend in scope, split by concern)

1. **Components & UI** - `explore-codebase`: "Find components related to [feature] in frontend/src/components/. Check props, state, Shadcn UI usage"
2. **Hooks & state** - `explore-codebase`: "Find hooks, React Query calls, and state management related to [feature] in frontend/src/hooks/ and frontend/src/lib/"
3. **Pages & routing** - `explore-codebase`: "Find pages and layouts related to [feature] in frontend/src/app/. Check route structure, data fetching, i18n"
4. **Types & API layer** - `explore-codebase`: "Find TypeScript types, API client functions related to [feature] in frontend/src/types/ and frontend/src/lib/"
5. **Similar patterns** - `explore-codebase`: "Find the most similar existing feature to [feature] in frontend/src/. I need to replicate its patterns"

### Supporting Agents (as needed, 1 each)

| Need | Agent | Prompt |
|------|-------|--------|
| Database | explore-db | "dev - Find tables related to [feature], check schema, relationships, RLS policies" |
| Library docs | explore-docs | "[library] [specific feature] documentation" |
| Best practices | websearch | "[topic] best practices 2025 2026" |

---

## 3.5 POST-EXPLORATION CHECK

After agents return, verify coverage across **all dimensions**:

1. **Full code path traced?** Can I trace handler -> usecase -> repository -> DB (backend) and page -> hook -> API -> component (frontend)? If gaps -> launch targeted `explore-codebase`
2. **Similar patterns identified?** Do I have a reference implementation to follow? If not -> launch `explore-codebase`
3. **Data model complete?** Tables, columns, relationships, RLS known? If not -> launch `explore-db`
4. **Library docs sufficient?** If not -> launch `explore-docs`

Do NOT proceed with incomplete context.

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

For significant UI: `Skill(skill="frontend-design:frontend-design")`

---

## 7. VERIFY

```bash
cd backend && go build ./... && go vet ./...
cd frontend && npm run build
```

Database verification: `mcp__supabase-dev__get_advisors` or `mcp__supabase-prod__get_advisors`

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
