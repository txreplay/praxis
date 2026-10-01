# Praxis — Review Evidence Rules

Shared by `praxis-review` and `praxis-review-pr`. Every rule here comes from findings that authors rejected — not for their conclusion, but for their reasoning. The bar is on the evidence, never on the tone: a Critical backed by a traced failure stays Critical, and an author's disagreement does not retire it.

## Fetch the ticket, the spec and the mock before judging intent

A diff tells you what the code does, not what it was *asked* to do. Many rejected findings argued with a decision the ticket had already settled, or reported as a gap something the spec deliberately deferred.

1. **Find the ticket key** — `praxis.json › ticket_pattern` (default `[A-Z][A-Z0-9]+-\d+`) in the PR title, body, branch name or commit subjects.
2. **Read the ticket** through the provider (« Fetch a ticket in full »), description **and comments** — the arbitration that changed the scope is usually in a comment.
3. **Follow the links** — Notion (`notion-fetch`; no link → `notion-search` on the feature name before concluding there is no spec), Figma (`get_design_context`, `get_screenshot`, `get_code_connect_map`, loaded in one `ToolSearch`).
4. **Degrade gracefully, and say so.** A connector may be absent in a headless run; never block the review on it. Try once, and on failure write one line: `contexte ticket/Notion/Figma non consulté : connecteur indisponible`.
5. **Read-only, always.** No ticket comment, transition or edit; no Notion or Figma write; never copy production PII into a review.
6. **Read the ticket to the end, every point of it** — every AC, every comment. When the ticket enumerates cases, walk the code against the enumeration item by item and say which ones you checked.

| What you find | What it makes |
|---|---|
| A requirement the diff does not implement | A real finding — quote the ticket line and the code that misses it |
| Behaviour the ticket never asked for | A **Question**, not a violation |
| The ticket contradicting the code | Not automatically the code being wrong — tickets go stale. Quote both sides and ask |
| A design detail a few pixels off the mock | A Nit at most, unless a token or a shared component is bypassed |

**Never cite a ticket, a spec page or a frame you did not open.**

## Prove the path exists before you claim it

The costliest wrong finding is a **product path that does not exist** — a chain that type-checks, that a reader can follow, and that no user or client can ever walk. Observed: a finding claimed an update could persist one field without its companion row; the chain was real in the code and unreachable in the product, because the form step is never mounted before its cache is seeded. Another listed a payload value as bypassing a guard, when the route's own option made the guard fetch first — while the value that *did* get through was never mentioned.

| The claim | What you owe before writing it |
|---|---|
| "a user can reach X" | The route, the guard and the render condition that let them — quoted |
| "a client can send Y" | The validation the payload survives, check by check — run against the installed versions |
| "this state is persisted" | The write path from entry point to column, including the branch actually taken |
| "nothing prevents Z" | The grep that found no guard, and where you looked |

**Enumerate the callers** — two greps close the question. A finding on a payload no caller constructs is a **contract-shape** finding, not a live bug; say which, because the fix and the urgency differ.

Cannot establish reachability → write it **as a Question, downgraded, saying exactly what you could not trace**. Do not invent the user journey: if the ticket, spec or mock do not describe the scenario, say it is your inference and ask.

## An exploit is executed, not reasoned about

A **class** of bug can be argued; a **list of values that get through** cannot. Observed: a review enumerated three bypass values on an authorization guard; the class was right, the list was not — one value never reached validation because of the route's own decorator options, and the value that did get through was missing. The author wrote the suggested test and got a 500 instead of the predicted 400.

- **Read the entry point**, not only the schema and the guard: decorators and their options, middleware order, pipes.
- **Run each value** through the installed validator — a five-line probe, its output pasted.
- **Sweep the whole family** when one falsy value gets through: `undefined`, `null`, `0`, `""`, `-1`, `NaN`, `"0"`, a float.
- Have the class but not the executed list → **write the class**.

## The test you propose must fail against the mutation you cite

Observed: a review asked for an assertion in a child component's own spec; the author answered that the child is rendered with props directly, does not even import the constant, and so cannot discriminate the cited mutation. Before writing « il suffit d'un test qui… »: name the mutation, find the level that owns the behaviour (a child rendered with props cannot catch a parent's bug), say which existing test would fall. Cannot check → propose the intent (« rien n'épingle X ») and leave the placement to the author.

## A remedy you have not run is not a remedy

Eight remedies came back corrected in three weeks, always the same way: the diagnosis held, the remedy did not — a suggestion that opened another bug (a row shown selected whose first click wrote the already-selected value: a silent refusal replaced by a dead click), a one-liner targeting the wrong i18n namespace that would have made the test pass for the wrong reason.

- **A `suggestion` block is a commit in someone else's PR.** Apply it on the head (throwaway worktree), run the file's suite, paste both results — green on the fix, red under the mutation. Not run ⇒ no `suggestion` block.
- **A mutation cited as proof must have been executed.** `CONCURRENT_BATCHES = Number.POSITIVE_INFINITY` was offered as "unbounded" when `Math.ceil(6 / Infinity) === 0` sends no request at all.
- **A replacement name gets a grep first** — the proposed name may already exist nearby, meaning something else.
- Cannot run it → say « non exécuté, chemin tracé ci-dessous ».

## Unreachable defensive code is not dead code

Never report a guard, a `throw` or a fallback as redundant because the current call graph cannot reach it. *« A defence in depth that the current call graph cannot reach is doing its job, not failing at it. »* The finding is **"this guard has no test"**, never **"this guard is useless"**.

## Check the tooling before proposing a split

"Separate PR", "revert this file", "commit these keys apart" can be impossible: a generator may rewrite the whole artefact and forbid hand edits. Check what regenerates it before asking anyone to carve it up.

## Evidence discipline — every surviving finding

1. **Quote the clause that defeats you, or do not quote at all.** Observed: a library doc line was quoted as forbidding a value while the same sentence named that value as the escape hatch. Re-read your citation start to finish, and quote enough that the author can check you.
2. **A consequence you have not followed through the code is not a consequence.** Trace the path, or describe only what you traced.
3. **Never state a number you have not measured** — a count, a cost, an inventory, "nowhere else", "the only caller". The most frequent reason a finding comes back corrected: the author runs the grep the review skipped (« le dossier portait 12 tests, pas 10 »). **A number without its command does not ship** — paste the raw `rg -c` / `git grep -n` output; not measured ⇒ « plusieurs ».
4. **Young code is not settled doctrine.** Date a module before citing it as authority:
   ```bash
   git log --reverse --format='%ai %s' -- <path> | head -1
   git log --oneline -- <path> | wc -l
   ```
   A weeks-old module with one commit, whose first consumers are the PR under review, is a convention being written. Report what **breaks**; a convention that looks wrong is a **Question** to its author.

## Reconcile agent output

Agents disagree, and an unarbitrated finding is how a false positive lands on someone's PR.

1. Cross-check overlapping claims.
2. On any contradiction, **verify it yourself** — the agent with the evidence wins, not the more assertive or the more alarming one.
3. A contested finding is never posted unarbitrated: confirm with proof, drop, or demote to a Question.
4. Deduplicate — same root cause, one finding at the cause.
5. Drop what a bot or reviewer already said.
6. Discard the padding — generic advice, findings on unchanged code, restatements.

Report the conclusion, not the arbitration.

## Comment hygiene (added or modified comments only)

A comment is either useless, or the signal that better code should be written; the documentation of a feature is its tests.

| Flag | Why |
|---|---|
| Paraphrase of the next line | The code says it |
| *What* a function does when its name says it | Rename instead |
| *How* a behaviour works | Belongs in a test name — pair with the missing test |
| Banners, narrative history, commented-out code | Structure / git carries it |
| JSDoc restating the signature | Noise |
| `TODO`/`FIXME` with no ticket and no owner | Will never be actioned |

**Never flag**: a decision or trade-off invisible in the code, an external constraint (library bug + version, API quirk), a non-obvious invariant, a ticket/RFC link, tooling directives (`@ts-expect-error`, `eslint-disable* -- reason`, `@deprecated`, codegen headers, i18n pragmas). Absence of comments is never a finding. Group same-cause comments in one file into one finding.

## Hardcoded user-facing strings

Any string a user reads comes from a translation key. Scan strings **added or modified** by the diff.

**Flag**: JSX text; textual props (`label`, `title`, `placeholder`, `helperText`, `alt`, `aria-label`, `tooltip`); toast/dialog copy, displayed errors, empty states; column/tab labels, options, `document.title`; template literals with a visible fixed part (which also hide a pluralisation problem).

**Never flag**: keys, `data-testid`, routes, query keys, enum values, API field names, CSS classes; logs and errors no UI renders; tests, stories, mocks, fixtures, scripts; a literal merely moved.

**Verify before flagging**: is `t` in scope; does the key already exist (reuse beats creation); is a key the diff uses present and actually translated in every shipped locale. Locale roots, the source of truth, the escape-hatch marker and the closed list of i18n projects are project facts — read them in the project review guide.

| Case | Severity |
|---|---|
| Literal on a screen whose neighbours are translated | Important |
| A key replaced by a literal, or a used key missing from a locale | Critical — ships broken text |
| Literal in a wholly untranslated path, or an escape marker with no ticket | Nit |

Group per file.
