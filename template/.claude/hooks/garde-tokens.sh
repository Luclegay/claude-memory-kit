#!/bin/bash
# ============================================================================
# Hook Stop — vigie de la consommation de tokens
#
# Ce script s'exécute à la fin de chaque réponse de l'agent. Il lit la
# transcription de la session (fichier .jsonl tenu par Claude Code) pour
# mesurer deux choses :
#   1. la TAILLE DU CONTEXTE actuel (ce que le modèle relit à chaque tour) ;
#   2. le CUMUL de tokens produits depuis le début de la session.
# Si un seuil est franchi, une alerte s'affiche pour l'utilisateur
# (via "systemMessage") — une seule fois par seuil et par session.
#
# Seuils par défaut (modifiables via des variables d'environnement) :
#   KITMEM_SEUIL_CONTEXTE = 120000 tokens (le contexte devient lourd → /compact)
#   KITMEM_SEUIL_CUMUL    = 150000 tokens produits (grosse session → pause ?)
# ============================================================================

# Le JSON de Claude Code arrive sur stdin ; on le range dans une variable
# d'environnement car le heredoc ci-dessous occupe déjà le stdin de python.
KITMEM_HOOK_INPUT=$(cat)
export KITMEM_HOOK_INPUT

python3 - <<'PYTHON'
import json, os, sys, tempfile

d = json.loads(os.environ.get("KITMEM_HOOK_INPUT") or "{}")
transcription = d.get("transcript_path") or ""
session = (d.get("session_id") or "inconnue")[:8]
if not transcription or not os.path.exists(transcription):
    sys.exit(0)

SEUIL_CONTEXTE = int(os.environ.get("KITMEM_SEUIL_CONTEXTE", "120000"))
SEUIL_CUMUL = int(os.environ.get("KITMEM_SEUIL_CUMUL", "150000"))

contexte = 0        # taille du contexte au dernier tour
cumul_sortie = 0    # total des tokens générés sur la session
try:
    with open(transcription, encoding="utf-8") as f:
        for ligne in f:
            try:
                obj = json.loads(ligne)
            except ValueError:
                continue
            usage = ((obj.get("message") or {}).get("usage")) or {}
            if not usage:
                continue
            cumul_sortie += usage.get("output_tokens") or 0
            # contexte ≈ tokens d'entrée du dernier appel (cache compris)
            contexte = (
                (usage.get("input_tokens") or 0)
                + (usage.get("cache_read_input_tokens") or 0)
                + (usage.get("cache_creation_input_tokens") or 0)
            )
except OSError:
    sys.exit(0)

def deja_alerte(niveau):
    """Vrai si l'alerte de ce niveau a déjà été émise pour cette session
    (un petit fichier-marqueur dans le dossier temporaire sert de mémoire)."""
    marqueur = os.path.join(tempfile.gettempdir(), f"kitmem-{session}-{niveau}")
    if os.path.exists(marqueur):
        return True
    open(marqueur, "w").close()
    return False

messages = []
if contexte >= SEUIL_CONTEXTE and not deja_alerte("contexte"):
    messages.append(
        f"⚠️ Kit mémoire — le contexte de la session atteint ≈{contexte:,} tokens "
        f"(seuil {SEUIL_CONTEXTE:,}). Chaque tour coûte de plus en plus cher. "
        "Conseil : tapez /compact, ou demandez à l'agent de noter l'état en cours "
        "dans memoire/scratchpad/ puis ouvrez une session neuve."
    )
if cumul_sortie >= SEUIL_CUMUL and not deja_alerte("cumul"):
    messages.append(
        f"⚠️ Kit mémoire — cette session a déjà produit ≈{cumul_sortie:,} tokens. "
        "Consommation inhabituelle : vérifiez votre quota avec /usage, et le détail "
        "avec scripts/rapport-tokens.sh."
    )

if messages:
    print(json.dumps({"systemMessage": "\n".join(messages)}))
sys.exit(0)
PYTHON
