#!/usr/bin/env bash
# Fase 4a: dalle proposte delle cultivar (col.cultivar_proposte e col.cultivar_mappa, copia locale) scrive i file da
# caricare sul database reale.
# - CARTELLA/taxa: i taxon di COL che mancano (cultivar_nuovi_taxa.sql) in un lotto per carica_taxa.sh, con base.txt
#   (righe di COL già in taxa), regni.txt (i regni già in taxa più quelli nuovi) e versione.txt;
# - CARTELLA/cultivar: lotti cultivar_NN.csv da 100.000 righe al massimo (prima i grex e le cultivar delle specie nuove,
#   poi per slug) e mappa.csv (righe di mappa_specie delle cultivar), con il manifesto per carica_cultivar.sh.
# Le chiavi sono quelle di public.taxa della copia, identica al reale (backup preso dopo la fase 3).
# Uso: bash scripts/tassonomia/cultivar_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
LOTTO=100000
VERSIONE=$("${PSQL[@]}" -tAc "select string_agg(distinct versione_col, ',') from public.taxa where origine = 'col'")
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "Versione di COL in taxa inattesa: $VERSIONE" >&2; exit 1; }
"${PSQL[@]}" -f scripts/tassonomia/cultivar_nuovi_taxa.sql
mkdir -p "$DIR/taxa" "$DIR/cultivar"

manifesto() {  # manifesto CARTELLA FILE PRIMO_CAMPO_DA_REGISTRARE(0/1)
  local righe primo=""
  righe=$(( $(wc -l < "$1/$2") - 1 ))
  [ "$3" = 1 ] && primo=$(sed -n 2p "$1/$2" | cut -d, -f"$4")
  printf '%s\t%s\t%s\t%s\n' "$2" "$righe" "$(shasum -a 256 "$1/$2" | cut -d' ' -f1)" "$primo" >> "$1/manifest.tsv"
}

# taxon di COL nuovi: un solo lotto, con la nota che li distingue (serve al rollback della fase 4a)
echo "$VERSIONE" > "$DIR/taxa/versione.txt"
"${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'col'" > "$DIR/taxa/base.txt"
"${PSQL[@]}" -tAc "select string_agg(distinct r, ',' order by r) from (select 'Plantae' as r union
                   select nome_scientifico from public.taxa where rango = 'kingdom' union
                   select coalesce(nullif(u.regno, ''), case when u.rango = 'kingdom' then u.nome end)
                     from col.cultivar_nuovi m join col.nome_uso u on u.id = m.col_id
                    where u.status in ('accepted', 'provisionally accepted')) x where r is not null" > "$DIR/taxa/regni.txt"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select m.id, 'col' as origine, m.col_id, '$VERSIONE' as versione_col, u.rango, u.nome as nome_scientifico,
               nullif(u.autore, '') as autore, nullif(split_part(lower(u.notho), ',', 1), '') as notho, u.status as stato,
               case when u.status in ('synonym', 'ambiguous synonym', 'misapplied') then coalesce(pn.id, pt.id) end as accettato_id,
               case when u.status in ('accepted', 'provisionally accepted') then coalesce(pn.id, pt.id) end as padre_id,
               'importato nella fase 4 (cultivar)' as nota
          from col.cultivar_nuovi m join col.nome_uso u on u.id = m.col_id
          left join col.cultivar_nuovi pn on pn.col_id = nullif(u.parent_id, '')
          left join public.taxa pt on pt.col_id = nullif(u.parent_id, '')
         order by m.col_id) to stdout with (format csv, header)" > "$DIR/taxa/lotto_01.csv"
manifesto "$DIR/taxa" lotto_01.csv 1 3

# cultivar: valori definitivi (taxon risolto, grex_id già calcolato), in lotti
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select p.id, p.slug, coalesce(p.taxon_id, n.id) as taxon_id, p.categoria, p.epiteto, p.gruppo, p.nome_commerciale,
               p.grex_id, p.fonti, p.vecchia_specie_id
          from col.cultivar_proposte p left join col.cultivar_nuovi n on n.col_id = p.taxon_col_id
         order by (p.categoria = 'grex') desc, (p.taxon_col_id is not null) desc, p.slug) to stdout with (format csv, header)" \
  > "$DIR/cultivar/tutte.csv"
tail -n +2 "$DIR/cultivar/tutte.csv" | split -l "$LOTTO" -a 2 -d - "$DIR/cultivar/parte_"
for parte in "$DIR"/cultivar/parte_*; do
  n=$(( 10#${parte##*_} + 1 ))
  file=$(printf 'cultivar_%02d.csv' "$n")
  { head -1 "$DIR/cultivar/tutte.csv"; cat "$parte"; } > "$DIR/cultivar/$file"
  rm "$parte"
  manifesto "$DIR/cultivar" "$file" 1 1
done
rm "$DIR/cultivar/tutte.csv"
"${PSQL[@]}" -c "
  copy (select m.vecchia_specie_id, m.vecchio_slug, m.vecchio_nome_scientifico, m.origine, coalesce(m.taxon_id, n.id) as taxon_id,
               m.cultivar_id, m.esito, m.nota
          from col.cultivar_mappa m left join col.cultivar_nuovi n on n.col_id = m.taxon_col_id
         order by m.vecchio_slug) to stdout with (format csv, header)" > "$DIR/cultivar/mappa.csv"
manifesto "$DIR/cultivar" mappa.csv 0
senza=$(python3 -c '
import csv, sys
n = sum(1 for f in sys.argv[2:] for r in csv.DictReader(open(f, encoding="utf-8")) if not r["taxon_id"])
n += sum(1 for r in csv.DictReader(open(sys.argv[1], encoding="utf-8")) if not r["taxon_id"] and not r["cultivar_id"])
print(n)' "$DIR/cultivar/mappa.csv" "$DIR"/cultivar/cultivar_*.csv)
[ "$senza" = 0 ] || { echo "Righe senza taxon nei file delle cultivar: $senza" >&2; exit 1; }
cut -f1,2 "$DIR/taxa/manifest.tsv" "$DIR/cultivar/manifest.tsv"
echo "base $(cat "$DIR/taxa/base.txt"), regni $(cat "$DIR/taxa/regni.txt")"
