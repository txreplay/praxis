# Praxis — Tracking File Templates

## Epic template

File: `{tracking_dir}/{folder}/{EPIC_KEY}-{slug}.md`

```markdown
# {EPIC_KEY} — {summary}

## Infos

| Champ        | Valeur                                       |
| ------------ | -------------------------------------------- |
| Ticket       | [{EPIC_KEY}]({ticket_url})                   |
| Statut       | {status_display}                             |
| Figma        | {figma_link or —}                            |
| Notion       | {notion_link or —}                           |
| Pull Request | —                                            |
| Branche      | —                                            |
| Dernière MAJ | {YYYY-MM-DD HH:mm}                          |

## Description

{description — original language from provider}

## Commentaires

{**author (date)** : content — for each comment}
{If none: "Aucun commentaire."}

## Tickets

| Ticket | Titre   | Statut           | Reste à faire | Blocage |
| ------ | ------- | ---------------- | ------------- | ------- |
| {KEY}  | {title} | {status_display} | —             | —       |

## Blocages

{Table of identified blockers or "Aucun blocage identifié."}

## Questions ouvertes

{Questions extracted from comments or "Aucune question ouverte."}
```

## Ticket template

File: `{tracking_dir}/{folder}/{TICKET_KEY}-{slug}.md`

```markdown
# {TICKET_KEY} — {summary}

## Infos

| Champ        | Valeur                                         |
| ------------ | ---------------------------------------------- |
| Ticket       | [{TICKET_KEY}]({ticket_url})                   |
| Statut       | {status_display}                               |
| Figma        | {figma_link or —}                              |
| Notion       | {notion_link or —}                             |
| Pull Request | —                                              |
| Dernière MAJ | {YYYY-MM-DD HH:mm}                            |

## Description

{description — original language from provider}

## Commentaires

{**author (date)** : content — for each comment}
{If none: "Aucun commentaire."}

## Progression

| Catégorie | Détails                                          |
| --------- | ------------------------------------------------ |
| À faire   | {deduced from acceptance criteria / description} |
| En cours  | —                                                |
| Terminé   | —                                                |
| Blocages  | —                                                |

## Avancement

- {YYYY-MM-DD} : Création du fichier de suivi
```

## Lessons file template

File: `{tracking_dir}/lessons.md`

```markdown
# Lessons

| Date | Ticket | Category | Lesson | Impact |
|------|--------|----------|--------|--------|
```

Categories: `api`, `testing`, `architecture`, `tooling`, `provider`, `performance`, `ux`, `other`

## Variable reference

| Variable | Source |
|---|---|
| `{tracking_dir}` | `praxis.json#tracking_dir` |
| `{folder}` | `{EPIC_KEY}-{slug}` |
| `{ticket_url}` | Provider URL pattern + `praxis.json#site` + ticket key |
| `{status_display}` | Praxis status → FR display (see common.md) |
| `{figma_link}` | Scanned from description/comments (`figma.com/design/`, `figma.com/file/`) |
| `{notion_link}` | Scanned from description/comments (`notion.so/`) |
