# Modello tassonomico, fase 6: l'app legge il nuovo catalogo — piano di implementazione

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** l'app (store, selettore, pagina pianta, ricerca, fallback offline) e le istruzioni di `/zorbadice` leggono `taxa`, `nomi_comuni`, `cultivar` e `schede` invece di `specie`; le piante nuove si collegano a un taxon o a una cultivar.

**Architecture:** il nome mostrato, l'eredità campo per campo e la ricerca si calcolano nel database con funzioni di sola lettura eseguite con i permessi di chi chiama (vedono solo le colonne pubbliche: le fonti restano protette). L'app chiede le «voci» del catalogo (una per taxon o cultivar, chiave `t:<uuid>` o `c:<uuid>`) e le tiene nello store in `store.catalogo`, con la stessa forma dei campi di oggi (`nome`, `specie`, `descrizione`, `esigenze`, `manutenzione`, `coltivazione`…), così le viste cambiano solo il modo di trovarle. `specie` e `generi` non si toccano.

**Tech Stack:** Postgres 17 su Supabase (plpgsql, PostgREST RPC), Vue 3 + Pinia, supabase-js, vite-plugin-pwa (Workbox), `node --test` per la logica pura.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md` (Regole di presentazione; Decisioni per la fase 4, punti 2, 3, 4, 14, 22; Fasi, punto 6).

## Global Constraints

- Nel frontend la fonte non si nomina mai (nemmeno «Wikimedia Commons»); unica eccezione l'attribuzione della foto richiesta dalla licenza (TASL: titolo fino alla 3.0, autore, link alla pagina del file, licenza con link).
- Nome mostrato di un taxon: nome comune preferito in italiano, altrimenti nome scientifico canonico. Nessun nome inventato.
- Nome mostrato di una cultivar: preferito della specie o, se manca, del genere + `'Epiteto'`, solo se quel nome non è preferito di un taxon di un'altra linea; altrimenti nome scientifico + `'Epiteto'`. L'epiteto non si traduce mai.
- Eredità campo per campo: cultivar → grex → taxon accettato → padri fino al genere compreso; solo schede `mostrata`; le schede non idonee non sono mai mostrate né ereditate.
- Le funzioni non leggono mai `fonti`, `nota`, `descrizione_originale`, `verificata_da`, `vecchia_specie_id`, `col_id`, `versione_col`, `origine`: con la chiave pubblica darebbero errore, ed è la prova che restano interne.
- Nessuna applicazione al database reale senza il via esplicito dell'utente in chat; nessun push senza richiesta.
- Mai stampare l'URL del database o la password; processi solo con `pgrep -f`; solo la porta 5432 (`SUPABASE_DB_URL` di `.env.local`).
- Prove sulla copia locale (porta 55440, `~/giardino-dati/copie/fase5`), mai in una transazione sul reale.
- Testi dell'interfaccia in italiano.

## Decisioni da approvare (proposte, con la ragione)

1. **Calcolo nel database.** Tre funzioni pubbliche di sola lettura: `catalogo_mie_piante()` (le voci delle piante di chi chiama, filtrate dall'RLS di `piante`), `catalogo_voci(chiavi)` (al più 200 voci) e `cerca_catalogo(q)`; le funzioni di servizio stanno nello schema `catalogo`, che PostgREST non espone. Ragione: nome, ambiguità ed eredità richiedono la catena dei padri; farlo nel browser vorrebbe decine di richieste per pianta.
2. **Campi vuoti:** un jsonb con soli valori nulli o vuoti (gli scheletri di PFAF) conta come vuoto e lascia ereditare il livello sopra (come la decisione 3 della fase 4 per la completezza).
3. **Livello indicato:** quando un campo viene da un livello sopra, la pagina lo dice con una riga sola, per esempio «Descrizione del genere *Hedera*» o «Cure della specie *Carex oshimensis*». Nessuna fonte.
4. **Selettore a campo vuoto:** mostra le voci delle tue piante («Nel tuo giardino»), non più un migliaio di specie verificate prese a caso. Da 2 caratteri cerca in tutto il catalogo.
5. **Offline:** l'app non usa più `specie.json` (resta nel repository fino alla fase 7). Le voci delle tue piante restano consultabili offline grazie alla cache del service worker (richiesta GET); la ricerca è solo online (richiesta POST, mai in cache: oggi le ricerche riempivano la cache e potevano scacciare i dati delle piante). Cache portata da 20 a 40 indirizzi.
6. **Varietà nel titolo:** se la pianta è collegata a una cultivar, il titolo non ripete la varietà scritta a mano (eviterebbe «Echinacea 'Meditation Pink' Meditation Pink»); la varietà resta nel modulo di modifica.
7. **Piante nuove e vincolo:** le piante nuove salvano `taxon_id` o `cultivar_id` e lasciano vuota `specie`; cambiando la voce di una pianta esistente anche la sua `specie` si svuota (non sarebbe più vera). Nella stessa migration `piante.specie` diventa facoltativa e il vincolo passa a «esattamente uno» (spec, `piante`). Conseguenza: tra l'applicazione e il push, nell'app pubblicata non si possono aggiungere piante (errore visibile, nessun dato perso).
8. **Credito della foto:** «Foto: Autore, licenza» con l'autore che porta alla pagina del file e la licenza alla sua pagina; per le licenze fino alla 3.0 anche il titolo del file. Tolto «/ Wikimedia Commons».
9. **Notogeneri senza ×** (× *Fatshedera*…, rinviati dalla fase 3): il nome si mostra come lo scrive COL, senza aggiungere il segno.
10. **Gruppo e nome commerciale:** righe a parte sotto il titolo («Gruppo Capitata Group», «In commercio come Brakelights»); il nome mostrato resta nome + `'Epiteto'`. Grex e Gruppi (categorie) si mostrano come nome + epiteto, senza apici.
11. **Richieste a Zorba:** le nuove `revisione_specie` salvano la chiave della voce (`voce`) e il nome (`nome_voce`); le 2 vecchie ricevono il nome a mano, così lo storico non mostra uno slug.
12. **`/zorbadice`:** legge il catalogo dalle tabelle nuove; `revisione_specie` scrive sulla scheda mostrata della voce o, se manca, crea una scheda mostrata sul taxon accettato o sulla cultivar; `specie` non si scrive più.
13. **Ricerca:** nomi comuni italiani (tutti), nomi scientifici dal genere in giù compresi i sinonimi (la riga dice «sinonimo «…»» e porta all'accettato), epiteti e nomi commerciali delle cultivar, e «nome + epiteto» («carex evergold», «edera glacier»); apici dritti e curvi ignorati. Prima i taxon, poi le cultivar; al più 30 risultati.

## Review Focus

- La pianta collegata a un sinonimo (5 piante: *Gaura lindheimeri*, *Pisum sativum*, *Citrus × sinensis*, *Pennisetum alopecuroides*, *Sansevieria*): deve mostrare nome e scheda dell'accettato e «Già nota come …»; coperto dalla prova dei nomi attesi (Task 1) e dal controllo nel browser (Task 8).
- La cultivar su un taxon sinonimo (*Sedum spurium* 'Tricolor', 3 piante): il nome si calcola sull'accettato; coperto dai nomi attesi.
- Una voce senza nessuna scheda (taxon di COL senza contenuto): la pagina non deve rompersi né mostrare sezioni vuote; prova in Task 1 (voce di un genere senza schede) e controllo nel browser.
- Ricerca con caratteri speciali (`%`, `_`, apici curvi, una lettera sola): nessun errore e nessun risultato spurio; prove in Task 1.
- Offline dopo un'apertura online: le piante mostrano ancora nomi e cure (cache GET di `catalogo_mie_piante`); controllo nel browser in Task 8, con la rete disattivata dagli strumenti del browser.

---

### Task 1: funzioni del catalogo nel database, con prove sulla copia locale

**Files:**
- Create: `supabase/migrations/20261021100000_tassonomia_fase6_catalogo.sql`
- Create: `scripts/tassonomia/rollback_fase6.sql`
- Create: `scripts/tassonomia/prova_fase6.sql`, `scripts/tassonomia/prova_fase6.sh`
- Create: `scripts/tassonomia/dati/fase6_nomi_attesi.tsv` (generato da `~/giardino-dati/col/fase6/attesi.py`, fuori dal repository)

**Interfaces:**
- Produces: `public.catalogo_mie_piante() returns jsonb` (oggetto `{chiave: voce}`), `public.catalogo_voci(chiavi text[]) returns jsonb` (stesso formato), `public.cerca_catalogo(q text) returns jsonb` (array di voci con in più `via`, `via_botanico`). Voce: `{chiave, tipo ('taxon'|'cultivar'), categoria, rango, nome, specie, nome_noto, gruppo, nome_commerciale, nomi_alternativi (array), stato_verifica, descrizione, esigenze, manutenzione, coltivazione, ciclo_vitale, vaso, alert (array), immagine, livelli: {campo: {rango, nome}}}`; `livelli` contiene solo i campi ereditati da un livello sopra.

- [ ] **Step 1: i nomi attesi.** Scrivere `~/giardino-dati/col/fase6/attesi.py`, che ricalcola il «Nome che vedrai» approvato dall'utente nella pagina della fase 5 con la stessa logica di `~/giardino-dati/col/fase5/pagina.py` (funzioni `mostrato_taxon` e `mostrato_cultivar`, stessi file `piante.tsv`, `nomi_mostrati.tsv`, `cultivar_candidate.tsv`, stesse tabelle `SICURE`/`PROBABILI`) e scrive `pianta<TAB>nome` per le 122 piante, con l'epiteto corretto ('Piccante Calabresé' → 'Piccante Calabrese'):

```python
#!/usr/bin/env python3
"""Nomi mostrati attesi per le 122 piante (fase 6): quelli approvati dall'utente nella pagina della fase 5."""
import csv, pathlib, runpy, sys
F5 = pathlib.Path.home() / 'giardino-dati/col/fase5'
ns = runpy.run_path(str(F5 / 'pagina.py'))          # rigenera anche la pagina, innocuo
out = pathlib.Path(sys.argv[1])
with open(out, 'w', encoding='utf-8') as f:
    f.write('pianta\tnome\n')
    for r, c, _nota, _prob in ns['A']:
        f.write(f"{r[0]}\t{ns['mostrato_cultivar'](c[3], c[2])}\n")
    for r in ns['B']:
        f.write(f"{r[0]}\t{ns['mostrato_cultivar'](r[15], r[14])}\n")
    for r in ns['C'] + ns['Dd']:
        f.write(f"{r[0]}\t{ns['mostrato_taxon'](r[10], r[13])}\n")
testo = out.read_text(encoding='utf-8').replace('Piccante Calabresé', 'Piccante Calabrese')
out.write_text(testo, encoding='utf-8')
print(len(testo.splitlines()) - 1, 'piante')
```

Run: `python3 ~/giardino-dati/col/fase6/attesi.py scripts/tassonomia/dati/fase6_nomi_attesi.tsv`
Expected: `122 piante`

- [ ] **Step 2: la prova, che fallisce.** Scrivere `scripts/tassonomia/prova_fase6.sql` (un blocco `do` che si ferma al primo controllo fallito; i nomi attesi vengono caricati prima in una tabella temporanea `attesi`):

```sql
-- Prove delle funzioni del catalogo (fase 6) sulla copia locale, con la migration applicata e le piante collegate come
-- dati/fase5_piante.tsv. Errore al primo controllo che fallisce. Lancio: prova_fase6.sh.
create temp table attesi (pianta text primary key, nome text not null);
\copy attesi from 'scripts/tassonomia/dati/fase6_nomi_attesi.tsv' with (format text, header true)
do $$
declare
  n bigint; v jsonb; r record; k text; t0 timestamptz;
begin
  -- jsonb vuoti
  if not (catalogo.vuoto(null) and catalogo.vuoto('null') and catalogo.vuoto('{}') and catalogo.vuoto('[]')
          and catalogo.vuoto('""') and catalogo.vuoto('{"a": null, "b": {"c": null, "d": []}}')) then
    raise exception 'vuoto: un valore vuoto non è riconosciuto';
  end if;
  if catalogo.vuoto('{"a": 0}') or catalogo.vuoto('"x"') or catalogo.vuoto('[false]') then
    raise exception 'vuoto: un valore pieno è preso per vuoto';
  end if;
  -- ogni pianta ha la sua voce, con il nome approvato nella fase 5
  select count(*) into n from public.piante p
   where catalogo.voce(case when p.cultivar_id is not null then 'c:' || p.cultivar_id else 't:' || p.taxon_id end) is null;
  if n > 0 then raise exception 'piante senza voce: %', n; end if;
  for r in select p.id, a.nome atteso,
                  catalogo.voce(case when p.cultivar_id is not null then 'c:' || p.cultivar_id else 't:' || p.taxon_id end) ->> 'nome' trovato
             from public.piante p join attesi a on a.pianta = p.id loop
    if r.trovato is distinct from r.atteso then raise exception 'pianta %: nome «%» invece di «%»', r.id, r.trovato, r.atteso; end if;
  end loop;
  select count(*) into n from public.piante p join attesi a on a.pianta = p.id;
  if n <> 122 then raise exception 'nomi attesi confrontati: % invece di 122', n; end if;
  -- catalogo_mie_piante (qui senza RLS: tutte le piante) dà una voce per chiave
  select count(*) into n from jsonb_object_keys(public.catalogo_mie_piante());
  if n <> (select count(distinct coalesce(cultivar_id, taxon_id)) from public.piante) then
    raise exception 'catalogo_mie_piante: % voci', n;
  end if;
  -- sinonimo: nome e scheda dell'accettato, e il nome con cui la pianta era conosciuta
  v := catalogo.voce('t:' || (select id from public.taxa where nome_scientifico = 'Gaura lindheimeri' and stato = 'synonym' limit 1));
  if v ->> 'specie' <> 'Oenothera lindheimeri' or v ->> 'nome_noto' <> 'Gaura lindheimeri' then
    raise exception 'sinonimo: specie %, nome_noto %', v ->> 'specie', v ->> 'nome_noto';
  end if;
  -- cultivar senza scheda propria: i campi vengono dal taxon, con il livello indicato
  select c.id into k from public.cultivar c where c.slug = 'carex-oshimensis-evergold';
  v := catalogo.voce('c:' || k);
  if exists (select 1 from public.schede where cultivar_id = k::uuid and mostrata) then
    raise exception 'la prova presuppone che carex-oshimensis-evergold non abbia una scheda propria';
  end if;
  if v ->> 'descrizione' is null or v #>> '{livelli,descrizione,rango}' <> 'species'
     or v #>> '{livelli,descrizione,nome}' <> 'Carex oshimensis' then
    raise exception 'eredità della cultivar: %', v -> 'livelli';
  end if;
  if v ->> 'tipo' <> 'cultivar' or v ->> 'specie' <> 'Carex oshimensis ''Evergold''' then
    raise exception 'cultivar: tipo %, specie %', v ->> 'tipo', v ->> 'specie';
  end if;
  -- un taxon con la scheda propria non indica livelli per la descrizione
  v := catalogo.voce('t:' || (select taxon_id from public.schede where mostrata and taxon_id is not null and descrizione is not null limit 1));
  if v -> 'livelli' ? 'descrizione' then raise exception 'livello indicato per una descrizione propria'; end if;
  -- schede non idonee: mai usate, nemmeno quando sono l'unica scheda del taxon
  select s.taxon_id, s.descrizione into r from public.schede s
   where s.taxon_id is not null and s.descrizione is not null
     and not exists (select 1 from public.schede m where m.taxon_id = s.taxon_id and m.mostrata) limit 1;
  v := catalogo.voce('t:' || r.taxon_id);
  if v ->> 'descrizione' is not distinct from r.descrizione and not (v -> 'livelli' ? 'descrizione') then
    raise exception 'scheda non idonea usata come propria per %', r.taxon_id;
  end if;
  -- un genere senza nessuna scheda: voce con il nome e senza campi
  v := catalogo.voce('t:' || (select t.id from public.taxa t where t.rango = 'genus' and t.stato = 'accepted'
                                and not exists (select 1 from public.schede s where s.taxon_id = t.id) limit 1));
  if v ->> 'nome' is null or v ? 'descrizione' then raise exception 'genere senza schede: %', v; end if;
  -- ambiguità (decisione 22): stesso nome su genere e specie non è ambiguo; su un'altra linea sì
  select c.id into k from public.cultivar c join public.taxa t on t.id = c.taxon_id
   where t.nome_scientifico = 'Lavandula angustifolia' and c.categoria = 'cultivar' order by c.slug limit 1;
  v := catalogo.voce('c:' || k);
  if v ->> 'nome' not like 'Lavanda ''%''' then raise exception 'lavanda: %', v ->> 'nome'; end if;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti)
    select t.id, 'it', 'Lavanda', true, '{prova}' from public.taxa t
     where t.nome_scientifico = 'Rosa canina' and t.stato = 'accepted'
       and not exists (select 1 from public.nomi_comuni n where n.taxon_id = t.id and n.lingua = 'it' and n.preferito);
    if not found then raise exception 'la prova di ambiguità presuppone Rosa canina senza preferito'; end if;
    v := catalogo.voce('c:' || k);
    if v ->> 'nome' not like 'Lavandula angustifolia ''%''' then raise exception 'ambiguo non riconosciuto: %', v ->> 'nome'; end if;
    raise sqlstate 'P0099';
  exception when sqlstate 'P0099' then null;
  end;
  -- Gruppo come categoria
  v := catalogo.voce('c:' || (select id from public.cultivar where slug = 'brachyglottis-dunedin-hybrids'));
  if v ->> 'nome' not like '% Dunedin Group' or v ->> 'categoria' <> 'gruppo' then raise exception 'gruppo: %', v ->> 'nome'; end if;
  -- ricerca
  for r in select * from (values
      ('rosmarino', 't', 'Salvia rosmarinus', null::text),
      ('Rosmarinus officinalis', 't', 'Salvia rosmarinus', 'Rosmarinus officinalis'),
      ('evergold', 'c', 'Carex oshimensis ''Evergold''', null),
      ('‘Evergold’', 'c', 'Carex oshimensis ''Evergold''', null),
      ('carex evergold', 'c', 'Carex oshimensis ''Evergold''', null)
    ) x(q, tipo, specie, via) loop
    select count(*) into n from jsonb_array_elements(public.cerca_catalogo(r.q)) e
     where e ->> 'specie' = r.specie and left(e ->> 'chiave', 1) = r.tipo and (r.via is null or e ->> 'via' = r.via);
    if n <> 1 then raise exception 'ricerca «%»: % risultati per %', r.q, n, r.specie; end if;
  end loop;
  if jsonb_array_length(public.cerca_catalogo('%')) <> 0 or jsonb_array_length(public.cerca_catalogo('a')) <> 0
     or jsonb_array_length(public.cerca_catalogo('')) <> 0 or jsonb_array_length(public.cerca_catalogo(null)) <> 0 then
    raise exception 'ricerca troppo corta o con soli caratteri speciali: risultati non vuoti';
  end if;
  perform public.cerca_catalogo('a_b%c');
  t0 := clock_timestamp();
  if jsonb_array_length(public.cerca_catalogo('rosa')) not between 1 and 30 then raise exception 'ricerca «rosa»: troppi o nessun risultato'; end if;
  if clock_timestamp() - t0 > interval '3 seconds' then raise exception 'ricerca «rosa» lenta: %', clock_timestamp() - t0; end if;
  if (select count(*) from jsonb_object_keys(public.catalogo_voci(array(select 't:' || id from public.taxa limit 300)))) > 200 then
    raise exception 'catalogo_voci accetta più di 200 chiavi';
  end if;
  if public.catalogo_voci(array['x', 't:non-uuid', 'c:00000000-0000-0000-0000-000000000000']) <> '{}' then
    raise exception 'chiavi non valide: risultato non vuoto';
  end if;
  -- permessi: con il ruolo pubblico le funzioni girano (non leggono colonne interne)
  execute 'set local role anon';
  perform public.catalogo_voci(array['c:' || k]);
  perform public.cerca_catalogo('evergold');
  execute 'reset role';
  raise notice 'PROVA CATALOGO OK';
end $$;
```

Scrivere `scripts/tassonomia/prova_fase6.sh` sul modello di `prova_fase5.sh` (stessa guardia sull'URL locale, stesso `PSQL`, `fallita()`):

```bash
#!/usr/bin/env bash
# Prove della fase 6 (funzioni del catalogo) sulla copia locale: migration, prova delle funzioni, rollback rifiutato se
# una pianta non ha più la vecchia specie, rollback, di nuovo la migration. Serve la public.piante minima collegata di
# prova_fase5.sh (lanciarla prima).
# Uso: bash scripts/tassonomia/prova_fase6.sh URL_COPIA      Uscita 0 e ultima riga PROVE FASE 6 OK = riuscite.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
D=scripts/tassonomia
M=supabase/migrations/20261021100000_tassonomia_fase6_catalogo.sql
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
funzioni() { "${PSQL[@]}" -tAc "select count(*) from pg_proc where proname in ('catalogo_voci', 'catalogo_mie_piante', 'cerca_catalogo')"; }
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.piante where num_nonnulls(taxon_id, cultivar_id) = 1')" = 122 ] \
  || fallita preparazione "le piante della copia non sono collegate: lanciare prima prova_fase5.sh"
[ "$(funzioni)" = 0 ] || fallita preparazione "funzioni già presenti"

out=$("${PSQL[@]}" -1 -f $M 2>&1) || fallita migration "$out"
out=$("${PSQL[@]}" -f $D/prova_fase6.sql 2>&1) || fallita catalogo "$out"
grep -qF 'PROVA CATALOGO OK' <<<"$out" || fallita catalogo "$out"
echo "PROVA catalogo OK"

out=$("${PSQL[@]}" -c 'begin' -c "update public.piante set specie = null where id = (select min(id) from public.piante)" \
      -f $D/rollback_fase6.sql 2>&1) && fallita rollback "accettato con una pianta senza vecchia specie"
grep -qF 'Rollback fase 6 rifiutato' <<<"$out" || fallita rollback "$out"
"${PSQL[@]}" -1 -f $D/rollback_fase6.sql
[ "$(funzioni)" = 0 ] || fallita rollback "funzioni ancora presenti"
[ "$("${PSQL[@]}" -tAc "select is_nullable from information_schema.columns where table_name = 'piante' and column_name = 'specie'")" = NO ] \
  || fallita rollback "specie ancora facoltativa"
out=$("${PSQL[@]}" -1 -f $M 2>&1) || fallita rilancio "$out"
[ "$(funzioni)" = 3 ] || fallita rilancio "funzioni: $(funzioni)"
echo "PROVA rollback OK"
echo "PROVE FASE 6 OK"
```

Run: `bash scripts/tassonomia/prova_fase6.sh postgresql://postgres@127.0.0.1:55440/postgres`
Expected: FAIL, `PROVA migration FALLITA` (la migration non esiste ancora).

- [ ] **Step 3: la migration.** Scrivere `supabase/migrations/20261021100000_tassonomia_fase6_catalogo.sql`:

```sql
-- Fase 6 del modello tassonomico: l'app legge il nuovo catalogo. Funzioni di sola lettura, eseguite con i permessi di
-- chi chiama (security invoker): leggono solo colonne pubbliche di taxa, nomi_comuni, cultivar e schede, mai fonti,
-- note o identificatori interni. Le funzioni di servizio stanno nello schema catalogo, che PostgREST non espone.
-- piante.specie diventa facoltativa (le piante nuove si collegano solo a un taxon o a una cultivar) e il collegamento
-- diventa obbligatorio: esattamente uno tra taxon_id e cultivar_id (spec, sezione piante). Rollback:
--   psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase6.sql
-- Piano: docs/superpowers/plans/2026-10-20-modello-tassonomico-fase6-app.md
create schema catalogo;
revoke all on schema catalogo from public;
grant usage on schema catalogo to anon, authenticated;

-- Vuoto: null, testo vuoto, oppure oggetto o array fatto solo di valori vuoti (gli scheletri di PFAF)
create function catalogo.vuoto(v jsonb) returns boolean language plpgsql immutable set search_path = '' as $$
begin
  if v is null then return true; end if;
  case jsonb_typeof(v)
    when 'null' then return true;
    when 'string' then return btrim(v #>> '{}') = '';
    when 'object' then return not exists (select 1 from jsonb_each(v) e where not catalogo.vuoto(e.value));
    when 'array' then return not exists (select 1 from jsonb_array_elements(v) e(x) where not catalogo.vuoto(e.x));
    else return false;
  end case;
end $$;

-- Ranghi dal genere in giù (vocabolario di COL): quelli che la catena attraversa e che la ricerca mostra
create function catalogo.sotto_genere(rango text) returns boolean language sql immutable set search_path = '' as $$
  select rango in ('genus', 'subgenus', 'section botany', 'species aggregate', 'species', 'subspecies', 'variety',
                   'subvariety', 'form', 'subform', 'proles', 'lusus', 'infraspecific name', 'infrasubspecific name')
$$;

create function catalogo.accettato(t uuid) returns uuid language sql stable set search_path = '' as $$
  select coalesce(accettato_id, id) from public.taxa where id = t
$$;

-- Tutti i padri di un taxon nella classificazione (per l'ambiguità dei nomi)
create function catalogo.antenati(t uuid) returns setof uuid language sql stable set search_path = '' as $$
  with recursive a(id, padre, n) as (
    select id, padre_id, 0 from public.taxa where id = t
    union all
    select p.id, p.padre_id, a.n + 1 from a join public.taxa p on p.id = a.padre where a.n < 40
  )
  select id from a where id <> t
$$;

-- Catena dell'eredità di un taxon: l'accettato (ord 0), poi i padri fino al genere compreso
create function catalogo.catena(t uuid) returns table (ord int, id uuid, rango text, nome_scientifico text)
language sql stable set search_path = '' as $$
  with recursive c(ord, id, rango, nome, padre) as (
    select 0, a.id, a.rango, a.nome_scientifico, a.padre_id from public.taxa a where a.id = catalogo.accettato(t)
    union all
    select c.ord + 1, p.id, p.rango, p.nome_scientifico, p.padre_id from c join public.taxa p on p.id = c.padre
     where c.rango <> 'genus' and catalogo.sotto_genere(p.rango) and c.ord < 12
  )
  select ord, id, rango, nome from c
$$;

create function catalogo.preferito(t uuid) returns text language sql stable set search_path = '' as $$
  select nome from public.nomi_comuni where taxon_id = t and lingua = 'it' and preferito
$$;

-- Il nome è preferito anche di un taxon di un'altra linea, né antenato né discendente (decisione 22 della fase 4)
create function catalogo.ambiguo(nome text, t uuid) returns boolean language sql stable set search_path = '' as $$
  select exists (
    select 1 from public.nomi_comuni n
     where n.lingua = 'it' and n.preferito and n.nome = ambiguo.nome and n.taxon_id <> t
       and n.taxon_id not in (select catalogo.antenati(t))
       and t not in (select catalogo.antenati(n.taxon_id)))
$$;

-- Livelli dell'eredità di una voce: la cultivar (ord 0), il suo grex (ord 1), poi la catena del suo taxon
create function catalogo.livelli(chiave text) returns table (ord int, tipo text, id uuid, rango text, nome_scientifico text)
language plpgsql stable set search_path = '' as $$
declare
  i uuid; t uuid; g uuid; cat text; sci text; grex text;
begin
  begin
    i := split_part(chiave, ':', 2)::uuid;
  exception when invalid_text_representation then return;
  end;
  if split_part(chiave, ':', 1) = 't' then
    return query select c.ord, 'taxon'::text, c.id, c.rango, c.nome_scientifico from catalogo.catena(i) c;
  elsif split_part(chiave, ':', 1) = 'c' then
    select c.taxon_id, c.grex_id, c.categoria into t, g, cat from public.cultivar c where c.id = i;
    if not found then return; end if;
    select a.nome_scientifico into sci from public.taxa a where a.id = catalogo.accettato(t);
    select c.epiteto into grex from public.cultivar c where c.id = g;
    return query select 0, 'cultivar'::text, i, cat, null::text;
    if g is not null then return query select 1, 'cultivar'::text, g, 'grex'::text, sci || ' ' || grex; end if;
    return query select c.ord + 2, 'taxon'::text, c.id, c.rango, c.nome_scientifico from catalogo.catena(t) c;
  end if;
end $$;

-- Una voce del catalogo: nome mostrato, nome scientifico, campi della scheda ereditati campo per campo
create function catalogo.voce(chiave text) returns jsonb language plpgsql stable set search_path = '' as $$
declare
  i uuid; t uuid; a uuid; a_rango text; a_sci text; noto text; nome text; base text; fornitore uuid;
  cat text; epiteto text; gruppo text; commerciale text; grex text; tipo text; altri jsonb; campi jsonb; livelli jsonb; stato text;
begin
  begin
    i := split_part(chiave, ':', 2)::uuid;
  exception when invalid_text_representation then return null;
  end;
  if split_part(chiave, ':', 1) = 't' then
    tipo := 'taxon'; t := i;
  elsif split_part(chiave, ':', 1) = 'c' then
    tipo := 'cultivar';
    select c.taxon_id, c.categoria, c.epiteto, c.gruppo, c.nome_commerciale, g.epiteto
      into t, cat, epiteto, gruppo, commerciale, grex
      from public.cultivar c left join public.cultivar g on g.id = c.grex_id where c.id = i;
    if not found then return null; end if;
  else
    return null;
  end if;
  a := catalogo.accettato(t);
  if a is null then return null; end if;
  select x.rango, x.nome_scientifico into a_rango, a_sci from public.taxa x where x.id = a;
  select case when x.id <> a then x.nome_scientifico end into noto from public.taxa x where x.id = t;

  if tipo = 'taxon' then
    nome := catalogo.preferito(a);
    if nome is null and a_rango in ('subspecies', 'variety', 'form')
       and split_part(a_sci, ' ', 2) = split_part(a_sci, ' ', 4) then        -- autonimo: il nome della specie
      nome := catalogo.preferito((select x.padre_id from public.taxa x where x.id = a));
    end if;
    nome := coalesce(nome, a_sci);
    select coalesce(jsonb_agg(n.nome order by n.nome), '[]') into altri
      from public.nomi_comuni n where n.taxon_id = a and n.lingua = 'it' and not n.preferito;
  else
    base := catalogo.preferito(a); fornitore := a;
    if base is null and a_rango <> 'genus' then
      select c.id into fornitore from catalogo.catena(a) c where c.rango = 'genus';
      base := catalogo.preferito(fornitore);
    end if;
    if base is not null and catalogo.ambiguo(base, fornitore) then base := null; end if;
    nome := case when cat = 'cultivar' then coalesce(base, a_sci) || coalesce(' ' || grex, '') || ' ''' || epiteto || ''''
                 else coalesce(base, a_sci) || ' ' || epiteto end;
    a_sci := case when cat = 'cultivar' then a_sci || coalesce(' ' || grex, '') || ' ''' || epiteto || ''''
                  else a_sci || ' ' || epiteto end;
    noto := null; altri := '[]';
  end if;

  with l as (select * from catalogo.livelli(chiave)),
  s as (
    select l.ord, l.rango, l.nome_scientifico, s.stato_verifica, s.descrizione, s.esigenze, s.manutenzione, s.ciclo_colturale,
           s.ciclo_vitale, s.vaso, s.alert, s.immagine
      from l join public.schede s on s.mostrata and l.tipo = 'taxon' and s.taxon_id = l.id
    union all
    select l.ord, l.rango, l.nome_scientifico, s.stato_verifica, s.descrizione, s.esigenze, s.manutenzione, s.ciclo_colturale,
           s.ciclo_vitale, s.vaso, s.alert, s.immagine
      from l join public.schede s on s.mostrata and l.tipo = 'cultivar' and s.cultivar_id = l.id
  ),
  e as (
    select s.ord, s.rango, s.nome_scientifico, s.stato_verifica, x.key, x.value
      from s, jsonb_each(jsonb_build_object('descrizione', s.descrizione, 'esigenze', s.esigenze, 'manutenzione', s.manutenzione,
             'coltivazione', s.ciclo_colturale, 'ciclo_vitale', s.ciclo_vitale, 'vaso', s.vaso, 'alert', to_jsonb(s.alert),
             'immagine', s.immagine)) x
     where not catalogo.vuoto(x.value)
  ),
  scelti as (select distinct on (key) * from e order by key, ord)
  select coalesce(jsonb_object_agg(key, value), '{}'),
         coalesce(jsonb_object_agg(key, jsonb_build_object('rango', rango, 'nome', nome_scientifico)) filter (where ord > 0), '{}'),
         max(stato_verifica) filter (where key = 'descrizione')
    into campi, livelli, stato from scelti;

  return campi || jsonb_strip_nulls(jsonb_build_object(
    'chiave', chiave, 'tipo', tipo, 'categoria', cat, 'rango', a_rango, 'nome', nome, 'specie', a_sci, 'nome_noto', noto,
    'gruppo', gruppo, 'nome_commerciale', commerciale, 'stato_verifica', stato))
    || jsonb_build_object('nomi_alternativi', altri, 'livelli', livelli);
end $$;

create function catalogo.voci(chiavi text[]) returns jsonb language sql stable set search_path = '' as $$
  select coalesce(jsonb_object_agg(k, v), '{}')
    from (select k, catalogo.voce(k) v from (select distinct unnest(chiavi) k) u) x where v is not null
$$;

create function public.catalogo_voci(chiavi text[]) returns jsonb language sql stable set search_path = '' as $$
  select catalogo.voci(chiavi[1:200])
$$;

-- Le voci delle piante di chi chiama: l'RLS di piante lascia vedere solo le sue
create function public.catalogo_mie_piante() returns jsonb language sql stable set search_path = '' as $$
  select catalogo.voci(array(
    select distinct case when cultivar_id is not null then 'c:' || cultivar_id else 't:' || taxon_id end
      from public.piante where num_nonnulls(taxon_id, cultivar_id) = 1))
$$;

-- Ricerca: nomi comuni italiani, nomi scientifici dal genere in giù (sinonimi verso l'accettato), epiteti e nomi
-- commerciali delle cultivar, «nome epiteto». Apici ignorati; meno di 2 caratteri utili: nessun risultato.
create function public.cerca_catalogo(q text) returns jsonb language plpgsql stable set search_path = '' as $$
declare
  testo text := btrim(regexp_replace(regexp_replace(coalesce(q, ''), '[''‘’‛`´"“”]', '', 'g'), '\s+', ' ', 'g'));
  pat text; primo text; resto text;
begin
  if length(regexp_replace(testo, '[%_\\\s]', '', 'g')) < 2 then return '[]'; end if;
  pat := '%' || regexp_replace(testo, '([\\%_])', '\\\1', 'g') || '%';
  if position(' ' in testo) > 0 then
    primo := regexp_replace(split_part(testo, ' ', 1), '([\\%_])', '\\\1', 'g') || '%';
    resto := '%' || regexp_replace(substr(testo, position(' ' in testo) + 1), '([\\%_])', '\\\1', 'g') || '%';
  end if;
  return (
    with
    nc as (select n.taxon_id, n.nome, n.preferito from public.nomi_comuni n where n.lingua = 'it' and n.nome ilike pat limit 60),
    tx as (select t.nome_scientifico, t.stato, coalesce(t.accettato_id, t.id) acc from public.taxa t
            where t.nome_scientifico ilike pat and catalogo.sotto_genere(t.rango) limit 60),
    cv as (select c.id from public.cultivar c where c.epiteto ilike pat or c.nome_commerciale ilike pat limit 60),
    cv2 as (select c.id from public.cultivar c
             where resto is not null and c.epiteto ilike resto
               and exists (select 1 from catalogo.catena(c.taxon_id) k
                            where k.nome_scientifico ilike primo
                               or exists (select 1 from public.nomi_comuni n where n.taxon_id = k.id and n.lingua = 'it' and n.nome ilike primo))
             limit 60),
    cand as (
      select 't:' || nc.taxon_id k, case when not nc.preferito then nc.nome end via, false via_botanico, 0 gruppo,
             lower(nc.nome) = lower(testo) esatto from nc
      union all
      select 't:' || tx.acc, case when tx.stato <> 'accepted' then tx.nome_scientifico end, tx.stato <> 'accepted', 0,
             lower(tx.nome_scientifico) = lower(testo) from tx
      union all select 'c:' || cv.id, null, false, 1, false from cv
      union all select 'c:' || cv2.id, null, false, 1, false from cv2
    ),
    uniche as (select distinct on (k) * from cand order by k, (via is null) desc, esatto desc),
    prime as (select * from uniche order by esatto desc, gruppo, (via is null) desc, k limit 30),
    voci as (select p.*, catalogo.voce(p.k) v from prime p)
    select coalesce(jsonb_agg(v || jsonb_strip_nulls(jsonb_build_object('via', via, 'via_botanico', case when via is not null then via_botanico end))
                    order by esatto desc, gruppo, (v ->> 'stato_verifica' = 'verificato') desc nulls last, v ->> 'nome'), '[]')
      from voci where v is not null
  );
end $$;

revoke all on all functions in schema catalogo from public;
grant execute on all functions in schema catalogo to anon, authenticated;
revoke all on function public.catalogo_voci(text[]), public.catalogo_mie_piante(), public.cerca_catalogo(text) from public;
grant execute on function public.catalogo_voci(text[]), public.catalogo_mie_piante(), public.cerca_catalogo(text) to anon, authenticated;

alter table public.piante alter column specie drop not null;
alter table public.piante drop constraint piante_taxon_o_cultivar;
alter table public.piante add constraint piante_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) = 1);
```

Nota: la riga dell'autonimo confronta il secondo e il quarto elemento del nome («*Lavandula angustifolia* subsp. *angustifolia*»).

- [ ] **Step 4: il rollback.** Scrivere `scripts/tassonomia/rollback_fase6.sql`:

```sql
-- Rollback della fase 6: toglie le funzioni del catalogo e rimette piante.specie obbligatoria e il vincolo «al più uno».
-- Rifiutato se una pianta non ha più la vecchia specie (creata o cambiata dall'app nuova): andrebbe prima ricollegata a
-- mano a una riga di specie. Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase6.sql
do $$
declare n bigint;
begin
  select count(*) into n from public.piante where specie is null;
  if n > 0 then raise exception 'Rollback fase 6 rifiutato: % piante senza la vecchia specie', n; end if;
end $$;
drop function public.cerca_catalogo(text), public.catalogo_mie_piante(), public.catalogo_voci(text[]);
drop schema catalogo cascade;
alter table public.piante drop constraint piante_taxon_o_cultivar;
alter table public.piante add constraint piante_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) <= 1);
alter table public.piante alter column specie set not null;
```

- [ ] **Step 5: le prove passano.** Prima `bash scripts/tassonomia/prova_fase5.sh postgresql://postgres@127.0.0.1:55440/postgres` (ricrea le piante collegate sulla copia; attesa `PROVE FASE 5 OK`), poi:

Run: `bash scripts/tassonomia/prova_fase6.sh postgresql://postgres@127.0.0.1:55440/postgres`
Expected: `PROVE FASE 6 OK`. Un nome diverso dall'atteso si esamina uno per uno: se la funzione segue la specifica e la pagina della fase 5 no, si corregge il file dei nomi attesi con una riga nel registro e la differenza va all'utente prima dell'applicazione sul reale.

- [ ] **Step 6: mutazioni.** Due mutazioni a mano sulla copia, ognuna da vedere fallire e poi annullare: (a) in `catalogo.voce` togliere `s.mostrata and` dal primo ramo → la prova delle schede non idonee fallisce; (b) in `catalogo.ambiguo` togliere la condizione sugli antenati → il caso della lavanda fallisce. Ripristinare con il rollback e rilanciare `prova_fase6.sh` fino a `PROVE FASE 6 OK`.

- [ ] **Step 7: Commit**

```bash
git add supabase/migrations/20261021100000_tassonomia_fase6_catalogo.sql scripts/tassonomia/rollback_fase6.sql \
        scripts/tassonomia/prova_fase6.sql scripts/tassonomia/prova_fase6.sh scripts/tassonomia/dati/fase6_nomi_attesi.tsv
git commit -m "Tassonomia fase 6: funzioni del catalogo (voci, eredità campo per campo, ricerca) con prove e rollback"
```

### Task 2: logica pura dell'app (chiavi, credito della foto, livelli)

**Files:**
- Create: `src/utils/catalogo.js`
- Test: `src/utils/catalogo.test.mjs`

**Interfaces:**
- Produces: `chiavePianta(riga) → 't:<uuid>' | 'c:<uuid>' | null`; `colonneDaChiave(chiave) → { taxon_id, cultivar_id } | null`; `slugDaNome(testo) → string`; `creditoFoto(immagine) → { titolo, autore, licenza, pagina, licenzaUrl } | null`; `etichettaLivello(livello) → string` («del genere Hedera»); `varietaNelTitolo(voce, varieta) → string`.

- [ ] **Step 1: il test, che fallisce.** `src/utils/catalogo.test.mjs`:

```js
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { chiavePianta, colonneDaChiave, slugDaNome, creditoFoto, etichettaLivello, varietaNelTitolo } from './catalogo.js'

const U = '0b6c2f4e-1f2a-4c3b-9d8e-7f6a5b4c3d2e'

test('chiave dalla riga di piante', () => {
  assert.equal(chiavePianta({ taxon_id: U, cultivar_id: null }), `t:${U}`)
  assert.equal(chiavePianta({ taxon_id: null, cultivar_id: U }), `c:${U}`)
  assert.equal(chiavePianta({}), null)
})

test('colonne dalla chiave', () => {
  assert.deepEqual(colonneDaChiave(`t:${U}`), { taxon_id: U, cultivar_id: null })
  assert.deepEqual(colonneDaChiave(`c:${U}`), { taxon_id: null, cultivar_id: U })
  assert.equal(colonneDaChiave('hedera-helix'), null)
  assert.equal(colonneDaChiave(''), null)
  assert.equal(colonneDaChiave(null), null)
})

test('slug per l\'id delle piante nuove', () => {
  assert.equal(slugDaNome("Carex oshimensis 'Evergold'"), 'carex-oshimensis-evergold')
  assert.equal(slugDaNome('Citrus × aurantium'), 'citrus-aurantium')
  assert.equal(slugDaNome('Lillà'), 'lilla')
  assert.equal(slugDaNome(''), 'pianta')
})

test('credito della foto secondo la licenza', () => {
  const img = { url: 'https://upload.wikimedia.org/x.jpg', attribuzione: 'Mario Rossi', licenza: 'CC BY-SA 3.0',
    licenza_url: 'https://creativecommons.org/licenses/by-sa/3.0', fonte_pagina: 'https://commons.wikimedia.org/wiki/File:Hedera_helix_01.jpg' }
  assert.deepEqual(creditoFoto(img), { titolo: 'Hedera helix 01', autore: 'Mario Rossi', licenza: 'CC BY-SA 3.0',
    pagina: img.fonte_pagina, licenzaUrl: img.licenza_url })
  assert.equal(creditoFoto({ ...img, licenza: 'CC BY-SA 4.0' }).titolo, null)
  assert.equal(creditoFoto({ ...img, licenza: 'CC BY 2.5' }).titolo, 'Hedera helix 01')
  assert.equal(creditoFoto({ ...img, licenza: 'Public domain' }).titolo, null)
  assert.equal(creditoFoto({ ...img, fonte_pagina: 'https://commons.wikimedia.org/wiki/File:Fiore%20d%27arancio.png' }).titolo, "Fiore d'arancio")
  assert.equal(creditoFoto({ url: 'u' }).autore, null)
  assert.equal(creditoFoto(null), null)
  assert.equal(creditoFoto({}), null)
})

test('etichetta del livello', () => {
  assert.equal(etichettaLivello({ rango: 'genus', nome: 'Hedera' }), 'del genere Hedera')
  assert.equal(etichettaLivello({ rango: 'species', nome: 'Carex oshimensis' }), 'della specie Carex oshimensis')
  assert.equal(etichettaLivello({ rango: 'variety', nome: 'X y var. z' }), 'della varietà X y var. z')
  assert.equal(etichettaLivello({ rango: 'grex', nome: 'Phalaenopsis Abc' }), 'del grex Phalaenopsis Abc')
  assert.equal(etichettaLivello({ rango: 'lusus', nome: 'X' }), 'di X')
  assert.equal(etichettaLivello(null), '')
})

test('varietà nel titolo', () => {
  assert.equal(varietaNelTitolo({ tipo: 'cultivar' }, 'Meditation Pink'), '')
  assert.equal(varietaNelTitolo({ tipo: 'taxon' }, 'nano'), 'nano')
  assert.equal(varietaNelTitolo(null, 'nano'), 'nano')
  assert.equal(varietaNelTitolo({ tipo: 'taxon' }, null), '')
})
```

Run: `node --test src/utils/`
Expected: FAIL, `Cannot find module` per `catalogo.js`.

- [ ] **Step 2: l'implementazione.** `src/utils/catalogo.js` (nessun import con `@/`: deve girare anche con `node --test`):

```js
// Logica pura del catalogo (fase 6 del modello tassonomico): chiavi delle voci, credito delle foto, livelli
// dell'eredità. Una voce è un taxon (chiave "t:<uuid>") o una cultivar ("c:<uuid>"), calcolata nel database
// (funzioni catalogo_* della migration 20261021100000).

export function chiavePianta(riga) {
  if (riga?.cultivar_id) return `c:${riga.cultivar_id}`
  if (riga?.taxon_id) return `t:${riga.taxon_id}`
  return null
}

export function colonneDaChiave(chiave) {
  const [tipo, id] = String(chiave ?? '').split(':')
  if (!id) return null
  if (tipo === 't') return { taxon_id: id, cultivar_id: null }
  if (tipo === 'c') return { taxon_id: null, cultivar_id: id }
  return null
}

// Prima parte dell'id delle piante nuove ("slug-timestamp", come sempre: la galleria usa l'id come cartella)
export function slugDaNome(testo) {
  const slug = String(testo ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')
  return slug || 'pianta'
}

// Attribuzione richiesta dalle licenze Creative Commons (TASL): autore, pagina del file, licenza; il titolo del file
// solo per le licenze fino alla 3.0, che lo chiedono. La fonte (il sito) non si nomina.
export function creditoFoto(immagine) {
  if (!immagine?.url) return null
  const licenza = immagine.licenza ?? null
  const versione = Number(/(\d+(?:\.\d+)?)\s*$/.exec(licenza ?? '')?.[1])
  let titolo = null
  if (versione && versione <= 3 && immagine.fonte_pagina) {
    const file = decodeURIComponent(immagine.fonte_pagina.split('/').pop() ?? '').replace(/^File:/, '')
    titolo = file.replace(/\.[a-z0-9]+$/i, '').replace(/_/g, ' ') || null
  }
  return { titolo, autore: immagine.attribuzione ?? null, licenza, pagina: immagine.fonte_pagina ?? null, licenzaUrl: immagine.licenza_url ?? null }
}

const PREPOSIZIONI = {
  genus: 'del genere', subgenus: 'del sottogenere', 'section botany': 'della sezione', species: 'della specie',
  'species aggregate': 'dell\'aggregato', subspecies: 'della sottospecie', variety: 'della varietà',
  subvariety: 'della sottovarietà', form: 'della forma', subform: 'della sottoforma', grex: 'del grex',
  cultivar: 'della cultivar', gruppo: 'del gruppo',
}

export function etichettaLivello(livello) {
  if (!livello?.nome) return ''
  return `${PREPOSIZIONI[livello.rango] ?? 'di'} ${livello.nome}`
}

// Una pianta collegata a una cultivar ha già la varietà nel nome: non si ripete quella scritta a mano
export function varietaNelTitolo(voce, varieta) {
  return voce?.tipo === 'cultivar' ? '' : (varieta || '')
}
```

- [ ] **Step 3: il test passa.**

Run: `node --test src/utils/`
Expected: `# pass 6`, `# fail 0`.

- [ ] **Step 4: Commit**

```bash
git add src/utils/catalogo.js src/utils/catalogo.test.mjs
git commit -m "Tassonomia fase 6: logica pura del catalogo (chiavi, credito della foto, livelli) con test"
```

### Task 3: lo store legge il catalogo, e tutte le viste che leggevano store.specie

**Files:**
- Modify: `src/stores/dati.js` (tolti `COLONNE_SPECIE`, `mappaSpecie`, `CAMPI_EREDITABILI`, `campoVuoto`, `fondiEredita`, `caricaSpecie`; `mappaPiante` aggiunge `voce`; nuovo stato `catalogo` e funzioni `caricaVoci`, `vocePianta`, `nomePianta`)
- Modify: `src/components/PiantaRiga.vue:13,50-54`, `src/components/DossierPianta.vue:79`, `src/views/AttivitaView.vue:165-166`, `src/views/HomeView.vue:391,438-439`, `src/views/GalleryView.vue:280-283,302-307`, `src/views/IrrigazioneView.vue:165,232`, `src/views/ConcimiView.vue:178-190`, `src/views/PianteView.vue:177,207-213`, `src/composables/useSuggerimentoIrrigazione.js:37-44`, `src/composables/useRichiesteAgente.js:28`, `src/views/AgenteView.vue:111-112`, `src/views/PiantaView.vue:357` (solo la ricerca della voce; il resto della pagina nel Task 5)

**Interfaces:**
- Consumes: `chiavePianta` (Task 2); `catalogo_mie_piante`, `catalogo_voci` (Task 1).
- Produces: `store.catalogo` (`{chiave: voce}`), `store.vocePianta(pianta) → voce | null`, `store.nomePianta(pianta) → string`, `store.caricaVoci(chiavi) → Promise<void>` (scarica solo quelle mancanti), `store.aggiungiVoci(oggetto)`; ogni pianta dello store ha `voce` (la chiave) oltre a `specie`.

- [ ] **Step 1: il controllo, che fallisce.** Il controllo di questo task è che nessun file legga più la vecchia forma e che l'app si costruisca:

Run: `grep -rnE "store\.specie|COLONNE_SPECIE|mappaSpecie|fondiEredita|specie\?\.\[p\.specie\]" src; npm run build 2>&1 | tail -3`
Expected: oggi una ventina di righe trovate (FAIL del controllo).

- [ ] **Step 2: lo store.** In `src/stores/dati.js`: togliere il blocco da `// Pilota Fase 2` fino alla fine di `caricaSpecie` e scrivere al suo posto:

```js
// Catalogo (fase 6 del modello tassonomico): le piante puntano a un taxon o a una cultivar, e il database calcola per
// ognuno una «voce» (nome mostrato, nome scientifico, campi della scheda ereditati campo per campo dal livello sopra,
// vedi la migration 20261021100000_tassonomia_fase6_catalogo.sql). I campi hanno gli stessi nomi di prima (nome,
// specie, descrizione, esigenze, manutenzione, coltivazione…), quindi le viste cambiano solo il modo di trovarla:
// store.vocePianta(p) invece di store.specie[p.specie]. Le voci delle piante si chiedono con una GET (in cache nel
// service worker: restano consultabili offline); specie.json non si usa più.
async function rpcGet(supabase, funzione, argomenti) {
  const { data, error } = await supabase.rpc(funzione, argomenti, { get: true })
  if (error) throw error
  return data ?? {}
}
```

In `mappaPiante` aggiungere, accanto a `specie: p.specie,`, la riga `voce: chiavePianta(p),` (import in testa: `import { chiavePianta } from '@/utils/catalogo'`).

Nello store: sostituire `const specie    = ref(null)` con `const catalogo  = ref(null)`; sostituire il blocco da `// Slug delle specie da caricare subito` fino a `specie.value = await caricaSpecie(slugReferenziati)` con:

```js
      // Voci del catalogo: quelle delle piante (una richiesta, filtrata dall'RLS) più quelle delle richieste di
      // revisione ancora mostrate nello storico di AgenteView. Senza rete e senza cache: catalogo vuoto, le viste
      // mostrano il nome di riserva (nomePianta) invece di rompersi.
      try {
        catalogo.value = await rpcGet(supabase, 'catalogo_mie_piante')
        const chiaviRichieste = Object.values(richiesteData ?? {}).map(r => r.voce).filter(Boolean)
        await caricaVoci(chiaviRichieste)
      } catch (e) {
        console.error('Catalogo non disponibile', e)
        catalogo.value = catalogo.value ?? {}
      }
```

e aggiungere, prima di `async function aggiorna()`:

```js
  function aggiungiVoci(voci) {
    catalogo.value = { ...(catalogo.value ?? {}), ...voci }
  }

  // Scarica le voci che mancano (al più 200 per richiesta, il limite di catalogo_voci)
  async function caricaVoci(chiavi) {
    const mancanti = [...new Set(chiavi.filter(k => k && !catalogo.value?.[k]))]
    for (let i = 0; i < mancanti.length; i += 200) {
      aggiungiVoci(await rpcGet(useSupabase(), 'catalogo_voci', { chiavi: mancanti.slice(i, i + 200) }))
    }
  }

  function vocePianta(pianta) {
    return pianta?.voce ? (catalogo.value?.[pianta.voce] ?? null) : null
  }

  // Nome da mostrare per una pianta; senza voce (offline alla prima apertura) la vecchia specie o «Pianta»
  function nomePianta(pianta) {
    return vocePianta(pianta)?.nome ?? pianta?.specie ?? 'Pianta'
  }
```

e nel `return` dello store sostituire `specie` con `catalogo` e aggiungere `caricaVoci, aggiungiVoci, vocePianta, nomePianta`.

- [ ] **Step 3: le viste.** Sostituzioni una per una (stesso significato, nuova ricerca della voce):
  - `PiantaRiga.vue:50` → `const specie = computed(() => store.vocePianta(props.pianta))`; riga 13 → `{{ store.nomePianta(pianta) }}`.
  - `DossierPianta.vue:79` → `const specie = computed(() => pianta.value ? store.vocePianta(pianta.value) : null)`.
  - `AttivitaView.vue:165-166`, `HomeView.vue:391,438-439`, `GalleryView.vue:280-283`, `ConcimiView.vue:184-190`, `PianteView.vue:177` → `const sp = store.vocePianta(p)` (o `specie` dove la variabile si chiama così) e `const nomeSpecie = store.nomePianta(p)`; in `ConcimiView.vue:178` la condizione `!store.specie` diventa `!store.catalogo`.
  - `GalleryView.vue:302-307` → `const specie = pianta ? store.vocePianta(pianta) : null` e `nomeSpecie: pianta ? store.nomePianta(pianta) : piantaId`.
  - `IrrigazioneView.vue:165` → `return store.nomePianta(p)`; riga 232 → `suggerimentoIrrigazione(pianteCoperte(target), store.catalogo)`.
  - `useSuggerimentoIrrigazione.js`: il secondo parametro diventa `catalogo` (commento a riga 13: «`catalogo` è store.catalogo»), riga 41 → `const sp = catalogo?.[p.voce]`, riga 44 → `const nomeSpecie = sp?.nome ?? p.specie ?? 'Pianta'`. Verificare che `pianteCoperte` passi le piante dello store (con `voce`); se passa altro, ledger.
  - `PianteView.vue:207-213` (ricerca tra le piante): `nomeSpecie = store.nomePianta(p)` e al posto dello slug `p.specie` il nome scientifico `store.vocePianta(p)?.specie ?? p.specie ?? ''`.
  - `useRichiesteAgente.js:28` → `if (r.tipo === 'revisione_specie' && (r.voce || r.specie)) return r.nome_voce ?? store.catalogo?.[r.voce]?.nome ?? r.specie`.
  - `AgenteView.vue:111-112` → `v-if="richiestaSelezionata.voce || richiestaSelezionata.specie"` e `{{ richiestaSelezionata.nome_voce ?? store.catalogo?.[richiestaSelezionata.voce]?.nome ?? richiestaSelezionata.specie }}`.
  - `PiantaView.vue:357` → `pianta.value ? store.vocePianta(pianta.value) : null`.

- [ ] **Step 4: il controllo passa.**

Run: `grep -rnE "store\.specie|COLONNE_SPECIE|mappaSpecie|fondiEredita|specie\?\.\[p\.specie\]" src; npm run build 2>&1 | tail -3 && node --test src/utils/`
Expected: nessuna riga da grep; build riuscita (`✓ built in`); test `# fail 0`. (Il selettore usa ancora le vecchie funzioni: se la build si ferma su `SelettoreSpecie.vue`, questo task si chiude insieme al Task 4, con una riga nel registro.)

- [ ] **Step 5: Commit**

```bash
git add src/stores/dati.js src/components src/views src/composables
git commit -m "Tassonomia fase 6: lo store legge le voci del catalogo, le viste le cercano per pianta"
```

### Task 4: il selettore cerca nel catalogo e le piante si salvano con taxon o cultivar

**Files:**
- Modify: `src/components/SelettoreSpecie.vue` (script: ricerca, voci, dossier; template: righe e credito)
- Modify: `src/views/EditPiantaView.vue:13,78,129,142-155`, `src/composables/usePianteApi.js:21-46,97-112`, `src/views/AgenteView.vue` (creazione della richiesta `revisione_specie`)
- Modify: `public/data/richieste-agente.json` (il campo `nome_voce` sulle 2 vecchie `revisione_specie`)

**Interfaces:**
- Consumes: `cerca_catalogo` (Task 1); `store.catalogo`, `caricaVoci`, `aggiungiVoci` (Task 3); `colonneDaChiave`, `slugDaNome`, `creditoFoto`, `etichettaLivello` (Task 2).
- Produces: `SelettoreSpecie` con `v-model` = chiave della voce; `salvaPianta({ id, isNuova, voce, zona, … })`.

- [ ] **Step 1: il controllo, che fallisce.**

Run: `grep -nE "from\('specie'\)|COLONNE_SPECIE|specie_padre_id|Wikimedia Commons|rinominaSpecieInPiante" src -r; npm run build 2>&1 | tail -3`
Expected: righe trovate in `SelettoreSpecie.vue`, `PiantaView.vue`, `usePianteApi.js` (FAIL).

- [ ] **Step 2: il selettore.** Nello script di `SelettoreSpecie.vue`:
  - import: togliere `mappaSpecie, COLONNE_SPECIE, fondiEredita`; aggiungere `import { creditoFoto, etichettaLivello } from '@/utils/catalogo'`.
  - `riga(v)` trasforma una voce in una riga della tendina:

```js
function riga(v) {
  return {
    key: v.chiave, nome: v.nome, nomeScientifico: v.specie !== v.nome ? v.specie : '',
    viaSinonimo: v.via ?? null, viaBotanico: !!v.via_botanico,
    verificata: v.stato_verifica === 'verificato', immagine: v.immagine ?? null,
    cultivarDi: v.tipo === 'cultivar' ? (v.categoria ?? 'cultivar') : null,
  }
}
```

  - `risultatiRemoti = ref([])` (chiavi nell'ordine del database); `specieFiltrate`: con meno di 2 caratteri, le voci delle piante dell'utente (`Object.values(store.piante ?? {}).map(p => p.voce)`, senza doppioni) ordinate per nome; altrimenti, se `risultatiRemoti` è pieno, quelle voci nell'ordine ricevuto; finché la ricerca non risponde (o offline) il filtro locale sulle voci già nello store (`nome`, `specie`, `nomi_alternativi`, con `normalizzaApici`); al più 30.
  - `slugPossedute` diventa `chiaviPossedute` (le `voce` delle piante), e i gruppi «Nel tuo giardino» / «Nel catalogo» confrontano `s.key` con quelle.
  - `eseguiRicercaRemota(q)`: una sola chiamata `const { data, error } = await supabase.rpc('cerca_catalogo', { q })` (POST: mai in cache), poi `store.aggiungiVoci(Object.fromEntries(data.map(v => [v.chiave, v])))` e `risultatiRemoti.value = data.map(v => v.chiave)`; resta il token contro le risposte fuori ordine e `ricercaOffline` in caso di errore; tolti `escapeIlike` e `risolviEMergeCultivar`.
  - `watch(() => props.modelValue, …)`: se la voce non è nello store, `await store.caricaVoci([val])`.
  - `statoBadge`/`statoBadgeClasse`: per `tipo === 'cultivar'` il badge è `categoria` (`cultivar`, `grex`, `gruppo`) con classe `cv`; altrimenti come oggi su `stato_verifica`.
  - `hero`: `{ thumbUrl, miniUrl, credito: creditoFoto(img) }`.
  - `livelloDescrizione = computed(() => etichettaLivello(specieSelezionata.value?.livelli?.descrizione))`, `livelloCure = computed(() => etichettaLivello(specieSelezionata.value?.livelli?.manutenzione))`.

  Nel template: la riga del credito diventa

```html
<span v-if="hero.credito" class="dh-credit" @click.stop>
  Foto<template v-if="hero.credito.titolo"> «{{ hero.credito.titolo }}»</template>:
  <a v-if="hero.credito.autore" :href="hero.credito.pagina" target="_blank" rel="noopener">{{ hero.credito.autore }}</a><template v-if="hero.credito.autore && hero.credito.licenza">, </template>
  <a v-if="hero.credito.licenza && hero.credito.licenzaUrl" :href="hero.credito.licenzaUrl" target="_blank" rel="noopener">{{ hero.credito.licenza }}</a>
  <template v-else-if="hero.credito.licenza">{{ hero.credito.licenza }}</template>
</span>
```

  sotto `<div class="slabel">La specie</div>` la riga `<p v-if="livelloDescrizione" class="dossier-livello">Descrizione {{ livelloDescrizione }}</p>`, sotto `<div class="slabel">Calendario cure</div>` la riga `<p v-if="livelloCure" class="dossier-livello">Cure {{ livelloCure }}</p>`; le note «Specie verificate — digita…» diventano «Le tue piante — digita per cercare in tutto il catalogo, cultivar inclusi»; nello stile, `.dossier-livello { font: 400 12px/1.4 var(--font-sans); color: var(--ink-soft); margin: -4px 0 8px; }` e le regole di `.dh-credit a { color: inherit; }`.

- [ ] **Step 3: il salvataggio.** `usePianteApi.js`: la firma diventa `salvaPianta({ id, isNuova, voce, zona, sottozona, coltivato_in, varieta, impianto, impianto_circa, note })`; nella riga da scrivere `...colonneDaChiave(voce)` al posto di `specie`, più `specie: null` se la pianta è nuova o se `voce !== store.piante?.[id]?.voce` (la vecchia specie non sarebbe più vera); se `colonneDaChiave(voce)` è `null` lancia `new Error('voce del catalogo mancante')`. Nello store la pianta salvata riceve `voce` e la `specie` scritta (o quella di prima). Togliere `rinominaSpecieInPiante` (nessuno la chiama più: era della vecchia modale di modifica delle specie).
  `EditPiantaView.vue`: `form.specie` → `form.voce` (righe 13, 78, 129: `voce: p.voce ?? ''`, 142); riga 145: `const id = isNuova.value ? \`${slugDaNome(store.catalogo?.[form.value.voce]?.specie)}-${Date.now()}\` : route.params.id`; nel salvataggio `voce: form.value.voce`.
  `AgenteView.vue`: dove si crea la richiesta, per `revisione_specie` salvare `voce: specieSelezionata.value` e `nome_voce: store.catalogo?.[specieSelezionata.value]?.nome ?? null` invece di `specie`.
  `public/data/richieste-agente.json`: alle 2 richieste `revisione_specie` aggiungere `nome_voce` con il nome della vecchia riga di `specie` (lettura in sola lettura sul reale: `select slug, nome from specie where slug in (…)`).

- [ ] **Step 4: il controllo passa.**

Run: `grep -nE "from\('specie'\)|COLONNE_SPECIE|specie_padre_id|rinominaSpecieInPiante" src -r; npm run build 2>&1 | tail -3 && node --test src/utils/`
Expected: nessuna riga (la scritta «Wikimedia Commons» di `PiantaView.vue` va via nel Task 5); build riuscita; test `# fail 0`.

- [ ] **Step 5: Commit**

```bash
git add src/components/SelettoreSpecie.vue src/views/EditPiantaView.vue src/composables/usePianteApi.js src/views/AgenteView.vue public/data/richieste-agente.json
git commit -m "Tassonomia fase 6: il selettore cerca nel catalogo, le piante si salvano con taxon o cultivar"
```

### Task 5: pagina della pianta (nomi, livelli, credito, gruppo)

**Files:**
- Modify: `src/views/PiantaView.vue` (righe 46-53, 65-68, 109-112, 152-166, 257-263, 362-375 e stile)
- Modify: `src/components/DossierPianta.vue` (livello delle cure)

**Interfaces:**
- Consumes: `store.vocePianta` (Task 3), `creditoFoto`, `etichettaLivello`, `varietaNelTitolo` (Task 2).

- [ ] **Step 1: il controllo, che fallisce.**

Run: `grep -nE "Wikimedia Commons|nome_accettato|nomi_alternativi\?*\.split" src -r`
Expected: righe in `PiantaView.vue` (FAIL).

- [ ] **Step 2: la pagina.**
  - Titolo (righe 46 e 65): `{{ store.nomePianta(pianta) }}<i v-if="varietaTitolo">&nbsp;{{ varietaTitolo }}</i>` con `const varietaTitolo = computed(() => varietaNelTitolo(specie.value, pianta.value?.varieta))`.
  - `nomiAlternativi` (riga 369): `const alt = specie.value?.nomi_alternativi; return Array.isArray(alt) ? alt.slice(0, 3).join(', ') : ''`.
  - `nomeAccettato` diventa `nomeNoto = computed(() => specie.value?.nome_noto ?? '')`, e nel template le due righe «Oggi accettata come …» diventano `<p v-if="nomeNoto" class="pbino">Già nota come {{ nomeNoto }}</p>` (e `phead-text__bino`).
  - Sotto le stesse righe: `<p v-if="specie?.gruppo" class="pbino">Gruppo {{ specie.gruppo }}</p>` e `<p v-if="specie?.nome_commerciale" class="pbino">In commercio come {{ specie.nome_commerciale }}</p>`, nelle due intestazioni.
  - Credito (riga 52): lo stesso blocco del Task 4 su `creditoFoto(fotoHero)` (in `fotoHero`, riga 263, passare anche `licenza` e `licenza_url`), classe `phead-credit`.
  - Sezione «La specie»: sotto lo `slabel`, `<p v-if="livelloDescrizione" class="livello">Descrizione {{ livelloDescrizione }}</p>`; sotto lo `slabel` di «Stato cure» `<p v-if="livelloCure" class="livello">Cure {{ livelloCure }}</p>`; `livelloDescrizione`/`livelloCure` come nel Task 4. Stile `.livello` uguale a `.dossier-livello`.
  - `DossierPianta.vue`: la stessa riga `Cure {{ livelloCure }}` sopra le cure.

- [ ] **Step 3: il controllo passa.**

Run: `grep -nE "Wikimedia Commons|nome_accettato|nomi_alternativi\?*\.split" src -r; npm run build 2>&1 | tail -3 && node --test src/utils/`
Expected: nessuna riga; build riuscita; test `# fail 0`.

- [ ] **Step 4: Commit**

```bash
git add src/views/PiantaView.vue src/components/DossierPianta.vue
git commit -m "Tassonomia fase 6: pagina della pianta con nome noto, livelli ereditati, gruppo e credito della foto"
```

### Task 6: cache offline, istruzioni di /zorbadice e documentazione

**Files:**
- Modify: `vite.config.js:70-83`
- Modify: `.claude/commands/zorbadice.md` (righe 52, 54, 60, 89-91, 120-128, 135-137)
- Modify: `CLAUDE.md` (architettura dello store, sezione «Migrazione specie → Supabase», sezione del modello tassonomico, `useCure`)

- [ ] **Step 1: il controllo, che fallisce.**

Run: `grep -nE "tabella .specie.|from specie|update specie" .claude/commands/zorbadice.md | wc -l; grep -c "maxEntries: 20, maxAgeSeconds: 60 \* 60 \* 24 \* 30" vite.config.js`
Expected: più di 0 righe nelle istruzioni; `2` nella configurazione (FAIL).

- [ ] **Step 2: la cache.** Nella regola di Supabase di `vite.config.js`, `maxEntries: 40` e al commento si aggiunge: «Le voci del catalogo delle piante (`rpc/catalogo_mie_piante`, GET) stanno qui e restano consultabili offline; la ricerca (`rpc/cerca_catalogo`) è una POST e non entra mai in cache, così non scaccia i dati delle piante.»

- [ ] **Step 3: /zorbadice.** Riscrivere i punti che citano `specie`:
  - contesto (riga 52): per le piante si legge la voce con `select public.catalogo_voci(array['t:'||taxon_id])` o `'c:'||cultivar_id` (o `catalogo.voce(...)`), che dà nome mostrato, nome scientifico e campi ereditati; per cercare una specie per nome, `select public.cerca_catalogo('…')`; `specie` e `generi` sono l'archivio in sola lettura.
  - `identifica_specie` (righe 89-91): l'NPK di confronto si legge da `manutenzione.npk` della voce trovata con `cerca_catalogo`; non si invita mai a «aggiungere la specie».
  - `revisione_specie` (righe 120-128): la richiesta porta `voce` (nelle vecchie, `specie` = slug: si trova la voce con `select coalesce('c:'||c.id, 't:'||m.taxon_id) from …` su `cultivar.slug` o `mappa_specie.vecchio_slug`); si legge la voce; si scrive sulla scheda mostrata del livello della voce stessa (`schede` con `mostrata` e `taxon_id` = accettato, oppure `cultivar_id`); se manca, si inserisce una scheda nuova con `mostrata = true`, `stato_verifica = 'bozza'`, `fonti = '{"Revisione via /zorbadice — <data>"}'`; `alert` e `fonti` in aggiunta, mai sovrascritti; mai citare la fonte nei testi; `specie` non si scrive più.
  - `consiglio_concimazione` (righe 135-137): la pianta si trova per nome con `catalogo_voci` sulle piante dell'utente; il fabbisogno da `manutenzione.npk` della voce.
  - salvataggio (righe 54, 60): `apply_migration` sulle tabelle `schede`/`progetti`/`tappe`, non più `specie`.

- [ ] **Step 4: CLAUDE.md.** Nell'architettura: `stores/dati.js ← … carica le voci del catalogo delle piante (catalogo_mie_piante) …`, nuova riga `utils/catalogo.js ← chiavi delle voci, credito delle foto, livelli dell'eredità (test: node --test src/utils/)`. Nella sezione delle specie: lettura, fallback e ricerca descritti come fatti storici fino alla fase 6, con il rinvio al paragrafo della fase 6. Nel paragrafo del modello: titolo «fasi 1-6 di 7» e il paragrafo della fase 6 (funzioni, chiavi, decisioni approvate, prove `prova_fase6.sh`, rollback `rollback_fase6.sql`, vincolo «esattamente uno», `specie.json` non più usato).

- [ ] **Step 5: il controllo passa.**

Run: `grep -nE "from specie|update specie" .claude/commands/zorbadice.md; grep -c "maxEntries: 40" vite.config.js; npm run build 2>&1 | tail -3`
Expected: nessuna riga nelle istruzioni (salvo il cenno all'archivio in sola lettura, che non contiene quelle parole); `1`; build riuscita.

- [ ] **Step 6: Commit**

```bash
git add vite.config.js .claude/commands/zorbadice.md CLAUDE.md
git commit -m "Tassonomia fase 6: cache offline delle voci, istruzioni di /zorbadice sul nuovo catalogo, CLAUDE.md"
```

### Task 7: revisione finale (un revisore) e correzioni

- [ ] **Step 1:** pacchetto della revisione (`review-package` della skill) dal commit precedente al Task 1 a HEAD; un solo revisore, sul modello più capace, con il piano, la specifica, la sezione Review Focus e le righe `Ruling:` del registro.
- [ ] **Step 2:** correzioni Critical/Important con una prova che prima fallisce (SQL in `prova_fase6.sql` o JS in `catalogo.test.mjs`), poi `prova_fase6.sh` e `node --test src/utils/` e build verdi; i minori nel registro.

### Task 8: applicazione sul reale e verifica nel browser (solo con il via dell'utente)

**Files:**
- Create: `scripts/tassonomia/verifica_fase6.sql`

- [ ] **Step 1: la verifica.** `scripts/tassonomia/verifica_fase6.sql`, per il reale (sola lettura): carica `dati/fase6_nomi_attesi.tsv`, controlla le 122 piante (una voce ciascuna, nome uguale all'atteso), le tre funzioni presenti, `piante.specie` facoltativa e il vincolo «esattamente uno», `set role anon` → `catalogo_mie_piante()` vuota (o negata) e `cerca_catalogo('rosmarino')` con *Salvia rosmarinus*, `select fonti from schede limit 1` negato; ultima riga `VERIFICA FASE 6 OK`.
- [ ] **Step 2: il via.** Chiedere all'utente il via in chat, con la spiegazione: migration solo additiva (funzioni) più `specie` facoltativa e il vincolo; spazio trascurabile; fino al push l'app pubblicata non può aggiungere piante.
- [ ] **Step 3:** backup completo (`scripts/backup-db.sh`, come nelle fasi precedenti) e impronta di `specie` prima (`scripts/tassonomia/impronta_specie.sql`).
- [ ] **Step 4:** `psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f supabase/migrations/20261021100000_tassonomia_fase6_catalogo.sql`, poi `psql … -f scripts/tassonomia/verifica_fase6.sql` → `VERIFICA FASE 6 OK`; impronta di `specie` dopo, identica.
- [ ] **Step 5: verifica nel browser.** `npm run dev` e, dall'utente, l'elenco: Home, Piante (nomi e ricerca), una pianta su taxon, una su cultivar ('Evergold'), una su sinonimo (Gaura: «Già nota come»), una su genere (Echeveria), Sansevieria (nome e scheda di *Dracaena*); credito della foto con i link; nuova pianta cercando «edera glacier» e poi eliminata; modifica della voce di una pianta e ritorno; richiesta a Zorba di revisione (solo creazione, poi cancellata dallo storico); offline: dopo un'apertura, strumenti del browser → rete disattivata, ricarica: piante con nomi e cure, ricerca con l'avviso offline. Se non ci sono strumenti del browser per me, l'utente riferisce o manda un export HAR.
- [ ] **Step 6:** CLAUDE.md con l'esito e il backup; commit; push solo su richiesta dell'utente (il deploy pubblica l'app nuova).
