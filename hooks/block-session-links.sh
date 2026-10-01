#!/usr/bin/env bash
# PreToolUse(Bash): refuse any commit / push / PR / issue text that carries a
# Claude session link (`Claude-Session:` trailer or claude.ai/code/session URL).
# Conversations are private: a session link must never reach a commit, a PR or an issue.
set -uo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -z "$cmd" ] && exit 0

grep -qE '(^|[;&|[:space:]])(git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+(commit|push)|gh[[:space:]]+(pr[[:space:]]+(create|edit|comment|review)|issue))' <<<"$cmd" || exit 0

pattern='Claude-Session|claude\.ai/code/session'
block() {
  echo "BLOQUÉ (block-session-links) : $1 contient un lien de session Claude (Claude-Session / claude.ai/code/session). Les conversations sont privées : retire la ligne avant de commit/push/publier." >&2
  exit 2
}

grep -qE "$pattern" <<<"$cmd" && block "la commande"

# Message or body files: git commit -F <f>, --file=<f>, gh --body-file <f>, -F <f>
while read -r f; do
  f="${f/#\~/$HOME}"
  [ -n "$f" ] && [ "${f:0:1}" != "/" ] && [ -n "$cwd" ] && f="$cwd/$f"
  [ -f "$f" ] && grep -qE "$pattern" "$f" && block "le fichier $f"
done < <(grep -oE '(-F|--file|--body-file)[= ]+[^[:space:];&|]+' <<<"$cmd" | sed -E 's/^(-F|--file|--body-file)[= ]+//; s/^["'"'"']//; s/["'"'"']$//')

# git push: the unpushed commits must not carry the trailer either
if grep -qE 'git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push' <<<"$cmd"; then
  dir=$(grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' <<<"$cmd" | head -1 | awk '{print $3}' | tr -d '"'"'"'')
  dir="${dir/#\~/$HOME}"
  [ -z "$dir" ] && dir="$cwd"
  [ -z "$dir" ] && dir="."
  if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$dir" log --format=%B HEAD --not --remotes 2>/dev/null | grep -qE "$pattern" && block "un commit non poussé ($(git -C "$dir" log --format='%h' HEAD --not --remotes | head -3 | tr '\n' ' '))"
  fi
fi

exit 0
