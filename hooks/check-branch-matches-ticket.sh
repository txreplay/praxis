#!/bin/bash
# PreToolUse on Bash — refuse un `git commit` ou `git push` si la branche
# écrite ne porte pas le ticket praxis actif ({tracking_dir}/.current du
# checkout principal, tracking_dir lu dans praxis.json).
#
# Motif : un commit parti sur la branche d'un autre ticket, restée active à
# l'insu de tout le monde. Le commit n'annonce sa branche qu'après l'avoir écrite ;
# ce garde-fou rend l'écart visible AVANT l'écriture.
#
# Silencieux (exit 0) dès qu'il ne peut pas se prononcer : pas de jq, pas une
# écriture git, hors dépôt git, pas de suivi praxis, HEAD détachée, ou une
# commande qui change elle-même de branche avant d'écrire.
set -uo pipefail
command -v jq &>/dev/null || exit 0

INPUT=$(cat)
CMD=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
[ -z "$CMD" ] && exit 0
CWD=$(jq -r '.cwd // empty' <<<"$INPUT")
[ -z "$CWD" ] && CWD="$PWD"

# `git [options globales] commit|push`, n'importe où dans la commande
# (derrière `&&`, `;`, `(`, `$(`…). Options globales : -C <dir>, -c <k=v>, --xxx[=v].
GIT_OPTS='([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--[a-z-]+(=[^[:space:]]+)?))*'
WRITE_RE="(^|[;&|(\`\$[:space:]])git${GIT_OPTS}[[:space:]]+(commit|push)([[:space:]]|\$)"
grep -qE "$WRITE_RE" <<<"$CMD" || exit 0
MATCH=$(grep -oE "git${GIT_OPTS}[[:space:]]+(commit|push)([[:space:]]|\$)" <<<"$CMD" | head -1)
ACTION=$(grep -oE '(commit|push)([[:space:]]|$)' <<<"$MATCH" | tail -1 | tr -d '[:space:]')

# La commande change de branche elle-même avant d'écrire : impossible de juger.
grep -qE "git${GIT_OPTS}[[:space:]]+(checkout|switch)([[:space:]]|\$)" <<<"$CMD" && exit 0

# Répertoire écrit : cwd de l'appel, puis `cd <dir>` de la commande, puis `git -C <dir>`.
resolve() { # base path → absolute path
  local p="${2/#\~/$HOME}"
  p="${p#[\"\']}"; p="${p%[\"\']}"
  case "$p" in /*) echo "$p" ;; *) echo "$1/$p" ;; esac
}
DIR="$CWD"
CD_TARGET=$(grep -oE "(^|[;&(][[:space:]]*)cd[[:space:]]+[^[:space:];&|]+" <<<"$CMD" | tail -1 | sed -E 's/^.*cd[[:space:]]+//')
[ -n "$CD_TARGET" ] && DIR=$(resolve "$DIR" "$CD_TARGET")
C_TARGET=$(grep -oE -- '-C[[:space:]]+[^[:space:]]+' <<<"$MATCH" | tail -1 | sed -E 's/^-C[[:space:]]+//')
[ -n "$C_TARGET" ] && DIR=$(resolve "$DIR" "$C_TARGET")
git -C "$DIR" rev-parse --git-dir &>/dev/null || exit 0

# .current et praxis.json vivent dans le checkout principal (ignorés par git,
# donc absents des worktrees).
COMMON=$(git -C "$DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
ROOT=$(dirname "$COMMON")
CFG="$ROOT/praxis.json"
TRACKING_DIR=".claude/generated/praxis"
[ -f "$CFG" ] && TRACKING_DIR=$(jq -r '.tracking_dir // ".claude/generated/praxis"' "$CFG" 2>/dev/null)
CURRENT_FILE="$ROOT/$TRACKING_DIR/.current"
[ -f "$CURRENT_FILE" ] || exit 0

TICKET=$(jq -r '.ticket // empty' "$CURRENT_FILE" 2>/dev/null)
[ -z "$TICKET" ] && exit 0

BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

# `git push <remote> <src>[:<dst>]` : la branche écrite est <src>, pas HEAD.
if [ "$ACTION" = "push" ]; then
  REST=$(sed -E "s/.*git${GIT_OPTS}[[:space:]]+push//; s/[;&|].*\$//" <<<"$CMD")
  POS=()
  # shellcheck disable=SC2086
  for a in $REST; do case "$a" in -*) ;; *) POS+=("$a") ;; esac; done
  if [ "${#POS[@]}" -ge 2 ]; then
    SRC="${POS[1]#+}"; SRC="${SRC%%:*}"
    [ -n "$SRC" ] && [ "$SRC" != "HEAD" ] && BRANCH="$SRC"
  fi
fi

# HEAD détachée : aucun nom de branche à comparer, on ne se prononce pas.
[ "$BRANCH" = "HEAD" ] && exit 0

# Branches de déploiement partagées : on y pousse le travail d'un ticket depuis
# une branche de feature, donc leur nom ne portera jamais le ticket actif.
# Liste : praxis.json › deploy.branch + deploy.shared_branches, plus `staging`.
[ "$BRANCH" = "staging" ] && exit 0
if [ -f "$CFG" ]; then
  while read -r shared; do
    [ -n "$shared" ] && [ "$BRANCH" = "$shared" ] && exit 0
  done < <(jq -r '[.deploy.branch // empty] + ((.deploy.shared_branches // []) | if type == "array" then . else [.] end) | .[]' "$CFG" 2>/dev/null)
fi

HAYSTACK=$(tr '[:upper:]' '[:lower:]' <<<"$BRANCH")
# Clé délimitée : KEY-1 ne doit pas valider une branche KEY-12.
key_in_branch() {
  local needle re
  needle=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  re="(^|[^a-z0-9])${needle}([^0-9]|\$)"
  [[ "$HAYSTACK" =~ $re ]]
}
key_in_branch "$TICKET" && exit 0

# Branche d'un lot : plusieurs sous-tâches livrées dans une seule PR, la branche
# porte alors la clé du parent (`.epic` dans .current).
EPIC=$(jq -r '.epic // empty' "$CURRENT_FILE" 2>/dev/null)
[ -n "$EPIC" ] && key_in_branch "$EPIC" && exit 0

cat >&2 <<EOF
BLOCKED: mauvaise branche pour ce « git $ACTION ».
  branche écrite : $BRANCH
  ticket praxis actif : $TICKET${EPIC:+ (parent : $EPIC)}
Vérifie avec « git -C $DIR branch --show-current ». Puis, au choix :
  - bascule sur la branche du ticket (ou du parent, pour une PR de lot) ;
  - ou, si la branche est volontaire, mets .current à jour
    ($CURRENT_FILE) avant de committer.
EOF
exit 2
