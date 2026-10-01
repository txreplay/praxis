---
name: praxis-report
description: Génère le rapport d'activité de la semaine (feuille de temps) à partir des commits, PRs, tickets et du suivi praxis, réparti par jour sur la liste d'activités du projet. Utiliser quand l'utilisateur invoque /praxis-report, demande de remplir sa feuille de temps, ou demande « sur quoi j'ai travaillé cette semaine » en vue du reporting. Paramètre optionnel — « semaine dernière » ; défaut = semaine courante.
argument-hint: "[semaine dernière]"
---

# /praxis-report — rapport d'activité hebdomadaire

Reconstituer la semaine depuis git, GitHub, les tickets et praxis, la mapper sur les activités imposées, et produire un récap par jour.

## Config

`praxis.json › report`:

```json
"report": {
  "activities": ".claude/generated/praxis/report/activities.md",
  "unit": 0.25,
  "fill": "overlay"
}
```

- `activities` — la liste officielle des activités et les règles de mapping (fichier local). Absent → demander la liste avant d'analyser.
- `unit` — granularité en jours (défaut `0.25`).
- La section `## praxis-report` de l'overlay porte l'outil de saisie (URL, pièges d'interface) et les règles propres à l'entreprise.

## 1. Semaine cible

`semaine dernière` → lundi–vendredi précédents ; sinon lundi → aujourd'hui. Calculer avec `date`, jamais deviner :

```bash
# lundi courant (BSD, puis GNU)
date -v-mon +%Y-%m-%d 2>/dev/null || date -d "monday this week" +%Y-%m-%d
# semaine précédente : lundi et vendredi
date -v-mon -v-7d +%Y-%m-%d 2>/dev/null || date -d "monday last week" +%Y-%m-%d
date -v-mon -v-3d +%Y-%m-%d 2>/dev/null || date -d "friday last week" +%Y-%m-%d
```

## 2. Exceptions AVANT d'analyser

Chaque jour ouvré totalise **exactement 1j**. Demander d'abord : jours off ou partiels (congés, férié, formation, trajet, séminaire), événements hors code notables (management, atelier). Les jours off sortent du récap ; le hors-code va dans l'activité « autre » de la liste.

## 3. Collecter (en parallèle)

```bash
git log --all --no-merges --author="$(git config user.name)" \
  --since="<lundi> 00:00" --until="<fin> 23:59" \
  --date=format:'%a %Y-%m-%d' --pretty='%ad | %h | %s'
gh pr list --author @me --state all --search "updated:>=<lundi>" --json number,title,createdAt,mergedAt,headRefName
```

- **Les reviews ne comptent pas** — en grande partie automatisées ; seuls les commits et le cadrage sans commit comptent.
- **Tickets** : extraire `ticket_pattern` des commits et branches, résoudre titre et description via le provider — c'est le contexte fonctionnel qui permet le bon mapping.
- **Praxis** : `{tracking_dir}` pour les tickets en cours (cadrage, analyse = du travail même sans commit).

## 4. Mapper sur les activités

Lire `report.activities`. Règles :
- Mapper par le **domaine fonctionnel du ticket**, pas par le nom technique du commit.
- Un correctif sur une fonctionnalité d'un projet listé → l'activité de ce projet ; la maintenance générique → l'activité de maintenance de la liste.
- Cadrage et analyse d'un ticket → même activité que le ticket.
- **Ne jamais inventer d'activité.** Un travail sans activité correspondante est signalé comme « activité manquante » avec le libellé proposé ; une activité générique seulement en provisoire.

## 5. Répartir par jour

- Ancrer chaque activité sur les **jours réels** des commits.
- Granularité `unit` minimum ; chaque jour non off = 1j.
- **Regrouper, ne pas émietter** : 1 à 2 activités par jour, idéalement une journée entière sur une seule. Le total hebdo par activité prime sur l'exactitude du créneau. Arrondir au 0,5j quand ça supprime des miettes.
- Jours sans signal git : s'appuyer sur praxis et les tickets, sinon une hypothèse signalée à valider.

## 6. Récap

Format exact (virgule décimale, libellés verbatim de la liste) :

```
- Lundi :
    - 0,5j : <activité>
    - 0,5j : <activité>
- Mardi :
    - 1j : <activité>
```

Puis une courte justification par activité (tickets/PRs qui y mènent). Attendre la validation et ajuster.

## 7. Saisie

Une fois le récap validé, **proposer** de remplir l'outil de saisie décrit dans l'overlay via Claude in Chrome (outils chargés seulement si accepté). Si la liste d'activités visible dans l'outil diffère de `report.activities`, mettre ce fichier à jour. **Ne jamais soumettre pour approbation** : l'utilisateur envoie lui-même.
