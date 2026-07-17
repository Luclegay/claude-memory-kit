#!/bin/bash
# ============================================================================
# rapport-tokens.sh — combien ce projet a-t-il consommé ?
#
# Additionne les tokens enregistrés dans les transcriptions locales de
# Claude Code (~/.claude/projects/…) pour CE projet.
#
# Usage :
#   ./scripts/rapport-tokens.sh            # aujourd'hui
#   ./scripts/rapport-tokens.sh --jours 7  # les 7 derniers jours
#
# Notes honnêtes :
#   - c'est une mesure LOCALE (tokens vus dans les transcriptions), utile pour
#     repérer une dérive ; le quota officiel de votre abonnement se consulte
#     avec la commande /usage dans Claude Code ;
#   - pour un rapport de coûts détaillé multi-projets : `npx ccusage`
#     (outil open source indépendant).
# ============================================================================
set -euo pipefail

JOURS=1
[ "${1:-}" = "--jours" ] && JOURS="${2:-7}"

PROJET="$(pwd)"
DOSSIER_ENCODE=$(printf '%s' "$PROJET" | sed 's/[^a-zA-Z0-9]/-/g')
TRANSCRIPTIONS="$HOME/.claude/projects/$DOSSIER_ENCODE"

if [ ! -d "$TRANSCRIPTIONS" ]; then
  echo "Aucune transcription pour ce projet ($TRANSCRIPTIONS)."
  exit 0
fi

# Python parcourt lui-même les transcriptions (fichiers potentiellement gros :
# on ne les fait pas transiter par des variables ou des pipes inutiles).
python3 - "$TRANSCRIPTIONS" "$JOURS" <<'PYTHON'
import json, os, sys, time
from collections import defaultdict

dossier, jours = sys.argv[1], int(sys.argv[2])
limite = time.time() - jours * 86400
totaux = defaultdict(int)
par_modele = defaultdict(int)

for nom in os.listdir(dossier):
    if not nom.endswith(".jsonl"):
        continue
    chemin = os.path.join(dossier, nom)
    if os.path.getmtime(chemin) < limite:
        continue
    with open(chemin, encoding="utf-8", errors="replace") as f:
        for ligne in f:
            try:
                obj = json.loads(ligne)
            except ValueError:
                continue
            message = obj.get("message") or {}
            usage = message.get("usage") or {}
            if not usage:
                continue
            totaux["entrée (non cachée)"] += usage.get("input_tokens") or 0
            totaux["entrée (cache lu)"] += usage.get("cache_read_input_tokens") or 0
            totaux["entrée (cache créé)"] += usage.get("cache_creation_input_tokens") or 0
            totaux["sortie"] += usage.get("output_tokens") or 0
            par_modele[message.get("model") or "?"] += usage.get("output_tokens") or 0

print(f"📊 Tokens du projet — {jours} dernier(s) jour(s)")
for cle, valeur in totaux.items():
    print(f"   {cle:22s} : {valeur:>12,} tokens".replace(",", " "))
if par_modele:
    print("   Par modèle (tokens de sortie) :")
    for modele, valeur in sorted(par_modele.items(), key=lambda x: -x[1]):
        print(f"     {modele:35s} {valeur:>10,}".replace(",", " "))
print()
print("ℹ️  Quota officiel de l'abonnement : tapez /usage dans Claude Code.")
print("ℹ️  Rapport de coûts détaillé (tous projets) : npx ccusage")
PYTHON
