#!/bin/bash
# ============================================================================
# install.sh — installe le kit mémoire dans un projet
#
# Usage :
#   ./install.sh /chemin/vers/votre/projet
#   ./install.sh .          # installer dans le dossier courant
#
# Ce que fait le script, dans l'ordre :
#   1. copie memoire/, .claude/ (hooks, skills, settings) et scripts/ ;
#   2. ne casse RIEN d'existant : CLAUDE.md existant → on ajoute une section ;
#      settings.json existant → le nôtre est posé à côté avec un mode d'emploi ;
#   3. rend les scripts exécutables ;
#   4. crée un dépôt git s'il n'y en a pas (indispensable au versionnage de la
#      mémoire) et fait un premier commit.
# ============================================================================
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"          # dossier du kit (là où vit ce script)
CIBLE="${1:-}"

if [ -z "$CIBLE" ]; then
  echo "Usage : ./install.sh /chemin/vers/votre/projet" >&2
  exit 1
fi
CIBLE="$(cd "$CIBLE" 2>/dev/null && pwd)" || { echo "❌ Dossier introuvable : $1" >&2; exit 1; }

if [ "$CIBLE" = "$KIT" ]; then
  echo "❌ Installez le kit dans un AUTRE dossier que le kit lui-même." >&2
  exit 1
fi

echo "📦 Installation du kit mémoire dans : $CIBLE"

# --- 1. Le dossier memoire/ (sans écraser une mémoire existante) ------------
if [ -d "$CIBLE/memoire" ]; then
  echo "   memoire/ existe déjà → conservé tel quel (aucune modification)."
else
  cp -R "$KIT/template/memoire" "$CIBLE/memoire"
  echo "   memoire/ créé (index, organisation, leçons, journal, scratchpad, propositions)."
fi

# --- 2. CLAUDE.md (ajout, jamais écrasement) --------------------------------
if [ -f "$CIBLE/CLAUDE.md" ]; then
  if grep -q "kit « Dreaming »" "$CIBLE/CLAUDE.md"; then
    echo "   CLAUDE.md contient déjà les règles du kit → inchangé."
  else
    { echo; echo; cat "$KIT/template/CLAUDE.md"; } >> "$CIBLE/CLAUDE.md"
    echo "   CLAUDE.md existant → règles du kit AJOUTÉES à la fin (rien d'écrasé)."
  fi
else
  cp "$KIT/template/CLAUDE.md" "$CIBLE/CLAUDE.md"
  echo "   CLAUDE.md créé."
fi

# --- 3. .claude/ : hooks, skills, settings ----------------------------------
mkdir -p "$CIBLE/.claude"
cp -R "$KIT/template/.claude/hooks" "$CIBLE/.claude/"
mkdir -p "$CIBLE/.claude/skills"
cp -R "$KIT/template/.claude/skills/." "$CIBLE/.claude/skills/"
chmod +x "$CIBLE/.claude/hooks/"*.sh
echo "   Hooks et skills installés (.claude/hooks, .claude/skills)."

if [ -f "$CIBLE/.claude/settings.json" ]; then
  cp "$KIT/template/.claude/settings.json" "$CIBLE/.claude/settings.kit-memoire.json"
  echo "   ⚠️ .claude/settings.json existe déjà : le nôtre est posé à côté sous"
  echo "      le nom settings.kit-memoire.json. Fusionnez les blocs \"hooks\" et"
  echo "      \"permissions\" à la main (ou demandez à Claude de le faire)."
else
  cp "$KIT/template/.claude/settings.json" "$CIBLE/.claude/settings.json"
  echo "   .claude/settings.json créé (permissions + hooks)."
fi

# --- 4. Scripts et .gitignore ------------------------------------------------
mkdir -p "$CIBLE/scripts"
cp "$KIT/template/scripts/dream.sh" "$KIT/template/scripts/rapport-tokens.sh" "$CIBLE/scripts/"
chmod +x "$CIBLE/scripts/dream.sh" "$CIBLE/scripts/rapport-tokens.sh"
echo "   scripts/dream.sh et scripts/rapport-tokens.sh installés."

if [ -f "$CIBLE/.gitignore" ]; then
  if ! grep -q "memoire/scratchpad" "$CIBLE/.gitignore"; then
    { echo; cat "$KIT/template/.gitignore"; } >> "$CIBLE/.gitignore"
    echo "   Règles ajoutées au .gitignore existant."
  fi
else
  cp "$KIT/template/.gitignore" "$CIBLE/.gitignore"
  echo "   .gitignore créé."
fi

# --- 5. git : indispensable au versionnage de la mémoire --------------------
cd "$CIBLE"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "   Dépôt git déjà présent → parfait, le versionnage de la mémoire est actif."
else
  git init -q
  echo "   Dépôt git créé (git init) — nécessaire pour l'historique de la mémoire."
fi
git add CLAUDE.md .claude memoire scripts .gitignore 2>/dev/null || true
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -q -m "Installation du kit mémoire (claude-memory-kit)" --no-verify
  echo "   Premier commit effectué."
fi

echo
echo "✅ Terminé ! Prochaines étapes :"
echo "   1. Ouvrez memoire/organisation/conventions.md et adaptez les règles à votre projet."
echo "   2. Lancez \`claude\` dans $CIBLE : l'index mémoire se charge tout seul."
echo "   3. Une fois par semaine : ./scripts/dream.sh"
