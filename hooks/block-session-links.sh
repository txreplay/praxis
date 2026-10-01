#!/usr/bin/env bash
# PreToolUse(Bash): refuse any commit / push / PR / issue / release text that
# carries a Claude session link (a `Claude-Session:` trailer with a URL, or a
# claude.ai/code/session URL). Conversations are private: a session link must
# never reach a commit, a PR, an issue or a release.
#
# Only the shape of a real link is matched, so a command may mention the words
# (a grep for them, a commit describing this hook) without being blocked.
set -uo pipefail
command -v jq &>/dev/null || exit 0

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -z "$cmd" ] && exit 0
[ -z "$cwd" ] && cwd="$PWD"

# Writes that publish text: git [global options] commit|push, and the gh
# commands that send a body, a message or notes.
git_opts='([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--[a-z-]+(=[^[:space:]]+)?))*'
lead='(^|[;&|(`$[:space:]])'
writes="${lead}(git${git_opts}[[:space:]]+(commit|push)([[:space:]]|\$)|gh[[:space:]]+(pr[[:space:]]+(create|edit|comment|review|merge)|issue|release|api)([[:space:]]|\$))"
grep -qE "$writes" <<<"$cmd" || exit 0

pattern='Claude-Session:[[:space:]]*https?://|claude\.ai/code/session[_/][A-Za-z0-9]'
block() {
  echo "BLOQUÉ (block-session-links) : $1 contient un lien de session Claude. Les conversations sont privées : retire la ligne avant de commit/push/publier." >&2
  exit 2
}

grep -qiE "$pattern" <<<"$cmd" && block "la commande"

# Directory the command writes from: cwd, then `cd <dir>`, then `git -C <dir>`.
resolve() {
  local p="${2/#\~/$HOME}"
  p="${p#[\"\']}"; p="${p%[\"\']}"
  case "$p" in /*) echo "$p" ;; *) echo "$1/$p" ;; esac
}
dir="$cwd"
cd_target=$(grep -oE "(^|[;&(][[:space:]]*)cd[[:space:]]+[^[:space:];&|]+" <<<"$cmd" | tail -1 | sed -E 's/^.*cd[[:space:]]+//')
[ -n "$cd_target" ] && dir=$(resolve "$dir" "$cd_target")
c_target=$(grep -oE "git${git_opts}[[:space:]]+(commit|push)" <<<"$cmd" | grep -oE -- '-C[[:space:]]+[^[:space:]]+' | tail -1 | sed -E 's/^-C[[:space:]]+//')
[ -n "$c_target" ] && dir=$(resolve "$dir" "$c_target")

# Message or body files: git commit -F <f>, --file=<f>, gh --body-file <f>, -F <f>
while read -r f; do
  [ -z "$f" ] && continue
  f=$(resolve "$dir" "$f")
  [ -f "$f" ] && grep -qiE "$pattern" "$f" && block "le fichier $f"
done < <(grep -oE '(-F|--file|--body-file|--notes-file)[= ]+[^[:space:];&|]+' <<<"$cmd" | sed -E 's/^(-F|--file|--body-file|--notes-file)[= ]+//')

# git push: no unpushed commit on any local branch may carry a link. The log is
# read into a variable first — piping it into `grep -q` under pipefail lets a
# match through when grep exits before git log has finished writing (SIGPIPE).
if grep -qE "git${git_opts}[[:space:]]+push([[:space:]]|\$)" <<<"$cmd"; then
  if git -C "$dir" rev-parse --git-dir &>/dev/null; then
    msgs=$(git -C "$dir" log --format='%h%n%B' --branches --not --remotes 2>/dev/null)
    if grep -qiE "$pattern" <<<"$msgs"; then
      shas=""
      for h in $(git -C "$dir" rev-list --branches --not --remotes 2>/dev/null); do
        body=$(git -C "$dir" show -s --format=%B "$h")
        grep -qiE "$pattern" <<<"$body" && shas="$shas ${h:0:9}"
      done
      block "un commit non poussé (${shas# })"
    fi
  fi
fi

exit 0
