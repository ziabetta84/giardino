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
├── stores/dati.js           ← Pinia store: carica tutti i JSON una volta sola
├── composables/
│   ├── useApi.js            ← GitHub API: saveJSON(), uploadFile(), token management
│   ├── useMeteo.js          ← Open-Meteo (no API key)
│   ├── useCure.js           ← logica urgenze cure (irrigazione, concimazione, potatura)
│   ├── useConcimi.js        ← abbinamento concime↔pianta per distanza NPK normalizzata (vedi sotto)
│   ├── useProgetti.js       ← logica progetti/tappe (scadenzaCalcolata da ultima tappa, ecc.)
│   ├── useGalleria.js       ← listing/upload foto via Contents API (usato da GalleryView)
│   ├── useRepoStatus.js / useAppUpdate.js ← confronto build corrente vs ultimo commit main + banner update PWA (StatusBar.vue)
│   ├── useSupabase.js       ← client Supabase (specie in lettura/scrittura, vedi sotto)
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

Tutti i dati vivono in `public/data/` come JSON. Le scritture avvengono tramite la **GitHub Contents API** (`useApi.js → saveJSON`), che richiede un Personal Access Token con scope `contents:write` salvato in `localStorage.github_token`.

| File | Contenuto |
|------|-----------|
| `piante.json` | Piante con zona, sottozona, ultima_cura per tipo |
| `specie.json` | Profili di cura per specie (~8700 specie) con manutenzione stagionale — fallback offline, vedi sotto |
| `zone.json` | Metadati delle 6 zone (nome, tipo, esposizione, microclima) |
| `sottozone.json` | Sottozone indicizzate per chiave zona |
| `concimi.json` | Dispensa concimi posseduti, con NPK `{n, p, k}` — usata da `useConcimi.js` per il match con le esigenze della specie |
| `progetti.json` | Progetti del giardino con `tappe[]` (data, descrizione, esito) — schema in `useProgetti.js` |
| `richieste-agente.json` | Coda richieste AI (stato: in_attesa → completata/errore) |
| `settings.json` | Coordinate GPS per Open-Meteo |

### Migrazione specie → Supabase (Fase 2 completata, letture e scritture)

Le **specie** sono ora gestite su **Supabase** (progetto `ncuhhsvtjwcolhpdxbkt`, "Il Giardino di Zorba", tabella `specie`, ~9000 righe, RLS attive) sia in lettura che in scrittura. Stato attuale:

- **Lettura**: `useDatiStore` (`stores/dati.js → caricaSpecie()`) legge le specie da Supabase via `useSupabase.js` (client con URL + chiave anon in `.env`, sicuri da versionare perché protetti dalle policy RLS). L'oggetto risultante mantiene la stessa forma usata da tutta l'app (stessa chiave `slug`, stessi campi `specie`, `coltivazione`, ecc. — mappati da `nome_scientifico`/`ciclo_colturale`, vedi `mappaSpecie()`).
- **Fallback**: se Supabase non risponde, si ripiega su `specie.json` statico (fetch, non GitHub API) — file mantenuto solo come copia di riserva offline, non più aggiornato ad ogni scrittura: può quindi risultare via via disallineato da Supabase.
- **Scrittura**: `SelettoreSpecie.vue` scrive **direttamente su Supabase** (`insert`/`update` sulla tabella `specie`, per `id` quando modifica una riga esistente). Le policy RLS di scrittura (`specie: scrittura pubblica temporanea (insert|update)`, solo `INSERT`/`UPDATE`, mai `DELETE`) sono volutamente aperte (`true`) perché l'app non ha ancora un sistema di login: la chiave anon è pubblica nel bundle, quindi chiunque conosca l'URL potrebbe scrivere/corrompere righe (ma non cancellarle). **Da sostituire con policy basate su `auth.uid()` quando verrà implementato un vero login** — decisione presa esplicitamente con l'utente, non un'svista.
- Il comando `/elabora` per `revisione_specie` scrive anch'esso direttamente su Supabase (via MCP `execute_sql`/`apply_migration`), non più su `specie.json`.
- Le migration schema/dati vivono in `supabase/migrations/` (es. `..._aggiunge_colonna_immagine.sql`, batch di popolamento `pfaf_bozza`/`immagini_hero`, import da fonti esterne — vedi `fonti/criterio-importazione.md`).

### Autenticazione utente (Fase 4 migrazione Supabase, avviata)

`useAuth.js` gestisce la sessione via **Supabase Auth**, solo email/password per ora (Google rimandato: richiede creare un OAuth client su Google Cloud Console e configurarlo nel dashboard Supabase, passaggio manuale non ancora fatto). Stato reattivo condiviso a livello di modulo (`utente`, `caricamento`, `recuperoInCorso`), aggiornato via `onAuthStateChange`. `AccountView.vue` (route `/account`, link in `NavBar`/icona in `StatusBar`) espone login/registrazione/logout/recupero password. Il progetto Supabase richiede la conferma email di default (`signUp` non ritorna una sessione finché l'utente non clicca il link ricevuto via mail) — gestito in UI con un messaggio esplicito, non è un bug.

Il router (`router/index.js`) ha una guardia globale: senza sessione attiva, ogni rotta diversa da `/account` reindirizza lì (`App.vue` nasconde anche NavBar/BottomNav/StatusBar in quello stato, mostrando solo il form centrato). Il client Supabase usa `flowType: 'pkce'` (`useSupabase.js`) invece del default `implicit`: coi token nel fragment dell'URL, `createWebHashHistory` (che vive anch'esso nel fragment) romperebbe il parsing del link di recupero password — con PKCE il codice arriva in query string, prima del `#`, senza conflitti. **Il redirect URL di reset (origine + `/giardino/`) va aggiunto tra le "Redirect URLs" del progetto Supabase (dashboard → Authentication → URL Configuration), altrimenti Supabase lo rifiuta.**

**Importante**: per ora l'account **non controlla ancora nessun dato** — coesiste col token GitHub in `localStorage` (che resta l'unico meccanismo che sblocca le scritture) esattamente come da piano (Fase 4 = login obbligatorio per usare l'app, ma senza scoping dei dati; l'assegnazione dei dati per utente, RLS su `auth.uid()` per zone/piante/progetti/ecc., arriva con la Fase 5, non ancora iniziata).

## Coda richieste agente AI

Le richieste create da `AgenteView.vue` vengono scritte in `richieste-agente.json` con stato `in_attesa`. Il comando `/elabora` (`.claude/commands/elabora.md`) contiene la procedura completa, tipo per tipo — è la fonte di verità, da consultare invece di indovinare il formato risposta; in sintesi: legge la coda, elabora ogni richiesta (può includere foto in base64), aggiorna il JSON con `stato: completata` e `risposta.messaggio`, azzera `foto` (per non far crescere il file oltre la soglia di ~1MB della Contents API), e fa commit.

Alcuni tipi scrivono anche altrove, non solo la risposta testuale:
- `revisione_specie` → aggiorna anche la riga corrispondente nella tabella `specie` su Supabase (via MCP `execute_sql`/`apply_migration`), non `specie.json`
- `pianifica_progetto` → crea/aggiorna anche `progetti.json` (schema tappe in `useProgetti.js`)
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
