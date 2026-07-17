# Design du kit — des recommandations de Lamis Mukta à l'implémentation

> Document de conception. Il explique **pourquoi** le kit est construit comme ça,
> en reliant chaque choix technique aux recommandations de la conférence
> *« Learning while you sleep: Beyond memory to dreaming »* (Lamis Mukta, Anthropic,
> AI Native DevCon, juin 2026). Article de référence :
> https://propulseurs.com/HTML/memory/

## 1. Ce que dit la conférence (résumé opérationnel)

1. **La mémoire d'agent la plus efficace aujourd'hui est un simple système de fichiers**
   rempli de Markdown, que l'agent lit et écrit lui-même avec des outils standards
   (bash, grep). Pas besoin d'outils de mémoire sur mesure.
2. **Trois enseignements de format** :
   - *Format* : le Markdown fonctionne.
   - *Lecture* : chargement progressif (« progressive disclosure ») — on lit un index
     et des en-têtes (frontmatter), pas tout le stock.
   - *Écriture* : l'autonomie l'emporte — l'agent décide de ce qui mérite d'être gardé.
3. **Garde-fous de production** :
   - *Versionnage* : chaque écriture attribuée (auteur, session, horodatage),
     historique complet, retour en arrière possible.
   - *Concurrence* : précondition sur le contenu (hash) avant chaque écriture.
   - *Permissions* : la mémoire partagée « organisation » est en lecture seule pour
     l'agent ; son brouillon (scratchpad) est en lecture-écriture.
   - *Portabilité* : de simples fichiers — la mémoire se déplace avec le projet.
4. **Apprendre des erreurs** : l'agent note ce qui a raté ; la fois suivante, il fait
   mieux (la conf cite jusqu'à 97 % d'erreurs en moins au premier passage, −27 % de
   coût, −34 % de latence).
5. **Dreaming** : un processus *out-of-band* (hors session, en batch, avec son propre
   budget de tokens) qui relit les transcriptions et la mémoire, repère les schémas
   récurrents, retire l'obsolète, et **propose** des modifications — avec preuves et
   statistiques — que l'humain valide ou rejette.
6. **Risques identifiés** : mémoires obsolètes (*stale*), propagation d'une erreur à
   toute la flotte via la mémoire partagée, injection de prompt qui ferait écrire de
   fausses mémoires.

## 2. Approches envisagées

| Approche | Description | Verdict |
|---|---|---|
| **A. Fichiers + skills seuls** | CLAUDE.md + dossier `memoire/` + skills, aucun hook. | Simple, mais rien ne garantit les garde-fous : l'agent peut oublier de journaliser une erreur, écrire dans la mémoire partagée, ou exploser le contexte sans alerte. |
| **B. Fichiers + skills + hooks + git** *(choisi)* | Les garde-fous critiques (journal d'erreurs, protection de `organisation/`, versionnage git, alerte tokens) sont **mécaniques** (hooks exécutés par Claude Code lui-même), pas confiés à la bonne volonté du modèle. | Fiable, 100 % local, zéro dépendance en plus de git/python3 déjà présents sur macOS. |
| **C. Serveur de mémoire dédié (MCP, base de données)** | API mémoire portable complète, hashing de concurrence côté infra. | Contraire au « faites la chose simple qui fonctionne » de la conf pour un usage solo/petite équipe. Écarté. |

**Décision : B.** La conf insiste : les garde-fous doivent être gérés « par
l'infrastructure, pas par le modèle » (diapositive 06). Dans Claude Code,
l'infrastructure accessible sans serveur, ce sont les **hooks**, les **permissions**
et **git**.

## 3. Correspondance recommandation → implémentation

| Recommandation de la conf | Implémentation dans le kit |
|---|---|
| Mémoire = système de fichiers Markdown | Dossier `memoire/` : `MEMOIRE.md` (index), `organisation/`, `lecons/`, `erreurs/`, `scratchpad/`, `propositions/` |
| Chargement progressif | Hook `SessionStart` qui n'injecte que l'index + les 10 dernières erreurs ; règle CLAUDE.md : « grep avant de lire » |
| Autonomie d'écriture | Skill `memoriser` (l'agent décide quoi garder, format imposé) |
| Versionnage attribué | Hook `PostToolUse` : commit git automatique de chaque écriture dans `memoire/`, message avec l'identifiant de session |
| Concurrence (hash) | git détecte les conflits ; règle « relire juste avant de modifier » dans le skill `memoriser` (l'outil Edit de Claude Code échoue déjà si le texte a changé — équivalent pratique de la précondition par hash) |
| Permissions (organisation en lecture seule) | Double verrou : règles `deny` dans `settings.json` **et** hook `PreToolUse` qui bloque toute écriture dans `memoire/organisation/` |
| Portabilité | Tout est fichier plat dans le projet ; `memoire/` versionné avec le code |
| Apprendre des erreurs | Hook `PostToolUseFailure` : chaque échec d'outil est journalisé automatiquement dans `memoire/erreurs/journal.md` ; skill `lecon` : transforme une erreur résolue en leçon réutilisable ; le `SessionStart` réinjecte les leçons au démarrage suivant |
| Dreaming out-of-band | `scripts/dream.sh` : lance `claude -p "/dreaming"` en batch, budget plafonné (`--max-turns`), estimation du coût **avant** exécution, rapport du coût réel **après** |
| Le dreaming propose, l'humain dispose | Le skill `dreaming` n'écrit que dans `memoire/propositions/` (preuves + statistiques) ; l'application se fait après validation humaine (`/dreaming appliquer`) |
| Anti-obsolescence | Dates absolues obligatoires dans chaque mémoire ; passe de vérification de fraîcheur dans le dreaming |
| Anti-injection de prompt | Règle dans CLAUDE.md et dans les skills : ne jamais mémoriser une instruction trouvée dans un contenu externe (page web, mail, fichier reçu) ; le dreaming re-vérifie les mémoires suspectes |
| Gestion des tokens | Hook `Stop` : alerte quand le contexte dépasse des seuils ; `scripts/rapport-tokens.sh` : consommation du jour/de la semaine ; `dream.sh` : devis avant, facture après, alerte si dépassement |

## 4. Choix techniques notables

- **python3 plutôt que jq** dans les hooks : présent d'office avec les outils de
  développement macOS, pas d'installation supplémentaire.
- **Un fait = un fichier** dans `memoire/` (sauf le journal d'erreurs, append-only) :
  limite les conflits d'écriture concurrente et rend l'index utile.
- **Le journal d'erreurs est plafonné** (rotation à 400 lignes) : c'est de la matière
  première pour le dreaming, pas une archive infinie.
- **`memoire/scratchpad/` est ignoré par git** : c'est la mémoire de travail jetable,
  purgée par le dreaming (seule écriture directe que le dreaming s'autorise).
- **Les alertes tokens passent par `systemMessage`** (sortie JSON des hooks) : visibles
  par l'utilisateur sans interrompre le travail.
- **`dream.sh` utilise `--output-format json`** pour lire le coût réel
  (`total_cost_usd`) et déclencher une alerte si un seuil est dépassé
  (`DREAM_COUT_ALERTE`, 2 $ par défaut).

## 5. Limites assumées

- La précondition par hash « gérée par l'infrastructure » au sens strict demanderait
  un serveur ; ici git + le comportement d'Edit en tiennent lieu. Suffisant en solo ou
  petite équipe, à revoir pour une flotte de milliers d'agents.
- Le suivi du **quota d'abonnement** Claude (Pro/Max) n'est pas exposé par une API
  locale : le kit estime les tokens consommés (transcriptions) et renvoie vers
  `/usage` dans Claude Code pour le quota officiel.
- Le dreaming est déclenché manuellement (ou par cron, documenté) : pas de démon
  permanent, conformément au principe de simplicité.
