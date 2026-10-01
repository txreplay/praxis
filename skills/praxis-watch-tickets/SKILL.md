---
name: praxis-watch-tickets
description: Use when the user wants their assigned tickets watched in the background and pre-read before they start them — "surveille mes tickets", "watch my tickets", "/loop /praxis-watch-tickets", "prépare les questions sur mes prochains tickets". One pass per invocation, designed for /loop. Do NOT use to start a ticket (/praxis-start) or to triage one on demand (/praxis-triage).
argument-hint: "[state] [post=ask|auto] [skip <KEY>] [unskip <KEY>] [force <KEY>] [chained]"
---

**YOU ARE EXECUTING THE `/praxis-watch-tickets` SKILL.** One pass: scan, pre-read at most `watch.tickets.budget` tickets, surface answers, report, schedule. Never loop internally.

## References

- [common.md](../references/common.md) — config, tracking paths, slugification, destructive-action gates
- [templates.md](../references/templates.md) — ticket file template
- [watch.md](../references/watch.md) — `watch` config, overlay, window, state files, next pass
- `providers/{provider}.md` — « Search tickets », « Fetch a ticket in full », « Post a comment »

Load config, then `watch.tickets` and the overlay's `## praxis-watch-tickets` section. `{state}` = `{state_dir}/tickets`. First, one `ToolSearch` call: `select:PushNotification,ScheduleWakeup`. No `AskUserQuestion` available (subagent, headless) → nothing is posted; drafted questions stay `pending`. Output in French.

## Non-negotiable rules

- **Only tickets assigned to the user are tracked, pre-read and commented.** A parent epic, a linked ticket or a blocker may be read **for context**; never tracked, commented or transitioned.
- **Read-only on the provider, except the question comment** — posted after `AskUserQuestion`, or without asking only under `post=auto`, opted into per launch and never saved in the state.
- **Never touch `.current`, never create a branch or worktree, never change a status.** Another session may be working; this skill only prepares.
- **Read-only on the checkout**: `rg`, `git log`, `git show origin/main:<path>`.
- **Questions are for humans, written like a human**: short, direct, one per line, no headings, no first names of non-developers.
- **State outside the repo**, in `{state}/state.json`.

## 0. Arguments & state

| Argument | Effect |
|---|---|
| *(none)* | Normal pass, `post=ask` |
| `state` | Print the state table, stop. No provider call. |
| `post=auto` | Post drafted questions without asking. First line of the report says so. |
| `skip <KEY>` / `unskip <KEY>` | Never pre-read `<KEY>` / clear it. Confirm in one line, stop. |
| `force <KEY>` | Pre-read `<KEY>` this pass even if done or in progress. |
| `chained` | Invoked by `/praxis-watch`: skip step 6, hand the report back. |

No state file → first run, one line. Outside the window (watch.md) → one line, stop.

## 1. Scan

Provider « Search tickets » with `watch.tickets.jql`. Every key returned is **seen** (`lastSeen` = its `updated`); being seen is not being pre-read.

| Case | Action |
|---|---|
| No `prereadAt`, no `skipped` | **candidate** (step 2) |
| `updated` > `lastSeen`, `questionPostedAt` set | **possible answer** → step 4 |
| `updated` > `lastSeen`, no question posted | note the change in the report, no new pre-read |
| In state, absent from a **complete** scan | closed or reassigned → drop, one line. Never on a partial scan. |

Candidates: status category `new` only (others with `force`). Order: priority (highest first), then oldest `created`. Take `budget`.

## 2. Pre-read (« survol ») — per candidate

Everything is stored; nothing is decided.

1. **Ticket** — provider « Fetch a ticket in full »: description, AC, comments, links (design, spec, PR, chat), parent (context only), linked issues (key + status). Attachments listed by name, never claimed as read; when one obviously carries the expectation, a question asks what it shows.
2. **Design** — each Figma link: `mcp__Figma__get_metadata` on the node, `mcp__Figma__get_screenshot`; 2–3 sentences on the screen and every state drawn (empty, error, disabled, tooltip).
3. **Spec** — each Notion link: `mcp__notion__notion-fetch`; the rules relevant to the AC.
4. **Code readiness** (read-only, from `origin/main`). Follow the overlay's **Code readiness** recipe when it has one — it knows the project layout. Otherwise, generically: decide the kind (front / back / content) from prefix, labels and description; `rg` the implied route, DTO or entity; find the closest existing feature; check whether a named feature flag exists (its state on an environment is a question **for the user**); PRs cited → `gh pr view <n> --json state,mergedAt`.
5. **Triage** — size S/M/L with the signals of `praxis-triage`, recommended workflow.
6. **Questions**, grouped by recipient — product, design, back — plus « pour toi » for what only the user can answer (flag state, priority, branch strategy). In the tracking file only: why it blocks, options seen, the default you would take.

Write it: find an existing file first (`ls {tracking_dir}/*/{KEY}-*.md`); none → create `{tracking_dir}/{KEY}-{slug}/{KEY}-{slug}.md` from the ticket template (no `.current` update). Then add:

```markdown
## Survol ({YYYY-MM-DD})

| Sujet | État |
|---|---|
| Contrat API | présent / partiel / absent — {path or —} |
| Back | {ticket/PR and state, or —} |
| Flag | `{name}` — {existe / n'existe pas} — état : {inconnu / …} |
| Figma | {n} nœuds, capturés {HH:mm} — {states seen} |
| Notion | {rules extracted, or —} |
| Code | {module, closest feature} |
| Taille | {S/M/L} → {workflow} |

### Questions à poster (produit / design / back)
- **Produit** — {question} · pourquoi ça bloque · options · défaut envisagé

### Questions pour toi (jamais postées)
- {…}
```

Avancement: `- {date} : Survol — taille {S/M/L}, {n} questions ({produit}/{design}/{back})`.

## 3. Post the questions

Only « Questions à poster » goes to the provider; « Questions pour toi » goes to the report. One comment per ticket:

```
Quelques questions avant de démarrer :
- {question, one line, ends with ?}
Merci !
```

Two to five lines, no context block, no numbered analysis; an obvious default goes in the question (« … sinon je pars sur X ? »).

`post=ask`: one `AskUserQuestion` per ticket with the **full** draft and « Poster » / « Modifier » / « Ne pas poster ». `post=auto`: post directly. Record `questionPostedAt`, `questionCommentId`, `questions`. Not posted → `pending: true`; the next interactive pass asks again.

## 4. Answers

For each ticket with `questionPostedAt` and a newer `updated`: comments newer than `questionPostedAt` by someone else. Per answer: one-line summary and the decision it implies; append to the tracking file (Commentaires, and Décisions as `clarification` per common.md); `PushNotification` « {KEY} : réponse de {rôle} — {one line} »; state `answeredAt`, `lastSeen`. A comment that answers nothing is reported, not recorded as a decision.

## 5. Report

```markdown
## Passe HH:MM — tickets assignés

**Nouveaux survolés** : {KEY} ({S/M/L}, {n} questions — postées / en attente de ton ok)
**Réponses reçues** : {KEY} — {one line}
**Changements** : {KEY} passé en {statut} / nouveau commentaire
**En attente de réponse** : {KEY} depuis {n} j
**Questions pour toi** : {KEY} — {question}
```

Then `lastRunAt`, save the state.

## 6. Next pass

Per watch.md › Next pass with `watch.tickets.interval_sec`. Skipped under `chained`.

## Appendix A — state schema

```json
{
  "lastRunAt": "2026-09-17T14:00:00Z",
  "tickets": {
    "KEY-1": {
      "summary": "…", "status": "…", "lastSeen": "2026-09-17T13:50:00.000+0200",
      "prereadAt": "2026-09-17T14:02:00Z", "size": "M", "questions": ["…"],
      "questionPostedAt": null, "questionCommentId": null, "pending": true,
      "answeredAt": null, "skipped": null
    }
  }
}
```

`lastSeen` mirrors the provider's `updated` and advances only after reporting. `prereadAt: null` = seen, not pre-read. `skipped` ∈ `null` · `user-request`.
