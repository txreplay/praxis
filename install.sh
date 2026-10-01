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
    -*) echo "Unknown option: $arg (see --help)" >&2; exit 2 ;;
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

# Link <src> to <dest>: create, keep when already right, refresh a stale or
# dangling link, never overwrite a real file. Prints one line, returns 0 when
# the link was created or refreshed.
link_into() {
  local src="$1" dest="$2" label="$3"
  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo "  ✓ $label (already linked)"
      return 1
    fi
    echo "  ↻ $label (updating link)"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  ⚠ $label — exists but is not a symlink, skipping"
    return 1
  else
    echo "  + $label"
  fi
  ln -s "$src" "$dest"
}

INSTALLED=0
TOTAL=0
for src in "$SKILLS_DIR"/praxis-*/; do
  [ -f "$src/SKILL.md" ] || continue
  src="${src%/}"
  skill="$(basename "$src")"
  TOTAL=$((TOTAL + 1))
  if link_into "$src" "$TARGET_DIR/$skill" "$skill"; then
    INSTALLED=$((INSTALLED + 1))
  fi
done

# Agents used by praxis-review / praxis-review-pr
AGENTS_SRC="$PRAXIS_DIR/agents"
AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
if [ -d "$AGENTS_SRC" ]; then
  mkdir -p "$AGENTS_DIR"
  for src in "$AGENTS_SRC"/*.md; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    link_into "$src" "$AGENTS_DIR/$name" "agent ${name%.md}" || true
  done
fi

echo "Done. $INSTALLED skill(s) installed or refreshed, $TOTAL total."

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
