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
- Data access rules (row-level / tenant / role restrictions)?

Do not proceed until critical details are clarified.

---

## 2. EXPLORE (PARALLEL)

Follow [exploration.md](../references/exploration.md): find where the code lives, launch the backend and frontend agents in one message, add the supporting ones as needed, then run its post-exploration check. Do NOT proceed with incomplete context.

---

## 3. VALIDATE ARCHITECTURE

Display architecture plan:

```markdown
## Architecture Plan - [Feature Name]

### Database
- Tables / models to create: [list with columns]
- Tables / models to modify: [changes]
- Migrations and access rules

### Backend ([the project's architecture, from exploration])
- Models / entities: [list]
- Services / use cases: [list with descriptions]
- Routes / controllers: [endpoints]
- Code to reuse: [from exploration]

### Frontend ([the project's framework, from exploration])
- Types, API client, data hooks, components, pages/routes
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
5. Configuration (the project's config mechanism for thresholds, limits, feature flags — NO hardcoded values)
6. Database (migrations, columns, access rules)
7. Backend Implementation (phases following the project's layers, data first, entry points last)
8. Frontend Implementation (phases: Types/API -> Data hooks -> Components -> Pages/routes)
9. Execution Plan (checkboxes for each task)
10. Important Notes (compatibility, performance, security)

### Phase Rules
- Order: data and domain first, entry points and UI last, following the project's layers
- Max 5 items per phase - split if more
- Separate plain CRUD from business logic
- Each phase must typecheck and build independently (commands per [common.md — Verification commands](../references/common.md#verification-commands))

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
