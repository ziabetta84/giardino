#!/usr/bin/env python3
"""Scrive la migration dei taxon nuovi per le pagine RHS e il suo rollback, dal CSV esportato da rhs_taxa_nuovi.sh.

Uso: python3 -I rhs_taxa_nuovi_scrivi.py NUOVI.csv MIGRATION_BASE ROLLBACK.sql
  MIGRATION_BASE senza estensione: un file MIGRATION_BASE.sql, oppure AAAAMMGGhhmmss_nome_1.sql, poi la parte 2 con la versione +100 (…120100_nome_2.sql), se supera ~1,9 MB.

Ogni file della migration è un solo blocco DO (atomico anche fuori da una transazione): rifiuta tutto se uno dei col_id
è già in taxa, inserisce, poi controlla il conteggio cumulativo e che ogni padre e accettato sia risolto. Padri e
accettati si cercano per col_id al momento dell'applicazione (in taxa o tra le righe dello stesso file): le righe sono in
ordine di profondità, quindi un padre è sempre nello stesso file o in uno precedente.
"""
import csv
import sys

NOTA = "importato dal controllo RHS (23/11/2026)"
VERSIONE = "COL26.9 XR"
LIMITE = 1_900_000


def q(v):
    return "null" if v in (None, "") else "'" + v.replace("'", "''") + "'"


righe = list(csv.DictReader(open(sys.argv[1], encoding="utf-8")))
base, rollback = sys.argv[2], sys.argv[3]
per_col = {r["col_id"]: r for r in righe}
prof = {}


def profondita(c):
    if c in prof:
        return prof[c]
    r = per_col[c]
    rif = r["padre_col"] or r["accettato_col"]
    prof[c] = 0 if rif not in per_col else profondita(rif) + 1
    return prof[c]


import sys as _s
_s.setrecursionlimit(10000)
righe.sort(key=lambda r: (profondita(r["col_id"]), r["col_id"]))

valori = [
    "(" + ", ".join(q(r[k]) for k in ("id", "col_id", "rango", "nome_scientifico", "autore", "notho", "stato",
                                       "padre_col", "accettato_col")) + ")"
    for r in righe
]
lotti, corrente, dim = [], [], 0
for v in valori:
    if corrente and dim + len(v) > LIMITE:
        lotti.append(corrente)
        corrente, dim = [], 0
    corrente.append(v)
    dim += len(v) + 3
lotti.append(corrente)

conteggi = {}
for r in righe:
    conteggi[r["origine"]] = conteggi.get(r["origine"], 0) + 1
riepilogo = ", ".join(f"{k.split(' ', 1)[1]} {v}" for k, v in sorted(conteggi.items()))
cumulato = 0
for i, lotto in enumerate(lotti, 1):
    cumulato_prima = cumulato
    cumulato += len(lotto)
    # ogni parte ha una versione sua (Supabase registra le migration per versione): 120000, 120100, ...
    cartella, _, file_base = base.rpartition("/")
    versione, _, resto = file_base.partition("_")
    versione = str(int(versione) + (i - 1) * 100)
    nome = f"{cartella}/{versione}_{resto}.sql" if len(lotti) == 1 else f"{cartella}/{versione}_{resto}_{i}.sql"
    parte = "" if len(lotti) == 1 else f" (parte {i} di {len(lotti)}, da applicare in ordine)"
    with open(nome, "w", encoding="utf-8") as f:
        f.write(f"""-- Taxon di Catalogue of Life (COL26.9 XR) per le pagine RHS senza taxon{parte}.
-- In tutto {len(righe)} righe nuove di public.taxa ({riepilogo}), nota '{NOTA}':
-- gli accettati dei nomi RHS trovati in COL (scripts/rhs-import/dati/col_abbinamenti_rhs_assenti.tsv), la catena dei
-- padri fino a un taxon già presente, i sinonimi degli accettati e dei generi nuovi (regole della fase 2).
-- Generata da scripts/rhs-import/rhs_taxa_nuovi.sh; pagine RHS → accettato in scripts/rhs-import/dati/rhs_taxa_nuovi_pagine.tsv.
-- Un solo blocco: se uno dei col_id è già in taxa non scrive nulla. Rollback: scripts/rhs-import/rollback_rhs_taxa_nuovi.sql
do $migrazione$
declare n bigint;
begin
  create temp table rhs_nuovi (id uuid primary key, col_id text not null unique, rango text not null,
    nome_scientifico text not null, autore text, notho text, stato text not null, padre_col text, accettato_col text);
  insert into rhs_nuovi values
{(','+chr(10)).join('    ' + v for v in lotto)};

  select count(*) into n from rhs_nuovi r join public.taxa t on t.col_id = r.col_id or t.id = r.id;
  if n > 0 then raise exception 'taxon già presenti in taxa: %, nessuna scrittura', n; end if;
  select count(*) into n from public.taxa where nota = '{NOTA}';
  if n <> {cumulato_prima} then raise exception 'righe con questa nota già in taxa: % (attese {cumulato_prima})', n; end if;

  insert into public.taxa (id, origine, col_id, versione_col, rango, nome_scientifico, autore, notho, stato,
                           accettato_id, padre_id, nota)
  select r.id, 'col', r.col_id, '{VERSIONE}', r.rango, r.nome_scientifico, r.autore, r.notho, r.stato,
         case when r.accettato_col is not null then coalesce(na.id, ta.id) end,
         case when r.padre_col is not null then coalesce(np.id, tp.id) end,
         '{NOTA}'
    from rhs_nuovi r
    left join rhs_nuovi np on np.col_id = r.padre_col
    left join public.taxa tp on tp.col_id = r.padre_col
    left join rhs_nuovi na on na.col_id = r.accettato_col
    left join public.taxa ta on ta.col_id = r.accettato_col;

  select count(*) into n from public.taxa where nota = '{NOTA}';
  if n <> {cumulato} then raise exception 'conteggio inatteso: % righe (attese {cumulato})', n; end if;
  select count(*) into n from public.taxa t join rhs_nuovi r on r.id = t.id
   where (r.padre_col is not null and t.padre_id is null) or (r.accettato_col is not null and t.accettato_id is null)
      or (t.stato in ('accepted', 'provisionally accepted') and t.padre_id is null);
  if n > 0 then raise exception 'taxon nuovi con padre o accettato non risolto: %', n; end if;
  drop table rhs_nuovi;
end
$migrazione$;
""")
    print(f"{nome}: {len(lotto)} righe")

col_ids = [r["col_id"] for r in righe]
with open(rollback, "w", encoding="utf-8") as f:
    f.write(f"""-- Rollback dei taxon aggiunti per le pagine RHS (supabase/migrations/20261123120000_rhs_taxa_nuovi_1.sql e 20261123120100_rhs_taxa_nuovi_2.sql).
-- Toglie le {len(righe)} righe con nota '{NOTA}' e col_id dell'elenco qui sotto. Rifiutato se una scheda, una
-- cultivar, una pianta, un nome comune o una riga di mappa_specie punta a uno di questi taxa, se un altro taxon li usa
-- come padre o accettato, o se le righe non sono esattamente quelle attese.
-- Uso: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/rhs-import/rollback_rhs_taxa_nuovi.sql (poi vacuum di public.taxa)
do $rollback$
declare n bigint;
begin
  create temp table rhs_via (col_id text primary key);
  insert into rhs_via values
{(','+chr(10)).join("    (" + q(c) + ")" for c in col_ids)};
  create temp table rhs_via_id as
    select t.id from public.taxa t join rhs_via v on v.col_id = t.col_id where t.nota = '{NOTA}';
  select count(*) into n from rhs_via_id;
  if n <> {len(righe)} then raise exception 'trovate % righe da togliere, attese {len(righe)}', n; end if;
  select count(*) into n from public.taxa where nota = '{NOTA}';
  if n <> {len(righe)} then raise exception 'in taxa ci sono % righe con la nota, attese {len(righe)}', n; end if;
  select (select count(*) from public.schede where taxon_id in (select id from rhs_via_id))
       + (select count(*) from public.cultivar where taxon_id in (select id from rhs_via_id))
       + (select count(*) from public.piante where taxon_id in (select id from rhs_via_id))
       + (select count(*) from public.nomi_comuni where taxon_id in (select id from rhs_via_id))
       + (select count(*) from public.mappa_specie where taxon_id in (select id from rhs_via_id)) into n;
  if n > 0 then raise exception 'righe che puntano ai taxa da togliere: %, rollback rifiutato', n; end if;
  select count(*) into n from public.taxa t
   where t.id not in (select id from rhs_via_id)
     and (t.padre_id in (select id from rhs_via_id) or t.accettato_id in (select id from rhs_via_id));
  if n > 0 then raise exception 'altri taxon usano questi come padre o accettato: %, rollback rifiutato', n; end if;
  delete from public.taxa where id in (select id from rhs_via_id);
  drop table rhs_via_id;
  drop table rhs_via;
end
$rollback$;
""")
print(f"{rollback}: {len(col_ids)} col_id")
