---
name: praxis-learn
description: Capture a cross-ticket lesson or surface relevant lessons for the current ticket. Use when the user invokes "/praxis learn" to record a pattern, or "/praxis learn --review" to see lessons relevant to the current work.
---

# /praxis learn [--review]

Capture or review cross-ticket lessons.

## Arguments

- No argument: **capture mode** — record a new lesson
- `--review`: **review mode** — surface relevant lessons

## References

- [common.md](../references/common.md) — status model, paths, conventions
- [templates.md](../references/templates.md) — lessons file format

## Capture mode (default)

### 0. Load config

Per [common.md — Loading the provider](../references/common.md#loading-the-provider) (config only).

### 1. Gather the lesson

Ask one question at a time: **What did you learn?**, **Category?**, **Impact?** (optional).

### 2. Resolve ticket context

Per [common.md — Active ticket resolution](../references/common.md#active-ticket-resolution).

### 3. Write to lessons.md

Create file if missing. Append row with date, ticket, category, lesson, impact. Chronological order.

### 4. Cross-reference in ticket

Add to **Avancement**: `- {YYYY-MM-DD} : **Lesson** — {summary} (voir lessons.md)`

## Review mode (`--review`)

### 0. Load config and resolve ticket

Same as capture mode.

### 1. Score relevance

For each lesson, score (0-3) on three axes:
- **Category match** (0-1): lesson category matches ticket domain (e.g., `api` lesson for API ticket)
- **Code area overlap** (0-1): lesson references files/modules related to this ticket
- **Keyword proximity** (0-1): lesson text shares terms with ticket AC/description

Sum the scores. Show lessons scoring ≥ 1. If no lessons score ≥ 1 → "Aucune lesson pertinente pour ce ticket."

### 2. Surface top lessons

Display top 5 by score. If any scores 3 → offer to add a note in the ticket's Progression.
