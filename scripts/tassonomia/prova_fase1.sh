#!/usr/bin/env bash
# Prove della fase 1 del modello tassonomico. Ogni prova gira in una transazione che non viene mai confermata:
# il database non cambia. Uscita 0 = tutte le prove passate.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')
PSQL=(psql "$URL" -X -q -v ON_ERROR_STOP=1)

"${PSQL[@]}" -f scripts/tassonomia/prova_fase1.sql

for prova in guardia doppia; do
  file="scripts/tassonomia/prova_fase1_${prova}.sql"
  [ -f "$file" ] || continue
  atteso=$(head -1 "$file" | sed 's/^-- ATTESO: //')
  if out=$("${PSQL[@]}" -f "$file" 2>&1); then
    echo "PROVA $prova FALLITA: doveva dare errore"; exit 1
  fi
  if ! grep -qF "$atteso" <<<"$out"; then
    echo "PROVA $prova FALLITA: errore diverso da quello atteso"; echo "$out"; exit 1
  fi
  echo "PROVA $prova OK"
done
echo "PROVE FASE 1 OK"
