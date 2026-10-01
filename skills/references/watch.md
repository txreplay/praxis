# Praxis — Watch Conventions

Shared by `praxis-watch`, `praxis-watch-prs` and `praxis-watch-tickets`. Read [common.md](common.md) first.

## Configuration

Everything project-specific lives in the project's `praxis.json` (gitignored by the project, never committed to praxis) under `watch`, and in the optional **overlay** file it points to. A skill never hardcodes a channel, a repo, a person, a path or an incident.

```json
{
  "overlay": ".claude/generated/praxis/project.md",
  "watch": {
    "timezone": "Europe/Paris",
    "window": { "days": "1-5", "start": "08:30", "end": "18:30" },
    "state_dir": "~/.claude/state/praxis-watch",
    "prs": {
      "source": "slack",
      "channel": "C0XXXXXXXXX",
      "channel_name": "team-pr-review",
      "repo": "acme/app",
      "frontend_markers": ["front", "frontend"],
      "scope_all_globs": ["apps/front/**", "libs/front/**", "*.tsx"],
      "scope_contract_globs": ["apps/api/bff/**"],
      "budget": 5,
      "interval_sec": 900
    },
    "tickets": {
      "jql": "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC",
      "budget": 2,
      "interval_sec": 1800
    }
  }
}
```

| Key | Meaning | Default |
|---|---|---|
| `overlay` | Markdown file with project-specific prose (people, past incidents, code-readiness recipes, machine limits). Must be gitignored by the project. | none |
| `watch.timezone` | Timezone of the window | system |
| `watch.window` | Days (`date +%u` range) and hours of activity | `1-5`, `08:30`–`18:30` |
| `watch.state_dir` | Root of the state files, **outside any repo** | `~/.claude/state/praxis-watch` |
| `watch.prs.source` | Chat adapter, `references/sources/{source}.md` | `slack` |
| `watch.prs.channel` / `channel_name` | Review-request channel id / display name | required |
| `watch.prs.repo` | `owner/name` — the only repo in scope, every other link is dropped | required |
| `watch.prs.frontend_markers` | Words in the request message that settle "this PR is for us" without reading the diff | `[]` |
| `watch.prs.scope_all_globs` | Changed files that make the PR reviewable in full | required |
| `watch.prs.scope_contract_globs` | Changed files reviewed as a contract only (DTOs, generated types) | `[]` |
| `watch.prs.budget` | Review subagents per pass | `5` |
| `watch.tickets.jql` | Provider query for the user's assigned, not-done tickets | required |
| `watch.tickets.budget` | Pre-reads per pass | `2` |
| `*.interval_sec` | Delay between passes under a self-paced `/loop` | `900` / `1800` |

Missing `watch` section → stop with « Section `watch` absente de praxis.json — voir praxis.example.json. »

## The overlay

If `overlay` is set and the file exists, **read it once at the start of the pass**. Its sections are named after the skill that consumes them (`## praxis-watch-prs`, `## praxis-watch-tickets`, `## praxis-ship`). They carry what a generic skill cannot know: who is who on the team, past incidents that justify a rule, the project's code layout, machine limits. Overlay guidance **adds** to the skill; it never relaxes a human gate.

## Window

Inside `watch.window` (in `watch.timezone`) a pass works. Outside it does no work at all — no chat call, no `gh`, no provider call, no dispatch — and prints one line: « Hors fenêtre ({days} {start}–{end}), rien fait. »

## Next pass (self-paced `/loop`)

| Launched as | What to do at the end of the pass |
|---|---|
| `/loop /<skill>` (self-paced) | `ScheduleWakeup`, per the table below |
| `/loop <interval> /<skill>` (fixed cron) | nothing — the cron fires again |
| by hand | nothing |
| with `chained` (from `praxis-watch`) | nothing — the caller schedules |

| Now | `ScheduleWakeup` |
|---|---|
| inside the window | `delaySeconds: {interval_sec}`, `noop: true` when the pass changed nothing |
| after the window end, or a day outside `days` | `stop: true`, and one line « Fin de la veille pour aujourd'hui. » |
| before the window start | delay until the start, capped at 3600, `noop: true` |

**One session per day.** A loop session grows with every pass. Start a fresh session each morning; the state files carry everything, nothing lives in the conversation.

## State files

Under `{state_dir}` — `prs/state.json`, `prs/reviews/`, `tickets/state.json`. Never inside a repo. Write with a temp copy and `jq`, never by hand-editing in place. A state file is a cache: when it disagrees with the provider or GitHub, the remote wins and the state is corrected.

## Presence gate

Spawning agents while the user is away produces drafts that go stale before anyone arbitrates them. The signal is the latency of the last `AskUserQuestion`, persisted in `prs/state.json`:

```json
"presence": { "lastAskedAt": "<ISO>", "lastAnsweredAt": "<ISO>", "lastLatencySec": 132 }
```

Write `lastAskedAt` immediately before every `AskUserQuestion`, `lastAnsweredAt` + `lastLatencySec` the moment the answer comes back. `lastLatencySec` > 1800 → **away**: dispatch nothing, report the queue in full and say `dispatch suspendu (dernière réponse il y a Nmin)`. A direct message from the user saying they are present resets it (`lastLatencySec` small, `lastAnsweredAt` now).

Why the latency of the *previous* answer: `AskUserQuestion` blocks the pass until answered, so a running pass can never observe a question hanging. Accept one review of overshoot per absence — the first review of an absence goes out, and its unanswered question is what the next pass sees.

## Notifications

One `PushNotification` per pass at most, only when something awaits the user, under 200 characters, most urgent first. Load `PushNotification` and `ScheduleWakeup` with one `ToolSearch` call at the start of the pass.

The terminal also notifies on every turn end; that cannot be suppressed per skill. Do not shrink or empty the report to avoid it — an empty answer is re-prompted and costs a round-trip. Make the report useful instead; if the noise is too much, lengthen the interval.

## Report header

Every report starts with the time from the shell (`date '+%H:%M'`), never guessed. A pass where nothing happened is one line plus the standing situation, one item per line.
