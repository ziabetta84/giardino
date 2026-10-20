# Modello tassonomico, fase 7: passaggio definitivo — piano di implementazione

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** l'app usa solo le tabelle nuove; `specie` e `generi` diventano un archivio in sola lettura, non più leggibile dai client; la colonna `piante.specie` sparisce; gli indici di ricerca dell'archivio si tolgono (con il via dell'utente).

**Architecture:** prima l'app smette di leggere e scrivere `piante.specie` (pubblicata con il push), poi una migration sul database toglie la colonna e chiude l'archivio: revoca dei permessi ai client, niente più policy di lettura, un trigger che rifiuta ogni scrittura su `specie` e `generi` anche da `postgres`, salvo un'impostazione di sessione esplicita. Una seconda migration, separata, toglie i 4 indici trigram di `specie`. L'ordine conta: con la colonna tolta prima del deploy, l'app pubblicata fallirebbe a ogni salvataggio di una pianta.

**Tech Stack:** Postgres 17 su Supabase, Vue 3 + Pinia, `node --test`.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md` (Principi 1 e 2; Fasi, punto 7; `piante`: «la colonna `specie` resta finché l'app non è passata al nuovo modello»).

## Global Constraints

- I dati di `specie` e `generi` non cambiano: impronta (`scripts/tassonomia/impronta_specie.sql`) identica prima e dopo.
- Nessuna applicazione al reale senza il via esplicito in chat; nessun push senza richiesta; backup completo prima.
- Mai stampare l'URL del database; processi solo con `pgrep -f`; solo la porta 5432.
- Prove sulla copia locale (55440, database `giardino`).
- Nel frontend la fonte non si nomina mai.

## Decisioni da approvare

**Esito (20/10/2026):** approvate la 1 (togliere `piante.specie`), la 4 (indici) e la 5 (`specie.json`); la 2 (archivio chiuso ai client) e la 3 (trigger di sola lettura) non sono state scelte e restano fuori da questa fase: `specie` e `generi` mantengono permessi e policy di oggi. Il Task 2 si riduce quindi alla colonna di `piante`.

1. **`piante.specie` si toglie** (colonna e chiave esterna verso `specie`). Il vecchio slug di ogni pianta resta in `scripts/tassonomia/dati/fase5_piante.tsv` e il collegamento vecchio→nuovo in `mappa_specie`; il rollback rimette la colonna e la riempie da quel file.
2. **Archivio chiuso ai client:** revocati tutti i permessi di `anon` e `authenticated` su `specie` e `generi` (oggi hanno perfino TRUNCATE) e tolte le policy di lettura pubblica: l'app non le legge più e così la colonna `fonti` dell'archivio non è più leggibile con la chiave pubblica. `service_role` mantiene solo la lettura.
3. **Sola lettura anche per gli script:** un trigger su `specie` e `generi` rifiuta inserimenti, modifiche, cancellazioni e TRUNCATE, anche da `postgres`, salvo `set local giardino.archivio_scrivibile = 'si'` nella stessa transazione (per un rollback o una correzione voluta). Così un vecchio script dei lotti o una vecchia istruzione di `/zorbadice` non può più scriverci per sbaglio.
4. **Indici di ricerca dell'archivio tolti** (4 indici trigram, circa 31 MB): reversibile con `scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql`. Migration separata, applicata solo dopo la prima.
5. **`public/data/specie.json` tolto** dal repository (22 MB pubblicati a ogni deploy, non più letti dalla fase 6); resta nella storia di git e nel backup.

## Review Focus

- Una pianta salvata dall'app pubblicata vecchia (PWA non aggiornata) dopo la migration: errore visibile, nessun dato perso (la colonna `specie` non c'è più); va detto all'utente di aggiornare l'app prima.
- Un rollback della fase 6 o della fase 5 dopo la fase 7: deve rifiutare con un messaggio chiaro (prima `rollback_fase7.sql`).
- `verifica_fase6.sql` dopo la fase 7: controlla `piante.specie`; va adattata.

---

### Task 1: l'app non usa più piante.specie

**Files:** `src/stores/dati.js` (`mappaPiante`, `nomePianta`), `src/composables/usePianteApi.js` (`salvaPianta`), `src/composables/useSuggerimentoIrrigazione.js:44`, `src/views/PianteView.vue:212`, `src/views/PiantaView.vue:204`; tolto `public/data/specie.json`.

- [ ] **Step 1 (RED):** `grep -rnE "p\.specie|pianta\?*\.specie|precedente\?\.specie|specie: p\.specie|specie\.json" src public` → righe trovate.
- [ ] **Step 2:** `mappaPiante` senza `specie`; `nomePianta(p)` → `vocePianta(p)?.nome ?? 'Pianta'`; in `salvaPianta` niente più `specie` nella riga né nello store (resta solo `...colonne`); `useSuggerimentoIrrigazione.js:44` → `sp?.nome ?? 'Pianta'`; `PianteView.vue:212` → `store.vocePianta(p)?.specie ?? ''`; `PiantaView.vue:204` → `:titolo="pianta ? store.nomePianta(pianta) : ''"`; `git rm public/data/specie.json`; commento di `dati.js` aggiornato.
- [ ] **Step 3 (GREEN):** stesso grep → nessuna riga (salvo `useRichiesteAgente.js`/`AgenteView.vue`, dove `r.specie` è il campo delle vecchie richieste); `npm run build` riuscita; `node --test 'src/utils/*.test.mjs'` verde.
- [ ] **Step 4:** commit «Tassonomia fase 7: l'app non usa più piante.specie, tolto specie.json».

### Task 2: archivio in sola lettura e colonna tolta (migration)

**Files:** `supabase/migrations/20261021120000_tassonomia_fase7_archivio.sql`, `scripts/tassonomia/rollback_fase7.sql`, `scripts/tassonomia/prova_fase7.sql`, `scripts/tassonomia/prova_fase7.sh`, `scripts/tassonomia/verifica_fase7.sql`; adattati `verifica_fase6.sql`, `rollback_fase6.sql`, `rollback_fase5.sql` (rifiuto chiaro se manca `piante.specie`).

- [ ] **Step 1 (RED):** `prova_fase7.sql` (blocco `do`, sulla copia con la migration applicata): con `set local role anon` e `authenticated`, `select` su `specie` e `generi` negato (42501); da `postgres`, `update public.specie set nome = nome where slug = 'pomodoro'` rifiutato dal trigger con «archivio in sola lettura», e lo stesso per `insert`, `delete`, `truncate` e per `generi`; con `set local giardino.archivio_scrivibile = 'si'` in un sottoblocco annullato l'aggiornamento passa; `piante` non ha la colonna `specie`; nessuna policy su `specie` e `generi`; `service_role` ha solo `SELECT`; `catalogo_voci` e `cerca_catalogo` danno ancora le 122 voci e «rosmarino». `prova_fase7.sh URL_COPIA`: guardia sull'URL locale, migration, prova, rollback rifiutato se una pianta creata dopo non è nel file della fase 5, rollback, impronta di `specie` identica a prima, di nuovo la migration. Prima della migration la prova fallisce.
- [ ] **Step 2 (GREEN):** la migration:

```sql
-- Fase 7 del modello tassonomico: passaggio definitivo. specie e generi restano come archivio in sola lettura: nessun
-- permesso ai client, nessuna policy, un trigger che rifiuta ogni scrittura (anche da postgres) salvo
-- set local giardino.archivio_scrivibile = 'si'. La colonna piante.specie si toglie: il vecchio slug è in
-- scripts/tassonomia/dati/fase5_piante.tsv. Rollback: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase7.sql
revoke all on public.specie, public.generi from anon, authenticated, service_role;
grant select on public.specie, public.generi to service_role;
drop policy "specie: lettura pubblica" on public.specie;
drop policy "generi: lettura pubblica" on public.generi;

create function public.archivio_sola_lettura() returns trigger language plpgsql set search_path = '' as $$
begin
  if coalesce(current_setting('giardino.archivio_scrivibile', true), '') <> 'si' then
    raise exception 'archivio in sola lettura: % non è più modificabile (fase 7 del modello tassonomico)', tg_table_name
      using hint = 'per una correzione voluta: set local giardino.archivio_scrivibile = ''si'' nella stessa transazione';
  end if;
  return null;
end $$;
revoke all on function public.archivio_sola_lettura() from public, anon, authenticated;
create trigger specie_sola_lettura before insert or update or delete on public.specie
  for each statement execute function public.archivio_sola_lettura();
create trigger specie_sola_lettura_truncate before truncate on public.specie
  for each statement execute function public.archivio_sola_lettura();
create trigger generi_sola_lettura before insert or update or delete on public.generi
  for each statement execute function public.archivio_sola_lettura();
create trigger generi_sola_lettura_truncate before truncate on public.generi
  for each statement execute function public.archivio_sola_lettura();

alter table public.piante drop constraint if exists piante_specie_fkey;
alter table public.piante drop column specie;
```

  (Il trigger «for each statement» con `return null` lascia passare l'istruzione quando l'impostazione è attiva.) Il rollback: rifiuta se una pianta non è nel file della fase 5 (creata dopo: non avrebbe una vecchia specie); aggiunge `piante.specie text`, la riempie dal file, la rende obbligatoria, rimette la chiave esterna `on update cascade`, toglie trigger e funzione, rimette le policy e i permessi di prima (`grant all … to anon, authenticated, service_role`, come oggi). `verifica_fase7.sql` (reale, transazione annullata): le stesse condizioni della prova, senza l'impronta, che si confronta a parte con `impronta_specie.sql`.
- [ ] **Step 3:** mutazione: togliere il trigger su `generi` → la prova fallisce; ripristinare.
- [ ] **Step 4:** commit.

### Task 3: indici di ricerca dell'archivio (migration separata)

**Files:** `supabase/migrations/20261021130000_tassonomia_fase7_indici_archivio.sql` (`drop index` dei 4 trigram: `specie_nome_trgm_idx`, `specie_nome_scientifico_trgm_idx`, `specie_nomi_alternativi_trgm_idx`, `specie_sinonimi_botanici_trgm_idx`); rollback = `manutenzione_specie_3_ricrea_indici.sql` (verificare che ricrei proprio questi 4, identici).
- [ ] Prova sulla copia: drop, poi ricreazione, definizioni identiche (`pg_get_indexdef`) a prima; commit.

### Task 4: documentazione

CLAUDE.md (architettura dello store, sezione «Migrazione specie → Supabase» come storia con il rinvio all'archivio, paragrafo della fase 7, tabella dei file di `public/data/` senza `specie.json`), README (citazioni di `specie.json`), `.claude/commands/zorbadice.md` (l'archivio non è più leggibile da `anon`; si legge solo da `postgres`).

### Task 5: revisione finale (un revisore) e correzioni

### Task 6: applicazione (solo con il via dell'utente, in quest'ordine)

1. Push (richiesta dell'utente) e deploy dell'app del Task 1 (workflow Pages verde); l'utente aggiorna l'app con il banner su ogni dispositivo: un'app rimasta alla fase 6 non riesce più a creare né modificare piante dopo la migration.
2. Backup completo e impronta di `specie`.
3. Migration del Task 2, `verifica_fase7.sql`, impronta identica.
4. Migration del Task 3, spazio prima e dopo.
5. Controllo nel browser: aggiungi, modifica ed elimina una pianta; ricerca.
