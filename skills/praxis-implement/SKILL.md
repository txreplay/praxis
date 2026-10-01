---
name: praxis-implement
description: 'Implement features from an existing spec file, phase by phase, with parallel exploration and plan validation. Use when user has a spec file and says "implement phase X", "build from spec", "start development", or references a spec path. Requires a spec file as input. Do NOT use for quick changes without a spec (use /praxis-fix) or for creating the plan itself (use /praxis-spec).'
model: opus
argument-hint: spec=<path> phase=<number> [done=<phases>]
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

## 2.5 POST-EXPLORATION CHECK

After agents return, verify coverage across **all dimensions**:

1. **Full code path traced?** Can I trace handler -> usecase -> repository -> DB (backend) and page -> hook -> API -> component (frontend)? If gaps -> launch targeted `explore-codebase`
2. **Similar patterns identified?** Do I have a reference implementation to follow? If not -> launch `explore-codebase`
3. **Data model complete?** Tables, columns, relationships, RLS known? If not -> launch `explore-db`
4. **Library docs sufficient?** If not -> launch `explore-docs`

Do NOT proceed with incomplete context.

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
Backend: Domain -> Application -> Infrastructure -> Presentation
Frontend: Types -> API -> Hooks -> Components -> Pages
```

---

## 4. VALIDATE

Ask with AskUserQuestion: "Proceed with implementation?"
- "Implement"
- "Modify"

---

## 5. IMPLEMENT

After validation, implement in appropriate order:

**Backend:** Domain -> Application -> Infrastructure -> Presentation
- context.Context as first parameter for I/O
- Follow Clean Architecture patterns
- Complete error handling

**Frontend:** Types -> API -> Hooks -> Components -> Pages
- next-intl for ALL user-facing text
- Shadcn UI for standard components
- Strict TypeScript (no `any`)

For significant UI: `Skill(skill="frontend-design:frontend-design")`

---

## 6. VERIFY

```bash
# Backend
cd backend && go build ./... && go vet ./...
# Frontend
cd frontend && npm run build
```

Database verification: `mcp__supabase-dev__XXXX`

---

## 7. UPDATE SPEC

Check off completed items in the Execution Plan of the spec file.

---

## Rules

- **EXPLORE FIRST** - Always explore before implementing
- **REUSE** - Existing code/patterns as much as possible
- **VALIDATE** - Always ask before implementing
- **STAY IN SCOPE** - Only the specified phase
