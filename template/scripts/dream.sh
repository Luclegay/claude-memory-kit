#!/bin/bash
# ============================================================================
# dream.sh — lance une passe de « Dreaming » (consolidation de la mémoire)
#
# Processus OUT-OF-BAND au sens de Lamis Mukta : il tourne en dehors de vos
# sessions de travail, avec son propre budget de tokens, pour analyser les
# sessions passées et proposer des améliorations de la mémoire.
#
# Usage :
#   ./scripts/dream.sh                 # analyse (7 jours, 5 sessions max)
#   ./scripts/dream.sh --jours 14      # remonter plus loin
#   ./scripts/dream.sh --sessions 3    # limiter le nombre de sessions analysées
#   ./scripts/dream.sh --oui           # sans demande de confirmation (pour cron)
#   ./scripts/dream.sh --modele claude-haiku-4-5-20251001   # modèle plus économique
#
# Garde-fous intégrés :
#   - DEVIS avant exécution : estimation des tokens à lire, confirmation demandée
#     au-delà du seuil (KITMEM_SEUIL_DEVIS, défaut 200 000 tokens estimés) ;
#   - plafond de tours d'agent : --max-turns 40 ;
#   - FACTURE après exécution : coût réel affiché, ALERTE si supérieur à
#     DREAM_COUT_ALERTE (défaut 2.00 $).
# ============================================================================
set -euo pipefail

# --- Réglages (modifiables par variables d'environnement) -------------------
JOURS=7                # ancienneté maximale des sessions analysées
MAX_SESSIONS=5         # nombre maximal de transcriptions passées au dreaming
CONFIRMER=1            # 1 = demander confirmation si le devis dépasse le seuil
MODELE="${DREAM_MODELE:-}"                       # vide = modèle par défaut de claude
SEUIL_DEVIS="${KITMEM_SEUIL_DEVIS:-200000}"      # tokens estimés
COUT_ALERTE="${DREAM_COUT_ALERTE:-2.00}"         # dollars

while [ $# -gt 0 ]; do
  case "$1" in
    --jours)    JOURS="$2"; shift 2 ;;
    --sessions) MAX_SESSIONS="$2"; shift 2 ;;
    --oui)      CONFIRMER=0; shift ;;
    --modele)   MODELE="$2"; shift 2 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
done

# --- Localiser le projet et ses transcriptions ------------------------------
# Le script doit être lancé depuis la racine du projet (là où vit memoire/).
PROJET="$(pwd)"
if [ ! -d "$PROJET/memoire" ]; then
  echo "❌ Pas de dossier memoire/ ici. Lancez ce script depuis la racine du projet." >&2
  exit 1
fi

# Claude Code range les transcriptions dans ~/.claude/projects/<chemin-encodé>/
# (le chemin du projet où chaque caractère spécial devient un tiret).
DOSSIER_ENCODE=$(printf '%s' "$PROJET" | sed 's/[^a-zA-Z0-9]/-/g')
TRANSCRIPTIONS="$HOME/.claude/projects/$DOSSIER_ENCODE"

if [ ! -d "$TRANSCRIPTIONS" ]; then
  echo "❌ Aucune transcription trouvée ($TRANSCRIPTIONS)." >&2
  echo "   Il faut avoir déjà utilisé Claude Code dans ce projet." >&2
  exit 1
fi

# Les N transcriptions les plus récentes datant de moins de JOURS jours
LISTE=$(find "$TRANSCRIPTIONS" -maxdepth 1 -name "*.jsonl" -mtime -"$JOURS" -print0 \
  | xargs -0 ls -t 2>/dev/null | head -n "$MAX_SESSIONS" || true)

if [ -z "$LISTE" ]; then
  echo "Rien à rêver : aucune session de moins de $JOURS jours. 😴"
  exit 0
fi

# --- DEVIS : estimation des tokens avant de dépenser quoi que ce soit -------
OCTETS=$(echo "$LISTE" | tr '\n' '\0' | xargs -0 wc -c 2>/dev/null | tail -n 1 | awk '{print $1}')
EST_TOKENS=$(( OCTETS / 4 ))   # approximation classique : 1 token ≈ 4 caractères
NB=$(echo "$LISTE" | grep -c . )

echo "🌙 Dreaming — devis avant exécution"
echo "   Sessions à analyser : $NB (les plus récentes, < $JOURS jours)"
printf "   Volume brut : %'d octets ≈ %'d tokens (majorant : le skill échantillonne par grep)\n" "$OCTETS" "$EST_TOKENS"

if [ "$EST_TOKENS" -gt "$SEUIL_DEVIS" ] && [ "$CONFIRMER" -eq 1 ]; then
  echo "⚠️  Estimation au-dessus du seuil ($SEUIL_DEVIS tokens)."
  echo "   Astuce : réduisez avec --sessions 3 ou --jours 3."
  printf "   Continuer quand même ? [o/N] "
  read -r REPONSE
  case "$REPONSE" in o|O|oui|OUI) ;; *) echo "Annulé."; exit 0 ;; esac
fi

# --- Déposer la liste des sessions pour le skill dreaming -------------------
mkdir -p "$PROJET/memoire/scratchpad"
echo "$LISTE" > "$PROJET/memoire/scratchpad/dreaming-sessions.txt"

# --- Lancer la passe (batch, plafonnée) -------------------------------------
echo "   Lancement… (plafond : 40 tours d'agent)"
ARGS=(-p "/dreaming" --max-turns 40 --output-format json)
[ -n "$MODELE" ] && ARGS+=(--model "$MODELE")

SORTIE=$(claude "${ARGS[@]}" 2>&1) || {
  echo "❌ La passe de dreaming a échoué :" >&2
  echo "$SORTIE" | tail -n 5 >&2
  exit 1
}

# --- FACTURE : coût réel + alerte -------------------------------------------
export KITMEM_DREAM_SORTIE="$SORTIE"
python3 - "$COUT_ALERTE" <<'PYTHON'
import json, os, sys

seuil = float(sys.argv[1])
brut = os.environ.get("KITMEM_DREAM_SORTIE") or ""
# La sortie est du JSON ; en cas de texte parasite, on isole le dernier objet JSON.
try:
    resultat = json.loads(brut)
except ValueError:
    debut = brut.find("{")
    resultat = json.loads(brut[debut:]) if debut >= 0 else {}

cout = resultat.get("total_cost_usd") or 0.0
duree = (resultat.get("duration_ms") or 0) / 1000
tours = resultat.get("num_turns") or "?"
texte = (resultat.get("result") or "").strip()

print()
print("🌙 Dreaming terminé — facture réelle")
print(f"   Coût : {cout:.4f} $ · Durée : {duree:.0f}s · Tours : {tours}")
if cout > seuil:
    print(f"   🚨 ALERTE : coût supérieur au seuil ({seuil:.2f} $) !")
    print("      Réduisez --sessions/--jours ou passez sur un modèle plus économique")
    print("      (--modele claude-haiku-4-5-20251001) pour les prochaines passes.")
print()
if texte:
    print("── Résumé de la passe ──────────────────────────────")
    print(texte)
PYTHON

# Nettoyage de la liste de sessions
rm -f "$PROJET/memoire/scratchpad/dreaming-sessions.txt"

echo
echo "➡️  Prochaine étape : ouvrez memoire/propositions/, marquez [OK]/[NON],"
echo "   puis lancez :  claude \"/dreaming appliquer\""
