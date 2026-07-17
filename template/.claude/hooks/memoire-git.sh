#!/bin/bash
# ============================================================================
# Hook PostToolUse — garde-fou « versionnage » de la mémoire
# (recommandation Lamis Mukta : chaque écriture en mémoire doit être attribuée
#  — auteur, session, horodatage — avec un historique complet pour inspecter
#  et revenir en arrière.)
#
# Ce script s'exécute APRÈS chaque écriture de fichier réussie.
# Si le fichier écrit est dans memoire/, il crée un commit git automatique :
#   « mémoire: <fichier> (agent, session abc12345) »
# Résultat : `git log -- memoire/` = l'historique complet de la mémoire,
# et `git checkout <commit> -- memoire/` = le retour en arrière (rollback).
# ============================================================================

ENTREE=$(cat)   # le JSON envoyé par Claude Code sur l'entrée standard

# Extraire le chemin du fichier écrit et l'identifiant de session (2 lignes)
INFOS=$(printf '%s' "$ENTREE" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print((d.get("tool_input") or {}).get("file_path") or "")
print((d.get("session_id") or "")[:8])
' 2>/dev/null)

FICHIER=$(printf '%s' "$INFOS" | sed -n 1p)
SESSION=$(printf '%s' "$INFOS" | sed -n 2p)

# On ne s'occupe que des écritures dans le dossier memoire/ du projet
case "$FICHIER" in
  "$CLAUDE_PROJECT_DIR"/memoire/*) ;;   # oui → on continue
  *) exit 0 ;;                          # non → rien à faire
esac

cd "$CLAUDE_PROJECT_DIR" || exit 0
# Pas de dépôt git ? Le versionnage est impossible : on sort sans bloquer.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

git add -A memoire >/dev/null 2>&1
# --no-verify : ne pas déclencher d'éventuels hooks git du projet
# le commit ne porte QUE sur memoire/ pour ne pas embarquer d'autres fichiers
git commit --quiet --no-verify \
  -m "mémoire: ${FICHIER#"$CLAUDE_PROJECT_DIR"/} (agent, session ${SESSION:-inconnue})" \
  -- memoire >/dev/null 2>&1

exit 0
