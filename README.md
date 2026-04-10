# Praxis

Local ticket tracking for Claude Code. Bridges your task manager (Jira, Linear, GitHub Issues) with persistent markdown state that survives across sessions.

## Commands

```
# Core workflow
/praxis new HUB-30635     # Initialize tracking for an epic + all child tickets
/praxis start HUB-30636   # Set active ticket, prepare git branch/worktree
/praxis check              # Verify acceptance criteria coverage
/praxis sync               # Sync from provider + analyze code + fetch Figma/Notion
/praxis post               # Post a progress comment on the task manager
/praxis done               # Pre-flight gates, transition status, move to next

# Planning & triage
/praxis plan HUB-40000    # Break down an epic into tickets (when no children exist)
/praxis triage             # Assess complexity (S/M/L), suggest the right workflow
/praxis bug HUB-31982     # Lightweight tracking for a standalone ticket (no epic)

# Knowledge capture
/praxis capture            # Record an implementation decision or spec correction
/praxis learn              # Capture a cross-ticket lesson (or --review to surface relevant ones)

# Navigation
/praxis next               # Auto-detect the next action based on current state
/praxis list               # List all tracked epics and tickets with status
```

## Install

```bash
git clone https://github.com/YOUR_USER/praxis.git ~/praxis

# In your project — skills only:
~/praxis/install.sh /path/to/your/project

# Or with the SessionStart hook (auto-loads ticket context):
~/praxis/install.sh --with-hook /path/to/your/project

# Create your config:
cp ~/praxis/praxis.example.json /path/to/your/project/praxis.json
# Edit praxis.json with your provider settings
```

## Configuration

Create a `praxis.json` at your project root:

```json
{
  "provider": "jira",
  "site": "your-team.atlassian.net",
  "tracking_dir": ".claude/generated/praxis"
}
```

| Field | Description | Default |
|---|---|---|
| `provider` | Task manager adapter (`jira`, `linear`, `github`) | required |
| `site` | Your instance URL (used for ticket links) | required |
| `tracking_dir` | Where to store local tracking files | `.claude/generated/praxis` |

## Providers

Currently supported:
- **Jira** — via [jira CLI](https://github.com/ankitpokhrel/jira-cli)

Planned:
- Linear
- GitHub Issues

Adding a provider = one markdown file in `skills/praxis-new/references/providers/`. See `jira.md` for the format.

## How it works

### Local state

Praxis creates a local folder structure per epic (or standalone ticket):

```
.claude/generated/praxis/
├── .current                          # Active ticket pointer
├── lessons.md                        # Cross-ticket learnings
├── HUB-30635-candidate-profile/
│   ├── HUB-30635-candidate-profile.md  # Epic summary + ticket table
│   ├── HUB-30636-open-profile.md       # Ticket with progression
│   ├── HUB-30637-view-details.md
│   └── HUB-30638-download-docs.md
├── HUB-31982-status-filter/            # Standalone bug (no epic file)
│   └── HUB-31982-status-filter.md
```

Each ticket file tracks:
- Status (synced with provider)
- Acceptance criteria → progression (À faire / En cours / Terminé)
- Advancement log (what was done, when)
- Implementation decisions and spec corrections
- Links (PR, Figma, Notion)
- Fetched resources (Figma screenshots, Notion specs — via MCP when available)

### Pre-flight gates on `/praxis done`

Before transitioning a ticket, Praxis runs 4 verification gates:

| Gate | Check | Fail mode |
|---|---|---|
| Clean working tree | `git status` | BLOCK |
| AC coverage | All criteria in "Terminé" | WARN if partial, BLOCK if none |
| Build verification | typecheck + lint on affected projects | WARN |
| TODOs/FIXMEs | Scan branch diff | WARN |

### Lessons system

`/praxis capture` records decisions **per ticket**. `/praxis learn` promotes patterns to a shared `lessons.md` that persists **across tickets**. When starting new work, relevant lessons are surfaced automatically.

### Session continuity

With `--with-hook`, Praxis installs a SessionStart hook that loads the active ticket's context into every new Claude Code session. No more "where was I?"

## Typical workflows

### Epic with child tickets
```
/praxis new HUB-30635        # Fetch epic + children
          ↓
/praxis triage                # Assess first ticket → S/M/L
          ↓
/praxis start HUB-30636      # Activate, create branch
          ↓
  ... implement ...
          ↓
/praxis capture               # Record a spec deviation
          ↓
/praxis check                 # 4/5 AC covered
          ↓
  ... fix remaining ...
          ↓
/praxis check                 # 5/5 covered
          ↓
/praxis post                  # Post progress comment
          ↓
/praxis done                  # Gates ✅ → transition → next ticket
          ↓
/praxis learn                 # Promote key decisions to lessons
```

### Epic without children
```
/praxis plan HUB-40000        # Analyze → propose breakdown → create tickets
          ↓
/praxis start HUB-40001       # Begin first ticket
```

### Standalone bug
```
/praxis bug HUB-31982         # Track + triage + branch in one step
          ↓
  ... fix ...
          ↓
/praxis done                  # Gates → transition → done
```

### Lost? Just ask
```
/praxis next                  # "You have 3/5 AC covered. Run /praxis check."
```

## License

MIT
