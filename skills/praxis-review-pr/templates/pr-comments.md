# PR Review — formats et exemples

Ce fichier complète `SKILL.md` : il montre à quoi ressemble un bon commentaire, pas seulement sa structure.
Les commentaires sont rédigés **en français**. Code, identifiants et blocs de code restent inchangés.

---

## 1. Squelette de sortie terminal

```markdown
## PR Review: #<N> — <titre>

**<x> Critical | <x> Important | <x> Nice-to-have | <x> Questions**

### Critical
> **`path/to/file.ts` L<line>**
>
> **Bug :** <titre court>
>
> <problème + preuve + conséquence concrète>
>
> **Suggestion :**
> ```ts
> // correctif
> ```

### Important        → **Issue :**
### Nice-to-have     → **Nit :**
### Questions        → **Question :**

### Positive
- <3 à 5 points concrets>
```

---

## 2. Le niveau de preuve attendu

La différence entre un commentaire utile et du bruit, c'est la preuve. Trois exemples.

### ❌ Trop faible — spéculatif

> **Issue :** le fallback pourrait poser problème avec certaines locales.

Aucune preuve, aucun cas concret, l'auteur ne peut rien en faire.

### ⚠️ Moyen — juste mais non étayé

> **Issue :** un `localeText` partiel écrase tout le bundle de locale, l'UI repasse en anglais.

Le constat est correct mais l'auteur doit refaire l'enquête pour te croire.

### ✅ Bon — vérifié dans la version installée

> **Bug :** un `localeText` partiel efface tout le bundle de locale.
>
> `??` est du tout-ou-rien, et MUI ne backfille pas depuis la locale choisie — dans `@mui/x-date-pickers@7.29.4` :
>
> ```js
> // internals/hooks/useUtils.js
> const localeText = React.useMemo(
>   () => _extends({}, enUS.DEFAULT_LOCALE, localization.localeText), [...])
> ```
>
> `DEFAULT_LOCALE` est **enUS**. Reproduit à l'exécution :
> ```
> adapterLocale="fr" + localeText={{ okButtonLabel: 'Valider' }}
> -> cancelButtonLabel: "Cancel"  (attendu "Annuler")
> ```
>
> **Suggestion :**
> ```tsx
> const merged = useMemo(
>   () => ({ ...getPickerLocaleText(adapterLocale), ...localeText }),
>   [adapterLocale, localeText],
> )
> ```

Version installée citée, source lue, comportement reproduit, correctif concret.

---

## 3. Signaler aussi les non-problèmes vérifiés

Quand une piste évidente s'avère saine, dis-le — sinon elle reviendra à la prochaine review.

> **Nit :** ne **pas** ajouter d'optional chaining sur `.components.MuiLocalizationProvider.defaultProps.localeText` — vérifié dans les `.d.ts` des 5 bundles, chaque segment du chemin est non-optionnel. Ce serait du code mort.

Idem pour les faux positifs de perf : « `getX` s'exécute à chaque render mais retourne une référence de module constante, vérifié `get(frFR) === get(frFR)` → pas de re-render en cascade, pas de `useMemo` à ajouter ».

---

## 3 bis. Commentaires superflus dans le code

Un commentaire est soit inutile, soit le signal qu'on peut écrire un meilleur code. La doc d'une feature, c'est son test. On **signale**, on ne supprime jamais (skill read-only).

### ✅ Bon — on dit ce qui remplace le commentaire

> **Nit :** ces trois commentaires paraphrasent le code juste en dessous (`// on filtre les utilisateurs actifs` devant `.filter(u => u.isActive)`). Ils dériveront à la première modif. Le seul qui mérite de rester est L58 (`// l'API renvoie 200 sur un échec métier, cf. KEY-123`) : il acte une contrainte externe invisible dans le code.

> **Issue :** `// vérifie que le slot n'est pas déjà pris avant de créer` devant un bloc de 20 lignes — le commentaire fait le travail d'un nom. Extraire en `assertSlotAvailable(slot)` supprime le besoin de commenter et rend le cas testable isolément.

> **Nit :** `// TODO: gérer le cas multi-tenant` sans ticket ni owner — soit un ticket, soit on l'enlève ; sinon il restera là dans deux ans.

### ❌ À ne pas écrire

> **Nit :** ajouter une JSDoc sur `useUserFilters` pour la cohérence.

Réclamer un commentaire là où le code et les tests sont clairs, c'est du remplissage. L'absence de commentaire n'est jamais un finding.

> **Nit :** L12 commentaire inutile. L19 commentaire inutile. L23 commentaire inutile. L31 commentaire inutile.

Même cause, même fichier → **un seul** commentaire groupé.

---

## 4. Format re-review

```markdown
## Re-review PR #<N> — <titre>

**Depuis ta review du <date> :** <X> commits, <Y> fichiers modifiés

| Commentaire précédent | Fichier | Statut |
|---|---|---|
| Merge de `localeText` au lieu d'écrasement | `AppLocalizationProvider.tsx` L24 | ✅ Résolu |
| Ordre du spread `{...props}` | `AppLocalizationProvider.tsx` L25 | ✅ Résolu |
| `adapterLocale` non normalisé | `AppLocalizationProvider.tsx` L13 | ❌ Non adressé |
| Test manquant | `AppLocalizationProvider.tsx` L16 | ⚠️ Partiel — test ajouté mais ne couvre pas le cas partiel |

### Nouveaux findings
<format standard>
```

Statuts : ✅ Résolu · ⚠️ Partiel · ❌ Non adressé · 💬 Répondu par l'auteur.

Répondre **dans le thread existant** pour les points de suivi :
```bash
gh api "repos/<REPO>/pulls/<N>/comments/<comment_id>/replies" -f body="<texte>"
```

---

## 5. Payload GitHub

```json
{
  "commit_id": "<head_sha>",
  "body": "<résumé + section 'Hors-diff / suivi'>",
  "event": "COMMENT | REQUEST_CHANGES | APPROVE",
  "comments": [
    {"path": "libs/.../file.ts", "line": 24, "side": "RIGHT", "body": "<markdown>"},
    {"path": "libs/.../file.ts", "start_line": 12, "start_side": "RIGHT",
     "line": 14, "side": "RIGHT", "body": "<markdown multi-lignes>"}
  ]
}
```

Contraintes :
- `line` doit exister **dans le diff**, côté droit. Sinon → section « Hors-diff / suivi » du `body`.
- `path` relatif à la racine du repo, exactement tel qu'il apparaît dans le diff.
- Bloc `suggestion` uniquement si le contenu remplace exactement la plage commentée, indentation comprise.

---

## 6. Règles de rédaction

- Un bloc = un commentaire GitHub. Concis : ça se lit sur GitHub, pas dans un terminal.
- Chemin exact + ligne du fichier NEW (côté droit du diff).
- Suggestions : du code, jamais « à corriger ».
- Les questions servent une vraie ambiguïté — pas un nit déguisé en question.
- Section Positive : 3 à 5 points spécifiques à cette PR. Pas de compliment générique.
- Distinguer explicitement ce qui est **bloquant** de ce qui est **préexistant hors scope** — l'auteur n'est pas responsable de la dette qu'il traverse.
