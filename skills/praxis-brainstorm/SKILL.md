---
name: praxis-brainstorm
description: 'Collaborative ideation and design exploration before implementation. Explores user intent, requirements, and design through interactive questioning and example mapping. Use when starting a new feature, designing a component, planning functionality, or when user says "brainstorm", "let''s think about", "design this", "how should we build", "I have an idea". Do NOT use for bug fixes or quick changes (use /praxis-fix), or when a spec already exists (use /praxis-implement).'
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Example mapping (default for features):**

- After exploring approaches, proceed to example mapping for any feature work
- **When to use (default):** New features, complex behaviors, use case design
- **When to skip:** Bug fixes, refactoring, simple changes, BFF pass-throughs
- Only ask to skip if you believe the change falls into a "skip" category — otherwise just start mapping
- Work through the feature rule by rule using this format:

```markdown
#### :blue_book: Rule 1: [Business rule statement]

**Examples:**
- :white_check_mark: [Happy path scenario] → [expected outcome]
- :white_check_mark: [Another valid case] → [expected outcome]
- :x: [Invalid case] → error "[error message]"
- :x: [Edge case] → error "[error message]"

**Questions:**
- [Unknowns to clarify with stakeholder]
```

- Each rule becomes a use case behavior, each example becomes a test case
- Surface questions/edge cases as you go
- Keep examples concrete with real values (names, dates, amounts)
- **IMPORTANT:** Include the example mapping summary in the design document (required for writing-plans)

**Presenting the design (behavior-first):**

- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- **Lead with behaviors:** Structure the design around what the system does (rules and behaviors from example mapping) before explaining how it's built (architecture, components)
- Suggested section order:
  1. **Behaviors** — the business rules and their examples (this IS the core of the design)
  2. **Architecture** — how the code is structured to support those behaviors
  3. **Data flow** — how data moves through the system
  4. **Error handling** — how failures map to user-facing outcomes
  5. **Testing strategy** — how behaviors are verified
- The goal: someone reading the design should understand *what the system does* before *how it does it*
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**

- Write the validated design to `./.claude/generated/plans/YYYY-MM-DD-<topic>-design.md`
- The design document should be structured behavior-first: behaviors and example mapping up front, architecture as supporting context
- **Include the full example mapping in the design document** — this is the primary input for writing-plans, which splits tasks by behavior

**Implementation (if continuing):**

Ask: "Design validated. How do you want to implement?"

Offer these two options:

1. **Write implementation plan** (Recommended for large/complex features)
   - Uses writing-plans skill
   - Detailed step-by-step tasks with exact file paths
   - Good for: multi-day work, team handoff, stakeholder visibility

2. **Implement with TDD directly** (Recommended for exploration/smaller features)
   - Uses tdd skill
   - Let design emerge from tests, one test at a time
   - Good for: unclear requirements, refactoring, when you want flexibility
   - Baby steps with confirmation at each step

## BFF Pass-Through Services

When brainstorming a feature for a **BFF (Backend for Frontend)** that is a pure pass-through (Controller → Service → HTTP Provider → Microservice, no BFF-specific business logic):

- **Skip example mapping** — the business rules live in the microservice, not the BFF
- **Testing approach**: Integration tests at the controller level with MSW mocking the microservice HTTP calls (not unit tests per layer, not InMemoryProvider fakes)
- **Design is simpler**: Focus on DTO shape, error mapping (microservice errors → BFF HTTP statuses), and auth guard

This does NOT apply to microservices themselves (a microservice keeps outside-in TDD with fakes).

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
