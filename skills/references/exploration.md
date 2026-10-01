# Praxis — Codebase Exploration

Shared by `praxis-spec`, `praxis-fix` and `praxis-implement`. Stack-agnostic; examples are JavaScript/TypeScript.

## Where the code lives

Never assume a layout. Take it, in this order, from:
1. the project review guide (`praxis.json › review.guide`), sections `## Stack` and `## Routing`;
2. the project's `CLAUDE.md` / `AGENTS.md`;
3. a quick look at the repo root (`ls`, workspace config such as `nx.json`, `pnpm-workspace.yaml`, `turbo.json`, `package.json` workspaces).

Put the real paths into every agent prompt below — `[backend paths]`, `[frontend paths]`.

## Launch in parallel

All agents in **one message**, scaled to the task:

| Scope | Backend agents | Frontend agents |
|-------|---------------|-----------------|
| Single file fix | 1 | 1 |
| Single-layer feature | 2 | 2 |
| Multi-layer feature | 2–3 | 2–3 |
| Cross-cutting / large feature | 3–4 | 3–4 |

### Backend (min 2 when backend is in scope, split by concern)

1. **Domain & data shapes** — `explore-codebase`: "Find the entities, models, DTOs/schemas and validation related to [feature] in [backend paths]."
2. **Business logic** — `explore-codebase`: "Find the services / use cases / handlers that implement [feature] in [backend paths]. Read their dependencies and error handling."
3. **Entry points** — `explore-codebase`: "Find the routes / controllers / resolvers for [feature] in [backend paths]. Check guards, middleware, validation and response shapes."
4. **Data access & integrations** — `explore-codebase`: "Find the repositories / ORM queries, external API clients and config used by [feature] in [backend paths]."
5. **Closest existing feature** — `explore-codebase`: "Find the most similar existing feature to [feature] in [backend paths]. I need to replicate its patterns."

### Frontend (min 2 when frontend is in scope, split by concern)

1. **Components & UI** — `explore-codebase`: "Find the components related to [feature] in [frontend paths]. Check props, state, and which design-system components they use."
2. **Data & state** — `explore-codebase`: "Find the hooks, data-fetching calls (e.g. React Query) and state related to [feature] in [frontend paths]."
3. **Routes & pages** — `explore-codebase`: "Find the pages / routes / layouts for [feature] in [frontend paths]. Check route structure, data loading, i18n."
4. **Types & API layer** — `explore-codebase`: "Find the TypeScript types and API client functions for [feature] in [frontend paths]. Note any generated API types."
5. **Closest existing feature** — `explore-codebase`: "Find the most similar existing feature to [feature] in [frontend paths]. I need to replicate its patterns."

### Supporting (as needed, one each)

| Need | How |
|------|-----|
| Data model | `explore-codebase` on the schema and migrations (e.g. Prisma schema, SQL migrations, ORM entities): tables, columns, relations, indexes, access rules |
| Library docs | `explore-docs`: "[library] [specific API] documentation" — against the version installed in `node_modules` |
| Current practice | the WebSearch tool: "[topic] best practices" |

## Post-exploration check

Do not proceed with incomplete context:

1. **Full path traced?** Entry point → logic → data access (backend); route → data hook → API → component (frontend). Gaps → a targeted `explore-codebase`.
2. **Reference implementation found?** If not → `explore-codebase`.
3. **Data model known?** Tables, columns, relations, constraints, access rules. If not → `explore-codebase` on the schema.
4. **Library APIs verified** against the installed version? If not → `explore-docs`.
