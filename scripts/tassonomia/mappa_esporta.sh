#!/usr/bin/env bash
# Fase 3: dalle proposte decise (col.mappa_proposte, copia locale) scrive i file da caricare sul database reale.
# - CARTELLA/taxa: i taxon di COL che mancano in public.taxa (mappa_nuovi_taxa.sql) in un lotto per carica_taxa.sh, con
#   base.txt (righe di COL già in taxa, che restano) e regni.txt (regni ammessi dalla verifica);
# - CARTELLA/mappa: locali.csv (taxon locali) e mappa.csv (una riga per ogni riga da abbinare, valori definitivi), con il
#   manifesto per carica_mappa.sh. Le chiavi sono quelle di public.taxa della copia, identica al reale (stessi lotti).
# Uso: bash scripts/tassonomia/mappa_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
aperti=$("${PSQL[@]}" -tAc 'select count(*) from col.mappa_proposte where da_rivedere')
[ "$aperti" = 0 ] || { echo "Ci sono ancora $aperti casi da rivedere: prima mappa_decisioni.sql" >&2; exit 1; }
VERSIONE=$("${PSQL[@]}" -tAc "select string_agg(distinct versione_col, ',') from public.taxa where origine = 'col'")
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "Versione di COL in taxa inattesa: $VERSIONE" >&2; exit 1; }
"${PSQL[@]}" -f scripts/tassonomia/mappa_nuovi_taxa.sql
mkdir -p "$DIR/taxa" "$DIR/mappa"

manifesto() {  # manifesto CARTELLA FILE PRIMO_CAMPO_DA_REGISTRARE(0/1)
  local righe primo=""
  righe=$(( $(wc -l < "$1/$2") - 1 ))
  [ "$3" = 1 ] && primo=$(sed -n 2p "$1/$2" | cut -d, -f3)
  printf '%s\t%s\t%s\t%s\n' "$2" "$righe" "$(shasum -a 256 "$1/$2" | cut -d' ' -f1)" "$primo" >> "$1/manifest.tsv"
}

# taxon di COL nuovi: un solo lotto, con la nota che li distingue (serve al rollback della fase 3)
echo "$VERSIONE" > "$DIR/taxa/versione.txt"
"${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'col'" > "$DIR/taxa/base.txt"
"${PSQL[@]}" -tAc "select string_agg(distinct r, ',' order by r) from (select 'Plantae' as r union
                   select coalesce(nullif(u.regno, ''), case when u.rango = 'kingdom' then u.nome end)
                     from col.mappa_nuovi m join col.nome_uso u on u.id = m.col_id
                    where u.status in ('accepted', 'provisionally accepted')) x where r is not null" > "$DIR/taxa/regni.txt"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select m.id, 'col' as origine, m.col_id, '$VERSIONE' as versione_col, u.rango, u.nome as nome_scientifico,
               nullif(u.autore, '') as autore, nullif(split_part(lower(u.notho), ',', 1), '') as notho, u.status as stato,
               case when u.status in ('synonym', 'ambiguous synonym', 'misapplied') then coalesce(pn.id, pt.id) end as accettato_id,
               case when u.status in ('accepted', 'provisionally accepted') then coalesce(pn.id, pt.id) end as padre_id,
               'importato nella fase 3 (abbinamento)' as nota
          from col.mappa_nuovi m join col.nome_uso u on u.id = m.col_id
          left join col.mappa_nuovi pn on pn.col_id = nullif(u.parent_id, '')
          left join public.taxa pt on pt.col_id = nullif(u.parent_id, '')
         order by m.col_id) to stdout with (format csv, header)" > "$DIR/taxa/lotto_01.csv"
manifesto "$DIR/taxa" lotto_01.csv 1

# taxon locali e mappa
"${PSQL[@]}" -c "
  copy (select id, 'locale' as origine, 'genus' as rango, nome as nome_scientifico, 'generic' as notho, 'accepted' as stato,
               padre_id, 'notogenere assente da COL (fase 3)' as nota
          from col.mappa_locali order by nome) to stdout with (format csv, header)" > "$DIR/mappa/locali.csv"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select p.vecchia_specie_id, p.vecchio_slug, p.vecchio_nome_scientifico, p.origine,
               coalesce(t.id, n.id, l.id) as taxon_id, p.esito, p.nota
          from col.mappa_proposte p
          left join public.taxa t on t.col_id = p.col_id
          left join col.mappa_nuovi n on n.col_id = p.col_id
          left join col.mappa_locali l on l.nome = p.taxon_locale
         order by p.vecchio_slug, p.origine) to stdout with (format csv, header)" > "$DIR/mappa/mappa.csv"
manifesto "$DIR/mappa" locali.csv 0
manifesto "$DIR/mappa" mappa.csv 0
senza=$(python3 -c 'import csv, sys; print(sum(1 for r in csv.DictReader(open(sys.argv[1], encoding="utf-8")) if not r["taxon_id"] and r["esito"] != "non trovato"))' "$DIR/mappa/mappa.csv")
[ "$senza" = 0 ] || { echo "Righe di mappa senza taxon e con un esito diverso da 'non trovato': $senza" >&2; exit 1; }
cut -f1,2 "$DIR/taxa/manifest.tsv" "$DIR/mappa/manifest.tsv"
echo "base $(cat "$DIR/taxa/base.txt"), regni $(cat "$DIR/taxa/regni.txt")"
