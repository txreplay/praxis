# [FEATURE_NAME] Feature Specification

## 1. Overview

### Objective
[What this feature accomplishes]

### Summary
[Brief description of the feature]

### Tech Stack
- **Frontend**: [framework, language, UI library — from exploration]
- **Backend**: [runtime, framework, architecture — from exploration]
- **Database**: [engine, ORM / migration tool — from exploration]

---

## 2. Context and Motivation

### Why this feature?
[Business justification]

### User stories
- As a [user type], I want to [action] so that [benefit]

### Success criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

## 3. Functional Specifications

### Core behavior
[Detailed description of how the feature works]

### Business rules
1. [Rule 1]
2. [Rule 2]

### Edge cases
| Case | Expected behavior |
|------|-------------------|
| [Case 1] | [Behavior] |
| [Case 2] | [Behavior] |

### Error handling
| Error | Message | Action |
|-------|---------|--------|
| [Error 1] | "[Message]" | [Action] |

---

## 4. Technical Architecture

### Existing files to modify
| File | Changes |
|------|---------|
| `path/to/file.ts` | [Description] |

### New files to create
| File | Purpose |
|------|---------|
| `path/to/new/file.ts` | [Purpose] |

---

## 5. Configuration

### Configuration additions
[Where the project keeps configuration (config module, env schema, feature-flag service). Every threshold, limit and flag for this feature goes there.]

### Environment variables (.env)
```bash
# Only for secrets - API keys, credentials
# FEATURE_API_KEY=xxx
```

**Rule:** NO hardcoded values in code. All parameters must come from config.

---

## 6. Database

### Migrations
[Schema changes with the project's migration tool (e.g. a Prisma schema change + generated migration). For each new column: nullability, default or backfill, index for new filters, safe for a rolling deploy.]

### Access rules
[Who can read/write the new data, and where that is enforced.]

---

## 7. Backend Implementation

Phases follow the project's layers — data and domain first, entry points last. Use the real paths found during exploration.

### Phase 1: Data & domain
- [ ] Model / entity / schema: `[path]`

### Phase 2: Data access & integrations
- [ ] Repository / query / client: `[path]`

### Phase 3: Business logic
- [ ] Service / use case: `[path]`
- [ ] DTO / validation schema: `[path]`

### Phase 4: Entry points
- [ ] Route / controller: `[path]`

---

## 8. Frontend Implementation

### Phase 5: Types & API
- [ ] Types: `[path]/[feature].ts`
- [ ] API client: `[path]/[feature].ts`

### Phase 6: Hooks
- [ ] Query hook: `[path]/use[Feature]Query.ts`
- [ ] Mutation hooks

### Phase 7: Components
- [ ] Component: `[path]/[Component].tsx`

### Phase 8: Pages
- [ ] Page / route: `[path]`

---

## 9. Execution Plan

### Backend
- [ ] Phase 1: Data & domain
- [ ] Phase 2: Data access & integrations
- [ ] Phase 3: Business logic
- [ ] Phase 4: Entry points

### Frontend
- [ ] Phase 5: Types & API
- [ ] Phase 6: Hooks
- [ ] Phase 7: Components
- [ ] Phase 8: Pages

### Verification
- [ ] Typecheck, lint, test and build pass on the affected projects (commands per praxis `common.md › Verification commands`)
- [ ] Migrations reviewed for a rolling deploy

---

## 10. Important Notes

### Compatibility
- [Any compatibility concerns]

### Performance
- [Performance considerations]

### Security
- [Security considerations]

---

## Usage

```bash
# Execute phase by phase
/praxis-implement spec=.claude/generated/plans/[NAME]_FEATURE.md phase=1
/praxis-implement spec=.claude/generated/plans/[NAME]_FEATURE.md phase=2
# ... etc
```
