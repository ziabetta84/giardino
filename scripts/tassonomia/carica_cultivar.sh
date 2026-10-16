#!/usr/bin/env bash
# Fase 4a del modello tassonomico: carica public.cultivar (lotti cultivar_NN.csv) e le righe di mappa_specie delle
# cultivar (mappa.csv) preparati da cultivar_esporta.sh, un passo per transazione, con le righe già definitive (nessun
# aggiornamento: specifica, "Decisioni sullo spazio", punto 5). Va lanciato dopo carica_taxa.sh sui taxon nuovi della
# fase 4a: ogni taxon_id deve già esistere in taxa.
# Regole sullo spazio: prima di ogni passo controlla la somma dei database e il WAL; tra un lotto e l'altro fa una pausa
# (10 minuti sul reale); i 4 indici secondari di cultivar si tolgono prima e si ricreano dopo.
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione e quelli già caricati vengono saltati. Le altre
# tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_cultivar.sh URL CARTELLA_CULTIVAR CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO CULTIVAR OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; CV=${2:?manca CARTELLA_CULTIVAR}; OUT=${3:?manca CARTELLA_MISURE}
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
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.cultivar where id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
COLONNE_CULTIVAR='id,slug,taxon_id,categoria,epiteto,gruppo,nome_commerciale,grex_id,fonti,vecchia_specie_id'
COLONNE_MAPPA='vecchia_specie_id,vecchio_slug,vecchio_nome_scientifico,origine,taxon_id,cultivar_id,esito,nota'
# righe di mappa_specie delle cultivar: verso una cultivar, o di una riga di specie con l'epiteto tra apici
MAPPA_CULTIVAR="select count(*) from public.mappa_specie m where m.cultivar_id is not null
  or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%')"

# 1. I file sono quelli provati (sha256 del manifesto), con le colonne attese.
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ ( $file =~ ^cultivar_[0-9]{2}\.csv$ && $primo =~ $UUID ) || ( $file == mappa.csv && -z $primo ) ]] && [[ $righe =~ ^[0-9]+$ ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$CV/$file" | cut -d' ' -f1)" = "$sha" ] || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
  atteso=$COLONNE_CULTIVAR; [ "$file" = mappa.csv ] && atteso=$COLONNE_MAPPA
  [ "$(head -1 "$CV/$file")" = "$atteso" ] || { echo "RIFIUTATO: colonne inattese in $file" >&2; exit 1; }
done 3< "$CV/manifest.tsv"
grep -q $'^mappa.csv\t' "$CV/manifest.tsv" || { echo "RIFIUTATO: mappa.csv non è nel manifesto" >&2; exit 1; }
CULTIVAR=$(awk -F'\t' '$1 ~ /^cultivar_/ { s += $2 } END { print s }' "$CV/manifest.tsv")
RIGHE_MAPPA=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$CV/manifest.tsv")
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indici secondari tolti se c'è qualcosa da caricare (si ricreano al passo 4, anche dopo un'interruzione).
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  if [[ $file == cultivar_* ]] && ! caricato "$primo"; then da_caricare=$((da_caricare + 1)); fi
done 3< "$CV/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo gli indici secondari di cultivar ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.cultivar_taxon_id_idx, public.cultivar_epiteto_trgm_idx,
                   public.cultivar_nome_commerciale_trgm_idx, public.cultivar_grex_id_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file == cultivar_* ]] || continue
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.cultivar')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.cultivar ($COLONNE_CULTIVAR) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.cultivar) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$CV/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$CV/manifest.tsv"

# 4. Indici secondari (identici alle migration della fase 1 e della fase 4) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo gli indici secondari di cultivar"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists cultivar_taxon_id_idx on public.cultivar (taxon_id)' \
  -c 'create index if not exists cultivar_epiteto_trgm_idx on public.cultivar using gin (epiteto extensions.gin_trgm_ops)' \
  -c 'create index if not exists cultivar_nome_commerciale_trgm_idx on public.cultivar using gin (nome_commerciale extensions.gin_trgm_ops)' \
  -c 'create index if not exists cultivar_grex_id_idx on public.cultivar (grex_id) where grex_id is not null'
"${PSQL[@]}" -c 'analyze public.cultivar'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indici ricreati, WAL $wal MB"

# 5. Righe di mappa_specie delle cultivar: nessuna -> si caricano; tutte -> si salta; altrimenti rifiuto.
presenti=$("${PSQL[@]}" -tAc "$MAPPA_CULTIVAR")
if [ "$presenti" = "$RIGHE_MAPPA" ]; then
  tempo "righe di mappa delle cultivar già caricate"
elif [ "$presenti" = 0 ]; then
  controlla mappa
  tempo "carico $RIGHE_MAPPA righe di mappa delle cultivar"
  "${PSQL[@]}" -1 -c "copy public.mappa_specie ($COLONNE_MAPPA) from stdin with (format csv, header)" \
    -c "do \$\$ begin if ($MAPPA_CULTIVAR) <> $RIGHE_MAPPA then raise exception 'righe di mappa delle cultivar incomplete'; end if; end \$\$" \
    < "$CV/mappa.csv"
  "${PSQL[@]}" -c 'analyze public.mappa_specie'
else
  echo "RIFIUTATO: mappa_specie contiene $presenti righe di cultivar invece di 0 o $RIGHE_MAPPA" >&2; exit 1
fi

# 6. specie invariata, cultivar corrette, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_cultivar="$CULTIVAR" -v righe_mappa="$RIGHE_MAPPA" -f $D/verifica_fase4a.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO CULTIVAR OK"
