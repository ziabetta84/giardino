#!/usr/bin/env bash
# Traduce e naturalizza le schede rimaste in inglese, un lotto alla volta (issue #153).
# Ogni giro apre due sessioni Claude Code nuove (contesto pulito): una scrive il lotto con /naturalizza-lotto,
# l'altra lo verifica in modo indipendente su tutte le schede. Si ferma al primo errore.
#
# Uso, dalla radice del repository:
#   bash scripts/naturalizza-batch/loop-naturalizza.sh        # 1 lotto
#   bash scripts/naturalizza-batch/loop-naturalizza.sh 5      # 5 lotti
# Il resoconto di ogni giro finisce in scripts/naturalizza-batch/loop.log (ignorato da git).
#
# Fino al lotto 78 lo script viveva in una cartella temporanea del Mac ed è andato perso: questa è la versione
# ricostruita per le schede (28/10/2026). Se Claude Code chiede permessi che qui non sono previsti, aggiungerli a
# STRUMENTI invece di saltare i permessi.

set -euo pipefail

GIRI="${1:-1}"
QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADICE="$(cd "$QUI/../.." && pwd)"
LOG="$QUI/loop.log"
STRUMENTI="Read Write Edit Glob Grep Agent Bash(python3:*) Bash(psql:*) Bash(ls:*) Bash(git status:*)"

cd "$RADICE"

for ((i = 1; i <= GIRI; i++)); do
  echo "=== giro $i/$GIRI: scrittura — $(date '+%F %T') ===" | tee -a "$LOG"
  claude -p "/naturalizza-lotto" --allowedTools $STRUMENTI 2>&1 | tee -a "$LOG"

  ULTIMO="$(ls "$QUI"/lotto*_schede.json | sed -E 's/.*lotto([0-9]+)_schede.json/\1/' | sort -n | tail -1)"
  if [ ! -f "$QUI/lotto${ULTIMO}_schede_rollback.sql" ]; then
    echo "!!! il lotto $ULTIMO non risulta scritto (manca il rollback): mi fermo" | tee -a "$LOG"
    exit 1
  fi

  echo "=== giro $i/$GIRI: verifica indipendente del lotto $ULTIMO — $(date '+%F %T') ===" | tee -a "$LOG"
  claude -p "Sei il verificatore indipendente del lotto $ULTIMO di traduzione delle schede (issue #153). Leggi la skill \
.claude/commands/naturalizza-descrizioni.md e la sezione «Verifica» di .claude/commands/naturalizza-lotto.md. Confronta, \
scheda per scheda, scripts/naturalizza-batch/lotto${ULTIMO}_schede.json (prima) con lo stato attuale su Supabase \
(psql \"\$SUPABASE_DB_URL\" da .env.local): fatti persi o aggiunti, termini botanici e fitopatologici italiani, concordanze, \
regole di stile della skill. Lancia anche scripts/naturalizza-batch/controlla_schede.sql sugli id del lotto. Correggi tu \
gli errori sicuri con un update per scheda (mai sulle voci «Rusticità:», «Dimensioni a maturità:» e «Rischi (testo in inglese)»), \
e segnala quelli dubbi. Niente git add o commit. Chiudi con un resoconto breve in italiano." \
    --allowedTools $STRUMENTI 2>&1 | tee -a "$LOG"
done

echo "=== finito $GIRI lotti — $(date '+%F %T') ===" | tee -a "$LOG"
python3 "$QUI/esporta_schede.py" --conta | tee -a "$LOG"
