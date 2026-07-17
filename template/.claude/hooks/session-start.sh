#!/bin/bash
# ============================================================================
# Hook SessionStart — « chargement progressif » de la mémoire
# (recommandation Lamis Mukta : injecter un INDEX léger, jamais tout le stock)
#
# Ce que fait ce script : tout ce qu'il affiche (echo) est ajouté au contexte
# de l'agent au démarrage de la session. On n'injecte donc que :
#   1. l'index de la mémoire (une ligne par souvenir),
#   2. les 10 dernières erreurs journalisées (pour ne pas les répéter),
#   3. une alerte s'il y a des propositions de dreaming en attente.
# ============================================================================

MEM="$CLAUDE_PROJECT_DIR/memoire"

# 1. L'index (le catalogue de la bibliothèque, pas les livres)
if [ -f "$MEM/MEMOIRE.md" ]; then
  echo "## Mémoire du projet (index — ouvre les fichiers seulement si pertinent)"
  # grep -v retire les lignes de commentaires HTML pour économiser des tokens
  grep -v '^<!--' "$MEM/MEMOIRE.md" | grep -v '^     '
  echo
fi

# 2. Les erreurs récentes non traitées (celles marquées [traité] sont exclues)
if [ -f "$MEM/erreurs/journal.md" ]; then
  RECENTES=$(grep '^- ' "$MEM/erreurs/journal.md" | grep -v '\[traité\]' | tail -n 10)
  if [ -n "$RECENTES" ]; then
    echo "## Erreurs récentes journalisées (à ne pas répéter — voir memoire/erreurs/journal.md)"
    echo "$RECENTES"
    echo
  fi
fi

# 3. Propositions de dreaming en attente de validation humaine ?
if ls "$MEM/propositions/"*dreaming*.md >/dev/null 2>&1; then
  if ls "$MEM/propositions/"*dreaming*.md 2>/dev/null | grep -qv -- '-traite\.md$'; then
    echo "⚠️ Des propositions de Dreaming attendent une validation humaine dans memoire/propositions/. Signale-le à l'utilisateur."
  fi
fi

exit 0
