# CLAUDE.md

Questo file fornisce indicazioni a Claude Code (claude.ai/code) per lavorare in questo repository.

## Panoramica del progetto

**Giardino di Rob** — applicazione web Vue 3 per la gestione di un giardino personale a Centinarola, Fano (PU), Italia. Tutti i contenuti sono in italiano.

## Comandi principali

```bash
npm run dev      # avvia dev server (localhost:5173)
npm run build    # build produzione → dist/
npm run preview  # anteprima build locale
```

Il deploy su GitHub Pages avviene automaticamente tramite GitHub Actions (`.github/workflows/deploy.yml`) ad ogni push su `main`: pubblica `dist/` sul branch `gh-pages`. La sorgente di GitHub Pages va impostata sul branch `gh-pages`.

## Architettura

```
src/
├── main.js                  ← bootstrap Vue + Pinia + Router
├── App.vue                  ← layout globale (NavBar, BottomNav, StatusBar, banner token)
├── router/index.js          ← route con createWebHashHistory (necessario per gh-pages)
├── stores/dati.js           ← Pinia store: carica specie/zone/sottozone/piante da Supabase e i JSON residui una volta sola
├── composables/
│   ├── useApi.js            ← GitHub API: saveJSON(), uploadFile(), token management
│   ├── useMeteo.js          ← Open-Meteo (no API key)
│   ├── useCure.js           ← logica urgenze cure (irrigazione, concimazione, potatura)
│   ├── useConcimi.js        ← abbinamento concime↔pianta per distanza NPK normalizzata (vedi sotto)
│   ├── useProgetti.js       ← logica progetti/tappe (scadenzaCalcolata da ultima tappa, ecc.)
│   ├── useGalleria.js       ← listing/upload foto via Contents API (usato da GalleryView)
│   ├── useRepoStatus.js / useAppUpdate.js ← confronto build corrente vs ultimo commit main + banner update PWA (StatusBar.vue)
│   ├── useSupabase.js       ← client Supabase (specie, zone/sottozone/piante, in lettura/scrittura, vedi sotto)
│   ├── usePianteApi.js      ← CRUD piante su Supabase (creazione/modifica/eliminazione, cure, rinomina specie a cascata; Fase 5)
│   └── useAuth.js           ← sessione Supabase Auth (Fase 4 migrazione, vedi sotto)
├── components/
│   ├── PiantaRiga.vue       ← riga pianta riutilizzabile (usata in PianteView)
│   └── ModalConferma.vue    ← dialog eliminazione generico
└── views/                   ← una view per route (incl. AccountView.vue, login/registrazione)
public/data/                 ← JSON letti a runtime dal frontend
docs/                        ← vecchio sito Jekyll (non più attivo)
docs/gallery/piante/         ← foto piante organizzate per {id-pianta}/
supabase/migrations/         ← migration SQL del progetto Supabase "Il Giardino di Zorba"
```

## Dati e persistenza

I dati residui (richieste-agente) vivono in `public/data/` come JSON. Le scritture avvengono tramite la **GitHub Contents API** (`useApi.js → saveJSON`), che richiede un Personal Access Token con scope `contents:write` salvato in `localStorage.github_token`.

Specie, piante, zone, sottozone, progetti, tappe, concimi e settings sono tabelle Supabase (`specie`/`piante`/`zone`/`sottozone`/`progetti`/`tappe`/`concimi`/`settings`), con RLS per utente su piante/zone/sottozone/progetti/tappe/concimi/settings — vedi "Migrazione specie → Supabase", "Migrazione zone/sottozone/piante → Supabase" e "Completamento Fase 5" più sotto.

| File | Contenuto |
|------|-----------|
| `specie.json` | Profili di cura per specie (~8700 specie) con manutenzione stagionale — fallback offline, vedi sotto |
| `richieste-agente.json` | Coda richieste AI (stato: in_attesa → completata/errore) |

### Migrazione specie → Supabase (Fase 2 completata, letture e scritture)

Le **specie** sono ora gestite su **Supabase** (progetto `ncuhhsvtjwcolhpdxbkt`, "Il Giardino di Zorba", tabella `specie`, ~9000 righe, RLS attive) sia in lettura che in scrittura. Stato attuale:

- **Lettura**: `useDatiStore` (`stores/dati.js → caricaSpecie()`) legge le specie da Supabase via `useSupabase.js` (client con URL + chiave anon in `.env`, sicuri da versionare perché protetti dalle policy RLS). L'oggetto risultante mantiene la stessa forma usata da tutta l'app (stessa chiave `slug`, stessi campi `specie`, `coltivazione`, ecc. — mappati da `nome_scientifico`/`ciclo_colturale`, vedi `mappaSpecie()`).
- **Fallback**: se Supabase non risponde, si ripiega su `specie.json` statico (fetch, non GitHub API) — file mantenuto solo come copia di riserva offline, non più aggiornato ad ogni scrittura: può quindi risultare via via disallineato da Supabase.
- **Scrittura**: `SelettoreSpecie.vue` scrive **direttamente su Supabase** (`insert`/`update` sulla tabella `specie`, per `id` quando modifica una riga esistente). Le policy RLS di scrittura (`specie: scrittura pubblica temporanea (insert|update)`, solo `INSERT`/`UPDATE`, mai `DELETE`) sono volutamente aperte (`true`) perché l'app non ha ancora un sistema di login: la chiave anon è pubblica nel bundle, quindi chiunque conosca l'URL potrebbe scrivere/corrompere righe (ma non cancellarle). **Da sostituire con policy basate su `auth.uid()` quando verrà implementato un vero login** — decisione presa esplicitamente con l'utente, non un'svista.
- Il comando `/elabora` per `revisione_specie` scrive anch'esso direttamente su Supabase (via MCP `execute_sql`/`apply_migration`), non più su `specie.json`.
- Le migration schema/dati vivono in `supabase/migrations/` (es. `..._aggiunge_colonna_immagine.sql`, batch di popolamento `pfaf_bozza`/`immagini_hero`, import da fonti esterne — vedi `fonti/criterio-importazione.md`).

### Migrazione zone/sottozone/piante → Supabase (Fase 5, completata)

Zone, sottozone e piante sono su Supabase (tabelle `zone`, `sottozone`, `piante`), con RLS reale per utente (`owner_id = auth.uid()`, colonna con default `auth.uid()` sulle nuove righe create dall'app) — a differenza di `specie`, qui le policy non sono aperte: ogni utente vede e scrive solo i propri dati. `piante.zona_id`/`sottozona_id` sono foreign key verso `zone`/`sottozone` (non più stringhe libere come nei vecchi JSON): rinominare una zona o sottozona non richiede più aggiornare le piante che la referenziano (prima gestito a mano in `SottozoneView.vue`). `piante.id` resta testo nello stesso formato di sempre (`slug-timestamp`) per compatibilità con la struttura cartelle della gallery foto (`docs/gallery/piante/{id-pianta}/`).

Lo store (`stores/dati.js → caricaTutto()`) ricostruisce comunque la stessa forma a oggetti keyed-by-nome usata da sempre da tutta l'app (`store.zone["Est"]`, `pianta.zona === "Est"`), risolvendo gli id via join lato client (`mappaZone`/`mappaSottozone`/`mappaPiante`) — le view non trattano mai zona/sottozona come id. Le scritture passano da `usePianteApi.js` (creazione/modifica/eliminazione pianta, registrazione cura, rinomina specie a cascata) o da chiamate dirette a Supabase nelle view di zone/sottozone (stesso pattern di `SelettoreSpecie.vue` per le specie): niente più riscrittura dell'intero file JSON con retry su conflitto SHA, ogni riga è indipendente.

Offline: la cache del service worker (Workbox, `vite.config.js`) copre anche il dominio REST di Supabase (`NetworkFirst`), sostituendo il vecchio fallback su file statici per queste tre entità. La cache viene svuotata al logout (`useAuth.js`) per evitare che un device condiviso mostri offline i dati dell'utente precedente.

### Completamento Fase 5: progetti/tappe, settings, concimi → Supabase

Anche `progetti`, `tappe`, `settings` e `concimi` sono ora tabelle Supabase con RLS reale per utente (`owner_id = auth.uid()`), stesso pattern di zone/sottozone/piante. `tappe` è una tabella a sé (non un campo jsonb dentro `progetti`): `ProgettoView.vue` riconcilia l'intero form (insert/update/delete mirati per tappa, via `useProgettiApi.js`), mentre `AttivitaView.vue` aggiorna una singola tappa per id (`registraTappa`) — un campo jsonb condiviso tra questi due percorsi di scrittura avrebbe perso silenziosamente le modifiche concorrenti, una tabella con una riga per tappa lo evita per costruzione.

`settings` è una riga singola per utente (`owner_id` è la chiave primaria). `zona_climatica_id` viene calcolato una sola volta, al primo salvataggio con il campo ancora vuoto, da `useZonaClimatica.js` (euristica su lat/lon/altitudine, mai più ricalcolato dopo per non sovrascrivere una scelta manuale) — modificabile a mano dalla nuova pagina `/impostazioni` (linkata da `/account`).

`cure_log` come tabella a parte e uno script di importazione per `coltivazione` erano nello scope originale della issue #122 ma sono stati chiusi come già soddisfatti: `piante.ultima_cura` (jsonb, solo l'ultima cura per tipo) copre l'unico uso reale oggi (calcolo urgenze), e `piante.coltivato_in` (vaso/terra/acqua) è lo stesso campo già descritto con un altro nome.

`richieste-agente.json` resta l'unico dato ancora su GitHub/JSON senza scoping per utente — legato al comando `/elabora`, eseguito manualmente, va ridiscusso a parte in un round futuro.

Verificata a mano nel browser dopo l'implementazione (creazione/modifica/eliminazione di zone/sottozone/piante, rinomina specie a cascata, registrazione cure singola e bulk, blocco eliminazione zona con piante). La verifica ha trovato e corretto due problemi non emersi dalla sola lettura del codice: `ZoneView.vue`/`SottozoneView.vue` non avevano un pulsante per eliminare (la logica c'era già per le zone, mancava del tutto per le sottozone); e `App.vue` ricaricava lo store due volte a ogni apertura dell'app già autenticata (il watch sul cambio utente si registrava prima che la sessione fosse risolta, vedendo la sua prima risoluzione come un cambio utente).

### Autenticazione utente (Fase 4 migrazione Supabase, avviata)

`useAuth.js` gestisce la sessione via **Supabase Auth**, solo email/password per ora (Google rimandato: richiede creare un OAuth client su Google Cloud Console e configurarlo nel dashboard Supabase, passaggio manuale non ancora fatto). Stato reattivo condiviso a livello di modulo (`utente`, `caricamento`, `recuperoInCorso`), aggiornato via `onAuthStateChange`. `AccountView.vue` (route `/account`, link in `NavBar`/icona in `StatusBar`) espone login/registrazione/logout/recupero password. Il progetto Supabase richiede la conferma email di default (`signUp` non ritorna una sessione finché l'utente non clicca il link ricevuto via mail) — gestito in UI con un messaggio esplicito, non è un bug.

Il router (`router/index.js`) ha una guardia globale: senza sessione attiva, ogni rotta diversa da `/account` reindirizza lì (`App.vue` nasconde anche NavBar/BottomNav/StatusBar in quello stato, mostrando solo il form centrato). Il client Supabase usa `flowType: 'pkce'` (`useSupabase.js`) invece del default `implicit`: coi token nel fragment dell'URL, `createWebHashHistory` (che vive anch'esso nel fragment) romperebbe il parsing del link di recupero password — con PKCE il codice arriva in query string, prima del `#`, senza conflitti. **Il redirect URL di reset (origine + `/giardino/`) va aggiunto tra le "Redirect URLs" del progetto Supabase (dashboard → Authentication → URL Configuration), altrimenti Supabase lo rifiuta.**

**Importante**: l'account ora controlla zone/sottozone/piante/progetti/tappe/concimi/settings (Fase 5 completamento, completata — vedi sopra). Il token GitHub in `localStorage` resta necessario per richieste-agente (unico dato su GitHub/JSON rimasto).

## Coda richieste agente AI

Le richieste create da `AgenteView.vue` vengono scritte in `richieste-agente.json` con stato `in_attesa`. Il comando `/elabora` (`.claude/commands/elabora.md`) contiene la procedura completa, tipo per tipo — è la fonte di verità, da consultare invece di indovinare il formato risposta; in sintesi: legge la coda, elabora ogni richiesta (può includere foto in base64), aggiorna il JSON con `stato: completata` e `risposta.messaggio`, azzera `foto` (per non far crescere il file oltre la soglia di ~1MB della Contents API), e fa commit.

Alcuni tipi scrivono anche altrove, non solo la risposta testuale:
- `revisione_specie` → aggiorna anche la riga corrispondente nella tabella `specie` su Supabase (via MCP `execute_sql`/`apply_migration`), non `specie.json`
- `pianifica_progetto` → crea/aggiorna anche le righe corrispondenti nelle tabelle `progetti`/`tappe` su Supabase (via MCP `execute_sql`/`apply_migration`)
- `consiglio_concimazione` → usa lo stesso criterio di match NPK di `useConcimi.js` (distanza euclidea su rapporti normalizzati, soglia 0.15), per coerenza con quanto l'utente vede già in app
- `identifica_specie` → prima dell'analisi visiva, interroga l'API di identificazione PlantNet (`PLANTNET_API_KEY` in `.env.local`) come riscontro oggettivo; il giudizio finale resta comunque quello visivo di Claude, non un pass-through automatico dei risultati PlantNet

Schema richiesta:
```json
{
  "tipo": "identifica_specie | revisione_specie | consiglio_cura | consiglio_concimazione | diagnosi | pianifica_progetto | altro",
  "messaggio": "...",
  "foto": "<base64 opzionale>",
  "stato": "in_attesa",
  "creata": "<ISO>",
  "risposta": null
}
```

## Logica cure (`useCure.js`)

`valutaCura(pianta, specie, tipo)` legge `specie.manutenzione[tipo][stagione]`, calcola i giorni dall'ultima cura e restituisce `{ urgente, label, giorni }`. `cureUrgentiPianta` filtra solo i tipi urgenti. La stagione è calcolata dal mese corrente.

## Gallery

Le foto esistenti sono in `docs/gallery/piante/{id-pianta}/{timestamp}_{filename}.jpg` sul branch `main` e vengono servite tramite URL raw di GitHub. I caricamenti nuovi seguono la stessa struttura. La `GalleryView` usa la Contents API per listare le cartelle e costruisce gli URL raw.

## Palette e design

```css
--rose: #cc6e6e  --gold: #e0b84a  --sage: #7a9e82  --olive: #9aaa5a  --cream: #faf7f2
```
Font: Playfair Display (titoli display) · Lora (serif secondario) · DM Sans (UI/body).
Classi globali: `.card`, `.btn`, `.btn-rose/sage/ghost`, `.badge`, `.pill`, `.skeleton`, `.form-input`, `.search-input`, `.title-display`, `.gradient-title`, `.section-label`.
