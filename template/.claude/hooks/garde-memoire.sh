#!/bin/bash
# ============================================================================
# Hook PreToolUse — garde-fou « permissions » de la mémoire
# (recommandation Lamis Mukta : la mémoire partagée de l'organisation est en
#  LECTURE SEULE pour l'agent ; une erreur qui s'y glisserait se propagerait
#  à toutes les sessions.)
#
# Ce script s'exécute AVANT chaque outil Write/Edit/Bash de l'agent.
# Il BLOQUE :
#   - toute écriture dans memoire/organisation/  (lecture seule),
#   - toute écriture directe dans le journal d'erreurs (réservé au hook),
#   - toute commande bash destructrice (rm, mv…) visant le dossier memoire/.
# C'est une deuxième serrure : les règles "deny" de settings.json font déjà
# le même travail — la défense en profondeur est volontaire.
# ============================================================================

# Le JSON de Claude Code arrive sur stdin ; on le range dans une variable
# d'environnement car le heredoc ci-dessous occupe déjà le stdin de python.
KITMEM_HOOK_INPUT=$(cat)
export KITMEM_HOOK_INPUT

python3 - <<'PYTHON'
import json, os, re, sys

donnees = json.loads(os.environ.get("KITMEM_HOOK_INPUT") or "{}")
outil = donnees.get("tool_name", "")
entree = donnees.get("tool_input") or {}

def bloquer(raison):
    """Répond à Claude Code : appel refusé, avec l'explication donnée à l'agent."""
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": raison,
        }
    }))
    sys.exit(0)

# --- Cas 1 : écriture de fichier (Write / Edit / MultiEdit) -----------------
if outil in ("Write", "Edit", "MultiEdit"):
    chemin = entree.get("file_path") or ""
    if "memoire/organisation/" in chemin:
        bloquer("Garde-fou mémoire : memoire/organisation/ est en LECTURE SEULE pour "
                "l'agent (mémoire partagée). Écris ta suggestion dans "
                "memoire/propositions/ ; un humain validera.")
    if chemin.endswith("memoire/erreurs/journal.md"):
        # Seule modification tolérée du journal : ANNOTER une ligne avec [traité …]
        # sans rien supprimer (l'ancien texte doit se retrouver intact dans le
        # nouveau). Tout le reste est bloqué : le journal est rempli par un hook.
        ancien = entree.get("old_string") or ""
        nouveau = entree.get("new_string") or ""
        annotation_pure = (
            outil == "Edit"
            and "[traité" in nouveau
            and ancien != ""
            and ancien.replace("\n", "") in nouveau.replace("\n", "")
        )
        if not annotation_pure:
            bloquer("Garde-fou mémoire : le journal d'erreurs est rempli automatiquement "
                    "par un hook. Seule modification autorisée : ajouter une mention "
                    "[traité → lecons/<fichier>] à une ligne existante via Edit, sans "
                    "supprimer le texte d'origine.")

# --- Cas 2 : commande bash ---------------------------------------------------
if outil == "Bash":
    commande = entree.get("command") or ""
    # Commandes destructrices ou d'écriture visant la mémoire
    if re.search(r"\bmemoire/", commande):
        if re.search(r"\b(rm|rmdir|mv|unlink|shred)\b", commande):
            # Exceptions : le scratchpad est jetable (purge autorisée), et le
            # dreaming peut renommer (mv) un fichier de propositions en -traite.md.
            cibles = re.findall(r"memoire/[^\s'\"]*", commande)
            autorise = cibles and (
                all(c.startswith("memoire/scratchpad/") for c in cibles)
                or (
                    re.search(r"\bmv\b", commande)
                    and all(c.startswith(("memoire/scratchpad/",
                                          "memoire/propositions/")) for c in cibles)
                )
            )
            if not autorise:
                bloquer("Garde-fou mémoire : suppression/déplacement interdit dans "
                        "memoire/ (sauf memoire/scratchpad/). Le nettoyage passe "
                        "par la passe de dreaming, validée par un humain.")
        if re.search(r"(>>?|\btee\b|\bsed\s+-i)\s*\S*memoire/organisation/", commande):
            bloquer("Garde-fou mémoire : memoire/organisation/ est en lecture seule "
                    "pour l'agent, y compris via bash.")

sys.exit(0)   # aucun problème : l'appel d'outil suit son cours normal
PYTHON
