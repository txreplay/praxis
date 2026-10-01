---
name: praxis-tdd
description: Use when implementing any feature or bugfix with strict baby-steps TDD - enforces minimal code and mandatory checkpoints
---

# Strict Test-Driven Development

## Philosophy

This is Kent Beck's original TDD discipline. Not "write tests first" - that's too loose. This is **baby steps with proof at every stage**.

**The Rule:** You cannot write a single line of implementation without a failing test that DEMANDS it.

**The Discipline:** The simplest code that passes is often absurdly simple. That's correct. Resist the urge to "just write the real thing."

## The Cycle

```
RED → verify → GREEN → verify → REFACTOR → verify → COMMIT → verify → repeat
      ↑                ↑                    ↑                 ↑
   CHECKPOINT       CHECKPOINT          CHECKPOINT       CHECKPOINT
   (confirm)        (confirm)           (confirm)        (confirm)
```

Every arrow with "CHECKPOINT" requires user confirmation before proceeding.

## Mandatory Checkpoints

### CHECKPOINT 1: Before Writing Test

State the behavior in ONE sentence:
> "I will write a test that [specific behavior]"

**Wait for confirmation.**

### CHECKPOINT 2: After RED (Test Fails)

Show:
1. The test code
2. The failure message
3. Confirm: "This fails because [the feature is missing], not because of [typo/syntax/setup error]"

**Wait for confirmation.**

### CHECKPOINT 3: Before GREEN (Propose Simplest Code)

State the absolute simplest code that would pass:
> "The simplest code to pass this test is: [code]"

This might be:
- `return true`
- `return 'hardcoded string'`
- `return null`
- `if (input === 1) return true`

**If it feels stupid, it's probably right.**

**Wait for confirmation.**

### CHECKPOINT 4: After GREEN (Test Passes)

Show:
1. The implementation
2. Test output (passing)
3. Ask: "Add another test to force generalization, or is this behavior complete?"

**Wait for confirmation.**

### CHECKPOINT 5: Before Refactor (Production AND Test Code)

Refactoring applies to **both production code AND test code**. You MUST review test files for quality — they are first-class code.

**Step 1: Run the Test Refactoring Checklist**

Go through each item. You cannot say "no refactoring needed" without explicitly evaluating every point:

| Check | What to look for |
|-------|-----------------|
| **Duplicated setup** | Is the same object/state created in multiple tests? Extract to a shared helper, `beforeEach`, or factory function. |
| **Duplicated act** | Are multiple tests calling the same function with the same boilerplate around it? Extract a `subject()` or `act()` helper. |
| **Unclear test names** | Does each test name read as a behavior specification? Rename vague names like "works correctly" to "returns false for odd numbers". |
| **Arrange/Act/Assert clarity** | Is each test clearly structured in 3 sections? Add blank lines to separate them if needed. |
| **Magic values** | Are there unexplained literals? Extract to named constants or use descriptive variable names. |
| **Long test bodies** | Is any test longer than ~10 lines? Consider extracting setup into helpers. |
| **Inconsistent patterns** | Do all tests in the file follow the same structure and conventions? |

**Step 2: State your findings**

> "Test file review:
> - [item]: [finding — either a specific refactoring or why it's genuinely clean]
> - ...
> Production code review:
> - [specific change or why it's clean]"

You must list **at least 3 checklist items** you evaluated with concrete findings. A bare "no refactoring needed" without this evaluation is FORBIDDEN.

**Wait for confirmation.**

### CHECKPOINT 6: After Cycle (Commit)

Propose a commit for the completed cycle:
1. Summarize the behavior implemented
2. Suggest commit message: `test(scope): [behavior implemented]`

Example:
> "Cycle complete. Ready to commit: `test(isEven): return true for even numbers`"

**Wait for confirmation, then create the commit.**

## Hard Constraints

### Code Justification Rule

No arbitrary line limits. Instead:

**Every line of implementation must trace to a test assertion.**

Before writing code, you must answer for each line:
> "This line exists because test X asserts Y"

If you cannot justify a line against a current test, delete it.

### No Speculation

These are FORBIDDEN until a test demands them:
- Parameters with default values
- Configuration options
- Error handling for hypothetical cases
- Generic types
- Helper functions
- Comments explaining "why"

### The Triangulation Rule

**You cannot generalize without two failing tests.**

| Tests | Allowed Implementation |
|-------|----------------------|
| `add(1,1) → 2` | `return 2` |
| `add(1,1) → 2` AND `add(2,3) → 5` | `return a + b` |

One test = hardcode. Two tests = generalize. No exceptions.

## Example: Building `isEven`

### Cycle 1

**CHECKPOINT 1:** "I will write a test that checks if 2 is even"

```typescript
test('returns true for 2', () => {
  expect(isEven(2)).toBe(true)
})
```

**CHECKPOINT 2:** "Fails because isEven doesn't exist"

**CHECKPOINT 3:** "Simplest code: `return true`"

```typescript
function isEven(n: number): boolean {
  return true
}
```

**CHECKPOINT 4:** "Passes. Add another test?"

**CHECKPOINT 5:**
> "Test file review:
> - Duplicated setup: only one test, nothing to deduplicate yet.
> - Test name: 'returns true for 2' — clear behavior specification.
> - Arrange/Act/Assert: single-line test, structure is clear.
>
> Production code review: single return statement, nothing to clean up."

**CHECKPOINT 6:** "Cycle complete. Ready to commit: `test(isEven): return true for 2`"

### Cycle 2

**CHECKPOINT 1:** "I will write a test that checks if 3 is not even"

```typescript
test('returns false for 3', () => {
  expect(isEven(3)).toBe(false)
})
```

**CHECKPOINT 2:** "Fails because we return true for everything"

**CHECKPOINT 3:** "Simplest code: `return n === 2`"

Wait - that still passes both tests. Even simpler.

Actually: `return n % 2 === 0` is needed to pass both. But is there something simpler?

`return n !== 3` - passes both tests!

**This is the discipline.** Present the truly simplest, let user decide.

```typescript
function isEven(n: number): boolean {
  return n !== 3
}
```

**CHECKPOINT 4:** "Passes. This is absurd but correct. Add another test?"

**CHECKPOINT 5:**
> "Test file review:
> - Duplicated setup: both tests call `isEven(n)` directly with no shared setup needed — clean.
> - Test names: 'returns true for 2' and 'returns false for 3' — both describe behavior clearly.
> - Consistency: both tests follow the same `expect(isEven(x)).toBe(y)` pattern — consistent.
>
> Production code review: single return statement, nothing to clean up."

**CHECKPOINT 6:** "Cycle complete. Ready to commit: `test(isEven): return false for 3`"

### Cycle 3

**CHECKPOINT 1:** "I will write a test that checks if 5 is not even"

```typescript
test('returns false for 5', () => {
  expect(isEven(5)).toBe(false)
})
```

**CHECKPOINT 2:** "Fails because `5 !== 3` is true, but we need false"

**CHECKPOINT 3:** "Now I need real logic. Simplest: `return n % 2 === 0`"

```typescript
function isEven(n: number): boolean {
  return n % 2 === 0
}
```

**CHECKPOINT 4:** "All tests pass. Generalization earned."

**CHECKPOINT 5:**
> "Test file review:
> - Duplicated setup: three tests all follow `expect(isEven(x)).toBe(y)`. This is fine — no shared state to extract. Each test is a single assertion with no setup overhead.
> - Test names: 'returns true for 2', 'returns false for 3', 'returns false for 5' — all describe input/output behavior. However, now that we have the generalized implementation, consider grouping with `describe` blocks for even/odd cases if more tests are added.
> - Magic values: 2, 3, 5 are self-explanatory for an isEven function — no extraction needed.
>
> Production code review: `n % 2 === 0` is the final generalized form — clean and minimal."

**CHECKPOINT 6:** "Cycle complete. Ready to commit: `test(isEven): correctly identify even and odd numbers`"

## Anti-Patterns

| You Think | Reality | Action |
|-----------|---------|--------|
| "I'll just write the real implementation" | You haven't earned it | Write simpler code |
| "This obviously needs X" | Nothing is obvious until tested | Wait for failing test |
| "Let me handle this edge case" | Edge case needs its own test first | Stop, write test |
| "This is too slow" | Slow is fast. Debugging is slower. | Trust the process |
| "The user will think I'm stupid" | The user asked for this discipline | Continue |
| "One more line won't hurt" | It will. That's how debt starts. | Remove the line |

## When to Use This Skill vs Regular TDD

| Situation | Use |
|-----------|-----|
| Learning TDD discipline | **Strict TDD** |
| Training yourself to slow down | **Strict TDD** |
| Complex logic where you keep over-engineering | **Strict TDD** |
| Simple CRUD with clear patterns | Regular TDD |
| Time pressure with well-understood domain | Regular TDD |

## Red Flags - STOP Immediately

If I do any of these, call me out:

- Skip a checkpoint
- Generalize without two tests
- Add "just one more thing"
- Say "while I'm here..."
- Propose real implementation when fake would pass
- Handle errors without a test requiring it
- Write a line I cannot justify against a test assertion


## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Debugging Integration

Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

Never fix bugs without a test.

## Testing Anti-Patterns

When adding mocks or test utilities, read @testing-anti-patterns.md to avoid common pitfalls:
- Testing mock behavior instead of real behavior
- Adding test-only methods to production classes
- Mocking without understanding dependencies

## Final Note

This process feels slow. It is slow. That's the point.

The goal is not speed. The goal is:
1. **Proof** that every line of code is necessary
2. **Discipline** to resist speculation
3. **Trust** in the test suite

Speed comes later, when the discipline is internalized.
