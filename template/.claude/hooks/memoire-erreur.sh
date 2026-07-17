#!/bin/bash
# ============================================================================
# Hook PostToolUseFailure — la matière première de l'apprentissage
# (recommandation Lamis Mukta : les agents doivent apprendre de leurs erreurs ;
#  le dreaming analyse ensuite ces échecs pour repérer les schémas récurrents.)
#
# Ce script s'exécute automatiquement à CHAQUE échec d'un outil (commande bash
# qui plante, édition impossible, etc.). Il ajoute une ligne datée dans
# memoire/erreurs/journal.md :
#   - 2026-07-17 14:02 · Bash · « npm run dev » → EADDRINUSE… · session ab12cd34
# Le journal est plafonné à 400 lignes (rotation) : c'est un tampon d'analyse,
# pas une archive infinie.
# ============================================================================

JOURNAL="$CLAUDE_PROJECT_DIR/memoire/erreurs/journal.md"
[ -d "$(dirname "$JOURNAL")" ] || exit 0   # kit non installé ici : ne rien faire

# Le JSON de Claude Code arrive sur stdin ; on le range dans une variable
# d'environnement car le heredoc ci-dessous occupe déjà le stdin de python.
KITMEM_HOOK_INPUT=$(cat)
export KITMEM_HOOK_INPUT

python3 - "$JOURNAL" <<'PYTHON'
import datetime, json, os, re, sys

journal = sys.argv[1]
d = json.loads(os.environ.get("KITMEM_HOOK_INPUT") or "{}")

outil = d.get("tool_name", "?")
entree = d.get("tool_input") or {}
reponse = d.get("tool_response") or {}
session = (d.get("session_id") or "")[:8]

# Un résumé court de ce qui était tenté (compact : le journal doit rester léger)
if outil == "Bash":
    tentative = (entree.get("command") or "")[:80]
else:
    tentative = (entree.get("file_path") or "")[:80]

# Le message d'erreur, aplati et tronqué
message = str(reponse.get("message") or reponse.get("text") or reponse)
message = re.sub(r"\s+", " ", message).strip()[:200]

# Certains « échecs » sont juste l'utilisateur qui refuse une permission :
# ce n'est pas une erreur de l'agent, on ne journalise pas.
if re.search(r"(user doesn.?t want|permission den|rejected|user chose)", message, re.I):
    sys.exit(0)

quand = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
ligne = f"- {quand} · {outil} · « {tentative} » → {message} · session {session or '?'}\n"

# Lecture du journal existant + rotation à 400 entrées
try:
    with open(journal, encoding="utf-8") as f:
        contenu = f.readlines()
except FileNotFoundError:
    contenu = ["# Journal des erreurs (rempli automatiquement)\n", "\n"]

entetes = [l for l in contenu if not l.startswith("- ")]
entrees = [l for l in contenu if l.startswith("- ")]
entrees.append(ligne)
entrees = entrees[-400:]          # rotation : on garde les 400 plus récentes

with open(journal, "w", encoding="utf-8") as f:
    f.writelines(entetes + entrees)
PYTHON

exit 0   # toujours non bloquant : une erreur d'outil ne doit pas être aggravée
