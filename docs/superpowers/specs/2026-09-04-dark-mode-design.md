# Fase 3 restyle "Taccuino" — dark mode

Data: 2026-09-04
Stato: approvato (design discusso in chat + mockup Artifact "Giardino di Notte", https://claude.ai/code/artifact/513e53c6-b637-4b37-a80b-0e494a5d9ab6)

## Contesto

Prossimo passo del restyle "Taccuino" (vedi memoria `project_restyle_taccuino`). `SettingsView.vue` porta già un campo `ui.theme` (default `'auto'`) ma senza alcun controllo nel form né logica che lo applichi: oggi non esiste alcun meccanismo dark mode. Decisioni già chiuse in review in una sessione precedente:

- interruttore esplicito in Impostazioni, **non** rilevazione automatica da sistema (`prefers-color-scheme` non usato)
- default **chiaro**
- palette scura **calda** (marrone-verde), non un grigio neutro — ogni token scuro nasce dalla stessa tinta del suo equivalente chiaro, non da un desaturato

## Meccanismo

Attributo `data-theme="dark"` su `<html>`. Tutte le regole scure vivono in `main.css`, sotto `:root[data-theme="dark"] { --token: ...; }` — nessun componente stila mai un colore fuori dai token esistenti (era già la convenzione post-Fase 1).

Nuovo composable `src/composables/useTema.js`:
- stato reattivo module-level `tema` (`'light' | 'dark'`), letto all'avvio da `localStorage.giardino_theme` (fallback `'light'`)
- `applicaTema(t)`: imposta `document.documentElement.dataset.theme`, scrive `localStorage.giardino_theme`, aggiorna `<meta name="theme-color">` (hex fisso per tema, non calcolato da CSS)
- `impostaTema(t)`: chiama `applicaTema(t)` e salva su Supabase via `useSettingsApi` (`ui: { theme: t }`) se l'utente è autenticato
- riconciliazione: al primo caricamento delle settings da Supabase (`App.vue`, dopo `store.caricaTutto()`), se `store.settings.ui.theme` differisce dal tema applicato localmente, vince Supabase (fonte di verità cross-device) — si applica e si riallinea `localStorage`

Script inline in `index.html`, prima del bootstrap Vue, legge `localStorage.giardino_theme` e imposta subito l'attributo — evita il lampo chiaro→scuro al caricamento.

## Palette scura

Token ridefiniti sotto `:root[data-theme="dark"]`, stessa struttura di quelli chiari in `main.css` (righe 3-49). Valori esatti come nell'Artifact "Giardino di Notte" (già verificati visivamente lì):

Neutrali: `--cream:#1c1810; --cream-dark:#342c1d; --white:#262015; --ink-tile:#2e2718; --carta-2:#241f14; --ink:#f2e8d8; --ink-mid:#cdbfa4; --ink-soft:#8f8369; --ink-faint:#4a4230;`

Rose: `--rose:#e0898a; --rose-dark:#f0acac; --rose-light:#4a2b2b; --rose-pale:#241a19; --rose-bg:#3a2422; --rose-ink:#f0acac;`
Gold: `--gold:#eec769; --gold-dark:#f6da97; --gold-light:#4a3c1e; --gold-pale:#231e13; --gold-bg:#362c15; --gold-ink:#f6da97;`
Sage: `--sage:#93bb9b; --sage-dark:#b7d6bd; --sage-light:#2b3c30; --sage-pale:#1c211c; --sage-bg:#223326; --sage-ink:#b7d6bd;`
Olive: `--olive:#b3c473; --olive-dark:#cddb95; --olive-light:#38401f; --olive-bg:#2a2e18; --olive-ink:#cddb95;`
Acqua: `--acqua:#8dbcdd; --acqua-dark:#b3d5ec; --acqua-bg:#203244; --acqua-ink:#a8cfe6;`
Uovo: `--uovo:#ddcda6; --uovo-dark:#ecdfc0;`

Regola per token futuri (nuove tinte che dovessero aggiungersi dopo questa fase): stessa tinta (hue) dell'equivalente chiaro; l'accento base si schiarisce (non si scurisce) per leggibilità su fondo scuro; la variante "-dark" (ruolo: enfasi/hover) diventa ancora più chiara, non più scura; le tinte pallide ("-light"/"-pale", sfondi pillole/badge) diventano versioni scure sature della stessa tinta; le coppie "-bg"/"-ink" restano una superficie scura satura + testo chiaro tinto, mantenendo il contrasto AA.

## Interruttore in Impostazioni

`SettingsView.vue`: un `<select class="form-input">` Chiaro/Scuro dentro un nuovo blocco `.form-card`, stesso pattern del select "Zona climatica" già presente nella pagina. Cambiarlo chiama subito `tema.impostaTema(...)` (applicazione istantanea, non solo al "Salva" del form) — coerente con l'aspettativa di un toggle di tema, che si vede subito. Il default `'auto'` residuo in `SettingsView.vue`/`useSettingsApi.js` diventa `'light'`.

## Casi particolari

- **Zorba** (`ZorbaLogo.vue`, icona `i-gatto` in `IconDefs.vue`): resta nero (`fill:#000`/`#000000`), mai ricolorato. In dark mode si aggiunge `filter: drop-shadow(0 0 3px rgba(242,232,216,.55))` per separarlo dal fondo scuro — regola CSS scoped alle classi di utilizzo (`.hero__z`, `.boot-logo`, mini-logo in `SideNav`/`AppBar`), non dentro `ZorbaLogo.vue` stesso (resta agnostico al tema).
- **Foto** (`.gimg` in Gallery/PiantaView, `.hero__scene` in Home): `filter: brightness(.88)` sotto `[data-theme="dark"]`, leggera attenuazione, nessun cambio di colore.
- **`.day__dm`** in `MeteoView.vue`: `color:#000` hardcoded → `color: var(--ink)`.
- **`theme-color`**: aggiornato da `useTema.js` (hex fisso `#faf7f2` chiaro / `#1c1810` scuro), non nel meta statico di `index.html` (che resta il default chiaro per il primo paint pre-JS, coerente con lo script anti-flash che comunque corregge `data-theme` prima del render ma non rilancia il meta finché Vue non monta — accettabile, è solo il colore della barra di stato del browser).

## Fuori scope

- Velatura stagionale hero (Fase 4, separata)
- Retrofit di eventuali colori hardcoded scoperti solo in fase di implementazione ma non elencati sopra: da correggere comunque se trovati (stessa convenzione token), annotati nell'esito

## Verifica

Nessun test runner nel progetto. Verifica: `npm run build` (nessun errore) + controllo visivo reale via skill `run` (screenshot chiaro/scuro di Home, scheda pianta, Meteo, Impostazioni) prima di considerare la fase conclusa.
