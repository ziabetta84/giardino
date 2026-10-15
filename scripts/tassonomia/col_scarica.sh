#!/usr/bin/env bash
# Scarica Catalogue of Life Extended Release in formato ColDP (specifica, "Fonti e regole adottate") in una cartella
# fuori dal repository (decisione 3), riprendendo da dove si è fermato, e ne verifica l'integrità. Se il file c'è già
# non si riscarica: una versione nuova di COL è un reimport, da pianificare a parte (spostare prima il file vecchio).
# Il sito di download vuole un browser: user agent da browser e cookie.
# Uso: bash scripts/tassonomia/col_scarica.sh CARTELLA        (stampa: versione <alias di metadata.yaml>)
set -euo pipefail
DIR=${1:?manca CARTELLA}
SORGENTE=https://download.checklistbank.org/col/xr_latest_coldp.zip
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"
mkdir -p "$DIR"
cd "$DIR"
CURL=(curl -sS -L --fail -A "$UA" -c cj.txt -b cj.txt)
if [ -f xr_latest_coldp.zip ]; then
  echo "già scaricato"
else
  tot=$("${CURL[@]}" -I "$SORGENTE" | tr -d '\r' | awk 'tolower($1) == "content-length:" { n = $2 } END { print n }')
  [[ $tot =~ ^[0-9]+$ ]] || { echo "Dimensione del file sul server non disponibile" >&2; exit 1; }
  # un file parziale di un'altra versione non si può riprendere
  [ "$(cat xr_latest_coldp.zip.dimensione 2>/dev/null)" = "$tot" ] || rm -f xr_latest_coldp.zip.part
  echo "$tot" > xr_latest_coldp.zip.dimensione
  for tentativo in 1 2 3 4 5 6 7 8 9 10; do
    [ -f xr_latest_coldp.zip.part ] && [ "$(stat -f %z xr_latest_coldp.zip.part)" -ge "$tot" ] && break
    "${CURL[@]}" -C - --speed-limit 20000 --speed-time 60 -o xr_latest_coldp.zip.part "$SORGENTE" \
      || echo "tentativo $tentativo interrotto, riprendo" >&2
  done
  [ "$(stat -f %z xr_latest_coldp.zip.part)" -eq "$tot" ] || { echo "Scaricamento incompleto" >&2; exit 1; }
  mv xr_latest_coldp.zip.part xr_latest_coldp.zip
  rm -f xr_latest_coldp.zip.dimensione
fi
unzip -tq xr_latest_coldp.zip > /dev/null
shasum -a 256 xr_latest_coldp.zip > xr_latest_coldp.zip.sha256
unzip -p xr_latest_coldp.zip metadata.yaml | awk -F': ' '$1 == "alias" { print "versione " $2 }'
