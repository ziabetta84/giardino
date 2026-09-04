# Esito — Zone edit nel foglio + × sulla hero del selettore specie

Branch `zone-nel-foglio` · **mergiato su `main`** (merge `f3afc13`), deploy GitHub Pages OK, 04/09/2026.
Piano: `2026-09-04-zone-nel-foglio-x-hero.md`. Esecuzione subagent-driven: 2 task (indipendenti, eseguiti in parallelo) + review per task + review finale su Opus + 1 fix wave (1 finding Important) + re-review scoped.

## Fatto

| Commit | Cosa |
|---|---|
| `c2ec953` | **`FoglioLaterale.vue`** — nuova prop additiva `senzaIntestazione: { type: Boolean, default: false }`; `v-if="!senzaIntestazione"` sul solo `<div class="foglio__hd">`. Esc / focus / `:inert` / scroll-lock / `.foglio__grab` invariati. I 4 altri consumatori (Progetti/Concimi/Sottozone/Attività) non la passano → nessun cambiamento. **`SelettoreSpecie.vue`** — `<FoglioLaterale v-model="dossierAperto" senza-intestazione>`, via lo slot `#intestazione`; nuovo `<button class="dossier-x">` in `position:absolute` (top/right 12, 30×30, z-index 5 sopra lo stack hero a z-index 3) come primo figlio di `.dossier`. |
| `a82df4e` | Piano. |
| `5217bbc` | **Zone edit nel foglio** — la logica insert/update/rename di `EditZonaView` portata dentro `ZoneView` sullo schema di `SottozoneView`: stato `mostraForm`/`salvando`/`errore`/`modificaOriginale`/`form` (+ helper `formVuoto()`), `apriNuovo`/`apriModifica(z)`/`chiudiForm`/`salva`. `salva()` scrive su Supabase (`.select().single()` → la riga in `store.zone[nome]` porta anche `criticita`/`manutenzione` non esposti dal form), `store.aggiorna()` **solo** sul rename, guard anti-collisione nome (miglioria rispetto a `EditZonaView` che non l'aveva). "＋ Aggiungi" e la matita da `<RouterLink>` a `<button>`. **Eliminati** `EditZonaView.vue`, le route `zona-nuova` (`/zone/nuova`) e `zona-modifica` (`/zone/:zona/modifica`), la classe CSS `.zona-edit-wide` (serviva solo a quella pagina). Commenti stale `EditZonaView` → `ZoneView` in `main.css`/`useIconeZona.js`/`IconDefs.vue`. |
| `4537c7f` | **Fix review finale (Important):** la `.dossier-x` era pensata per la foto; sul ramo **senza foto** (`.dh-np`, sfondo chiaro — caso frequente per le "bozza" del catalogo) cadeva sopra `.np-name` e aveva contrasto scarso. Ora `:class="{ 'dossier-x--np': !hero }"` → `.dossier-x--np { background: var(--cream-dark); color: var(--ink-mid); }` (stesso trattamento della × di `FoglioLaterale`), e `.dh-np` passa a `padding: 18px 52px 4px 16px` così il nome non ci passa sotto. |

**`FoglioLaterale` ora in 6 viste.** L'unico modo di modificare/creare una zona o sottozona è il foglio dentro `ZoneView`/`SottozoneView`; non esistono più pagine-form piene per le zone.

## Nessun ruling preso in autonomia

Scan pre-flight pulito, nessun fix loop arrivato al limite, review finale su Opus riuscita al primo tentativo. Zero decisioni prese al posto di Rob in questo round.

## Da guardare nel QA browser (Minor differiti)

- **ZoneView**: ＋Aggiungi → "Nuova zona"; matita → "Modifica zona" coi campi popolati (descrizione e microclima rich text inclusi); `Esc` / velo / Annulla chiudono e resettano; "Salva" chiude su successo e la lista si aggiorna.
- **Rinomina di una zona con piante e sottozone**: dopo il salvataggio `/zone/<nuovo>/sottozone` elenca ancora le sue sottozone e `/piante?zona=<nuovo>` conta ancora le piante (breve flash skeleton da `store.aggiorna()`). Su Supabase verificare che dopo un **edit semplice** (solo descrizione) `criticita`/`manutenzione` di quella riga siano intatti — il codice dice di sì (arrivano da `salvata`), è lo scenario da controllare una volta sui dati veri.
- **Nome duplicato**: rinominando la zona A col nome della zona B compare "Una zona con questo nome esiste già." sopra il select tipo, il foglio resta aperto, niente scritto.
- **URL ritirati**: `#/zone/nuova` / `#/zone/:zona/modifica` da un vecchio bookmark ora danno pagina vuota (warning "No match found" in console, `<RouterView>` vuoto). Nessun link in-app ci porta. Pre-esistente per qualsiasi URL storto — manca una catch-all route. **One-liner per uno sweep futuro:** `{ path: '/:pathMatch(.*)*', redirect: '/' }` in `router/index.js`.
- **SelettoreSpecie**: specie **con** foto → foglio senza barra header, × scura in alto a destra sulla foto. Specie **senza** foto (bozza con nome lungo) → × crema che non tocca il nome. Desktop (≥640, foglio laterale) e mobile (dal basso, con maniglia) — la × cambia posizione relativa al bordo.
- `.dossier-x` scrolla via col contenuto del dossier quando si scorre in basso (accettato dal design "× sulla hero"; Esc/velo restano). Nessun `:hover`/`:focus-visible` sulla `.dossier-x` (il focus ring UA resta).
- Conferma veloce che Progetti/Concimi/Sottozone/Attività mostrano ancora la loro barra header con ×.
- `ModalConferma` (eliminazione zona/sottozona) resta un dialog centrato sopra il foglio; niente conflitto di scroll-lock (non tocca `body.overflow`).

## Fuori scope — round successivi

- **MeteoView redesign** in stile taccuino (registro verticale, `useMeteo` a 7 giorni di ore, mini-grafico orario, dettaglio nel foglio) — round dedicato con mockup.
- **Migration RLS `specie`** — round dedicato.
- **Fase 3** dark mode (`--uovo`, `--font-serif` inesistente, `useCureVisual.js` naming), **Fase 4** velatura stagionale hero.
- Le `<label>` inline vecchio stile di `SottozoneView` (non `.field-label`) — `ZoneView` usa `.field-label` perché la logica arriva da `EditZonaView` che già le usava; uniformare `SottozoneView` semmai in un giro di pulizia.
