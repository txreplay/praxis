#!/usr/bin/env bash
set -euo pipefail

# Praxis — Install skills into a project's .claude/skills/ directory
#
# Usage:
#   ./install.sh [/path/to/project]              # install skills only
#   ./install.sh --with-hook [/path/to/project]   # install skills + SessionStart hook

PRAXIS_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$PRAXIS_DIR/skills"

WITH_HOOK=false
PROJECT_ROOT=""

for arg in "$@"; do
  case "$arg" in
    --with-hook) WITH_HOOK=true ;;
    --help|-h)
      echo "Usage: install.sh [--with-hook] [/path/to/project]"
      echo ""
      echo "Options:"
      echo "  --with-hook   Also install the SessionStart hook (requires jq)"
      echo "  --help, -h    Show this help"
      exit 0
      ;;
    *) PROJECT_ROOT="$arg" ;;
  esac
done

PROJECT_ROOT="${PROJECT_ROOT:-.}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
TARGET_DIR="$PROJECT_ROOT/.claude/skills"

echo "Praxis — Installing skills"
echo "  From: $SKILLS_DIR"
echo "  Into: $TARGET_DIR"
echo ""

mkdir -p "$TARGET_DIR"

SKILLS=(praxis-new praxis-start praxis-check praxis-sync praxis-post praxis-done praxis-capture praxis-plan praxis-triage praxis-learn praxis-next praxis-bug praxis-list praxis-ship praxis-watch praxis-watch-prs praxis-watch-tickets praxis-review praxis-review-pr praxis-spec praxis-implement praxis-fix praxis-brainstorm praxis-tdd praxis-commit praxis-qa praxis-deploy praxis-report)
INSTALLED=0

for skill in "${SKILLS[@]}"; do
  src="$SKILLS_DIR/$skill"
  dest="$TARGET_DIR/$skill"

  if [ -L "$dest" ]; then
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      echo "  ✓ $skill (already linked)"
      continue
    else
      echo "  ↻ $skill (updating link)"
      rm "$dest"
    fi
  elif [ -e "$dest" ]; then
    echo "  ⚠ $skill — exists but is not a symlink, skipping"
    continue
  fi

  ln -s "$src" "$dest"
  echo "  + $skill"
  INSTALLED=$((INSTALLED + 1))
done

# Agents used by praxis-review / praxis-review-pr
AGENTS_SRC="$PRAXIS_DIR/agents"
AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
mkdir -p "$AGENTS_DIR"
for src in "$AGENTS_SRC"/*.md; do
  name="$(basename "$src")"
  dest="$AGENTS_DIR/$name"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ✓ agent $name (already linked)"
  elif [ -e "$dest" ]; then
    echo "  ⚠ agent $name — exists, skipping"
  else
    ln -s "$src" "$dest"
    echo "  + agent $name"
  fi
done

echo ""
echo "Done. $INSTALLED skill(s) installed, ${#SKILLS[@]} total."

# Check for praxis.json
if [ ! -f "$PROJECT_ROOT/praxis.json" ]; then
  echo ""
  echo "⚠ No praxis.json found at project root."
  echo "  Copy the template: cp $PRAXIS_DIR/praxis.example.json $PROJECT_ROOT/praxis.json"
  echo "  Then edit it with your provider settings."
fi

# Install SessionStart hook
if [ "$WITH_HOOK" = true ]; then
  echo ""

  if ! command -v jq &>/dev/null; then
    echo "⚠ jq is required for the SessionStart hook but was not found."
    echo "  Install it (brew install jq) then re-run with --with-hook."
    exit 1
  fi

  SETTINGS_DIR="$PROJECT_ROOT/.claude"
  SETTINGS_FILE="$SETTINGS_DIR/settings.json"
  mkdir -p "$SETTINGS_DIR"

  if [ -f "$SETTINGS_FILE" ]; then
    echo "⚠ $SETTINGS_FILE already exists."
    echo "  Add the SessionStart hook manually — see hooks/session-start.md"
  else
    cat > "$SETTINGS_FILE" << 'ENDJSON'
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
ENDJSON
    echo "  + SessionStart hook installed in $SETTINGS_FILE"
  fi
fi
