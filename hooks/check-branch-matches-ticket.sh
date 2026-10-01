#!/bin/bash
# PreToolUse on Bash — refuse un `git commit` ou `git push` si la branche
# courante ne porte pas le ticket praxis actif
# ({tracking_dir}/.current, tracking_dir lu dans praxis.json).
#
# Motif : un commit parti sur la branche d'un autre ticket, restée active à
# l'insu de tout le monde. Le commit n'annonce sa branche qu'après l'avoir écrite ;
# ce garde-fou rend l'écart visible AVANT l'écriture.
#
# Silencieux (exit 0) dès qu'il ne peut pas se prononcer : pas de jq, pas un
# commit, hors dépôt git, pas de suivi praxis, HEAD détachée.
set -uo pipefail
command -v jq &>/dev/null || exit 0

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# `git commit` / `git push` n'importe où : ils arrivent derrière un `&&`.
# Les deux écrivent — l'un l'historique local, l'autre le distant.
echo "$CMD" | grep -qE '\bgit\s+(commit|push)\b' || exit 0
ACTION=$(echo "$CMD" | grep -oE '\bgit\s+(commit|push)\b' | head -1 | awk '{print $2}')

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CFG="$ROOT/praxis.json"
TRACKING_DIR=".claude/generated/praxis"
[ -f "$CFG" ] && TRACKING_DIR=$(jq -r '.tracking_dir // ".claude/generated/praxis"' "$CFG" 2>/dev/null)
CURRENT_FILE="$ROOT/$TRACKING_DIR/.current"
[ -f "$CURRENT_FILE" ] || exit 0

TICKET=$(jq -r '.ticket // empty' "$CURRENT_FILE" 2>/dev/null)
[ -z "$TICKET" ] && exit 0

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
# HEAD détachée : aucun nom de branche à comparer, on ne se prononce pas.
[ "$BRANCH" = "HEAD" ] && exit 0

# Branches de déploiement partagées : on y pousse le travail d'un ticket depuis
# une branche de feature, donc leur nom ne portera jamais le ticket actif. Les
# bloquer n'attrape aucune erreur et force à fausser .current pour déployer.
# Liste : praxis.json › deploy.branch + deploy.shared_branches, plus `staging`.
if [ -f "$CFG" ]; then
  while read -r shared; do
    [ -n "$shared" ] && [ "$BRANCH" = "$shared" ] && exit 0
  done < <(jq -r '[.deploy.branch // empty] + (.deploy.shared_branches // []) | .[]' "$CFG" 2>/dev/null)
fi
[ "$BRANCH" = "staging" ] && exit 0

NEEDLE=$(echo "$TICKET" | tr '[:upper:]' '[:lower:]')
HAYSTACK=$(echo "$BRANCH" | tr '[:upper:]' '[:lower:]')

case "$HAYSTACK" in
  *"$NEEDLE"*) exit 0 ;;
esac

# Branche d'un lot : plusieurs sous-tâches livrées dans une seule PR, la branche
# porte alors la clé du parent (`.epic` dans .current) et non celle de chaque
# ticket.
EPIC=$(jq -r '.epic // empty' "$CURRENT_FILE" 2>/dev/null)
if [ -n "$EPIC" ]; then
  EPIC_NEEDLE=$(echo "$EPIC" | tr '[:upper:]' '[:lower:]')
  case "$HAYSTACK" in
    *"$EPIC_NEEDLE"*) exit 0 ;;
  esac
fi

cat >&2 <<EOF
BLOCKED: mauvaise branche pour ce « git $ACTION ».
  branche courante : $BRANCH
  ticket praxis actif : $TICKET${EPIC:+ (parent : $EPIC)}
Vérifie avec « git branch --show-current ». Puis, au choix :
  - bascule sur la branche du ticket (ou du parent, pour une PR de lot) ;
  - ou, si la branche est volontaire, mets .current à jour
    ($CURRENT_FILE) avant de committer.
EOF
exit 2
