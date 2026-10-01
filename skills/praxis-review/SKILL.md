---
name: praxis-review
description: Universal code review - auto-detects scope from git changes, spec, commit, or brief. Use after completing tasks, implementing major features, before merging, when stuck (fresh perspective), before refactoring (baseline check), or after fixing complex bugs.
argument-hint: "[scope=front|back|all] [feature=name] [spec=path] [mode=pushed|local] [commit=hash] [no-simplify] [no-comment-pass] [no-factor-pass]"
---

**YOU ARE EXECUTING THE `/praxis-review` SKILL.** Follow ALL instructions step by step — this is a workflow, not a freeform conversation. Think carefully. Follow CLAUDE.md rules.

## References

- [review-evidence.md](../references/review-evidence.md) — ticket context, reachability, executed exploits, remedies, evidence discipline, agent reconciliation, comment hygiene, user-facing strings.
- **Project review guide** — `praxis.json › review.guide`. Read it first. Its sections, when present, are authoritative and **replace** the generic defaults below:

| Guide section | Replaces |
|---|---|
| `## Stack` | the stack facts sent to agents (incl. what the repo does *not* use) |
| `## Routing` | the path → domain → review agent table of §1 |
| `## Existing reviews` | which bots and prefixes to read, and the known noise |
| `## Affected projects` | the command listing affected projects |
| `## Simplify prompts` | the §1.5 agent prompts |
| `## Comment keepers` | repo-typical comments that must stay (§1.6) |
| `## Exploration prompts` | the §2 agent prompts |
| `## Deep analysis dispatch` | the §2.6 agents and prompts, incl. guideline audits |
| `## i18n` | locale roots, source of truth, escape marker, projects |
| `## Test tiers` | the test tiers to compare against (§2.7 C) and the narrowed test command |
| `## Verify` | the §8 commands |
| `## Known local failures` / `## CI signals` | the §8 troubleshooting tables |
| `## Rules` | extra project rules appended to the final Rules list |

- **Checklists** — `praxis.json › review.checklists` (`{domain: path}`): scoring criteria per domain. None → agents score with their own axes and say so.
- **Report template** — `praxis.json › review.report_template`, else [templates/review-report.md](templates/review-report.md).

No guide configured → run with the generic defaults and say so in §9.

## Critical Instruction

**Use the Agent tool with `subagent_type` to analyze. Never read or analyze code files directly yourself** — except the line-precise mechanical passes (§1.6, §1.7) and verifying a contested claim. Agents do the heavy lifting; you orchestrate and aggregate.

Generic agents: `explore-codebase`, `explore-docs`, `backend-code-optimizer`, `frontend-code-reviewer`. Project agents come from the guide's Routing; when one is unavailable, fall back to the generic one and say so. Always correct a generic agent's built-in stack assumptions in the prompt with the guide's Stack.

---

## 1. DETERMINE SOURCE & SCOPE

**Spec alone** (`spec=file.md`) → the file list comes from the spec. **Spec + other source** → the spec is context, files come from the other source.

Source priority: `feature` → `commit` → `mode` → `spec` alone → default `mode=local`.

Use an unfiltered git output for diffs (a proxy that truncates output produces a wrong review — e.g. `rtk proxy git …` when rtk is installed).

| Source | Commands |
|---|---|
| `mode=pushed` (or no args and a clean tree) | `git log origin/$(git rev-parse --abbrev-ref HEAD) -1 --format="%H %s"` · `git show --name-only --format="" HEAD` · `git show HEAD` |
| `mode=local` (default) | `git diff origin/main...HEAD --name-only` · `git status --porcelain` · `git diff HEAD` |
| `commit=<hash>` | `git show --name-only <hash>` · `git show <hash>` |
| `feature=<name>` | `explore-codebase` finds every related file; apply `scope` with the guide's Routing |

**Route each file** with the guide's Routing table, first match wins. Default without a guide: backend / frontend / database / generated (flag hand edits) / config-docs. Apply `scope` if given.

**Existing review feedback** (when a PR exists), before the simplify pass — never re-litigate a point a human made, never restate a bot:

```bash
gh pr view --json number,title,url 2>/dev/null
gh api "repos/<REPO>/pulls/<n>/reviews?per_page=100" --jq '.[] | select(.body != "") | "[\(.user.login)/\(.state)] \(.body)"'
gh api "repos/<REPO>/pulls/<n>/comments?per_page=100" --jq '.[] | "[\(.user.login)] \(.path):\(.line // .original_line) :: \(.body)"'
```

An unresolved human blocking comment from a previous round outranks anything you find. The guide's Existing reviews section says how bots number their findings and what noise to ignore.

**Ticket, spec, mock** — per review-evidence.md.

**Affected projects** — the guide's command (e.g. an affected-graph query against `origin/main`). Keep the list: it drives §8.

```markdown
## Review Scope

**Source**: [feature/mode/spec/commit] · **Spec Context**: [path or None] · **Commit**: [hash]
**Detected Scope**: [back/front/both] · **Affected projects**: [list]

### Backend ([count] files) — grouped by domain key
### Frontend ([count] files) — grouped by domain key
### Other ([count] files) — flag anything generated
```

---

## 1.5 SIMPLIFY PASS (before review)

Clean the changed code first so the review focuses on real concerns.

- **A** — one simplification agent per domain present, in one message (the guide's Simplify prompts, else: dead code and unused imports, duplicated logic, over-complex conditionals, functions to split, existing helpers that replace inline code, over-extraction smells; prioritized list with `file:line`).
- **B** — apply only **safe, non-behavioural** changes with Edit, then report `### Simplify Pass` with one line per change.
- **C** — skip on `no-simplify`, no changed files, or only config/docs/generated.

---

## 1.6 COMMENT HYGIENE PASS (remove)

On lines **added or modified by the diff** only. Reading the hunks directly is allowed — the pass is line-precise.

Delete what review-evidence.md › Comment hygiene flags, plus comments restating a test's assertion (fold into the test name). Keep what it protects, plus the guide's Comment keepers. **Better code beats a deleted comment**: when a comment exists because the code is unclear and the fix is not safe blind, keep it and raise an Important finding in §5.

```markdown
### Comment Hygiene Pass
- [X] Removed — `file:line` — "<comment>" (paraphrases the code)
- [KEPT] `file:line` — "<comment>" (documents an accepted trade-off)
- [FLAGGED] `file:line` — kept, the code needs renaming/extraction → §5
```

Skip on `no-comment-pass`, or no relevant files.

---

## 1.7 FACTORIZATION PASS (copy-paste inside the diff) — MANDATORY

Reviewers repeatedly catch the same block written several times in one PR. §2 looks for code that duplicates **existing** helpers; this pass looks for code the diff duplicates **with itself** and with the lines next to what it touched. Report it even when it finds nothing.

**A — detect mechanically**:

```bash
git diff <BASE>...HEAD -U0 -- '*.ts' '*.tsx' '*.js' '*.jsx' | node -e '
const W = 4, files = {}; let cur = null
for (const l of require("fs").readFileSync(0, "utf8").split("\n")) {
  if (l.startsWith("+++ b/")) { cur = l.slice(6).trim(); files[cur] = [] }
  else if (l.startsWith("+") && !l.startsWith("+++") && cur) files[cur].push(l.slice(1).trim())
}
const skip = new Set(["}", "})", ")", "},", "]", "],"]), seen = new Map()
for (const [f, raw] of Object.entries(files)) {
  const lines = raw.filter((x) => x && !skip.has(x))
  for (let i = 0; i + W <= lines.length; i++) {
    const k = lines.slice(i, i + W).join("\n")
    seen.set(k, [...(seen.get(k) ?? []), `${f}:${i}`])
  }
}
;[...seen].filter(([, w]) => w.length >= 3).sort((a, b) => b[1].length - a[1].length)
  .forEach(([b, w]) => console.log(`x${w.length}  ${w[0]} …\n    ${b.replaceAll("\n", "\n    ")}\n`))
' | head -80
```

Adapt the globs to the stack. Also look at the code **around** each touched spot: adding the 15th identical `case` extends a copy-paste, and the whole family is in scope.

**B — judge**:

| Hit | Verdict |
|---|---|
| Same business rule in ≥ 2 places | **Important** — one helper, every call site uses it |
| Same body repeated for N keys, diff adds or edits members | **Important** — lookup + one code path |
| Same test setup in ≥ 3 tests | **Nice-to-have** — local builder or `it.each`, never at the cost of readability |
| Two short stable occurrences | Not a finding — say so (premature extraction is a finding too) |
| Repetition imposed by a generator | Not a finding — name the generator |

```markdown
### Factorization Pass
- Detector: {n} repeated windows (≥ 3) — or « aucun »
- [FACTOR] `file:line` ×{n} — {what repeats} → {proposal} (Important)
- [OK] `file:line` ×2 — {why it stays}
```

Every `[FACTOR]` goes to §5. Skip on `no-factor-pass` (say so in §9) or only config/docs/generated.

---

## 2. EXPLORE (PARALLEL)

Agents only, in **one message**, scaled to the scope — at least 2 per domain present. Use the guide's Exploration prompts. Generic defaults:

- **Backend** — correctness (error handling, null safety, async, data access); pattern comparison with the same service; architecture and dependency direction (multi-file changes); duplication against shared libs (new code); test coverage, stating for each new assertion whether it would still pass with its target line removed; guard and permission audit on every new or changed route (a permission borrowed from another feature is a product question, not your call).
- **Frontend** — correctness (hook deps, data-fetching library usage, types, error/loading states) hunting three classes: **state that lies** (a control showing "all" while a filter is still sent), **unreachable error path** (`data ?? []` whose callers never read `isError`), **redundant guard** (ternary branches that collapse); pattern comparison including **two derivations of one fact** and **parallel mechanisms**; component quality (theme tokens, accessibility, states, test ids); duplication across the **whole app source**, not just the module; user-facing strings and locales; test tier and falsifiability recon; feature-flag default path coverage.

| Supporting condition | Action |
|---|---|
| Schema / migration changed | nullability, defaults, index coverage, rolling-deploy safety |
| API contract changed | flag the generator to re-run and the generated artefact to commit |
| Shared lib changed | blast radius: consumers and public API changes |
| External library API in doubt | `explore-docs` |
| Feature-flag-dependent code | **ask the user** the flag's state on the target environment — never assume |

### 2.5 Post-exploration check

Full path traced from entry point to data layer? A reference implementation found? Schema and indexes known? Library APIs verified? Flag state confirmed **and its default known** (the default path is the one that ships)? Sibling test tier known? Any gap → one targeted agent.

---

## 2.6 DEEP ANALYSIS (PARALLEL) — MANDATORY

One agent per active domain key from §1, in **one message**, each with spec context and the aggregated exploration results, scoring against the domain's checklist (`review.checklists`) and returning Critical / Important / Nice-to-have with `file:line`. The guide's Deep analysis dispatch decides the agents, the extra audits (e.g. a frontend guidelines audit with its own score), and their prompts.

**User-facing strings** — mandatory whenever front files are touched: review-evidence.md › Hardcoded user-facing strings, with the guide's i18n facts.

Skip: `scope=front` → no backend agents; `scope=back` → no frontend agents; empty domains skipped; nothing changed → report « No files to review » and stop; only generated agent configs → do not review the content, report they must be reverted in favour of their canonical source.

Integrate: scores → §4; guideline violations and string findings → §4 and §5; categorized issues → §5.

---

## 2.7 FALSIFIABILITY CHECK — MANDATORY when the diff touches tests

**A test that cannot fail is not coverage** — the most frequent blocking finding in review. Skip only if the diff adds no test **and** no behaviour.

- **A — headline deliverable**: from the ticket/spec/title, the **one** behaviour the change exists to ship.
- **B — prove it**: for that behaviour and every new stateful one: neuter the production code (inert element, removed default, dropped wiring); run the narrowed test (the guide's command); **revert immediately** (`git checkout -- <file>`), one mutation at a time. Red → coverage real. Green → **Blocking**.

  ```markdown
  ### Falsifiability
  - [PROVEN] `Banner.test.tsx:59` — replaced `ProfileLink` with `<span>`: 2 tests fail.
  - [BLOCKING] `listSearch.test.ts` — removed `.default(false)` on `unreadOnly`: 0 tests fail. The rule lives only in a comment.
  - [TRACED, not run] … — when the suite needs a real DB or is too long, name the line that would be neutered.
  ```
- **C — tier parity**: compare with sibling slices or neighbouring endpoints (the guide's Test tiers). A missing tier the siblings all ship is a gap, Blocking when the wiring is the deliverable.
- **D — comment that should be a test**: every kept comment stating a rule gets step B. Nothing fails → a missing test, reported as such.

---

## 3. AGGREGATE RESULTS

Aggregate the §2.6 outputs; do not re-analyze. Format per the checklists.

```markdown
## Code Review Analysis

### Files Reviewed (from agent reports)
- `path/to/file` - [purpose of changes]
```

## 4. QUALITY SCORES

Per domain from the agents, then a global score weighted by file count per domain (generated and config/docs excluded from the denominator), with a 1–2 sentence assessment.

## 5. PROPOSE FIXES

Every finding states **how it was established**: **Verified** (traced chain `file:line → file:line`, or a command and what its output showed) or **Unreproduced** (a **question**, with what you tried and what would settle it). A comment, a PR description or an author's reply is never evidence of behaviour.

```markdown
## Recommended Fixes

### Critical (must fix)
1. **[Issue]** — File: `path:line` · Problem · Evidence · Fix

### Important (should fix)
### Nice-to-have
### Open questions (could not reproduce)
1. **[Suspicion]** — `path:line`. Tried: […]. Would settle it: […]
```

## 6. VALIDATE

`AskUserQuestion`: « Code review complete. What would you like to do? » — Apply all fixes · Apply Critical only · Apply Critical + Important · No fixes needed.

## 7. IMPLEMENT (if requested)

Apply the approved fixes with Edit, Critical first, one at a time, nothing left halfway. Do not change business logic unless it is a bug; ask when logic seems wrong. **Never edit generated files** — fix the source and re-run the generator.

## 8. VERIFY

Run the guide's Verify commands on the affected projects only — never across the whole repo. A failing check: prove whether it is pre-existing (reproduce on `origin/main`) before attributing it, and use the guide's Known local failures table. Never `--no-verify` on a hunch.

**Local green is not CI green.** Read `gh pr checks` and the CI summary (the guide's CI signals). A target that "passed" in under a second very likely did not run. A CI-red / local-green divergence is named and explained, never assumed to be an env gap.

## 9. SUMMARY

Per the report template. Say which passes were skipped and which context (guide, ticket, connectors) was unavailable.

---

## Rules

- **USE AGENTS**, route by path to the project's domain agent when it exists; correct generic agents' stack assumptions in every prompt
- **READ THE EXISTING REVIEWS FIRST** — extend bot findings, never repeat them; an unresolved human blocking comment outranks anything you find
- **PROVE THE TESTS CAN FAIL** (§2.7) — neuter, run, revert; a green test after the mutation is Blocking
- **EVIDENCE OR A QUESTION** — review-evidence.md applies to every finding
- **MEASURE** — scores per domain; **PRIORITIZE** Critical > Important > Nice-to-have; a lint rule set to `error` is Critical (it fails the build)
- **SIMPLIFY**, **STRIP USELESS COMMENTS**, **FACTOR WHAT THE DIFF REPEATS** — over-extraction is a finding too
- **FIX WHAT YOU FIND** after approval; **MINIMAL CHANGES**; **NEVER TOUCH GENERATED FILES**
- **ASK ABOUT FLAGS** — never assume a flag's state, always establish its default
- **CHECK ALL LOCALES**; **ROLE OVER `data-testid`** when the component exposes a role and an accessible name
- **VERIFY TARGETED, THEN READ CI**
- Plus the guide's `## Rules`
