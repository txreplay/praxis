# Praxis — SessionStart Hook

Automatically loads the active ticket context into every new Claude Code session.

## Install

Either run `install.sh --with-hook` or add manually to `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'CFG=praxis.json; [ -f \"$CFG\" ] || exit 0; TD=$(jq -r \".tracking_dir // \\\".claude/generated/praxis\\\"\" \"$CFG\"); [ -f \"$TD/.current\" ] || exit 0; jq empty \"$TD/.current\" 2>/dev/null || exit 0; F=$(jq -r .folder \"$TD/.current\"); T=$(jq -r .ticket \"$TD/.current\"); [ \"$F\" != null ] && [ \"$T\" != null ] || exit 0; echo \"=== Praxis: Active ticket ===\"; cat \"$TD/$F/$T\"-*.md 2>/dev/null || echo \"Ticket file not found\"'"
          }
        ]
      }
    ]
  }
}
```

Requires `jq`.

## What it does

Reads `praxis.json` → `.current` → ticket file. Outputs the ticket's full context (status, progression, avancement, decisions) so Claude knows where you left off.
