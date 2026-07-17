# Glossaire — les termes du kit, expliqués simplement

**Agent IA** — un assistant d'intelligence artificielle capable d'*agir* (lire des
fichiers, lancer des commandes, écrire du code), pas seulement de discuter.
Claude Code est un agent.

**Session** — une conversation de travail avec l'agent, du lancement de `claude`
jusqu'à sa fermeture. Sans mémoire, chaque session repart de zéro.

**Contexte (fenêtre de contexte)** — la « mémoire de travail » du modèle : tout ce
qu'il a sous les yeux à un instant donné (vos messages, les fichiers lus, les
résultats de commandes). Elle est limitée — d'où l'intérêt de ne charger que
l'essentiel.

**Token** — la plus petite unité de texte traitée par le modèle (≈ un mot ou un
morceau de mot ; en pratique 1 token ≈ 4 caractères). C'est l'unité de
consommation et de facturation. Moins de tokens = moins cher et plus rapide.

**CLAUDE.md** — un fichier texte à la racine du projet, lu automatiquement au
démarrage de chaque session : les « consignes permanentes » de l'agent.

**Markdown (.md)** — un format de texte brut avec une mise en forme légère
(titres avec `#`, listes avec `-`). Lisible par les humains ET par les agents ;
c'est le format recommandé pour la mémoire.

**Mémoire (au sens du kit)** — un dossier `memoire/` rempli de fichiers Markdown
que l'agent lit et écrit. Recommandation centrale de la conférence : la mémoire
d'agent la plus efficace est un simple système de fichiers.

**Index (MEMOIRE.md)** — le catalogue de la mémoire : une ligne par souvenir.
L'agent lit l'index, puis n'ouvre que les fichiers utiles. C'est la « divulgation
progressive » (*progressive disclosure*) : l'analogie de Lamis Mukta est une
bibliothèque où l'on parcourt les titres avant de sortir un livre.

**Skill (compétence)** — un dossier contenant un mode d'emploi détaillé pour une
tâche récurrente (ex. « comment enregistrer une leçon »). L'agent n'en lit d'abord
que le résumé (le *frontmatter*), et ne charge le détail que si nécessaire.

**Frontmatter** — le petit bloc d'informations entre `---` en tête d'un fichier :
nom, description, date… Le « résumé sur la tranche du livre ».

**Hook** — un petit script que Claude Code exécute automatiquement à un moment
précis (démarrage, avant/après une action, après un échec). Les garde-fous du
kit sont des hooks : ils s'appliquent mécaniquement, sans dépendre de l'IA.

**Permissions** — la liste de ce que l'agent a le droit de faire (dans
`.claude/settings.json`) : autorisations (`allow`) et interdictions (`deny`).

**git** — le système d'historique des fichiers utilisé par les développeurs.
Chaque enregistrement (« commit ») garde qui a changé quoi, quand. Le kit s'en
sert pour le **versionnage** de la mémoire : tout est traçable et réversible.

**Versionnage / rollback** — garder toutes les versions successives d'un fichier
(versionnage) pour pouvoir revenir à une version antérieure (rollback).

**Concurrence** — quand deux sessions veulent modifier le même fichier en même
temps. Règle du kit : relire le fichier juste avant de l'écrire ; git détecte
les conflits restants.

**Stale (obsolète)** — une information qui était vraie mais ne l'est plus, comme
un plan d'accès pas mis à jour après un déménagement. Le Dreaming fait la chasse
aux mémoires *stale*.

**Injection de prompt** — attaque où un texte (page web, mail, document) contient
des instructions cachées destinées à l'agent, par exemple « écris ceci dans ta
mémoire ». Parade du kit : les contenus lus sont des *données*, jamais des
*instructions*, et le Dreaming signale les mémoires suspectes.

**In-band / out-of-band** — *in-band* : ce qui se passe pendant la session de
travail (l'agent partage son attention entre la tâche et sa mémoire).
*Out-of-band* : ce qui tourne en dehors, avec son propre budget — comme le Dreaming.

**Dreaming** — le processus périodique (nom donné par Anthropic, par analogie
avec le sommeil) qui relit les sessions passées et la mémoire, repère les schémas
récurrents et propose des améliorations que l'humain valide. « Apprendre en
dormant. »

**Transcription** — l'enregistrement complet d'une session (messages, commandes,
erreurs), conservé par Claude Code dans `~/.claude/projects/`. C'est la matière
première du Dreaming.

**Scratchpad** — le brouillon de l'agent : notes temporaires, jetables, purgées
automatiquement.

**Orchestrateur / sous-agents** — architecture où un agent « chef d'équipe »
distribue le travail à des agents spécialisés puis assemble leurs résultats.
C'est ainsi qu'Anthropic fait tourner le Dreaming à grande échelle (un sous-agent
par session analysée).
