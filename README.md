# Praxis

A ticket-to-production workflow for Claude Code. Praxis bridges your task manager with persistent markdown state that survives across sessions, and drives every step around it: framing, spec, implementation, review, QA, commit, PR, deploy to a test environment, and a background watch over review requests and assigned tickets.

Praxis is generic. Everything specific to your team — channel ids, repo names, people, environments, incidents, code layout — lives in **your project**, in files the project gitignores. The skills only read their keys.

## Commands

```
# Tracking
/praxis-new KEY-30635      # Initialize tracking for an epic + all child tickets
/praxis-bug KEY-31982      # Lightweight tracking for a standalone ticket (no epic)
/praxis-plan KEY-40000     # Break an epic with no children into tickets
/praxis-triage             # Assess complexity (S/M/L), suggest the right workflow
/praxis-start KEY-30636    # Set the active ticket, prepare branch/worktree, show the resume point
/praxis-sync               # Sync from provider + analyze code + fetch Figma/Notion
/praxis-check              # Verify acceptance-criteria coverage
/praxis-post               # Post a progress comment on the task manager (after validation)
/praxis-done               # Pre-flight gates, transition status, move to next
/praxis-next               # Auto-detect the next action
/praxis-list               # List tracked epics and tickets

# Knowledge
/praxis-capture            # Record an implementation decision or spec correction
/praxis-learn              # Promote a cross-ticket lesson (or --review to surface relevant ones)

# Build
/praxis-brainstorm         # Explore intent and design before a feature
/praxis-spec name=x        # Write a phased feature spec
/praxis-implement spec=…   # Implement a spec phase by phase
/praxis-fix                # Bug fix / quick change without a spec
/praxis-tdd                # Strict baby-steps TDD

# Ship
/praxis-review             # Review local changes / a commit / a feature, fix after approval
/praxis-qa local           # Browser QA against the AC and the design
/praxis-commit             # Conventional commit + tracking sync
/praxis-ship               # Conformity → review → QA → commit → PR → tracking, with human gates
/praxis-deploy             # Merge onto the shared test branch, watch the deploy

# Review others
/praxis-review-pr 123      # GitHub-ready review of a PR (re-reviews, multi-PR consistency)

# Background watch (one pass per call, designed for /loop)
/praxis-watch              # Review-request channel + assigned tickets
/praxis-watch-prs          # Review requests, re-reviews on new commits, your PRs, red main after merge
/praxis-watch-tickets      # Pre-read assigned tickets, draft questions, collect answers

# Reporting
/praxis-report             # Weekly activity report from commits, PRs and tracking
```

## Install

```bash
git clone https://github.com/txreplay/praxis.git ~/praxis

# Skills + agents, linked into the project's .claude/
~/praxis/install.sh /path/to/your/project

# Same, plus the SessionStart hook (auto-loads the active ticket)
~/praxis/install.sh --with-hook /path/to/your/project

# Config
cp ~/praxis/praxis.example.json /path/to/your/project/praxis.json
```

Then add `praxis.json` and your overlay files to the project's `.gitignore`.

Skills are symlinked, so `git pull` in `~/praxis` updates every project. You can also link them once into `~/.claude/skills/` to use them everywhere.

## Configuration

`praxis.json` at the project root. Only `provider` and `site` are required; each section enables a group of skills. Full example: [praxis.example.json](praxis.example.json).

| Key | Used by | Description | Default |
|---|---|---|---|
| `provider` | all | Task-manager adapter (`jira`) | required |
| `site` | all | Instance host, for ticket links | required |
| `tracking_dir` | all | Local tracking files | `.claude/generated/praxis` |
| `ticket_pattern` | all, hooks | Regex of ticket keys in branches, commits, PR titles | `[A-Z][A-Z0-9]+-\d+` |
| `overlay` | all | Local markdown with project guidance, one section per skill | none |
| `ship` | ship, qa | `qa_targets`, `test_context`, `review_request` channel | — |
| `deploy` | deploy, qa, hooks | Shared test branch, deploy workflow, URL, other shared branches | — |
| `review` | review, review-pr | Project review `guide`, per-domain `checklists`, `report_template` | generic defaults |
| `watch` | watch* | Window, state dir, review channel, repo, scope globs, ticket query, budgets | — ([watch.md](skills/references/watch.md)) |
| `report` | report | Activity list file and granularity | — |

### Keep project specifics local

| File (in your project, gitignored) | Holds |
|---|---|
| `praxis.json` | Values: ids, names, globs, URLs, branches, queries |
| Overlay (`overlay`) | Prose per skill (`## praxis-qa`, `## praxis-watch-prs`, …): apps and ports, people and roles, past incidents behind a rule, code-readiness recipes, machine limits |
| Review guide (`review.guide`) | Sections replacing the generic review defaults: `## Stack`, `## Routing` (path → domain → agent), `## Exploration prompts`, `## i18n`, `## Verify`, `## Known local failures`… |
| Checklists, report template, activity list | Scoring criteria, report format, activities |

The overlay adds to a skill; it never relaxes a human gate. Before committing to praxis itself, grep for anything that identifies your company.

## Agents

`agents/` ships the subagents the review skills dispatch: `explore-codebase`, `explore-docs`, `frontend-code-reviewer`, `backend-code-optimizer`. A review guide can route a domain to your own project agents instead; generic ones are the fallback.

## Providers and sources

- **Task manager** — `skills/references/providers/`. Supported: **Jira** (jira CLI, or the Atlassian connector when available). Adding one = one markdown file implementing the provider contract (fetch, list children, search, transition, comment, create, status mapping, URL).
- **Chat** (review requests) — `skills/references/sources/`. Supported: **Slack** (read-only, drafts only).

## How it works

### Local state

```
.claude/generated/praxis/
├── .current                         # Active ticket pointer
├── lessons.md                       # Cross-ticket learnings
├── KEY-30635-user-profile/
│   ├── KEY-30635-user-profile.md    # Epic summary + ticket table
│   ├── KEY-30636-open-profile.md    # Ticket: status, AC progression, log, decisions, links, resources
│   └── KEY-30637-view-details.md
└── KEY-31982-status-filter/         # Standalone ticket (no epic file)
    └── KEY-31982-status-filter.md
```

The ticket file is the handoff between sessions: `/praxis-start` rebuilds the resume point from it, not from memory.

### Human gates

Commit, push, PR creation, provider comments, transitions, chat messages and review posts are **always** drafted, shown in full, and executed only after an explicit « ok ». Auto mode never overrides this ([common.md](skills/references/common.md)).

### `/praxis-ship`

Resolve and refresh (provider comments with attachments, PR states, feature-flag states asked, never assumed) → implement remaining spec phases → conformity (AC, comments, Figma re-captured, decisions) → review (mutation-proven falsifiability, flag default path, canonical helpers) → QA → commit → push and PR → tracking sync and review-request draft.

### Review

`/praxis-review` and `/praxis-review-pr` share [review-evidence.md](skills/references/review-evidence.md): read the ticket before judging intent, prove a path is reachable, execute an exploit rather than reason about it, run every suggested remedy, never state an unmeasured number. Agents explore and analyze in parallel; the orchestrator arbitrates.

### Background watch

Run `/loop /praxis-watch` in a dedicated session. Each pass, inside the configured window:
- scans the review channel, classifies requests by scope, dispatches reviews to subagents (with a 👀 reaction while in flight) and presents them for approval — after a staleness check against new commits and other reviewers;
- tracks reviewed PRs and re-reviews when the author pushes a fix;
- watches your own PRs for incoming reviews, and `main` after your merges, attributing a red pipeline before notifying;
- pre-reads your assigned tickets and drafts the questions to ask before you start.

Dispatch pauses when you are away (latency of your last answer). State lives under `watch.state_dir`, outside any repo.

### Pre-flight gates on `/praxis-done`

| Gate | Check | Fail mode |
|---|---|---|
| Clean working tree | `git status` | BLOCK |
| AC coverage | All criteria « Terminé » | WARN if partial, BLOCK if none |
| Build verification | typecheck + lint on affected projects | WARN |
| TODOs/FIXMEs | Branch diff | WARN |

### Hooks

- **SessionStart** (`--with-hook`) — loads the active ticket into every new session.
- **`hooks/check-branch-matches-ticket.sh`** (PreToolUse, Bash) — refuses `git commit` / `git push` when the branch does not carry the active ticket or its epic; shared deploy branches from `praxis.json › deploy` are exempt.
- **`hooks/block-session-links.sh`** (PreToolUse, Bash) — refuses any commit, push, PR or issue text carrying a Claude session link.

Register the two guards in `.claude/settings.json` under `hooks.PreToolUse` with matcher `Bash`.

## Typical workflows

### Epic with child tickets

```
/praxis-new KEY-30635      → fetch epic + children
/praxis-triage             → S/M/L, workflow
/praxis-start KEY-30636    → branch, resume point, lessons
/praxis-spec → /praxis-implement   (or /praxis-fix for a small change)
/praxis-capture            → record a spec deviation
/praxis-ship               → gates → commit → PR (draft) → tracking
/praxis-deploy             → shared test environment for QA
/praxis-done               → gates → transition → next ticket
/praxis-learn              → promote lessons
```

### Standalone bug

```
/praxis-bug KEY-31982 → /praxis-fix → /praxis-ship → /praxis-done
```

### Review loop

```
/loop /praxis-watch        → reviews to approve, your PRs' reviews, red main, ticket questions
```

### Lost?

```
/praxis-next               → "3/5 AC covered. Run /praxis-check."
```

## License

MIT
