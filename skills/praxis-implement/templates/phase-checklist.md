# Phase Development Checklist

## Pre-Implementation
- [ ] Read and understand the spec file
- [ ] Identify phase scope (backend/frontend/both)
- [ ] List all files to create/modify
- [ ] Identify external libraries needed
- [ ] Run exploration agents

## Exploration Verification
- [ ] Database schema understood (if needed)
- [ ] Similar patterns found in codebase
- [ ] Library documentation reviewed (if needed)
- [ ] No missing context

## Implementation Order

### Backend (if applicable)
1. [ ] Data & domain (models, entities, schemas)
2. [ ] Data access & integrations (repositories, queries, API clients)
3. [ ] Business logic (services, use cases, DTOs / validation)
4. [ ] Entry points (routes, controllers, middleware)

### Frontend (if applicable)
1. [ ] Types (interfaces, types)
2. [ ] API client (calls, generated types)
3. [ ] Data hooks (e.g. React Query)
4. [ ] Components (UI components)
5. [ ] Pages / routes

## Post-Implementation
- [ ] Typecheck, lint, test, build pass on the affected projects (praxis `common.md › Verification commands`)
- [ ] Migration reviewed (if the schema changed)
- [ ] Spec file updated with completed items
