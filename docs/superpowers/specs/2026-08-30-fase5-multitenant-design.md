# Design: Fase 5 migrazione Supabase — zone, sottozone, piante multi-tenant

## Contesto

`CLAUDE.md` descrive la Fase 5 come "assegnazione dei dati per utente, RLS su `auth.uid()` per zone/piante/progetti/ecc." A oggi però su Supabase esistono solo due tabelle: `specie` (catalogo condiviso, sola lettura/scrittura pubblica) e `zone_climatiche` (dati di riferimento climatico, non le zone del giardino dell'utente). Le zone, sottozone e piante dell'utente vivono ancora interamente in `public/data/{zone,sottozone,piante}.json`, scritte tramite GitHub Contents API (`useApi.js → saveJSON`, riscrittura dell'intero file con retry su conflitto di SHA).

La Fase 4 ha introdotto il login (Supabase Auth) come cancello d'accesso, ma senza alcuno scoping dei dati: chiunque autenticato vede gli stessi JSON. Questa fase collega finalmente i dati del giardino a un utente specifico, e sposta zone/sottozone/piante da JSON a tabelle Supabase relazionali, ponendo le basi per un vero multi-tenant (più persone, ciascuna con il proprio giardino isolato).

Fuori scope per questa fase (restano su JSON/GitHub, saranno un round successivo): `progetti.json`, `concimi.json`, `settings.json`, `richieste-agente.json` (quest'ultima resta legata al comando `/elabora`, eseguito manualmente via Claude Code solo dal proprietario del progetto — non ha oggi un percorso multi-utente e non lo guadagna in questa fase).

## Obiettivo

- Zone, sottozone e piante diventano tabelle Supabase relazionali, con integrità referenziale reale (FK a UUID) invece di stringhe libere.
- Ogni riga appartiene a un `owner_id`; RLS impedisce a un utente di vedere o modificare i dati di un altro.
- I dati esistenti (il giardino di Centinarola) vengono assegnati all'account già esistente (`robertagenovese@proton.me`, id `fc227422-ece8-4dca-b706-956ec7ca9e6e`).
- Nessuna vista Vue esistente deve richiedere un riscrittura sostanziale: lo store continua a esporre `zone`/`sottozone`/`piante` come oggetti keyed-by-nome, identici nella forma a oggi.
- Le scritture (creazione/modifica/eliminazione di zona, sottozona, pianta) passano da riscrittura dell'intero file JSON a insert/update/delete mirati sulla riga — eliminando la classe di conflitti concorrenti che `saveJSON` gestiva con retry.

## Modello dati

```sql
create table zone (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  nome text not null,
  descrizione text,
  esposizione text[],
  microclima text,
  criticita text,
  manutenzione text,
  tipo text,
  unique (owner_id, nome)
);

create table sottozone (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users default auth.uid(),
  zona_id uuid not null references zone(id) on delete cascade,
  nome text not null,
  descrizione text,
  esposizione text[],
  microclima text,
  criticita text,
  manutenzione text,
  tipo text,
  unique (zona_id, nome)
);

create table piante (
  id text primary key,   -- stesso formato "slug-timestamp" generato oggi client-side
                          -- (EditPiantaView.vue: `${form.specie}-${Date.now()}`), invariato
                          -- per non rompere la struttura cartelle della gallery foto
                          -- (docs/gallery/piante/{id-pianta}/)
  owner_id uuid not null references auth.users default auth.uid(),
  specie text not null references specie(slug),
  zona_id uuid not null references zone(id) on delete restrict,
  sottozona_id uuid references sottozone(id) on delete set null,
  varieta text,
  impianto text,
  impianto_circa text,
  note text,
  coltivato_in text,
  ultima_cura jsonb
);

alter table zone enable row level security;
alter table sottozone enable row level security;
alter table piante enable row level security;

create policy "zone: proprietario" on zone for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "sottozone: proprietario" on sottozone for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "piante: proprietario" on piante for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
```

**`piante.zona_id on delete restrict`** è un cambio di comportamento intenzionale. Oggi `ZoneView.vue → eliminaZona()` cancella una zona anche se contiene piante (mostra solo un avviso col conteggio, `contaPiante()`, ma non blocca), lasciandole con un riferimento `zona` a un nome ormai inesistente. Col vincolo DB, il tentativo di cancellare una zona con piante fallisce esplicitamente — comportamento più corretto del silenzioso orphaning attuale.

**`sottozone.zona_id on delete cascade`** replica esattamente il comportamento odierno (`ZoneView.vue:130-137`: cancellare una zona cancella incondizionatamente le sue sottozone).

**`piante.sottozona_id on delete set null`** replica il comportamento odierno per la sottozona (opzionale, nessun blocco).

**`piante.specie references specie(slug)`** aggiunge un'integrità che oggi non esiste (stringa libera in `piante.json`). Basso rischio: le specie non vengono mai cancellate (`CLAUDE.md`: le policy RLS di `specie` permettono solo `INSERT`/`UPDATE`, mai `DELETE`).

## Migrazione dati esistenti

Una migration SQL converte i tre JSON attuali in insert diretti, assegnando `owner_id = 'fc227422-ece8-4dca-b706-956ec7ca9e6e'` a tutte le righe. Ordine: `zone` → `sottozone` (via lookup `zona_id` per nome) → `piante` (via lookup `zona_id`/`sottozona_id` per nome). Gli id di `zone`/`sottozone` sono nuovi UUID generati dalla migration stessa; l'id di `piante` resta il valore testuale già presente nel JSON.

## Store (`src/stores/dati.js`)

`caricaTutto()` sostituisce le tre chiamate `caricaJSON('zone.json'|'sottozone.json'|'piante.json')` con query Supabase (`supabase.from('zone').select('*')`, ecc.). RLS scopa automaticamente per utente: nessun filtro esplicito su `owner_id` necessario lato client.

Una funzione di mappatura (accanto a `mappaSpecie`/`fondiEredita` già presenti nel file) ricostruisce la forma keyed-by-nome usata da tutta l'app:

- `store.zone` resta `{ [nomeZona]: { nome, descrizione, ... } }`, con l'aggiunta non invasiva di un campo `id` (UUID) usato solo dal livello di scrittura.
- `store.sottozone` resta `{ [nomeZona]: { [nomeSottozona]: {...} } }`, stessa aggiunta di `id`.
- `store.piante` resta `{ [idPianta]: { specie, zona: <nome>, sottozona: <nome|null>, ... } }` — `zona`/`sottozona` vengono risolti da `zona_id`/`sottozona_id` via join lato client contro le righe di `zone`/`sottozone` appena caricate.

Questo mantiene invariate le ~15 view che oggi leggono `pianta.zona`/`pianta.sottozona` come stringa e `store.zone[nome]`/`store.sottozone[nome]` (`PiantaRiga.vue`, `EditPiantaView.vue`, `EditZonaView.vue`, `ZoneView.vue`, `SottozoneView.vue`, `AttivitaView.vue`, `AttivitaGruppoZona.vue`, `AttivitaRiga.vue`, `raggruppaAttivita.js`, `GalleryView.vue`, `HomeView.vue`, `PiantaView.vue`, `PianteView.vue`, `ProgettiView.vue`, `ProgettoView.vue`).

## Scritture

`EditZonaView.vue`, `EditPiantaView.vue`, `SottozoneView.vue`, `ZoneView.vue` sostituiscono le chiamate `saveJSON('zone.json'|'sottozone.json'|'piante.json', ...)` con `insert`/`update`/`delete` diretti su Supabase (stesso pattern già in uso in `SelettoreSpecie.vue` per la tabella `specie`):

- **Creazione**: `insert` di una riga; per `piante`, l'id resta generato client-side come oggi.
- **Modifica**: `update` per `id` (o per `owner_id` + chiave naturale dove serve risolvere il nome scelto nel form in un `zona_id`/`sottozona_id` — lookup nello store già caricato, nessuna query aggiuntiva).
- **Eliminazione**: `delete` per `id`. `eliminaZona()` intercetta l'errore di violazione FK (`23503`) quando la zona ha piante collegate e mostra un messaggio esplicito invece di procedere silenziosamente.

Non serve più il pattern updater-con-retry di `saveJSON` (pensato per conflitti su un intero file JSON condiviso): ogni riga è indipendente, quindi la classe di conflitti concorrenti che gestiva sparisce strutturalmente.

## Offline (uso in giardino senza campo)

Oggi la resilienza offline per questi dati viene dal fallback `caricaStatico()` su `/giardino/data/*.json`, servito dalla cache del service worker (`vite.config.js`, regola Workbox `NetworkFirst` su quel pattern URL). Con zone/sottozone/piante solo su Supabase, questo fallback specifico non si applica più.

Aggiunta: una regola Workbox `NetworkFirst` sul dominio REST di Supabase (`https://ncuhhsvtjwcolhpdxbkt.supabase.co/rest/v1/*`), stesso `networkTimeoutSeconds: 3` già usato per gli altri pattern in `vite.config.js`.

Limite noto e mitigazione: la cache del service worker è per-URL, non per-utente (il JWT che identifica l'utente viaggia nell'header `Authorization`, non nell'URL) — su un device condiviso da più account, un utente offline potrebbe vedere temporaneamente dati cache-ati dell'utente precedente. Mitigazione: `useAuth.js` svuota la cache Supabase (`caches.delete('giardino-dati-supabase')` o equivalente) sull'evento `SIGNED_OUT`. Per l'uso attuale (singolo utente) non è un problema pratico, ma il design multi-tenant lo richiede comunque.

## Verifica

Nessun framework di test nel progetto: verifica manuale con `npm run dev`.

- Login con l'account esistente: `/zone`, `/piante` mostrano gli stessi dati di oggi (conteggio righe invariato rispetto ai JSON pre-migrazione).
- Creare una nuova zona, una sottozona al suo interno, una pianta in quella sottozona; modificare ciascuna; verificare che le view (`ZoneView`, `SottozoneView`, `PianteView`, `PiantaView`, `AttivitaView`) le mostrino correttamente.
- Eliminare una sottozona: le piante che la referenziavano restano, con sottozona vuota.
- Tentare di eliminare una zona con piante collegate: verificare il messaggio di blocco (non l'eliminazione silenziosa di oggi).
- Eliminare una zona senza piante: procede, e cancella anche le sue sottozone.
- Verifica RLS: da un secondo account (o query anonima con la chiave anon senza sessione), confermare che nessuna riga di `zone`/`sottozone`/`piante` sia leggibile.
- Verifica offline: build di produzione, disattivare la rete dopo un primo caricamento riuscito, confermare che `/piante` mostri l'ultima copia cache-ata invece di un errore.
