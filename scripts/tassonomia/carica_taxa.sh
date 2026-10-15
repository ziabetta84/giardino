#!/usr/bin/env bash
# Fase 2 del modello tassonomico: carica in public.taxa i lotti preparati da col_esporta_lotti.sh, uno per transazione.
# Regole sullo spazio (specifica, "Decisioni sullo spazio", punto 5):
# - prima di ogni passo controlla la somma dei database e il WAL;
# - tra un lotto e l'altro fa una pausa (10 minuti sul reale, perché il WAL venga riciclato);
# - i 3 indici secondari di taxa si tolgono prima e si ricreano dopo.
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione (c'è tutto o niente) e quelli già caricati
# vengono saltati. Le altre tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_taxa.sh URL CARTELLA_LOTTI CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO TAXA OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; LOTTI=${2:?manca CARTELLA_LOTTI}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  PAUSA_S=600; SOGLIA_MB=400; SOGLIA_WAL_MB=300
else
  PAUSA_S=${PAUSA_S:-0}; SOGLIA_MB=${SOGLIA_MB:-100000}; SOGLIA_WAL_MB=${SOGLIA_WAL_MB:-100000}
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
controlla() {
  "${PSQL[@]}" -v soglia_mb="$SOGLIA_MB" -v soglia_wal_mb="$SOGLIA_WAL_MB" -f $D/controlli_spazio.sql > "$OUT/controlli_$1.txt" \
    || { cat "$OUT/controlli_$1.txt" >&2; echo "FERMATO: spazio insufficiente prima di $1; in questo passo non è stato caricato niente" >&2; exit 1; }
}
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.taxa where col_id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}

# 1. I lotti sono quelli provati (sha256 del manifesto) e della versione dichiarata.
VERSIONE=$(cat "$LOTTI/versione.txt")
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "RIFIUTATO: versione non valida in versione.txt" >&2; exit 1; }
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file =~ ^lotto_[0-9]{2}\.csv$ && $righe =~ ^[0-9]+$ && $primo =~ ^[A-Za-z0-9]+$ ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$LOTTI/$file" | cut -d' ' -f1)" = "$sha" ] \
    || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
done 3< "$LOTTI/manifest.tsv"
ATTESE=$(awk -F'\t' '{ s += $2 } END { print s }' "$LOTTI/manifest.tsv")
altre=$("${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'col' and versione_col <> '$VERSIONE'")
[ "$altre" = 0 ] || { echo "RIFIUTATO: taxa contiene $altre righe di un'altra versione di COL" >&2; exit 1; }
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indici secondari tolti solo se c'è qualcosa da caricare.
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  caricato "$primo" || da_caricare=$((da_caricare + 1))
done 3< "$LOTTI/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo gli indici secondari di taxa ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.taxa_padre_id_idx, public.taxa_accettato_id_idx, public.taxa_nome_scientifico_trgm_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.taxa')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.taxa (id, origine, col_id, versione_col, rango, nome_scientifico, autore, notho, stato, accettato_id, padre_id) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.taxa) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$LOTTI/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$LOTTI/manifest.tsv"

# 4. Indici secondari (identici alla migration della fase 1) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo gli indici secondari di taxa"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists taxa_padre_id_idx on public.taxa (padre_id)' \
  -c 'create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id)' \
  -c 'create index if not exists taxa_nome_scientifico_trgm_idx on public.taxa using gin (nome_scientifico extensions.gin_trgm_ops)'
"${PSQL[@]}" -c 'analyze public.taxa'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indici ricreati, WAL $wal MB"

# 5. specie invariata, taxa corretta, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_attese="$ATTESE" -v versione="$VERSIONE" -f $D/verifica_fase2.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO TAXA OK"
