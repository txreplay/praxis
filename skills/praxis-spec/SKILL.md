---
name: praxis-spec
description: 'Create complete development plans and feature specifications with parallel codebase exploration. Use when user says "plan a feature", "create a spec", "write a plan", "design the architecture", or needs a structured spec file before implementation. Do NOT use for quick changes without planning (use /praxis-fix) or for initial ideation (use /praxis-brainstorm first).'
model: opus
argument-hint: name=<feature-name>
---

**YOU ARE EXECUTING THE `/praxis-spec` SKILL.** The user triggered this skill. Follow ALL instructions below step by step. Do NOT treat this as a freeform conversation - execute the skill workflow.

Follow CLAUDE.md rules.

**Output file:** `.claude/generated/plans/{$ARGUMENTS.name}_FEATURE.md` (uppercase)

## Ultra Think Strategy

Ultra think before each phase transition:
- After exploration results: reflect on completeness before planning
- Before writing spec: consider architecture, edge cases, future maintainability
- After validation: ensure the plan is comprehensive and actionable

---

## 1. GATHER REQUIREMENTS

Ask user for:
- Detailed feature description
- Mockups/screenshots if available
- Business rules and edge cases
- Integrations with existing features

Do not proceed until requirements are clear.

---

## 1.5 CLARIFY DETAILS

Use AskUserQuestion to clarify before exploration:

### Must clarify (if not specified)
- Error messages for user-facing failures?
- Default values for new fields?
- Validation rules?
- What triggers state changes?

### UX Decisions (if not specified)
- What happens on success? (toast, redirect, refresh?)
- What happens on error?
- Confirmation dialogs needed?

### Permissions (if not specified)
- Who can perform each action?
- RLS policy rules?

Do not proceed until critical details are clarified.

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

## 3. VALIDATE ARCHITECTURE

Display architecture plan:

```markdown
## Architecture Plan - [Feature Name]

### Database
- Tables to create: [list with columns]
- Tables to modify: [changes]
- RLS policies needed

### Backend (Go Clean Architecture)
- Entities: [list]
- Usecases: [list with descriptions]
- Handlers: [endpoints]
- Code to reuse: [from exploration]

### Frontend (Next.js)
- Types, Components, Hooks, Pages
- Code to reuse: [from exploration]

### Libraries / Best Practices
- [from exploration]
```

Ask with AskUserQuestion: "Validate this architecture?"
- "Validate"
- "Modify"

---

## 4. WRITE SPEC FILE

After validation, write complete spec to `.claude/generated/plans/{$ARGUMENTS.name}_FEATURE.md`.

Use the template structure from [templates/feature-spec-template.md](templates/feature-spec-template.md).

Structure:
1. Overview (objective, summary, tech stack)
2. Context and Motivation
3. Functional Specifications (detailed behavior, rules, edge cases)
4. Technical Architecture (existing files to modify, new files to create)
5. Configuration (`app.yaml` for thresholds, limits, feature flags - NO hardcoded values)
6. Database (migrations, columns, RLS policies)
7. Backend Implementation (phases: Domain -> Infrastructure -> Application -> Presentation)
8. Frontend Implementation (phases: Types/API -> Hooks -> Components -> Pages)
9. Execution Plan (checkboxes for each task)
10. Important Notes (compatibility, performance, security)

### Backend Phase Rules
- Order: Domain -> Infrastructure -> Application -> Presentation
- Max 5 items per phase - split if more
- Separate CRUD usecases from business logic usecases
- Each phase must compile independently

---

## 5. DELIVER

- Confirm file created
- Summarize the phases
- Indicate next steps:
  - `/praxis-implement spec=.claude/generated/plans/[name]_FEATURE.md phase=1`
  - `/praxis-implement spec=.claude/generated/plans/[name]_FEATURE.md phase=8`

---

## Rules

- **EXPLORE FIRST** - parallel exploration before the plan
- **CONTEXT IS KEY** - spec must be detailed enough for a new session
- **VALIDATE** - user validation before writing spec
- **CHECKBOXES** - execution plan with checkboxes to track progress
