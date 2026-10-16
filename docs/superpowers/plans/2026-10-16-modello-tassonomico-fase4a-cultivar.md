# Modello tassonomico — fase 4a: cultivar — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** caricare in `cultivar` le 196.446 righe ricavate dalla vecchia `specie` (196.223 cultivar, 220 grex, 3 Gruppi) con epiteto, Gruppo e nome commerciale riletti dai titoli RHS, più 389 taxon di COL e 167 righe di `mappa_specie` per le cultivar che non diventano righe di `cultivar`.

**Architecture:** la fase 4 è divisa in tre piani: 4a cultivar (questo), 4b schede, 4c nomi comuni e inventario finale. Lo 4b viene dopo perché le schede dei grex e delle 12 cultivar con una descrizione propria puntano a `cultivar`.
1. Una migration aggiunge `cultivar.grex_id` (e `schede.nota`, che serve alla 4b).
2. Uno script Python rilegge i 304.114 titoli delle pagine RHS già scaricate e dà a ogni riga cultivar di `specie` l'epiteto, il Gruppo e il nome commerciale.
3. Sulla copia locale (con COL completo) una query assegna il taxon di ogni cultivar, crea i grex e le righe di mappa, e sceglie le 23 specie da importare da COL.
4. Si esportano i file da caricare; il caricamento sul reale riusa `carica_taxa.sh` della fase 2 per i taxon e un nuovo `carica_cultivar.sh`, tutti e due rilanciabili.

**Tech Stack:** PostgreSQL 17 (Supabase, progetto `ncuhhsvtjwcolhpdxbkt`, piano gratuito; copia locale con i binari in `/opt/homebrew/opt/postgresql@17/bin/`), bash, Python 3 (solo libreria standard).

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md`: sezioni "Modello dati" (`cultivar`, `mappa_specie`), "Regole di presentazione", "Migrazione dei contenuti", "Decisioni sullo spazio" e "Decisioni per la fase 4 (approvate il 16/10/2026)", punti 5 e 15-19. La ricerca, con le misure e gli script, è in `~/giardino-dati/col/ricerca_fase4/` (`cultivar.md`, `cultivar_dati/`, `cultivar_sql/`).

## Global Constraints

- **Righe di `cultivar`** (decisioni 15-19 della fase 4):
  - una per ogni riga di `specie` con l'epiteto tra apici, tranne le righe fuse da più cultivar RHS e quelle senza epiteto leggibile (163), che hanno solo una riga di `mappa_specie` con esito «ambiguo»;
  - più i 220 grex e il Gruppo *Brachyglottis* Dunedin, che vengono da righe non cultivar della fase 3 (decisione 5); la loro riga di mappa resta quella della fase 3;
  - nessuna fusione automatica e nessun vincolo unico su taxon ed epiteto (decisione 18): i doppioni probabili vanno all'utente in un elenco.
- **Epiteto** (decisione 15): dal titolo RHS riletto (ICNCP art. 14.1, 21.4, 32.1), dal nome di `specie` solo dove il titolo manca. Mai tradotto, mai con gli apici.
- **taxon_id** (decisione 16): il taxon più basso noto (ICNCP art. 21.1-21.2), cioè il nome trovato della madre in `mappa_specie`, anche se sinonimo; per le 3.330 cultivar di specie agganciate per errore a una riga "Genere spp." la specie del nome, da `taxa` o da COL (23 specie da importare con le regole della fase 2, `nota = 'importato nella fase 4 (cultivar)'`); mai sopra il genere.
- **Gruppo e nome commerciale** (decisione 19): dai titoli RHS, valori multipli uniti con « | », Gruppo non tradotto, Serie non salvate.
- **Grex** (decisione 5): categoria `grex`, epiteto = nome senza genere e senza "gx"; le cultivar di orchidea figlie di un grex hanno `grex_id`.
- **Cultivar doppie cancellate** (4, dalla migration `20261013110000`): una riga di `mappa_specie` con `origine = 'rollback'`, verso la cultivar gemella.
- **Inserimento:** valori definitivi in un solo passaggio, nessun aggiornamento di massa (specifica, "Decisioni sullo spazio", punto 5); indici secondari costruiti dopo il caricamento; lotti da non più di circa 100 MB di WAL, con pause di 10 minuti sul reale.
- **Solo queste tabelle cambiano:** `taxa` (389 righe in più), `cultivar`, `mappa_specie` (167 righe in più) e lo schema di `cultivar` e `schede` (una colonna ciascuna). L'impronta di `specie` resta identica prima e dopo.
- **Permessi:** `cultivar.grex_id` leggibile dai client come le altre colonne pubbliche di `cultivar`; `schede.nota` no; `fonti` e `vecchia_specie_id` di `cultivar` restano interne.
- **Spazio:**
  - prima di ogni passo sul reale, somma dei database ≤ 400 MB e WAL ≤ 300 MB;
  - attesi circa 86 MB in più (misurati sulla copia: `cultivar` 86 MB con gli indici), cioè circa 357 MB su 500 (oggi 271,0);
  - sopra 450 MB ci si ferma (specifica, "Decisioni sullo spazio", punto 1).
- **Connessione:** sul reale solo `SUPABASE_DB_URL` (porta 5432), mai la 6543; `statement_timeout` di 2 minuti sul pooler, quindi ogni caricamento lo alza con `set local`.
- **Copia locale e reale:**
  - le prove girano sulla copia locale (`127.0.0.1:55440`), ripristinata dal backup preso dopo la fase 3; la copia resta accesa per la 4b, che userà le stesse chiavi di `cultivar`;
  - COL completo non entra mai nel reale;
  - sul reale, prima del Task 5, nessuna scrittura.
- **Regole di lavoro:**
  - nessuna applicazione al reale (né la migration né i caricamenti) senza il via esplicito dell'utente in chat;
  - nessun push senza richiesta;
  - l'URL del database non si stampa mai, nemmeno con `ps`; della connessione si stampa al massimo la porta;
  - se il controllo dei permessi blocca un comando sul reale, lo si dà all'utente da lanciare nel suo terminale.
- **Revisione e ramo:** si lavora su `main`; revisione dei Task 1–4 da parte di revisori nuovi prima del Task 5. I revisori scrivono le note in un file mentre lavorano.

## Review Focus

1. **Le cultivar delle piante dell'utente** (6) finite su un altro taxon o con l'epiteto cambiato: devono restare sulla loro specie o sul loro genere, con lo stesso epiteto. Casi in `prova_cultivar.sql` (Task 3).
2. **Una riga cultivar di `specie` persa** (né cultivar né riga di mappa) o doppia: `verifica_fase4a.sql` lo controlla su tutte le 196.388 righe (Task 4).
3. **Caricamento interrotto tra un lotto e l'altro:** il rilancio salta i lotti fatti e completa. Prova `ripresa` di `prova_fase4a.sh` (Task 4).
4. **Rollback quando la fase 4b è già cominciata** (una scheda punta a una cultivar): rifiuto. Prova `rollback` di `prova_fase4a.sh` (Task 4).
5. **Cultivar sopra il genere o legata al grex sbagliato:** `prova_cultivar.sql` e `verifica_fase4a.sql` (Task 3 e 4).

## Misure del prototipo (16/10/2026, copia locale dal backup dopo la fase 3)

| Misura | Valore |
|---|---|
| Righe di `specie` con l'epiteto tra apici | 196.388 (196.343 con madre, 45 orfane) |
| Epiteti | 194.313 uguali al titolo RHS, 1.854 corretti dal titolo (65 non a prefisso, riletti a mano), 37 righe fuse con l'epiteto tra i titoli, 21 senza titolo RHS, 157 righe fuse senza epiteto e 6 illeggibili (solo mappa) |
| Taxon | madre 192.841, genere spp. corretto 3.322, orfane 45, genere del nome invece di un rango superiore 17, grex 220, Gruppo 1 |
| Taxon nuovi | 389 di COL (23 specie con accettati, catena e sinonimi) |
| `cultivar` | 196.446 righe: cultivar 196.223, grex 220, gruppo 3; con `grex_id` 295, con Gruppo 3.969, con nome commerciale 14.166 |
| Righe di mappa | 167 (163 fuse o illeggibili, 4 doppie) |
| Doppioni probabili | 143 gruppi per l'utente |
| WAL | taxon 0,4 MB; cultivar 52,2 e 61,3 MB; indici 7,1 MB |
| Spazio | `cultivar` 86 MB con gli indici |
| Durata sulla copia | lettura dei titoli 4 s, proposte 7 s, prove della fase 4a circa 40 s |

## File

- Create: `supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql` — `cultivar.grex_id`, `schede.nota`.
- Create: `scripts/tassonomia/prova_fase4_colonne.sql`, `rollback_fase4_colonne.sql`.
- Create: `scripts/tassonomia/cultivar_titoli.py`, `test_cultivar_titoli.py`, `cultivar_estrai.py` — lettura dei titoli RHS.
- Create: `scripts/tassonomia/dati/fase4_cultivar_doppie.tsv` — le 4 cultivar doppie cancellate e la loro gemella.
- Create: `scripts/tassonomia/cultivar_proposte.sql`, `prova_cultivar.sql` — le proposte sulla copia.
- Create: `scripts/tassonomia/cultivar_nuovi_taxa.sql`, `cultivar_esporta.sh` — i file da caricare.
- Create: `scripts/tassonomia/carica_cultivar.sh`, `verifica_fase4a.sql`, `rollback_fase4a.sql`, `prova_fase4a.sh`, `cultivar_doppioni.sql`.
- Modify: `CLAUDE.md` (Task 5).

Tutti i comandi si lanciano dalla radice del repository. In ogni shell nuova vanno impostate queste variabili:
- `PG=/opt/homebrew/opt/postgresql@17/bin`;
- `SCRATCH` = la cartella temporanea della sessione (scratchpad);
- `COLDIR=$HOME/giardino-dati/col`;
- `F4=$COLDIR/fase4`;
- `COPIA=postgresql://postgres@127.0.0.1:55440/giardino`;
- `RHS=scripts/rhs-import/rhs_sitemaps_parsed.jsonl` (git-ignorato, 304.114 righe, sha256 `15d52ecac891097e787ac9a61e34f77d1024d3b303c9783c1ea22628299f871a`);
- `SUPABASE_DB_URL` da `.env.local`;
- `TS` e `BK` dal Task 5.

---

### Task 1: Copia locale e colonne nuove

**Files:**
- Create: `scripts/tassonomia/prova_fase4_colonne.sql`
- Create: `supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql`
- Create: `scripts/tassonomia/rollback_fase4_colonne.sql`

**Interfaces:**
- Consumes: il backup `backups/completo_20261016_115134_post_fase3.dump` (fase 3 applicata); `copia_locale.sh` e `col_carica_locale.sh` (fasi 1b e 2).
- Produces: sulla copia, `cultivar.grex_id uuid` (chiave esterna differita `cultivar_grex_fk`, indice parziale `cultivar_grex_id_idx`) e `schede.nota text`; `public.piante` minima; i permessi della fase 1.

- [ ] **Step 1: Copia locale pronta**

Si parte da una copia nuova, ricreata dal backup: una copia già accesa (per esempio quella del prototipo) può contenere cultivar o la migration.

```bash
bash scripts/tassonomia/copia_locale.sh ferma "$SCRATCH/copia_fase4" 2>/dev/null || true
bash scripts/tassonomia/copia_locale.sh crea backups/completo_20261016_115134_post_fase3.dump "$SCRATCH/copia_fase4"
bash scripts/tassonomia/col_carica_locale.sh "$COLDIR/xr_latest_coldp.zip" "$COPIA"
```

Poi, una volta sola: la `public.piante` minima (serve alle chiavi esterne dei rollback) e i permessi della fase 1, che il ripristino con `--no-privileges` non porta:

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -c "create table if not exists public.piante (id text primary key default gen_random_uuid()::text, taxon_id uuid references public.taxa (id) on delete restrict, cultivar_id uuid references public.cultivar (id) on delete restrict)"
python3 -c 'import re, sys; print("\n".join(m.group(0) for m in re.finditer(r"^(revoke|grant)\b.*?;", open(sys.argv[1], encoding="utf-8").read(), re.S | re.M)))' supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql > "$SCRATCH/permessi_fase1.sql"
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -1 -f "$SCRATCH/permessi_fase1.sql"
$PG/psql "$COPIA" -X -qAt -c "select 'specie ' || (select count(*) from public.specie) || ', taxa ' || (select count(*) from public.taxa) || ', mappa ' || (select count(*) from public.mappa_specie) || ', cultivar ' || (select count(*) from public.cultivar) || ', col ' || (select count(*) from col.nome_uso)"
```

Expected: `specie 212066, taxa 241311, mappa 15713, cultivar 0, col 8479599`.

- [ ] **Step 2: Scrivere la prova delle colonne**

`scripts/tassonomia/prova_fase4_colonne.sql`:

```sql
-- Prova della migration delle colonne della fase 4 (cultivar.grex_id, schede.nota): esistono, con la chiave esterna
-- verso cultivar, e i permessi di colonna sono quelli voluti (grex_id leggibile dai client, nota no). Sola lettura.
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'cultivar' and column_name = 'grex_id') then
    raise exception 'manca cultivar.grex_id';
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'schede' and column_name = 'nota') then
    raise exception 'manca schede.nota';
  end if;
  if not exists (select 1 from pg_constraint where conname = 'cultivar_grex_fk' and confrelid = 'public.cultivar'::regclass) then
    raise exception 'manca la chiave esterna cultivar_grex_fk';
  end if;
  if to_regclass('public.cultivar_grex_id_idx') is null then raise exception 'manca l''indice cultivar_grex_id_idx'; end if;
  if not has_column_privilege('anon', 'public.cultivar', 'grex_id', 'select') or not has_column_privilege('authenticated', 'public.cultivar', 'grex_id', 'select') then
    raise exception 'cultivar.grex_id non leggibile dai client';
  end if;
  if has_column_privilege('anon', 'public.schede', 'nota', 'select') or has_column_privilege('authenticated', 'public.schede', 'nota', 'select') then
    raise exception 'schede.nota leggibile dai client';
  end if;
  if has_column_privilege('anon', 'public.cultivar', 'fonti', 'select') or has_column_privilege('anon', 'public.schede', 'fonti', 'select') then
    raise exception 'colonne interne leggibili dai client';
  end if;
  raise notice 'COLONNE FASE 4 OK';
end $$;
```

- [ ] **Step 3: Lanciarla e vederla fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_fase4_colonne.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected: `ERROR:  manca cultivar.grex_id`.

- [ ] **Step 4: Scrivere la migration e il suo rollback**

`supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql`:

```sql
-- Modello tassonomico, fase 4: due colonne nuove sulle tabelle della fase 1, ancora vuote
-- (specifica docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md, "Decisioni per la fase 4", punti 5 e 13).
-- - cultivar.grex_id: il grex di una cultivar di orchidea (ICNCP art. 6.5: l'epiteto va associato al grex), leggibile
--   dai client come le altre colonne pubbliche di cultivar;
-- - schede.nota: note di lavorazione interne, non leggibile dai client (come le note di taxa, nomi_comuni e mappa_specie).
-- La chiave esterna è differita come quelle di taxa: dentro un lotto l'ordine delle righe non conta.
-- Rollback: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4_colonne.sql
alter table public.cultivar add column grex_id uuid,
  add constraint cultivar_grex_fk foreign key (grex_id) references public.cultivar (id) on delete restrict deferrable initially deferred,
  add constraint cultivar_grex_non_se_stesso check (grex_id <> id);
create index cultivar_grex_id_idx on public.cultivar (grex_id) where grex_id is not null;
grant select (grex_id) on public.cultivar to anon, authenticated;

alter table public.schede add column nota text;
```

`scripts/tassonomia/rollback_fase4_colonne.sql`:

```sql
-- Rollback della migration 20261017100000_tassonomia_fase4_colonne.sql: toglie cultivar.grex_id e schede.nota.
-- Si rifiuta se una delle due colonne contiene dati (prima rollback_fase4a.sql e, per le schede, quello della fase 4b).
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4_colonne.sql
do $$
begin
  if exists (select 1 from public.cultivar where grex_id is not null) or exists (select 1 from public.schede where nota is not null) then
    raise exception 'Rollback colonne fase 4 rifiutato: cultivar.grex_id o schede.nota contengono dati';
  end if;
end $$;
alter table public.cultivar drop column grex_id;
alter table public.schede drop column nota;
```

- [ ] **Step 5: Applicare, annullare e riapplicare sulla copia**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -1 -f supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_fase4_colonne.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -1 -f scripts/tassonomia/rollback_fase4_colonne.sql
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_fase4_colonne.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -1 -f supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_fase4_colonne.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected: `NOTICE:  COLONNE FASE 4 OK`, poi `ERROR:  manca cultivar.grex_id`, poi di nuovo `NOTICE:  COLONNE FASE 4 OK`.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql scripts/tassonomia/prova_fase4_colonne.sql scripts/tassonomia/rollback_fase4_colonne.sql
git commit -m "Tassonomia fase 4a: migration delle colonne cultivar.grex_id e schede.nota (copia locale) con la prova e il rollback"
```

---

### Task 2: Lettura dei titoli RHS

**Files:**
- Create: `scripts/tassonomia/test_cultivar_titoli.py`
- Create: `scripts/tassonomia/cultivar_titoli.py`
- Create: `scripts/tassonomia/cultivar_estrai.py`

**Interfaces:**
- Consumes: `scripts/rhs-import/species_key.py` (`base_species`, la chiave di specie usata dall'import delle cultivar); `$RHS`.
- Produces:
  - `cultivar_titoli.leggi_titolo(titolo) -> dict` (chiavi `epiteto`, `base`, `gruppo`, `grex`, `serie`, `commerciale` lista, `codici` lista, `altro` lista);
  - `cultivar_titoli.indice_titoli(titoli) -> dict` (nome di riga di specie → lista di titoli);
  - `cultivar_titoli.estrai(nome_scientifico, indice) -> dict` (chiavi `caso`, `epiteto`, `categoria`, `gruppo`, `nome_commerciale`, `grex`, `segnalazioni`, `titoli`);
  - `$F4/cultivar_estratte.tsv`: TSV con intestazione `id, caso, epiteto, categoria, gruppo, nome_commerciale, grex, segnalazioni, titoli`.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/test_cultivar_titoli.py`:

```python
"""Prove della lettura dei titoli RHS delle cultivar (fase 4a). Uso: python3 -m unittest scripts/tassonomia/test_cultivar_titoli.py"""
import os
import sys
import unittest

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cultivar_titoli import leggi_titolo, estrai, indice_titoli  # noqa: E402


class LeggiTitolo(unittest.TestCase):
    def test_apostrofo_dentro_l_epiteto(self):
        r = leggi_titolo("Symphyotrichum novi-belgii 'King's College'")
        self.assertEqual(r['epiteto'], "King's College")
        self.assertEqual(r['base'], 'Symphyotrichum novi-belgii')

    def test_nome_commerciale_tra_quadre_ed_epiteto_tra_parentesi(self):
        r = leggi_titolo("Salvia rosmarinus [Wilma's Gold] ('Wimtim01')")
        self.assertEqual(r['epiteto'], 'Wimtim01')
        self.assertEqual(r['commerciale'], ["Wilma's Gold"])

    def test_gruppo_tra_parentesi(self):
        r = leggi_titolo("Alcea rosea (Chater's Double Group) 'Icicle'")
        self.assertEqual((r['epiteto'], r['gruppo']), ('Icicle', "Chater's Double Group"))

    def test_grex(self):
        r = leggi_titolo("Cymbidium Rio Rita gx 'Radiant'")
        self.assertEqual((r['base'], r['grex'], r['epiteto']), ('Cymbidium', 'Rio Rita', 'Radiant'))

    def test_serie_e_codici(self):
        r = leggi_titolo("Lupinus 'Gallery Pink' (Gallery Series)")
        self.assertEqual((r['epiteto'], r['serie']), ('Gallery Pink', 'Gallery Series'))
        r = leggi_titolo("Rosa [Memento] ('Dicbar') (F)")
        self.assertEqual((r['epiteto'], r['commerciale'], r['codici']), ('Dicbar', ['Memento'], ['F']))

    def test_apostrofo_finale_doppio(self):
        r = leggi_titolo("Musa acuminata 'Iholena Ula'ula'' (AAA Group) (F)")
        self.assertEqual((r['epiteto'], r['gruppo']), ("Iholena Ula'ula", 'AAA Group'))

    def test_indice_di_omonimia_non_e_un_nome_commerciale(self):
        r = leggi_titolo("Clematis 'Arabella' [1]")
        self.assertEqual((r['epiteto'], r['commerciale'], r['codici']), ('Arabella', [], ['[1]']))


class Estrai(unittest.TestCase):
    titoli = [
        "Symphyotrichum novi-belgii 'King's College'",
        "Salvia rosmarinus [Wilma's Gold] ('Wimtim01')",
        "Calluna vulgaris 'Dart's Beauty'", "Calluna vulgaris 'Dart's Hedgehog'",
        "Hedera helix 'Goldchild'", "Hedera helix 'Goldchild' (v)",
        "Geranium [Rozanne] ('Gerwat')",
    ]

    def setUp(self):
        self.indice = indice_titoli(self.titoli)

    def test_epiteto_corretto_dal_titolo(self):
        e = estrai("Symphyotrichum novi-belgii 'King'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('corretto dal titolo RHS', "King's College"))

    def test_frammento_di_nome_commerciale(self):
        e = estrai("Salvia rosmarinus 's Gold] ('", self.indice)
        self.assertEqual((e['epiteto'], e['nome_commerciale']), ('Wimtim01', "Wilma's Gold"))

    def test_uguale_anche_con_piu_titoli(self):
        e = estrai("Hedera helix 'Goldchild'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('uguale al titolo RHS', 'Goldchild'))

    def test_riga_fusa_senza_epiteto(self):
        e = estrai("Calluna vulgaris 'Dart'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('fusa: nessun titolo con questo epiteto', ''))

    def test_senza_titolo_resta_l_epiteto_di_specie(self):
        e = estrai("Chamaecyparis lawsoniana 'Minima Glauca'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('senza titolo RHS (altra fonte): epiteto di specie', 'Minima Glauca'))

    def test_nome_commerciale_di_una_pianta_dell_utente(self):
        e = estrai("Geranium 'Gerwat'", self.indice)
        self.assertEqual((e['epiteto'], e['nome_commerciale'], e['categoria']), ('Gerwat', 'Rozanne', 'cultivar'))

    def test_gruppo_come_epiteto(self):
        e = estrai("Narcissus 'Montongo Group'", indice_titoli([]))
        self.assertEqual(e['categoria'], 'gruppo')


if __name__ == '__main__':
    unittest.main()
```

- [ ] **Step 2: Lanciarle e vederle fallire**

```bash
python3 -m unittest scripts/tassonomia/test_cultivar_titoli.py 2>&1 | tail -3
```

Expected: `FAILED (errors=1)` con `ModuleNotFoundError: No module named 'cultivar_titoli'`.

- [ ] **Step 3: Scrivere la lettura dei titoli**

`scripts/tassonomia/cultivar_titoli.py`:

```python
"""Fase 4a: lettura dei titoli delle pagine RHS delle cultivar secondo l'ICNCP (9ª ed.).

L'import delle cultivar (scripts/rhs-import/backfill_cultivar.py) ha costruito il nome di ogni riga di specie come
"<specie base> '<primo tratto tra apici del titolo RHS>'": l'epiteto si tronca al primo apostrofo ('King' per
'King's College') e Gruppo, nome commerciale e grex vanno persi. Qui si ritrovano i titoli da cui ogni riga è nata e
si rileggono:
- epiteto: tra il primo apice a inizio parola e l'ultimo apice seguito da fine o spazio, senza apici (art. 14.1);
  un apostrofo finale in più (Musa 'Iholena Ula'ula'') cade;
- nome commerciale: tra quadre, mai tra apici (art. 13.1, 17); un numero tra quadre è l'indice di omonimia di RHS;
- Gruppo: "(X Group)" o "X Group" davanti all'epiteto (art. 22.5), grex: "Genere Nome gx" (art. 23); le Serie non si
  registrano (App. X (2)); i codici di classificazione RHS tra parentesi ((v), (F)…) restano fuori.
"""
import os
import re
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'rhs-import'))
from species_key import base_species  # noqa: E402  (stessa chiave di specie usata dall'import)

CODICE = re.compile(r"^[A-Za-z0-9]{1,4}(\s?[a-z])?$|^\d+[a-z]?(-\d+)?$")
SERIE_MISCUGLIO = re.compile(r'\b(Series|Mixed|Mixture|Mix)\b')


def specie_aggregata(titolo):
    """Specie base come in build_full_aggregate.py: senza tratti tra apici, parentesi e quadre, le prime 2 parole
    (3 se la seconda è ×)."""
    s = re.sub(r"'[^']*'", '', titolo)
    s = re.sub(r'\([^)]*\)', '', s)
    s = re.sub(r'\[[^\]]*\]', '', s)
    parti = re.sub(r'\s+', ' ', s).strip().split(' ')
    if len(parti) >= 3 and parti[1] == '×':
        return ' '.join(parti[:3])
    return ' '.join(parti[:2])


def leggi_titolo(titolo):
    """Base, epiteto, gruppo, grex, nomi commerciali, serie, codici e altro di un titolo RHS."""
    r = {'commerciale': [], 'gruppo': None, 'grex': None, 'serie': None, 'codici': [], 'altro': [],
         'epiteto': None, 'base': None}
    s = titolo.strip()
    for x in re.findall(r'\[([^\]]*)\]', s):
        x = x.strip()
        if re.fullmatch(r'\d+', x):
            r['codici'].append('[%s]' % x)
        elif x.startswith("'"):
            r['altro'].append('[%s]' % x)
        else:
            r['commerciale'].append(x)
    s = re.sub(r'\s*\[[^\]]*\]', '', s)
    parentesi = []
    s = re.sub(r'\s*\(([^()]*)\)', lambda m: (parentesi.append(m.group(1).strip()), '')[1], s).strip()
    epiteto_tra_parentesi = None
    for p in parentesi:
        if len(p) >= 2 and p[0] == "'" and p[-1] == "'":
            epiteto_tra_parentesi = p[1:-1].strip()
        elif re.search(r'\bGroup$', p, re.I):
            r['gruppo'] = p
        elif re.search(r'\bSeries$', p, re.I):
            r['serie'] = p
        elif CODICE.match(p):
            r['codici'].append(p)
        else:
            r['altro'].append(p)
    m = re.search(r"(^|\s)'", s)
    if m:
        i = m.end() - 1
        chiusure = [k for k in range(i + 1, len(s)) if s[k] == "'" and (k == len(s) - 1 or s[k + 1] == ' ')]
        if chiusure:
            k = chiusure[-1]
            # un apostrofo prima dell'apice di chiusura fa parte della parola (Musa 'Iholena Ula'ula''), ma
            # l'epiteto non finisce mai con un apice
            r['epiteto'] = s[i + 1:k].strip().rstrip("'").strip()
            if s[k + 1:].strip():
                r['altro'].append(s[k + 1:].strip())
        base = s[:i].strip()
    else:
        base = s
    if r['epiteto'] is None and epiteto_tra_parentesi is not None:
        r['epiteto'] = epiteto_tra_parentesi
    elif epiteto_tra_parentesi is not None:
        r['altro'].append("('%s')" % epiteto_tra_parentesi)
    mg = re.match(r"^(×\s)?([A-Z][\w-]+)\s(.+?)\sgx$", base)
    if mg:
        r['grex'] = mg.group(3)
        base = (mg.group(1) or '') + mg.group(2)
    mgr = re.match(r"^(.+?)\s([A-Z][^']*\sGroup)$", base)
    if mgr and not r['gruppo']:
        r['gruppo'] = mgr.group(2)
        base = mgr.group(1)
    r['base'] = base
    return r


def indice_titoli(titoli):
    """Titoli RHS per nome di riga di specie, ricostruito come l'import: "<specie base> '<primo tratto tra apici>'"."""
    indice = {}
    for t in titoli:
        m = re.search(r"'([^']*)'", t or '')
        if not m or not m.group(1).strip():
            continue
        c = m.group(1).strip()
        for sp in {specie_aggregata(t), base_species(t)}:
            if sp:
                lista = indice.setdefault(f"{sp} '{c}'", [])
                if t not in lista:
                    lista.append(t)
    return indice


def _unisci(valori):
    v = []
    for x in valori:
        for y in (x or '').split(' | '):
            y = y.strip()
            if y and y not in v:
                v.append(y)
    return ' | '.join(v)


def _valido(ep):
    return (bool(ep) and ep == ep.strip() and ep[0] != "'" and ep[-1] != "'"
            and not re.search(r'[\[\]()]', ep) and not re.match(r'^[a-z]', ep))


def estrai(nome_scientifico, indice):
    """Epiteto, categoria, gruppo, nome commerciale e grex di una riga cultivar di specie, con il caso che li decide."""
    epiteto_specie = nome_scientifico.split("'")[1]
    titoli = indice.get(nome_scientifico, [])
    letti = [leggi_titolo(t) for t in titoli]
    epiteti = list(dict.fromkeys(x['epiteto'] for x in letti if x['epiteto']))
    gruppo = _unisci(x['gruppo'] for x in letti)
    commerciale = _unisci(' | '.join(x['commerciale']) for x in letti)
    grex = _unisci(x['grex'] for x in letti)
    segnalazioni = []
    if len(epiteti) == 1:
        epiteto = epiteti[0]
        caso = 'uguale al titolo RHS' if epiteto == epiteto_specie else 'corretto dal titolo RHS'
        if not _valido(epiteto):
            segnalazioni.append('epiteto RHS non valido')
    elif len(epiteti) > 1:
        # riga nata da più cultivar RHS: Gruppo, nomi commerciali e grex non sono di una sola cultivar
        gruppo = commerciale = grex = ''
        if epiteto_specie in epiteti:
            epiteto, caso = epiteto_specie, 'fusa: epiteto di specie presente tra i titoli'
        else:
            epiteto, caso = '', 'fusa: nessun titolo con questo epiteto'
    elif _valido(epiteto_specie) and not titoli:
        epiteto, caso = epiteto_specie, 'senza titolo RHS (altra fonte): epiteto di specie'
    else:
        epiteto, caso = '', 'senza epiteto leggibile'
    categoria = 'gruppo' if epiteto and re.search(r'\bGroup$', epiteto, re.I) else 'cultivar'
    if epiteto and SERIE_MISCUGLIO.search(epiteto):
        segnalazioni.append('serie o miscuglio di semi')
    if ' | ' in gruppo:
        segnalazioni.append('più Gruppi')
    if ' | ' in commerciale:
        segnalazioni.append('più nomi commerciali')
    return {'caso': caso, 'epiteto': epiteto, 'categoria': categoria, 'gruppo': gruppo, 'nome_commerciale': commerciale,
            'grex': grex, 'segnalazioni': '; '.join(segnalazioni), 'titoli': ' || '.join(titoli)}
```

- [ ] **Step 4: Rilanciare le prove**

```bash
python3 -m unittest scripts/tassonomia/test_cultivar_titoli.py 2>&1 | tail -2
```

Expected: `Ran 14 tests` e `OK`.

- [ ] **Step 5: Scrivere l'estrazione e lanciarla su tutte le cultivar**

`scripts/tassonomia/cultivar_estrai.py`:

```python
#!/usr/bin/env python3
"""Fase 4a: epiteto, categoria, Gruppo, nome commerciale e grex di ogni riga cultivar di specie, riletti dai titoli
delle pagine RHS già scaricate (vedi cultivar_titoli.py e la specifica, "Decisioni per la fase 4", punti 15 e 19).
Uso: python3 scripts/tassonomia/cultivar_estrai.py RHS_JSONL < cultivar_righe.tsv > cultivar_estratte.tsv
  RHS_JSONL: scripts/rhs-import/rhs_sitemaps_parsed.jsonl (git-ignorato, un oggetto JSON per pagina con
             nome_scientifico_titolo);
  standard input: TSV con intestazione id, nome_scientifico (le righe di specie con l'epiteto tra apici);
  standard output: TSV con intestazione id, caso, epiteto, categoria, gruppo, nome_commerciale, grex, segnalazioni,
             titoli. Il riepilogo dei casi va sullo standard error.
"""
import collections
import csv
import json
import os
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cultivar_titoli import estrai, indice_titoli  # noqa: E402

COLONNE = ['id', 'caso', 'epiteto', 'categoria', 'gruppo', 'nome_commerciale', 'grex', 'segnalazioni', 'titoli']


def titoli_rhs(percorso):
    with open(percorso, encoding='utf-8') as f:
        for riga in f:
            if riga.strip():
                t = (json.loads(riga).get('nome_scientifico_titolo') or '').replace('\t', ' ').replace('\n', ' ')
                if "'" in t:
                    yield t


def main():
    indice = indice_titoli(titoli_rhs(sys.argv[1]))
    righe = csv.DictReader(sys.stdin, delimiter='\t')
    out = csv.writer(sys.stdout, delimiter='\t', lineterminator='\n')
    out.writerow(COLONNE)
    conteggi = collections.Counter()
    for r in righe:
        e = estrai(r['nome_scientifico'], indice)
        conteggi[e['caso']] += 1
        for k in ('gruppo', 'nome_commerciale', 'grex'):
            conteggi['con ' + k] += bool(e[k])
        out.writerow([r['id']] + [e[k] for k in COLONNE[1:]])
    for k, v in sorted(conteggi.items()):
        print(f'{k}: {v}', file=sys.stderr)


if __name__ == '__main__':
    main()
```

```bash
chmod +x scripts/tassonomia/cultivar_estrai.py
mkdir -p "$F4"
shasum -a 256 "$RHS" | cut -d' ' -f1
$PG/psql "$COPIA" -X -q -c "copy (select id, nome_scientifico from public.specie where nome_scientifico like '%''%' order by id) to stdout with (format csv, delimiter E'\t', header)" > "$F4/cultivar_righe.tsv"
python3 scripts/tassonomia/cultivar_estrai.py "$RHS" < "$F4/cultivar_righe.tsv" > "$F4/cultivar_estratte.tsv"
```

Expected:
- lo sha256 di `$RHS` uguale a quello delle variabili; se no, fermarsi: il file RHS non è quello provato;
- sullo standard error: `con grex: 297`, `con gruppo: 3969`, `con nome_commerciale: 14169`, `corretto dal titolo RHS: 1854`, `fusa: epiteto di specie presente tra i titoli: 37`, `fusa: nessun titolo con questo epiteto: 157`, `senza epiteto leggibile: 6`, `senza titolo RHS (altra fonte): epiteto di specie: 21`, `uguale al titolo RHS: 194313`.

- [ ] **Step 6: Rileggere a mano le correzioni non a prefisso**

```bash
python3 - "$F4/cultivar_righe.tsv" "$F4/cultivar_estratte.tsv" <<'EOF'
import csv, sys
csv.field_size_limit(10**9)
ns = {r['id']: r['nome_scientifico'] for r in csv.DictReader(open(sys.argv[1], encoding='utf-8'), delimiter='\t')}
n = 0
for r in csv.DictReader(open(sys.argv[2], encoding='utf-8'), delimiter='\t'):
    if r['caso'] == 'corretto dal titolo RHS' and not r['epiteto'].startswith(ns[r['id']].split("'")[1]):
        n += 1
        print(f"{ns[r['id']]} -> '{r['epiteto']}' [gruppo: {r['gruppo']}] [commerciale: {r['nome_commerciale']}] << {r['titoli'][:90]}")
print(n)
EOF
```

Expected: 65 righe. Sono quasi tutte un nome commerciale con un apostrofo che troncava l'epiteto (`Rosa rugosa 's Dash] ('` → 'Interdash', nome commerciale «Dart's Dash»). Il resto sono descrittori tra parentesi che non fanno parte dell'epiteto (ICNCP art. 21.18): 'Colne Audley (1)', 'Burgundy Lace (compact form)', 'Haydn (H)', 'Siberian Improved (F2139)'. Sono state rilette il 16/10/2026 e accettate tutte. Una riga diversa da questo schema va annotata nel registro e decisa prima di proseguire.

- [ ] **Step 7: Commit**

```bash
git add scripts/tassonomia/test_cultivar_titoli.py scripts/tassonomia/cultivar_titoli.py scripts/tassonomia/cultivar_estrai.py
git commit -m "Tassonomia fase 4a: epiteto, Gruppo e nome commerciale delle cultivar riletti dai titoli RHS, con le prove"
```

---

### Task 3: Proposte delle cultivar sulla copia locale

**Files:**
- Create: `scripts/tassonomia/dati/fase4_cultivar_doppie.tsv`
- Create: `scripts/tassonomia/prova_cultivar.sql`
- Create: `scripts/tassonomia/cultivar_proposte.sql`

**Interfaces:**
- Consumes: `$F4/cultivar_estratte.tsv` (Task 2); `public.specie`, `public.mappa_specie`, `public.taxa`, `col.nome_uso` della copia.
- Produces:
  - `col.cultivar_proposte` (`id uuid`, `vecchia_specie_id`, `slug`, `taxon_id uuid` oppure `taxon_col_id text`, `categoria`, `epiteto`, `gruppo`, `nome_commerciale`, `grex_id`, `fonti text[]`, `origine_taxon`, `caso`);
  - `col.cultivar_mappa` (`vecchia_specie_id`, `vecchio_slug`, `vecchio_nome_scientifico`, `origine`, `taxon_id` oppure `taxon_col_id` oppure `cultivar_id`, `esito`, `nota`);
  - la funzione `col.nome_norm(text)`.

- [ ] **Step 1: Scrivere i dati delle cultivar doppie**

`scripts/tassonomia/dati/fase4_cultivar_doppie.tsv` (tabulazioni tra le colonne; dal file `scripts/nomi-italiani/rollback_hedera_residue.sql`):

```text
vecchia_specie_id	vecchio_slug	vecchio_nome_scientifico	gemella_specie_id
1ea76709-1d57-4b31-b761-5e83b9209da8	alyssum-snow-crystals	Alyssum 'Snow Crystals'	c66e52bc-c351-454f-ae82-6ea9c5e96af9
8f7f5700-0928-4104-b183-df9baaada0b2	anthurium-sumi	Anthurium 'Sumi'	c55d7c60-62b6-448f-ac2b-6c9db56ec744
e1650582-969e-4d18-93ac-c8c3a996063d	camellia-april-blush	Camellia 'April Blush'	0ea7e709-6bef-4c1a-ac03-270fa997947b
00950c31-47b6-480a-8fab-741ca47ecd63	camellia-volcano	Camellia 'Volcano'	b60d9c7c-af4b-464b-ac54-bee7e59c97d6
```

- [ ] **Step 2: Scrivere le prove delle proposte**

`scripts/tassonomia/prova_cultivar.sql`:

```sql
-- Prove delle proposte delle cultivar della fase 4a (cultivar_proposte.sql), sulla copia locale. Errore al primo
-- controllo che fallisce. Numeri e casi valgono per specie del 16/10/2026 (dopo la fase 3) e COL26.9 XR.
do $$
declare
  n bigint;
  atteso record;
begin
  -- 196.388 righe con apici - 163 fuse o illeggibili (solo mappa) + 220 grex + 1 Gruppo (Dunedin)
  select count(*) into n from col.cultivar_proposte;
  if n <> 196446 then raise exception 'cultivar proposte: % (attese 196446)', n; end if;
  select count(*) into n from col.cultivar_mappa;
  if n <> 167 then raise exception 'righe di mappa delle cultivar: % (attese 167: 163 fuse o illeggibili + 4 doppie)', n; end if;
  select count(*) into n from col.cultivar_proposte where taxon_id is null and taxon_col_id is null;
  if n > 0 then raise exception 'cultivar senza taxon: %', n; end if;
  select count(*) into n from col.cultivar_proposte p
    left join public.taxa t on t.id = p.taxon_id left join col.nome_uso u on u.id = p.taxon_col_id
   where coalesce(t.rango, u.rango) not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'cultivar su un taxon sopra il genere o di rango inatteso (ICNCP art. 21.2): %', n; end if;
  select count(*) into n from col.cultivar_proposte
   where btrim(epiteto) = '' or left(epiteto, 1) = '''' or right(epiteto, 1) = '''' or epiteto ~ '[\[\]]';
  if n > 0 then raise exception 'epiteti non validi: %', n; end if;
  select count(*) into n from (select vecchia_specie_id from col.cultivar_proposte group by 1 having count(*) > 1) x;
  if n > 0 then raise exception 'vecchie righe con più cultivar: %', n; end if;
  select count(*) into n from (select slug from col.cultivar_proposte group by 1 having count(*) > 1) x;
  if n > 0 then raise exception 'slug doppi: %', n; end if;
  -- categorie: 220 grex; i Gruppi sono Dunedin e i 2 epiteti che finiscono con Group
  select count(*) into n from col.cultivar_proposte where categoria = 'grex';
  if n <> 220 then raise exception 'grex: % (attesi 220)', n; end if;
  select count(*) into n from col.cultivar_proposte where categoria = 'gruppo';
  if n <> 3 then raise exception 'gruppi: % (attesi 3)', n; end if;
  -- cultivar di orchidea legate al loro grex (ICNCP art. 6.5)
  select count(*) into n from col.cultivar_proposte c join col.cultivar_proposte g on g.id = c.grex_id where g.categoria = 'grex';
  if n <> 295 then raise exception 'cultivar legate a un grex: % (attese 295)', n; end if;
  select count(*) into n from col.cultivar_proposte c where c.grex_id is not null
     and not exists (select 1 from col.cultivar_proposte g where g.id = c.grex_id and g.categoria = 'grex');
  if n > 0 then raise exception 'grex_id che non punta a un grex: %', n; end if;
  -- casi verificati nella ricerca (slug, epiteto, gruppo o nome commerciale, nome del taxon)
  for atteso in select * from (values
      ('symphyotrichum-novi-belgii-king', 'King''s College', null, 'Symphyotrichum novi-belgii'),
      ('alcea-rosea-s-double-group', 'Icicle', 'Chater''s Double Group', 'Alcea rosea'),
      ('brassia-rex', 'Rex', null, 'Brassia'),
      ('brachyglottis-dunedin-hybrids', 'Dunedin Group', null, 'Brachyglottis'),
      -- le cultivar delle piante dell'utente restano sulla loro specie o sul loro genere
      ('ficus-elastica-belize', 'Belize', null, 'Ficus elastica'),
      ('geranium-gerwat', 'Gerwat', 'Rozanne', 'Geranium'),
      ('mammillaria-elongata-d-one', 'D One', null, 'Mammillaria elongata'),
      ('muscari-armeniacum-manon', 'Manon', null, 'Muscari armeniacum'),
      ('narcissus-poeticus-recurvus', 'Recurvus', null, 'Narcissus poeticus'),
      ('tulipa-happy-generation', 'Happy Generation', null, 'Tulipa')
    ) v(slug, epiteto, altro, taxon) loop
    select count(*) into n from col.cultivar_proposte p
      left join public.taxa t on t.id = p.taxon_id left join col.nome_uso u on u.id = p.taxon_col_id
     where p.slug = atteso.slug and p.epiteto = atteso.epiteto
       and (atteso.altro is null or atteso.altro in (p.gruppo, p.nome_commerciale))
       and coalesce(t.nome_scientifico, u.nome) = atteso.taxon;
    if n <> 1 then raise exception 'caso %: atteso % su %', atteso.slug, atteso.epiteto, atteso.taxon; end if;
  end loop;
  -- cultivar di specie agganciate per errore al genere: passano alla specie del nome (ortensie, impatiens)
  select count(*) into n from col.cultivar_proposte p join public.specie s on s.id = p.vecchia_specie_id
    left join public.taxa t on t.id = p.taxon_id left join col.nome_uso u on u.id = p.taxon_col_id
   where s.nome_scientifico like 'Hydrangea macrophylla ''%' and coalesce(t.nome_scientifico, u.nome) <> 'Hydrangea macrophylla';
  if n > 0 then raise exception 'ortensie non su Hydrangea macrophylla: %', n; end if;
  select count(*) into n from col.cultivar_proposte p join public.specie s on s.id = p.vecchia_specie_id
   where s.nome_scientifico like 'Impatiens walleriana ''%' and p.taxon_col_id is null;
  if n > 0 then raise exception 'Impatiens walleriana non è tra i taxon da importare: %', n; end if;
  select count(distinct taxon_col_id) into n from col.cultivar_proposte where taxon_col_id is not null;
  if n <> 23 then raise exception 'specie da importare da COL: % (attese 23)', n; end if;
  -- righe fuse o illeggibili: solo mappa, esito ambiguo; doppie: mappa verso la gemella
  perform 1 from col.cultivar_mappa m join public.specie s on s.id = m.vecchia_specie_id
   where s.nome_scientifico = 'Calluna vulgaris ''Dart''' and m.esito = 'ambiguo' and m.cultivar_id is null;
  if not found then raise exception 'Calluna vulgaris ''Dart'' non è una riga di mappa ambigua'; end if;
  select count(*) into n from col.cultivar_mappa m join col.cultivar_proposte c on c.id = m.cultivar_id
   where m.origine = 'rollback' and m.esito = 'deciso dall''utente';
  if n <> 4 then raise exception 'cultivar doppie collegate alla gemella: % (attese 4)', n; end if;
  raise notice 'CULTIVAR CORRETTE: % cultivar, % righe di mappa, % specie da importare',
    (select count(*) from col.cultivar_proposte), (select count(*) from col.cultivar_mappa),
    (select count(distinct taxon_col_id) from col.cultivar_proposte where taxon_col_id is not null);
end $$;
```

- [ ] **Step 3: Lanciarle e vederle fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_cultivar.sql 2>&1 | grep -o 'ERROR.*'
```

Expected: `ERROR:  relation "col.cultivar_proposte" does not exist`.

- [ ] **Step 4: Scrivere le proposte**

`scripts/tassonomia/cultivar_proposte.sql`:

```sql
-- Fase 4a: le righe di cultivar da caricare (col.cultivar_proposte) e le righe di mappa_specie delle cultivar che non
-- diventano cultivar (col.cultivar_mappa), sulla copia locale con COL completo (schema col). Regole: specifica,
-- "Decisioni per la fase 4", punti 5 e 15-19.
-- - taxon_id = il taxon più basso noto (ICNCP art. 21.1-21.2): il nome trovato della madre in mappa_specie, anche se
--   sinonimo; per le cultivar di specie la cui madre è una riga "Genere spp." (difetto dell'import) la specie del nome,
--   accettata o sinonimo, presa da taxa o, se manca, da COL (taxon_col_id, da importare); per le orfane la riga madre
--   mancata (stesso nome, senza apici); mai sopra il genere: in quel caso il genere scritto nel nome;
-- - grex: righe non cultivar della fase 3 (nota "grex…" o Genere + nome maiuscolo sotto un notogenere locale), epiteto
--   = nome senza genere e senza "gx" (art. 16.3, 23.1); Brachyglottis Dunedin Hybrids = gruppo "Dunedin Group" (art. 3,
--   Nota 1, Es. 7); le cultivar figlie di un grex hanno grex_id (art. 6.5);
-- - righe fuse da più cultivar RHS o senza epiteto leggibile: nessuna cultivar, una riga di mappa (esito ambiguo);
-- - cultivar doppie cancellate (dati/fase4_cultivar_doppie.tsv): una riga di mappa verso la cultivar gemella.
-- Standard input: il TSV di cultivar_estrai.py. Lanciare dalla radice del repository.
set statement_timeout = 0;
drop table if exists col.cultivar_estratte, col.cultivar_doppie, col.cultivar_proposte, col.cultivar_mappa;
create table col.cultivar_estratte (id uuid primary key, caso text not null, epiteto text, categoria text not null, gruppo text,
                                    nome_commerciale text, grex text, segnalazioni text, titoli text);
\copy col.cultivar_estratte from pstdin with (format csv, delimiter E'\t', header)
create table col.cultivar_doppie (vecchia_specie_id uuid primary key, vecchio_slug text not null, vecchio_nome_scientifico text not null,
                                  gemella_specie_id uuid not null);
\copy col.cultivar_doppie from 'scripts/tassonomia/dati/fase4_cultivar_doppie.tsv' with (format csv, delimiter E'\t', header)

-- nome normalizzato per i confronti: segno d'ibrido tolto (COL scrive Camellia × williamsii, RHS Camellia williamsii)
create or replace function col.nome_norm(n text) returns text language sql immutable parallel safe as $$
  select lower(regexp_replace(btrim(regexp_replace(replace(n, '×', ' '), '(^|\s)x\s', ' ', 'g')), '\s+', ' ', 'g'))
$$;

do $$
declare n bigint;
begin
  select count(*) into n from public.specie s where s.nome_scientifico like '%''%'
     and not exists (select 1 from col.cultivar_estratte e where e.id = s.id);
  if n > 0 then raise exception 'righe cultivar di specie senza estrazione: %', n; end if;
  select count(*) into n from col.cultivar_estratte e where not exists (select 1 from public.specie s where s.id = e.id);
  if n > 0 then raise exception 'estrazioni per righe che non sono in specie: %', n; end if;
end $$;

create temp table cv as
select s.id, s.slug, s.nome_scientifico as ns, s.specie_padre_id, s.fonti,
       btrim(split_part(s.nome_scientifico, '''', 1)) as base,
       e.caso, e.epiteto, e.categoria, nullif(e.gruppo, '') as gruppo, nullif(e.nome_commerciale, '') as nome_commerciale,
       e.titoli, p.nome_scientifico as madre_ns, mp.taxon_id as madre_taxon
  from public.specie s
  join col.cultivar_estratte e on e.id = s.id
  left join public.specie p on p.id = s.specie_padre_id
  left join public.mappa_specie mp on mp.vecchia_specie_id = s.specie_padre_id;
alter table cv add column forma text, add column origine_taxon text, add column taxon_id uuid, add column taxon_col_id text;
update cv set forma = case
  when base ~ '^[A-Z][a-z-]+$' then 'G'
  when base ~ '^(× )?[A-Z][a-z-]+ (× )?[a-z][a-z-]+$' then 'G s'
  when base ~ '^(× )?[A-Z][a-z-]+ [A-Z]' then 'grex'
  else 'altro' end;
update cv set origine_taxon = case
  when specie_padre_id is null then 'orfana'
  when madre_ns ~ '\sspp\.?$' and forma = 'G s' then 'genere spp.'
  else 'madre' end;

-- taxa per nome normalizzato: l'accettato prima dei sinonimi (il nome trovato, come nella fase 3)
create temp table nome_taxa as
select distinct on (col.nome_norm(t.nome_scientifico), t.rango) col.nome_norm(t.nome_scientifico) as nome, t.rango, t.id
  from public.taxa t where t.rango in ('genus', 'species')
 order by col.nome_norm(t.nome_scientifico), t.rango, (t.stato in ('accepted', 'provisionally accepted')) desc,
          (t.stato = 'accepted') desc, t.id;
create index on nome_taxa (nome, rango);

update cv set taxon_id = madre_taxon where origine_taxon = 'madre';
update cv set taxon_id = n.id from nome_taxa n
 where cv.origine_taxon = 'genere spp.' and n.nome = col.nome_norm(cv.base) and n.rango = 'species';
-- orfane: la riga madre mancata (stesso nome, senza apici), altrimenti il nome base in taxa
update cv set taxon_id = mp.taxon_id from public.specie m join public.mappa_specie mp on mp.vecchia_specie_id = m.id
 where cv.origine_taxon = 'orfana' and m.specie_padre_id is null and m.nome_scientifico = cv.base;
update cv set taxon_id = n.id from nome_taxa n
 where cv.origine_taxon = 'orfana' and cv.taxon_id is null and n.nome = col.nome_norm(cv.base)
   and n.rango = case when cv.forma = 'G' then 'genus' else 'species' end;

-- specie del nome che mancano da taxa: da COL, in Plantae (per un sinonimo il regno è quello dell'accettato), niente
-- segnaposto "Genere spp"; l'accettato prima dei sinonimi
create temp table da_cercare as
select distinct col.nome_norm(base) as nome, lower(split_part(regexp_replace(base, '^× ', ''), ' ', 1)) as genere
  from cv where origine_taxon = 'genere spp.' and taxon_id is null;
create temp table col_trovati as
select distinct on (col.nome_norm(u.nome)) col.nome_norm(u.nome) as nome, u.id
  from col.nome_uso u
  left join col.nome_uso a on a.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym')
 where u.rango = 'species' and lower(split_part(regexp_replace(u.nome, '^× ', ''), ' ', 1)) in (select genere from da_cercare)
   and col.nome_norm(u.nome) in (select nome from da_cercare)
   and u.status in ('accepted', 'provisionally accepted', 'synonym', 'ambiguous synonym')
   and coalesce(nullif(u.regno, ''), a.regno) = 'Plantae' and u.nome !~ '\sspp?\.?\s*$'
 order by col.nome_norm(u.nome), (u.status = 'accepted') desc, (u.status = 'provisionally accepted') desc,
          (u.status = 'synonym') desc, u.id;
update cv set taxon_col_id = c.id from col_trovati c
 where cv.origine_taxon = 'genere spp.' and cv.taxon_id is null and c.nome = col.nome_norm(cv.base);

-- mai sopra il genere (ICNCP art. 21.2): madri finite su una tribù o una famiglia nella fase 3 -> il genere del nome
update cv set taxon_id = n.id, origine_taxon = origine_taxon || ', genere del nome'
  from public.taxa t, nome_taxa n
 where t.id = cv.taxon_id and t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form')
   and n.nome = col.nome_norm(split_part(regexp_replace(cv.base, '^× ', ''), ' ', 1)) and n.rango = 'genus';

-- righe grex e il Gruppo Dunedin, dalle righe non cultivar della fase 3
create temp table grex as
select mp.vecchia_specie_id as id, s.slug, s.fonti, mp.taxon_id,
       case when s.nome_scientifico ~ '\sHybrids$' then 'gruppo' else 'grex' end as categoria,
       case when s.nome_scientifico ~ '\sHybrids$'
            then regexp_replace(regexp_replace(s.nome_scientifico, '^(× )?[A-Z][a-z-]+ ', ''), ' Hybrids$', ' Group')
            else regexp_replace(s.nome_scientifico, '^(× )?[A-Z][a-z-]+ ', '') end as epiteto
  from public.mappa_specie mp join public.specie s on s.id = mp.vecchia_specie_id
 where mp.origine = 'specie' and s.nome_scientifico ~ '^(× )?[A-Z][a-z-]+ [A-Z]' and s.nome_scientifico !~ ''''
   and (mp.nota ilike 'grex%' or mp.esito in ('ibrido', 'rango superiore'));

create table col.cultivar_proposte (
  id uuid primary key default gen_random_uuid(), vecchia_specie_id uuid not null unique, slug text not null unique,
  taxon_id uuid, taxon_col_id text, categoria text not null, epiteto text not null, gruppo text, nome_commerciale text,
  grex_id uuid, fonti text[] not null, origine_taxon text not null, caso text not null);
insert into col.cultivar_proposte (vecchia_specie_id, slug, taxon_id, categoria, epiteto, fonti, origine_taxon, caso)
select id, slug, taxon_id, categoria, epiteto, fonti, 'riga ' || categoria || ' della fase 3', 'riga non cultivar' from grex;
insert into col.cultivar_proposte (vecchia_specie_id, slug, taxon_id, taxon_col_id, categoria, epiteto, gruppo, nome_commerciale,
                                   fonti, origine_taxon, caso)
select id, slug, taxon_id, taxon_col_id, categoria, epiteto, gruppo, nome_commerciale, fonti, origine_taxon, caso
  from cv where caso not in ('fusa: nessun titolo con questo epiteto', 'senza epiteto leggibile');
-- cultivar figlie di una riga grex
update col.cultivar_proposte c set grex_id = g.id
  from public.specie s, col.cultivar_proposte g
 where s.id = c.vecchia_specie_id and g.vecchia_specie_id = s.specie_padre_id and g.categoria = 'grex';

create table col.cultivar_mappa (
  vecchia_specie_id uuid primary key, vecchio_slug text not null unique, vecchio_nome_scientifico text not null,
  origine text not null, taxon_id uuid, taxon_col_id text, cultivar_id uuid, esito text not null, nota text not null);
insert into col.cultivar_mappa
select id, slug, ns, 'specie', taxon_id, taxon_col_id, null, 'ambiguo',
       case when caso = 'senza epiteto leggibile' then 'cultivar senza un epiteto leggibile nel nome né nei titoli RHS'
            else 'riga nata da più cultivar RHS (' || titoli || '): nessuna cultivar, collegata al taxon' end
  from cv where caso in ('fusa: nessun titolo con questo epiteto', 'senza epiteto leggibile');
insert into col.cultivar_mappa
select d.vecchia_specie_id, d.vecchio_slug, d.vecchio_nome_scientifico, 'rollback', null, null, c.id, 'deciso dall''utente',
       'cultivar doppia cancellata il 13/10/2026 (migration 20261013110000): la stessa cultivar sotto la specie'
  from col.cultivar_doppie d join col.cultivar_proposte c on c.vecchia_specie_id = d.gemella_specie_id;

\pset tuples_only on
\pset format unaligned
select 'cultivar ' || count(*) || ' (grex ' || count(*) filter (where categoria = 'grex') || ', gruppi '
       || count(*) filter (where categoria = 'gruppo') || ', con grex_id ' || count(grex_id) || ')' from col.cultivar_proposte;
select 'taxon: ' || origine_taxon || ' ' || count(*) from col.cultivar_proposte group by origine_taxon order by count(*) desc;
select 'specie da importare da COL ' || count(distinct taxon_col_id) || ' (' || count(*) || ' cultivar)' from col.cultivar_proposte
 where taxon_col_id is not null;
select 'righe di mappa delle cultivar ' || count(*) from col.cultivar_mappa;
```

- [ ] **Step 5: Eseguirle e rilanciare le prove**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/cultivar_proposte.sql < "$F4/cultivar_estratte.tsv" 2>&1 | grep -v NOTICE
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_cultivar.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected, in meno di un minuto:
- `cultivar 196446 (grex 220, gruppi 3, con grex_id 295)`;
- `taxon: madre 192841`, `taxon: genere spp. 3322`, `taxon: riga grex della fase 3 220`, `taxon: orfana 45`, `taxon: madre, genere del nome 17`, `taxon: riga gruppo della fase 3 1`;
- `specie da importare da COL 23 (737 cultivar)` e `righe di mappa delle cultivar 167`;
- infine `NOTICE:  CULTIVAR CORRETTE: 196446 cultivar, 167 righe di mappa, 23 specie da importare`.

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/dati/fase4_cultivar_doppie.tsv scripts/tassonomia/prova_cultivar.sql scripts/tassonomia/cultivar_proposte.sql
git commit -m "Tassonomia fase 4a: taxon, grex e righe di mappa delle cultivar (copia locale) con le prove"
```

---

### Task 4: Esportazione, caricamento, verifica e rollback sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_fase4a.sh`
- Create: `scripts/tassonomia/cultivar_nuovi_taxa.sql`
- Create: `scripts/tassonomia/cultivar_esporta.sh`
- Create: `scripts/tassonomia/carica_cultivar.sh`
- Create: `scripts/tassonomia/verifica_fase4a.sql`
- Create: `scripts/tassonomia/rollback_fase4a.sql`
- Create: `scripts/tassonomia/cultivar_doppioni.sql`

**Interfaces:**
- Consumes: `col.cultivar_proposte` e `col.cultivar_mappa` (Task 3); la migration del Task 1 applicata alla copia; `carica_taxa.sh`, `verifica_fase2.sql`, `impronta_specie.sql`, `controlli_spazio.sql` (fasi 1b, 2 e 3).
- Produces:
  - `cultivar_esporta.sh URL_COPIA CARTELLA` scrive:
    - in `CARTELLA/taxa`: `lotto_01.csv`, `manifest.tsv`, `versione.txt`, `base.txt` e `regni.txt`, per `carica_taxa.sh`;
    - in `CARTELLA/cultivar`: `cultivar_01.csv`, `cultivar_02.csv`, `mappa.csv` e `manifest.tsv`;
  - `carica_cultivar.sh URL CARTELLA_CULTIVAR CARTELLA_MISURE`: ultima riga `CARICAMENTO CULTIVAR OK`;
  - `prova_fase4a.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`: ultima riga `PROVE FASE 4A OK`;
  - `$F4/cultivar_doppioni.tsv`: l'elenco dei doppioni probabili per l'utente.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/prova_fase4a.sh`:

```bash
#!/usr/bin/env bash
# Prove della fase 4a (taxon in più e cultivar) sulla copia locale: rifiuti, file alterato, ordine sbagliato, ripresa
# dopo un lotto fallito, caricamento, rilancio, rollback rifiutato ed eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase4a.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da cultivar_esporta.sh (sottocartelle taxa e cultivar). La copia deve essere
#   allo stato della fase 3 con la migration delle colonne della fase 4 applicata e cultivar vuota.
# Uscita 0 = tutte le prove passate; alla fine la copia contiene il caricamento completo.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; E=${2:?manca CARTELLA_ESPORTA}; OUT=${3:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
[ ! -e "$OUT" ] || { echo "La cartella $OUT esiste già: usarne una nuova" >&2; exit 1; }
D=scripts/tassonomia
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
conta() { "${PSQL[@]}" -tAc "select (select count(*) from public.cultivar) || ' ' || (select count(*) from public.mappa_specie m
  where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%'))
  || ' ' || (select count(*) from public.taxa where nota = 'importato nella fase 4 (cultivar)')"; }
NUOVI=$(awk -F'\t' '{ s += $2 } END { print s }' "$E/taxa/manifest.tsv")
CULTIVAR=$(awk -F'\t' '$1 ~ /^cultivar_/ { s += $2 } END { print s }' "$E/cultivar/manifest.tsv")
MAPPA=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$E/cultivar/manifest.tsv")
LOTTO1=$(awk -F'\t' '$1 == "cultivar_01.csv" { print $2 }' "$E/cultivar/manifest.tsv")
VUOTO="0 0 0"
PIENO="$CULTIVAR $MAPPA $NUOVI"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "la copia non è nello stato della fase 3 ($(conta)): prima rollback_fase4a.sql"
carica() {  # carica CARTELLA PROVA: taxon in più e poi cultivar, con log in OUT
  bash $D/carica_taxa.sh "$URL" "$E/taxa" "$OUT/$1_taxa" > "$OUT/$1_taxa.log" 2>&1 || fallita "$2" "carica_taxa: $(tail -3 "$OUT/$1_taxa.log")"
  bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/$1_cultivar" > "$OUT/$1_cultivar.log" 2>&1 \
    || fallita "$2" "carica_cultivar: $(tail -3 "$OUT/$1_cultivar.log")"
  [ "$(tail -1 "$OUT/$1_cultivar.log")" = 'CARICAMENTO CULTIVAR OK' ] || fallita "$2" "$(tail -3 "$OUT/$1_cultivar.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_cultivar.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E/cultivar" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_cultivar.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E/cultivar" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato: rifiuto prima di scrivere.
cp -R "$E/cultivar" "$OUT/cultivar_alterata"
printf 'x' >> "$OUT/cultivar_alterata/cultivar_02.csv"
out=$(bash $D/carica_cultivar.sh "$URL" "$OUT/cultivar_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: cultivar_02.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ordine sbagliato (cultivar prima dei taxon nuovi): le cultivar delle specie nuove sono nel primo lotto, che non
#    entra (chiave esterna); non entra niente.
out=$(bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/r4" 2>&1) && fallita ordine "nessun errore"
grep -qF 'violates foreign key constraint' <<<"$out" || fallita ordine "$out"
[ "$(conta)" = "$VUOTO" ] || fallita ordine "stato inatteso: $(conta)"
echo "PROVA ordine OK"

# 4. Ripresa: il secondo lotto fallisce (una riga con lo stesso slug della sua prima riga, già presente); il primo
#    resta. Tolta la riga, il rilancio salta il primo lotto e carica il resto.
bash $D/carica_taxa.sh "$URL" "$E/taxa" "$OUT/r5_taxa" > "$OUT/r5_taxa.log" 2>&1 || fallita ripresa "carica_taxa: $(tail -3 "$OUT/r5_taxa.log")"
"${PSQL[@]}" -c "insert into public.cultivar (slug, taxon_id, epiteto, fonti)
                 select slug, taxon_id, 'Prova', '{prova}' from (select split_part(l, ',', 2) as slug, split_part(l, ',', 3)::uuid as taxon_id
                   from (select '$(sed -n 2p "$E/cultivar/cultivar_02.csv" | cut -d, -f1-3)'::text as l) x) y"
out=$(bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/r5" 2>&1) && fallita ripresa "nessun errore con il secondo lotto in conflitto"
grep -qF 'duplicate key value' <<<"$out" || fallita ripresa "$out"
[ "$("${PSQL[@]}" -tAc "select count(*) from public.cultivar where epiteto <> 'Prova'")" = "$LOTTO1" ] \
  || fallita ripresa "dopo il lotto fallito ci sono $("${PSQL[@]}" -tAc 'select count(*) from public.cultivar') cultivar"
"${PSQL[@]}" -c "delete from public.cultivar where epiteto = 'Prova' and fonti = '{prova}'"
bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/r6" > "$OUT/r6.log" 2>&1 || fallita ripresa "rilancio: $(tail -3 "$OUT/r6.log")"
grep -qF 'cultivar_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita ripresa "primo lotto ricaricato"
[ "$(conta)" = "$PIENO" ] || fallita ripresa "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA ripresa OK"

# 5. Rilancio: tutto saltato, stato invariato.
carica r7 rilancio
grep -qF 'cultivar_02.csv già caricato' "$OUT/r7_cultivar/tempi.txt" || fallita rilancio "lotto delle cultivar ricaricato"
grep -qF 'righe di mappa delle cultivar già caricate' "$OUT/r7_cultivar/tempi.txt" || fallita rilancio "mappa ricaricata"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 6. Rollback: rifiutato se la fase 4b ha già una scheda di cultivar (in una transazione mai confermata), poi eseguito
#    e seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' \
        -c "insert into public.schede (cultivar_id, fonti) select id, '{prova}' from public.cultivar limit 1" \
        -f $D/rollback_fase4a.sql 2>&1) && fallita rollback "rollback accettato con la fase 4b iniziata"
grep -qF 'Rollback fase 4a rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -f $D/rollback_fase4a.sql
"${PSQL[@]}" -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r8 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 4A OK"
```

- [ ] **Step 2: Lanciarle e vederle fallire**

```bash
bash scripts/tassonomia/prova_fase4a.sh "$COPIA" "$F4/esporta" "$SCRATCH/prove_fase4a_0" > "$SCRATCH/prove_fase4a_0.log" 2>&1; echo "uscita $?"; head -1 "$SCRATCH/prove_fase4a_0.log"
```

Expected: uscita diversa da 0 con `awk: can't open file …/esporta/taxa/manifest.tsv`, perché l'esportazione non esiste ancora.

- [ ] **Step 3: Scrivere i taxon nuovi e l'esportazione**

`scripts/tassonomia/cultivar_nuovi_taxa.sql`:

```sql
-- Fase 4a: taxon di COL da aggiungere a public.taxa per le cultivar (copia locale): le specie scritte nel nome di
-- cultivar agganciate per errore a una riga "Genere spp." che mancano da taxa (taxon_col_id di col.cultivar_proposte e
-- col.cultivar_mappa), i loro accettati, la catena dei padri fino a un taxon già presente e i sinonimi degli accettati e
-- dei generi nuovi: stesse regole della fase 2 e di mappa_nuovi_taxa.sql, niente segnaposto "Genere spp".
set statement_timeout = 0;
drop table if exists col.cultivar_nuovi;
create temp table semi as
select distinct x.id from (select taxon_col_id as id from col.cultivar_proposte union select taxon_col_id from col.cultivar_mappa) x
 where x.id is not null and not exists (select 1 from public.taxa t where t.col_id = x.id);
create temp table acc as
select distinct case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end as id
  from semi s join col.nome_uso u on u.id = s.id;
create temp table catena as
with recursive c(id) as (
  select id from acc
  union
  select u.parent_id from col.nome_uso u join c on u.id = c.id
   where u.parent_id <> '' and not exists (select 1 from public.taxa t where t.col_id = u.id))
select id from c;
create temp table sin as
select u.id from col.nome_uso u
 where u.status in ('synonym', 'ambiguous synonym') and u.nome !~ '\sspp?\.?\s*$'
   and u.parent_id in (select id from acc
                       union select c.id from catena c join col.nome_uso g on g.id = c.id where g.rango = 'genus');
create table col.cultivar_nuovi (col_id text primary key, id uuid not null unique default gen_random_uuid());
insert into col.cultivar_nuovi (col_id)
  select id from semi union select id from catena union select id from sin
  except select col_id from public.taxa where col_id is not null;
do $$
declare n bigint;
begin
  -- chiusura: il padre di ogni nuovo accettato e l'accettato di ogni nuovo sinonimo sono in taxa o tra i nuovi
  select count(*) into n from col.cultivar_nuovi m join col.nome_uso u on u.id = m.col_id
   where u.parent_id <> '' and not exists (select 1 from col.cultivar_nuovi x where x.col_id = u.parent_id)
     and not exists (select 1 from public.taxa t where t.col_id = u.parent_id);
  if n > 0 then raise exception 'nuovi taxon con il padre o l''accettato mancante: %', n; end if;
end $$;
\pset tuples_only on
\pset format unaligned
select 'specie cercate ' || (select count(*) from semi) || ', nuovi taxon COL ' || count(*) from col.cultivar_nuovi;
```

`scripts/tassonomia/cultivar_esporta.sh`:

```bash
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
```

- [ ] **Step 4: Scrivere il caricamento, la verifica e il rollback**

`scripts/tassonomia/carica_cultivar.sh`:

```bash
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
```

`scripts/tassonomia/verifica_fase4a.sql`:

```sql
-- Fase 4a: controllo di public.cultivar e delle righe di mappa_specie delle cultivar dopo il caricamento. Sola lettura.
-- Variabili psql: righe_cultivar (righe dei lotti) e righe_mappa (righe di mappa.csv).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_cultivar=N -v righe_mappa=M -f scripts/tassonomia/verifica_fase4a.sql
select set_config('fase4a.righe_cultivar', :'righe_cultivar', false), set_config('fase4a.righe_mappa', :'righe_mappa', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase4a.righe_cultivar')::bigint;
  mappa bigint := current_setting('fase4a.righe_mappa')::bigint;
  n bigint;
begin
  select count(*) into n from public.cultivar;
  if n <> attese then raise exception 'cultivar: % righe, attese %', n, attese; end if;
  -- ogni riga cultivar di specie (epiteto tra apici) è una cultivar o una riga di mappa, mai le due cose
  select count(*) into n from public.specie s where s.nome_scientifico like '%''%'
     and (select count(*) from public.cultivar c where c.vecchia_specie_id = s.id)
       + (select count(*) from public.mappa_specie m where m.vecchia_specie_id = s.id) <> 1;
  if n > 0 then raise exception 'righe cultivar di specie senza cultivar e senza mappa, o con tutte e due: %', n; end if;
  -- le cultivar vengono da una riga di specie, con lo stesso slug e le stesse fonti; grex e Gruppo Dunedin da righe non
  -- cultivar, le altre da righe con l'epiteto tra apici
  select count(*) into n from public.cultivar c left join public.specie s on s.id = c.vecchia_specie_id
   where s.id is null or s.slug <> c.slug or s.fonti <> c.fonti
      or (s.nome_scientifico !~ '''' and c.categoria = 'cultivar') or (s.nome_scientifico ~ '''' and c.categoria = 'grex');
  if n > 0 then raise exception 'cultivar che non corrispondono alla loro riga di specie: %', n; end if;
  -- taxon: mai sopra il genere (ICNCP art. 21.2)
  select count(*) into n from public.cultivar c join public.taxa t on t.id = c.taxon_id
   where t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'cultivar su un taxon sopra il genere: %', n; end if;
  -- grex: le figlie puntano a un grex
  select count(*) into n from public.cultivar c join public.cultivar g on g.id = c.grex_id where g.categoria <> 'grex';
  if n > 0 then raise exception 'grex_id che non punta a un grex: %', n; end if;
  -- righe di mappa delle cultivar: le fuse o illeggibili verso un taxon, le doppie (da rollback) verso una cultivar
  select count(*) into n from public.mappa_specie m
   where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%');
  if n <> mappa then raise exception 'righe di mappa delle cultivar: %, attese %', n, mappa; end if;
  select count(*) into n from public.mappa_specie m where m.cultivar_id is not null and (m.origine <> 'rollback' or m.taxon_id is not null);
  if n > 0 then raise exception 'righe di mappa verso una cultivar che non vengono dai rollback: %', n; end if;
  -- indici secondari presenti
  select count(*) into n from unnest(array['cultivar_taxon_id_idx', 'cultivar_epiteto_trgm_idx', 'cultivar_nome_commerciale_trgm_idx',
                                           'cultivar_grex_id_idx']) i where to_regclass('public.' || i) is null;
  if n > 0 then raise exception 'indici secondari di cultivar mancanti: %', n; end if;
  -- permessi: le colonne interne non si leggono con la chiave pubblica
  if has_column_privilege('anon', 'public.cultivar', 'fonti', 'select') or has_column_privilege('anon', 'public.cultivar', 'vecchia_specie_id', 'select')
     or not has_column_privilege('anon', 'public.cultivar', 'epiteto', 'select') or not has_column_privilege('anon', 'public.cultivar', 'grex_id', 'select') then
    raise exception 'permessi di colonna di cultivar inattesi';
  end if;
  raise notice 'cultivar: % righe (%), con grex_id %, con gruppo %, con nome commerciale %; righe di mappa delle cultivar %', attese,
    (select string_agg(categoria || ' ' || c, ', ' order by c desc) from (select categoria, count(*) c from public.cultivar group by 1) x),
    (select count(grex_id) from public.cultivar), (select count(gruppo) from public.cultivar),
    (select count(nome_commerciale) from public.cultivar), mappa;
end $$;
```

`scripts/tassonomia/rollback_fase4a.sql`:

```sql
-- Rollback della fase 4a: toglie le righe di mappa_specie delle cultivar, tutte le cultivar e i taxon di COL aggiunti
-- per le cultivar (riconoscibili dalla nota). Le righe di mappa della fase 3 e i taxon delle fasi 2 e 3 restano.
-- Si rifiuta se una scheda punta a una cultivar (fase 4b) o una pianta punta a una cultivar (fase 5).
-- Non TRUNCATE: schede, piante e mappa_specie hanno chiavi esterne verso cultivar.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4a.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.schede where cultivar_id is not null) or exists (select 1 from public.piante where cultivar_id is not null) then
    raise exception 'Rollback fase 4a rifiutato: schede o piante puntano già a una cultivar';
  end if;
end $$;
-- gli indici sulle chiavi esterne servono alla DELETE (vedi rollback_fase2.sql)
create index if not exists cultivar_taxon_id_idx on public.cultivar (taxon_id);
create index if not exists cultivar_grex_id_idx on public.cultivar (grex_id) where grex_id is not null;
create index if not exists taxa_padre_id_idx on public.taxa (padre_id);
create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id);
delete from public.mappa_specie m
 where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%');
delete from public.cultivar;
delete from public.taxa where origine = 'col' and nota = 'importato nella fase 4 (cultivar)';
```

- [ ] **Step 5: Esportare e lanciare le prove, due volte di fila**

Prima del secondo giro va fatto il rollback, perché le prove partono da `cultivar` vuota.

```bash
chmod +x scripts/tassonomia/cultivar_esporta.sh scripts/tassonomia/carica_cultivar.sh scripts/tassonomia/prova_fase4a.sh
bash scripts/tassonomia/cultivar_esporta.sh "$COPIA" "$F4/esporta" 2>&1 | grep -v NOTICE
bash scripts/tassonomia/prova_fase4a.sh "$COPIA" "$F4/esporta" "$SCRATCH/prove_fase4a_1" > "$SCRATCH/prove_fase4a_1.log" 2>&1; echo "giro 1 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4a_1.log"
$PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4a.sql 2>/dev/null
$PG/psql "$COPIA" -X -q -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
bash scripts/tassonomia/prova_fase4a.sh "$COPIA" "$F4/esporta" "$SCRATCH/prove_fase4a_2" > "$SCRATCH/prove_fase4a_2.log" 2>&1; echo "giro 2 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4a_2.log"
grep -h 'NOTICE:  cultivar\|NOTICE:  taxa' "$SCRATCH/prove_fase4a_1/r8_cultivar.log" "$SCRATCH/prove_fase4a_1/r8_taxa.log"; grep -h 'WAL' "$SCRATCH/prove_fase4a_1/r8_taxa/tempi.txt" "$SCRATCH/prove_fase4a_1/r8_cultivar/tempi.txt"
$PG/psql "$COPIA" -X -qAt -c "select 'cultivar ' || pg_size_pretty(pg_total_relation_size('public.cultivar'))"
shasum -a 256 "$F4/esporta/taxa/manifest.tsv" "$F4/esporta/cultivar/manifest.tsv"
```

Expected:
- dall'esportazione: `specie cercate 23, nuovi taxon COL 389`, `lotto_01.csv 389`, `cultivar_01.csv 100000`, `cultivar_02.csv 96446`, `mappa.csv 167`, `base 241303, regni Fungi,Plantae`;
- per tutti e due i giri `uscita 0`, poi `PROVA rifiuti OK`, `PROVA alterato OK`, `PROVA ordine OK`, `PROVA ripresa OK`, `PROVA rilancio OK`, `PROVA rollback OK`, `PROVE FASE 4A OK`;
- la NOTICE `cultivar: 196446 righe (cultivar 196223, grex 220, gruppo 3), con grex_id 295, con gruppo 3969, con nome commerciale 14166; righe di mappa delle cultivar 167` e `taxa: 241692 righe`;
- WAL sotto 100 MB in ogni passo (sul prototipo 0,4, 52,2, 61,3 e 7,1 MB);
- `cultivar 86 MB`.

Annotare nel registro i due sha256: il Task 5 li confronta.

- [ ] **Step 6: Prove di mutazione**

Ogni mutazione si applica a una copia di sicurezza dello script e si ripristina subito dopo. Tra un giro e l'altro la copia torna a `cultivar` vuota.

```bash
torna() { $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4a.sql > /dev/null 2>&1; $PG/psql "$COPIA" -X -q -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'; }
muta() {  # muta FILE ESPRESSIONE_SED NOME
  cp "$1" "$SCRATCH/mutazione.bak"; sed -i '' "$2" "$1"
  cmp -s "$1" "$SCRATCH/mutazione.bak" && echo "MUTAZIONE $3 NON APPLICATA"
  torna
  bash scripts/tassonomia/prova_fase4a.sh "$COPIA" "$F4/esporta" "$SCRATCH/mut4a_$3" > "$SCRATCH/mut4a_$3.log" 2>&1
  echo "mutazione $3: uscita $? — $(grep -E 'FALLITA' "$SCRATCH/mut4a_$3.log" | head -1 | cut -c1-90)"
  cp "$SCRATCH/mutazione.bak" "$1"
}
muta scripts/tassonomia/carica_cultivar.sh 's/\[ "$(shasum -a 256 "$CV\/$file" | cut -d. . -f1)" = "$sha" \]/true/' sha
muta scripts/tassonomia/carica_cultivar.sh 's/^  if caricato "$primo"; then tempo "$file già caricato"; continue; fi$/  :/' ripresa
muta scripts/tassonomia/rollback_fase4a.sql 's/raise exception .Rollback fase 4a rifiutato.*;/null;/' rifiuto
git status --short scripts/tassonomia/
torna
bash scripts/tassonomia/prova_fase4a.sh "$COPIA" "$F4/esporta" "$SCRATCH/prove_fase4a_finale" > "$SCRATCH/prove_fase4a_finale.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_fase4a_finale.log"
```

Expected:
- nessuna riga `NON APPLICATA`;
- `mutazione sha: … PROVA alterato FALLITA`;
- `mutazione ripresa: … PROVA ripresa FALLITA`;
- `mutazione rifiuto: … PROVA rollback FALLITA`;
- `git status` mostra solo i file nuovi di questo task;
- infine `uscita 0` e `PROVE FASE 4A OK`: la copia resta con il caricamento completo, con le stesse chiavi che andranno sul reale.

- [ ] **Step 7: Elenco dei doppioni per l'utente**

`scripts/tassonomia/cultivar_doppioni.sql`:

```sql
-- Fase 4a: elenco dei probabili doppioni tra le cultivar caricate, da far vedere all'utente (specifica, "Decisioni per
-- la fase 4", punto 18: nessuna fusione automatica). Stesso taxon e stesso epiteto a meno di maiuscole, apici
-- tipografici, trattini e spazi; le cultivar di orchidea con lo stesso epiteto in grex diversi sono ammesse (ICNCP
-- art. 6.5) e non compaiono. Sola lettura. Uscita: TSV con numero, taxon, epiteti, slug e nomi vecchi del gruppo.
\pset footer off
\pset format unaligned
\pset fieldsep '\t'
with c as (
  select c.*, lower(regexp_replace(translate(c.epiteto, '’‘´`-', ''''''''), '\s+', '', 'g')) as norm
    from public.cultivar c where c.categoria = 'cultivar'),
g as (
  select taxon_id, norm, coalesce(grex_id::text, '') as grex from c group by 1, 2, 3 having count(*) > 1)
select row_number() over (order by t.nome_scientifico, g.norm) as numero, t.nome_scientifico as taxon,
       string_agg(c.epiteto, ' | ' order by c.slug) as epiteti, string_agg(c.slug, ' | ' order by c.slug) as slug,
       string_agg(s.nome_scientifico, ' | ' order by c.slug) as nomi_vecchi
  from g join c on c.taxon_id = g.taxon_id and c.norm = g.norm and coalesce(c.grex_id::text, '') = g.grex
  join public.taxa t on t.id = g.taxon_id
  join public.specie s on s.id = c.vecchia_specie_id
 group by g.taxon_id, g.norm, g.grex, t.nome_scientifico
 order by 1;
```

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/cultivar_doppioni.sql > "$F4/cultivar_doppioni.tsv"; wc -l < "$F4/cultivar_doppioni.tsv"
```

Expected: 144 righe (143 gruppi più l'intestazione), per esempio *Allium cepa* 'Jet Set' | 'Jetset' e *Agapanthus* 'Dawn Star' | 'Dawnstar'. La ricerca ne contava 41 senza ignorare gli spazi.

- [ ] **Step 8: Commit**

```bash
git add scripts/tassonomia/prova_fase4a.sh scripts/tassonomia/cultivar_nuovi_taxa.sql scripts/tassonomia/cultivar_esporta.sh \
        scripts/tassonomia/carica_cultivar.sh scripts/tassonomia/verifica_fase4a.sql scripts/tassonomia/rollback_fase4a.sql \
        scripts/tassonomia/cultivar_doppioni.sql
git commit -m "Tassonomia fase 4a: esportazione, caricamento, verifica e rollback delle cultivar con le prove sulla copia locale"
```

**Prima del Task 5:** revisione dei commit dei Task 1–4 da parte di revisori nuovi (vedi Global Constraints). Ogni revisore scrive i risultati confermati in un file di note mentre lavora. Le correzioni importanti si fanno con una prova che fallisce prima. Se cambiano i file esportati, si rigenera l'esportazione in una cartella nuova, si rilanciano le prove e si annotano i nuovi sha256.

---

### Task 5: Caricamento sul database reale e documentazione

**Files:**
- Modify: `CLAUDE.md` (sezione "Modello tassonomico")

**Interfaces:**
- Consumes: `$F4/esporta` (Task 4) con gli sha256 annotati; la migration e i suoi script (Task 1); `carica_taxa.sh`, `carica_cultivar.sh`, `verifica_fase4a.sql`.

- [ ] **Step 1: Backup e controlli di partenza (solo letture)**

```bash
set -a; source .env.local; set +a
python3 -c 'import os, urllib.parse; print("porta", urllib.parse.urlsplit(os.environ["SUPABASE_DB_URL"]).port)'
echo "base $(cat "$F4/esporta/taxa/base.txt"), regni $(cat "$F4/esporta/taxa/regni.txt"), versione $(cat "$F4/esporta/taxa/versione.txt")"
TS=$(date +%Y%m%d_%H%M%S)
BK=backups/completo_${TS}_pre_fase4a.dump
$PG/pg_dump "$SUPABASE_DB_URL" -Fc -f "$BK"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "${BK%.dump}.impronta.txt"
$PG/pg_restore -f /dev/null "$BK" && echo BACKUP LEGGIBILE
diff backups/completo_20261016_111535_pre_fase3.impronta.txt "${BK%.dump}.impronta.txt" && echo "SPECIE COME NELLA COPIA"
$PG/psql "$SUPABASE_DB_URL" -X -q -f scripts/tassonomia/controlli_spazio.sql
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "select 'taxa col ' || count(*) filter (where origine = 'col') || ', locali ' || count(*) filter (where origine = 'locale') from public.taxa" -c "select 'mappa ' || count(*) || ', cultivar ' || (select count(*) from public.cultivar) from public.mappa_specie" -c "select 'grex_id ' || count(*) from information_schema.columns where table_schema = 'public' and table_name = 'cultivar' and column_name = 'grex_id'"
shasum -a 256 "$F4/esporta/taxa/manifest.tsv" "$F4/esporta/cultivar/manifest.tsv"
```

Expected:
- `porta 5432`; se è diversa, fermarsi;
- `base 241303, regni Fungi,Plantae, versione COL26.9 XR`;
- `BACKUP LEGGIBILE` e `SPECIE COME NELLA COPIA` (l'impronta di `specie` del backup della fase 3, uguale a quella della copia). Se no, fermarsi: i nomi da cui sono nate le cultivar sono cambiati;
- `somma_db_mb` circa 271, `wal_mb` sotto 300;
- `taxa col 241303, locali 8`, `mappa 15713, cultivar 0` e `grex_id 0` (la migration non è ancora applicata);
- i due sha256 uguali a quelli annotati nel Task 4. Se no, fermarsi: i file non sono quelli provati.

- [ ] **Step 2: Via esplicito dell'utente**

Chiedere in chat il via, dicendo:
- **cosa entra:** una colonna nuova in `cultivar` e una in `schede` (tabelle ancora vuote), 389 nomi di COL, 196.446 righe di `cultivar` e 167 righe di `mappa_specie`;
- **durata:** circa 35 minuti, di cui 30 di pause volute tra un passo e l'altro (10 minuti dopo i taxon, 10 tra i due lotti di cultivar, 10 prima degli indici);
- **effetto sull'app:** nessuno, perché l'app non legge ancora queste tabelle;
- **spazio:** circa 86 MB in più, fino a circa 357 MB su 500;
- **dati:** non cambia niente fuori da `taxa`, `cultivar` e `mappa_specie`; l'impronta di `specie` si confronta prima e dopo;
- **ripresa:** se si interrompe basta rilanciare lo stesso comando;
- **rollback:** pronto e provato (`rollback_fase4a.sql`, poi `rollback_fase4_colonne.sql`).

Senza un sì esplicito ci si ferma qui.

- [ ] **Step 3: Applicare la migration e caricare**

Va lanciato dalla sessione principale in background (`run_in_background`), senza fermarlo. Se il controllo dei permessi lo blocca, dare all'utente lo stesso blocco da incollare nel suo terminale. Per sapere se è attivo usare `pgrep -f carica_`, che stampa solo il pid.

```bash
set -a; source .env.local; set +a
OUT=backups/fase4a_$(date +%Y%m%d_%H%M%S)
mkdir -p "$OUT"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -1 -f supabase/migrations/20261017100000_tassonomia_fase4_colonne.sql > "$OUT.migration.log" 2>&1 \
  && $PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_fase4_colonne.sql >> "$OUT.migration.log" 2>&1 \
  && CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_taxa.sh "$SUPABASE_DB_URL" "$F4/esporta/taxa" "$OUT/taxa" > "$OUT.taxa.log" 2>&1 \
  && CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_cultivar.sh "$SUPABASE_DB_URL" "$F4/esporta/cultivar" "$OUT/cultivar" > "$OUT.cultivar.log" 2>&1; echo "uscita $?"
diff "${BK%.dump}.impronta.txt" "$OUT/taxa/impronta_specie_prima.txt" && diff "${BK%.dump}.impronta.txt" "$OUT/cultivar/impronta_specie_dopo.txt" && echo "SPECIE INVARIATA DALLO STEP 1"
```

Se tra lo Step 1 e lo Step 3 è passato molto tempo, prima di lanciare rifare l'impronta di `specie` e il confronto dello Step 1.

Expected:
- `uscita 0`;
- in `$OUT.migration.log` `NOTICE:  COLONNE FASE 4 OK`;
- in `$OUT.taxa.log` `taxa: 241692 righe` e `CARICAMENTO TAXA OK`;
- in `$OUT.cultivar.log` la NOTICE `cultivar: 196446 righe (…)` e `CARICAMENTO CULTIVAR OK`;
- `SPECIE INVARIATA DALLO STEP 1`;
- somma dei database circa 357 MB.

Se l'uscita non è 0, prima di tutto (sola lettura) `controlli_spazio.sql` e i conteggi dello Step 1. Poi:
- **errore nella migration:** non è stato scritto niente (`psql -1`); riferire;
- **`FERMATO: spazio insufficiente`, interruzione o connessione persa:** rilanciare lo stesso comando dopo aver tolto la migration dalla catena se è già applicata (`grex_id 1` nei conteggi): i caricamenti saltano i passi fatti;
- **`RIFIUTATO`:** non è stato scritto niente in quel passo; riferire;
- **`violates foreign key constraint` in `carica_cultivar.sh`:** i taxon nuovi non ci sono. Rilanciare da `carica_taxa.sh`;
- **`FALLITO: specie è cambiata` o un errore delle verifiche:** fermarsi e riferire. Il rollback si decide insieme: `rollback_fase4a.sql` con `psql -1`, poi `vacuum full` di `mappa_specie`, `cultivar` e `taxa`, poi `rollback_fase4_colonne.sql`.

- [ ] **Step 4: Controlli finali**

```bash
set -a; source .env; source .env.local; set +a
curl -s -w ' %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/cultivar?select=epiteto,nome_commerciale,grex_id&slug=eq.geranium-gerwat" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -o /dev/null -w 'fonti delle cultivar con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/cultivar?select=fonti&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c 'show statement_timeout' -c 'show lock_timeout'
```

Expected:
- `[{"epiteto":"Gerwat","nome_commerciale":"Rozanne","grex_id":null}] 200`;
- `fonti delle cultivar con la chiave pubblica: 401`;
- `2min` e `0`.

- [ ] **Step 5: Elenco dei doppioni all'utente e CLAUDE.md**

1. Pubblicare `$F4/cultivar_doppioni.tsv` come pagina privata (Artifact, con la skill `artifact-design`), con una frase che spiega che sono probabilmente la stessa cultivar scritta in due modi e che nessuna è stata fusa. Dare il link all'utente: le fusioni, se le vorrà, si fanno dopo con un aggiornamento di poche righe. Non è un passo che blocca.
2. La copia locale resta accesa: la 4b la usa con le stesse chiavi.
3. In `CLAUDE.md`, il titolo "### Modello tassonomico (in corso, fasi 1, 1b, 2 e 3 di 7 applicate)" diventa "### Modello tassonomico (in corso, fasi 1, 1b, 2, 3 e 4a di 7 applicate)" e in fondo alla sezione va aggiunto questo paragrafo, con le misure reali al posto di quelle attese se diverse:

```markdown
La fase 4a (piano `docs/superpowers/plans/2026-10-16-modello-tassonomico-fase4a-cultivar.md`) ha caricato `cultivar`: 196.446 righe (196.223 cultivar, 220 grex, 3 Gruppi) da ognuna delle 196.388 righe di `specie` con l'epiteto tra apici, più i grex e il Gruppo Dunedin, che erano righe non cultivar.
- **Epiteto, Gruppo e nome commerciale** riletti dai titoli delle pagine RHS già scaricate (`scripts/rhs-import/rhs_sitemaps_parsed.jsonl`, git-ignorato): 1.854 epiteti troncati dall'import corretti, 3.969 Gruppi, 14.166 nomi commerciali (decisioni 15 e 19 della fase 4). L'epiteto non si traduce mai.
- **Taxon:** il nome trovato della madre in `mappa_specie`, anche se sinonimo; le 3.330 cultivar di specie agganciate per errore a una riga «Genere spp.» sono sulla loro specie, con 23 specie importate da COL (389 righe di `taxa` con `nota = 'importato nella fase 4 (cultivar)'`); mai sopra il genere (ICNCP art. 21.2).
- **Grex:** categoria `grex`; le 295 cultivar di orchidea figlie hanno `cultivar.grex_id` (migration `20261017100000_tassonomia_fase4_colonne.sql`, che aggiunge anche `schede.nota` per la fase 4b; rollback `rollback_fase4_colonne.sql`).
- **Righe di mappa delle cultivar:** 167 in `mappa_specie`: 163 righe fuse da più cultivar RHS o senza epiteto leggibile (nessuna cultivar, esito «ambiguo») e 4 cultivar doppie cancellate il 13/10 (verso la gemella). Dopo la 4a `verifica_fase3.sql` non vale più: conta solo le righe della fase 3.
- **Doppioni:** nessuna fusione automatica; 143 gruppi probabili (stesso taxon ed epiteto a meno di maiuscole, trattini e spazi) dati all'utente in una pagina privata (`~/giardino-dati/col/fase4/cultivar_doppioni.tsv`).
- **Spazio:** circa 357 MB su 500. Caricamento in 2 lotti con pause di 10 minuti; impronta di `specie` identica prima e dopo. Backup preso prima: il file `$BK` dello Step 1 (`backups/completo_…_pre_fase4a.dump`).
- **Script, tutti in `scripts/tassonomia/`:** `cultivar_titoli.py` e `cultivar_estrai.py` (titoli RHS, prove `python3 -m unittest scripts/tassonomia/test_cultivar_titoli.py`); `cultivar_proposte.sql` e `prova_cultivar.sql` (copia locale con COL); `cultivar_nuovi_taxa.sql` e `cultivar_esporta.sh`; `carica_cultivar.sh`, `verifica_fase4a.sql`, `rollback_fase4a.sql` (rifiutato se una scheda o una pianta punta a una cultivar); `cultivar_doppioni.sql`.
- **Prove:** `bash scripts/tassonomia/prova_fase4a.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`, su una copia allo stato della fase 3 con la migration applicata, i permessi della fase 1 e una `public.piante` minima (vedi il piano, Task 1).
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "Tassonomia fase 4a applicata: cultivar (196.446 righe), grex e taxon in più, CLAUDE.md"
```

Nessun push senza richiesta dell'utente.
