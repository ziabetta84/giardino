# Esito — MeteoView redesign "Taccuino"

Branch `meteo-taccuino` · **mergiato su `main`** (merge `5002fab`), 04/09/2026.
Piano: `2026-09-04-meteo-taccuino.md` · Spec: `docs/superpowers/specs/2026-09-04-meteo-taccuino-design.md` · Mockup: `docs/superpowers/specs/assets/2026-09-04-meteo-taccuino-mockup.html` (https://claude.ai/code/artifact/9e088d24-3666-4d93-8ffb-157183f2ed81).
Esecuzione subagent-driven: 3 task (T2/T3 in parallelo alle review) + review per task + review finale su Opus + 1 fix wave (2 Minor) + re-review scoped.

## Fatto

| Commit | Cosa |
|---|---|
| `7135c02` | Spec + mockup (committati su `main` prima del branch). |
| `0d6268f` | **`useMeteo.js`** — nuova fn `oreDelGiorno(h, dataGiorno)`; ogni giorno di `giorni` porta `ore` (array orario, stessa forma dei vecchi item di `orarieOggi`) + `wd`/`dm` (etichette gutter). `orarieOggi` da `ref` popolato a mano a `computed(() => giorni.value[0]?.ore ?? [])` — export invariato. Rimosso `h.time.slice(0, 24)` (la risposta Open-Meteo conteneva già 7×24 punti orari, `forecast_days` vale anche per `hourly`; nessun cambio di URL). **`main.css`**: blocco globale **`.exc*`** (barra escursione min–max) + variante `.exc--lg` (foglio: numeri acqua/oro, track 8px, fill sempre pieno). |
| `676f112` | Piano. |
| `89b80e9` | **`MeteoGiorno.vue`** NUOVO — corpo del foglio di un giorno. Prop `{ giorno }`, no emit. Intestazione icona+condizione, barra escursione grande (`.exc--lg`), statistiche `.kv` (pioggia/vento sempre, umidità aria/suolo/evapotraspirazione solo se `!= null` — logica dall'ex `statisticheDettaglio`), **mini-grafico orario**: `chart` computed da `giorno.ore` → sparkline temperatura (`<polyline>` oro) + barrette probabilità pioggia (banda inferiore, `--acqua` opacity .28), pallini agli estremi. `null` se `ore.length < 2`. viewBox 320×88 fisso, scalato dal CSS. |
| `fd4c3a0` | **`MeteoView.vue`** riscritto. Via la griglia `repeat(auto-fill,minmax(160px,1fr))` di card e l'overlay centrato del dettaglio. Ora: `.slabel` "Oggi" / "Le prossime ore" / "I prossimi giorni"; **`.adesso`** editoriale (icona 76px, temp 52px Fraunces, riga "descrizione · umidità · vento"); nastro **`.ribbon`** (`.hour`, ora corrente su `--gold-pale`); blocco **`.alert-meteo`** (copia scoped di `.alert-cura` di PiantaView in tinta rosa: icona `allerta` in tessera, titolo Fraunces, righe); **`.ledger`**/`.day` (grid `38px 34px 1fr`, gutter con numero Fraunces `#000` + giorno Caveat `--ink-soft`, icona-timbro, `.exc` con `:style="excStyle(g)"`, pallino `.day__flag` sui giorni con avviso). `excStyle` posiziona la barra sul range min/max dei 7 giorni (`rangeSettimana`, guardia `min===max`). Dettaglio giorno in `<FoglioLaterale>` (wiring identico ad `AttivitaView`) con `<MeteoGiorno>`. Skeleton nella forma del registro. Rimossi: tutta la vecchia modale + griglia + `statisticheDettaglio`. |
| `65f45af` | **Fix review finale (2 Minor):** `loading` in `useMeteo` parte a `true` (copre la finestra pre-`carica` del deep-link a freddo a `/#/meteo`); le sezioni "Oggi" e "I prossimi giorni" passano dentro `<template v-if="adessoMeteo">` / `<template v-if="giorniSuccessivi.length">` come già "Le prossime ore" — niente più `.slabel` col filetto appesa nel vuoto senza dati (anche dopo mezzanotte su tab long-lived). |
| `84f3a64` (merge `d0029ce`) | **Follow-up dopo QA di Rob** ("nel grafico c'è solo la temperatura"): le 24 barrette della probabilità di pioggia erano illeggibili con dati reali (spesso 0–5%, a `opacity .28` = stecchini sub-pixel; oggi 0% ovunque = niente). Rifatto il mini-grafico: banda "umido" 0–100% in basso (sfondo `--acqua` opacity .07 + linea di base sempre visibile), **probabilità di pioggia come area continua** (`<path>`, non più `<rect>`), **nuova linea umidità dell'aria** (`--sage-dark`, disegnata solo se tutte le 24 ore hanno `umidita != null`) sulla stessa scala. Temperatura invariata nella banda superiore. Legenda sotto il grafico; label da "Temperatura e probabilità di pioggia, ora per ora" a "Ora per ora". `viewBox` 320×88 → 320×92. Solo `MeteoGiorno.vue`, senza subagent (fix mono-file). |

**`FoglioLaterale` ora in 7 viste.** `useMeteo`: il payload orario cresce da ~24 a ~168 righe (~30 KB, trascurabile). `HomeView` e `stores/dati.js` (che usano solo `{ giorni, carica }`) non toccati — modifiche a `giorni` additive.

## Nessun ruling preso in autonomia

Scan pre-flight pulito, nessun fix loop al limite, review finale su Opus riuscita al primo tentativo. Zero decisioni prese al posto di Rob.

## Da guardare nel QA browser (Minor differiti — nessuno bloccante)

- **iOS Safari / PWA iPhone**: `MeteoGiorno.vue` usa `svg { width:100%; height:auto }` — **primo `height:auto` su SVG in tutto il codebase**. Safari moderno calcola l'altezza dal viewBox, ma va confermato a vista che il grafico non collassi a 0 né si stiri.
- **Deep-link a freddo a `/#/meteo`** (refresh sulla route o avvio PWA lì): con il fix `loading=ref(true)` deve comparire lo skeleton, non le label orfane. *Osservazione latente non fixata:* se `store.caricaTutto()` rigettasse, lo skeleton resterebbe fisso invece di mostrare contenuto vuoto (comunque meglio di prima).
- **Registro**: filetti tra le righe; gutter (numero Fraunces nero / giorno Caveat grigio); la barra escursione riempie di più i giorni caldi (slitta a destra), di meno i freddi; pallino rosa **solo** sui giorni successivi con avviso (mai su oggi — l'avviso di oggi vive nel blocco `.alert-meteo` come "Oggi", e `giorniSuccessivi` parte da indice 1).
- **`.day:hover { background: var(--white) }`** resta appiccicato dopo tap su touch e la riga non ha `border-radius` — cosmetico, **non fixato** ("solo se stona in QA").
- **Foglio**: da "Adesso" e da una riga; `Esc`/velo/× chiudono, il focus torna alla riga toccata, lo scroll del body si sblocca; con *riduci animazioni* niente slide. Il grafico c'è anche per i giorni futuri (ore ora scaricate per tutti e 7). Il foglio di oggi mostra tutte le 24 ore, anche quelle passate (corretto).
- **Nastro `.ribbon`**: scroll orizzontale, `margin: 0 -4px` che sborda di 4px nel padding di `.app-main` senza creare scroll orizzontale di pagina.
- **Descrizioni WMO lunghe** ("Temporale con grandine") a 360px di larghezza nella riga `38px 34px 1fr`.
- **HomeView** striscia meteo invariata; **errore API** card centrata invariata; **offline** previsione dalla cache del service worker (stesso URL).

## Fuori scope — round successivi

- Sottotitolo con località/orario sotto "Meteo" (non c'è place-name in `settings`, solo lat/lon).
- "Temperatura percepita" nell'apertura (richiederebbe `apparent_temperature` nella fetch).
- **Fase 3 dark mode**: `.exc*` / `.alert-meteo*` / `.mg-chart*` avranno bisogno degli override (tokens `--acqua`/`--gold`/`--cream` ecc.). `#000` su `.day__dm` da rivedere lì.
- **Migration RLS `specie`** — round dedicato.
- Unificare `.kv` (globale) / `.alert-cura` (scoped PiantaView) / `.alert-meteo` (scoped MeteoView) come classi davvero condivise — pulizia a parte.
- `MeteoGiorno` `chart`: `temps` non difensivo su `temp` null (Open-Meteo non lo restituisce nella finestra 7 giorni); etichette x `00/06/12/18/23` statiche assumono 24 ore ordinate; `role="button"` gestisce Enter ma non Space.
