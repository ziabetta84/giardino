# MeteoView redesign "Taccuino" — Design

**Data:** 2026-09-04
**Stato:** approvato (mockup iterato 3 volte con Rob)
**Mockup:** `docs/superpowers/specs/assets/2026-09-04-meteo-taccuino-mockup.html` · https://claude.ai/code/artifact/9e088d24-3666-4d93-8ffb-157183f2ed81

## Obiettivo

Ridisegnare `/meteo` in coerenza con la direzione "Taccuino" (calda, a colori, da diario di giardino): via la griglia di card identiche — è il pattern più "AI-slop" della schermata — a favore di un **registro verticale**, una riga per giorno, con la barra d'escursione min–max come elemento di lettura. I dati Open-Meteo e le icone acquerellate restano invariati.

Cambia anche il livello dati: `useMeteo` oggi scarta 6 giorni su 7 di previsione oraria; il redesign li usa tutti, così ogni giorno del registro ha il suo mini-grafico orario nel foglio di dettaglio.

## Non obiettivi

- Nessun cambio di endpoint o di provider meteo (resta Open-Meteo, no API key).
- Nessun blocco dark-mode (è Fase 3).
- Nessuna modifica a `HomeView` (usa `useMeteo` solo per `{ giorni, carica }`, tocca solo campi esistenti) né a `stores/dati.js` (idem).
- Non si globalizza `.alert-cura` da `PiantaView`: il blocco avvisi del meteo ne è una copia deliberata in tinta rosa (`.alert-meteo`, scoped in MeteoView).

## Architettura

Tre unità:

1. **`src/composables/useMeteo.js`** — livello dati. Cambia solo come mappa la risposta: raggruppa le ore per giorno invece di `slice(0, 24)`.
2. **`src/views/MeteoView.vue`** — la view: apertura "Adesso", nastro orario, blocco avvisi, registro giorni, e il `FoglioLaterale` del giorno selezionato.
3. **`src/components/MeteoGiorno.vue`** (nuovo) — il contenuto del foglio di un giorno: barra escursione grande, statistiche `.kv`, mini-grafico orario. Prop `{ giorno: Object }`, nessun emit.

CSS condiviso nuovo in `src/assets/main.css`: solo il blocco **`.exc*`** (barra escursione), usato sia dal registro in MeteoView sia dal foglio in MeteoGiorno. Tutto il resto è scoped al proprio componente.

## 1. `useMeteo.js`

### Situazione attuale

`carica(lat, lon, days = 7)` chiama Open-Meteo con `hourly=...&forecast_days=7`: la risposta contiene **già** 7×24 = 168 punti orari. Il codice però fa:

```js
orarieOggi.value = h?.time ? h.time.slice(0, 24).map((ora, i) => ({ … })) : []
```

cioè tiene solo le prime 24 ore (oggi) e butta le altre 144.

### Cambiamento

- Nuova funzione modulo `oreDelGiorno(h, dataGiorno)` — filtra gli indici di `h.time` che iniziano con `dataGiorno` (stringa `"YYYY-MM-DD"`) e li mappa alla stessa forma degli attuali item di `orarieOggi` (`{ ora, label, icona, descrizione, temp, pioggiaProb, vento, umidita, umiditaSuolo }`).
- Dentro `giorni.value = d.time.map((data, i) => ({ … }))`, aggiungere il campo **`ore: oreDelGiorno(h, data)`** ad ogni giorno.
- `orarieOggi` **non è più un `ref` popolato a mano** ma un `computed(() => giorni.value[0]?.ore ?? [])`. L'export resta identico (`{ giorni, oggi, orarieOggi, avvisi, loading, errore, carica }`), così MeteoView continua a leggerlo e `HomeView`/`dati.js` (che non lo usano) non sono toccati.
- Rimuovere il blocco `orarieOggi.value = h?.time ? h.time.slice(0, 24)…` dal corpo di `carica`.
- `mediaGiorno` (usata per `umidita`/`umiditaSuolo` giornalieri) resta invariata.

Payload: la risposta cresce da ~24 a ~168 righe orarie (~30 KB JSON), trascurabile. Nessun parametro URL nuovo (`forecast_days=7` vale già anche per `hourly`).

Cache offline: invariata — stesso URL, coperto dal `NetworkFirst` del service worker.

## 2. `MeteoView.vue`

### Struttura del `<template>` (dall'alto)

```
<h1 class="page-title">Meteo</h1>
<p class="meteo-sub">{{ località }} · aggiornato alle {{ ora }}</p>     ← se disponibile

── stato: skeleton | errore | contenuto ──

[loading]  righe skeleton nella forma del registro (non più la griglia di card)
[errore]   card centrata attuale, invariata (icona meteo-errore)
[contenuto]:

  <div class="slabel">Oggi</div>
  <div class="adesso" @click="apriDettaglio(giorni[0])">           ← apre il foglio di oggi
    <span class="adesso__ic"><Icon :name="adessoMeteo.icona"/></span>
    <div>
      <div class="adesso__label">adesso</div>
      <div class="adesso__temp">{{ adessoMeteo.temp }}<sup>°</sup></div>
      <div class="adesso__desc"><b>{{ adessoMeteo.descrizione }}</b> · percepiti … · vento … km/h</div>
    </div>
  </div>

  <div class="slabel">Le prossime ore</div>
  <div class="ribbon">                                             ← ex "Oggi, ora per ora"
    <div v-for="o in orarieDaAdesso" class="hour" :class="{ now: oraCorrente(o) }"> … </div>
  </div>

  <div v-if="avvisi.length" class="alert-meteo">                    ← ex .form-card rosa
    <span class="alert-meteo__ic"><Icon name="allerta"/></span>
    <div class="alert-meteo__main">
      <div class="alert-meteo__title">Occhio a questi giorni</div>
      <div class="alert-meteo__rows">
        <div v-for="a in avvisi" class="alert-meteo__row"><Icon :name="a.icona"/><span><b>{{ a.giorno }}</b> — {{ a.testo }}</span></div>
      </div>
    </div>
  </div>

  <div class="slabel">I prossimi giorni</div>
  <div class="ledger">
    <div v-for="g in giorniSuccessivi" class="day" @click="apriDettaglio(g)"
         role="button" tabindex="0" @keydown.enter="apriDettaglio(g)">
      <span v-if="haAvviso(g)" class="day__flag" aria-hidden="true"></span>
      <div class="day__gut"><div class="day__wd">{{ g.wd }}</div><div class="day__dm">{{ g.dm }}</div></div>
      <span class="day__i"><Icon :name="g.icona"/></span>
      <div class="day__desc"><span class="nm">{{ g.descrizione }}</span><span class="day__rain">{{ g.pioggia }} mm</span></div>
      <div class="exc">
        <span class="exc__lo">{{ g.tMin }}°</span>
        <span class="exc__track"><span class="exc__fill" :style="excStyle(g)"></span></span>
        <span class="exc__hi">{{ g.tMax }}°</span>
      </div>
    </div>
  </div>

<FoglioLaterale :model-value="!!giornoSelezionato"
  @update:model-value="v => { if (!v) chiudiDettaglio() }"
  :titolo="giornoSelezionato ? titoloGiorno(giornoSelezionato) : ''">
  <MeteoGiorno v-if="giornoSelezionato" :giorno="giornoSelezionato" />
</FoglioLaterale>
```

### `<script setup>`

Nuovi/cambiati:

- `import FoglioLaterale from '@/components/FoglioLaterale.vue'`, `import MeteoGiorno from '@/components/MeteoGiorno.vue'`.
- Rimuovere l'`import`/uso di `Teleport` per il vecchio overlay.
- `giorniSuccessivi = computed(() => giorni.value.slice(1))` — invariato.
- Il campo giorno ottiene, oltre a quelli attuali, delle etichette pronte per il gutter: `wd` (giorno settimana abbreviato, `capitalize`) e `dm` (numero del mese). Si possono calcolare in MeteoView da `g.data` con `toLocaleDateString('it-IT', { weekday: 'short' })` / `{ day: 'numeric' }`, oppure in `useMeteo` accanto a `label`. **Decisione:** in `useMeteo`, accanto a `label`, così il formato data vive in un posto solo. `label` (già presente, es. "mer 11 set") resta per compatibilità con `HomeView`.
- `rangeSettimana = computed(...)` → `{ min, max }` sui `tMin`/`tMax` di tutti i `giorni` (se `min === max`, `max = min + 1`).
- `excStyle(g)` → `{ left: '<x>%', right: '<y>%' }` con `left = (g.tMin - min)/span*100`, `right = (max - g.tMax)/span*100`.
- `haAvviso(g)` → `avvisi.value.some(a => a.key.startsWith(g.data))` (gli avvisi hanno `key: `${g.data}-${a.testo}``).
- `titoloGiorno(g)` → es. `"giovedì 12 settembre"` (`toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long' })`).
- `apriDettaglio` / `chiudiDettaglio` / `giornoSelezionato` — invariati come nomi; ora pilotano `<FoglioLaterale>` invece dell'overlay.
- `adesso` (ref con `setInterval` 60s) / `chiaveOra` / `orarieDaAdesso` / `adessoMeteo` / `oraCorrente` — **invariati**. `orarieDaAdesso` continua a filtrare `orarieOggi.value` (che ora è il computed su `giorni[0].ore`).
- `statisticheDettaglio` — **rimosso da MeteoView**, spostato in `MeteoGiorno.vue`.

### Stati

- **Loading:** `v-if="loading"` → 6 righe `.day-skel` (icona tonda skeleton + due barrette), stessa altezza indicativa delle righe reali. Niente più griglia di card skeleton.
- **Errore:** invariato — la card centrata attuale con `meteo-errore`.
- **Vuoto:** non si verifica (Open-Meteo torna sempre 7 giorni o un errore).

### CSS scoped (MeteoView)

Nuovi: `.meteo-sub`, `.adesso` / `.adesso__ic` / `.adesso__label` (Caveat) / `.adesso__temp` (Fraunces 52px) / `.adesso__desc`, `.ribbon` / `.hour` / `.hour.now` / `.hour__t` / `.hour__i` / `.hour__d` / `.hour__r`, `.alert-meteo*` (copia di `.alert-cura` con token rosa: `--rose-bg`, `--rose-ink`, bordo `color-mix(in srgb, var(--rose) 28%, transparent)`, tessera icona `color-mix(in srgb, var(--rose) 16%, var(--cream))`), `.ledger` / `.day` / `.day__gut` / `.day__wd` (Caveat, `--ink-soft`) / `.day__dm` (Fraunces 18px, `#000`) / `.day__i` / `.day__desc` / `.day__rain` / `.day__flag`, `.day-skel`.

Rimossi: `.meteo-hero`, `.meteo-hero-icon-wrap`, `.meteo-label`, `.meteo-temp`, `.ora-box`, `.ora-corrente`, `.meteo-giorni-grid` + il `@media`, `.meteo-overlay`, `.meteo-dettaglio-box`, `.meteo-dettaglio-chiudi`, `.meteo-dettaglio-stats`, `.meteo-dettaglio-stat`, `.form-card > .slabel:first-child` / `.meteo-hero .slabel`.

`.slabel` è già globale in `main.css` (`font:700 11px/1 var(--font-sans); letter-spacing:.13em; text-transform:uppercase; ::after` col filetto) — si usa così com'è.

## 3. `MeteoGiorno.vue` (nuovo)

**Prop:** `{ giorno: { type: Object, required: true } }`. Nessun emit.

**Template:**

```
<div class="mg">
  <div class="mg__hd">
    <span class="mg__ic"><Icon :name="giorno.icona" /></span>
    <div>
      <div class="mg__cond">{{ giorno.descrizione }}</div>
    </div>
  </div>

  <div class="exc exc--lg">
    <span class="exc__lo">{{ giorno.tMin }}°</span>
    <span class="exc__track"><span class="exc__fill" :style="excStyle"></span></span>
    <span class="exc__hi">{{ giorno.tMax }}°</span>
  </div>

  <div class="kv">
    <div v-for="s in stat" :key="s.label">
      <span class="mg__kic"><Icon :name="s.icona" /></span>
      <span><span class="k">{{ s.label }}</span><span class="v">{{ s.valore }}</span></span>
    </div>
  </div>

  <div v-if="chart" class="mg-chart">
    <div class="slabel">Ora per ora</div>
    <svg :viewBox="`0 0 ${chart.W} ${chart.H}`" preserveAspectRatio="none" role="img" aria-label="Andamento orario">
      <g class="mg-chart__rain"><rect v-for="(b,i) in chart.rainBars" :key="i" :x="b.x" :y="b.y" width="8" :height="b.h" /></g>
      <polyline class="mg-chart__temp" :points="chart.tempPoints" fill="none" />
      <circle :cx="chart.first.x" :cy="chart.first.y" r="3" />
      <circle :cx="chart.last.x" :cy="chart.last.y" r="3" />
    </svg>
    <div class="mg-chart__x"><span>00</span><span>06</span><span>12</span><span>18</span><span>23</span></div>
  </div>
</div>
```

L'intestazione titolo (giorno per esteso) la mette `FoglioLaterale` via `:titolo` — `MeteoGiorno` mostra solo la condizione.

**`<script setup>`:**

- `stat` = computed: array `[{ icona, label, valore }]` — `pioggia` (`goccia`, `${g.pioggia} mm`), `vento` (`vento`, `${g.vento} km/h`), poi `umidita`/`umiditaSuolo`/`evapotraspirazione` solo se `!= null` (stessa logica dell'attuale `statisticheDettaglio`). Icone: `goccia`, `vento`, `umidita`, `umidita-suolo`, `evapotraspirazione`.
- `excStyle` = computed — serve il range settimana. **Non disponibile in `MeteoGiorno`** (che vede un giorno solo). **Decisione:** la barra grande nel foglio usa il range del **giorno stesso** riempiendo sempre 0→100% (`left:0; right:0`), perché lì non c'è il confronto tra giorni; i numeri `tMin`/`tMax` ai lati bastano. Quindi `excStyle` fissa `{ left: '0%', right: '0%' }` — di fatto la barra è piena e serve solo come gradiente acqua→oro sotto i due numeri. (In alternativa MeteoView passa `range` come prop: **scartata**, YAGNI — nel foglio non c'è nulla con cui confrontare.)
- `chart` = computed da `giorno.ore` (24 punti):
  - `null` se `ore.length < 2`.
  - `W = 320`, `H = 88`, `pad = 6`, banda inferiore 22px per le barrette pioggia.
  - `x(i) = pad + i/(n-1) * (W - 2·pad)`.
  - `y(t) = pad + (1 - (t - tMin)/tSpan) * (H - 2·pad - 22)` con `tMin`/`tMax`/`tSpan` sui `temp` delle ore (`tSpan || 1`).
  - `tempPoints` = stringa `"x,y x,y …"`.
  - `rainBars` = `[{ x: x(i)-4, y: H - pad - h, h }]` con `h = (pioggiaProb ?? 0)/100 * 22`.
  - `first`/`last` = `{ x, y }` del primo/ultimo punto (per i pallini agli estremi).

**CSS scoped (MeteoGiorno):** `.mg` (padding), `.mg__hd` / `.mg__ic` (58px) / `.mg__cond`, `.kv` (riuso della forma già usata in DossierPianta/SelettoreSpecie: `grid 1fr 1fr`, `.k` label piccola, `.v` Fraunces — **NB:** `.kv` è scoped in quei componenti, non globale; qui va ridefinita scoped uguale, oppure — meglio — si globalizza `.kv` in `main.css`. **Decisione:** ridefinire `.kv` scoped in MeteoGiorno, coerente con la scelta fatta finora di non globalizzare `.kv`; una futura pulizia potrà unificarla), `.mg__kic` (26px), `.mg-chart` (wrapper: `background: var(--cream)`, `border: 1px solid var(--cream-dark)`, `border-radius: 14px`, padding), `.mg-chart svg` (`width:100%; height:auto`), `.mg-chart__temp` (`stroke: var(--gold-dark)`, `stroke-width: 2.5`, `stroke-linecap/linejoin: round`), `.mg-chart__rain rect` (`fill: var(--acqua)`, `opacity: .28`), `.mg-chart circle` (`fill: var(--gold-dark)`), `.mg-chart__x` (riga etichette, `font-size: 9px`, `color: var(--ink-faint)`, `space-between`).

## 4. `main.css` — blocco `.exc*` (nuovo, globale)

```css
/* Barra escursione min–max — registro Meteo + foglio del giorno */
.exc { display:flex; align-items:center; gap:8px; }
.exc__lo, .exc__hi { flex:none; font:600 11.5px/1 var(--font-display); color:var(--ink-mid); }
.exc__track { position:relative; flex:1; height:5px; border-radius:999px; background:var(--cream-dark); }
.exc__fill { position:absolute; top:0; bottom:0; border-radius:999px;
  background:linear-gradient(90deg, var(--acqua), var(--gold)); }
.exc--lg { gap:12px; }
.exc--lg .exc__lo { color:var(--acqua-ink); font-size:15px; }
.exc--lg .exc__hi { color:var(--gold-ink); font-size:15px; }
.exc--lg .exc__track { height:8px; }
```

## Verifica

Nessun runner di test nel repo → verifica = `npm run build` (exit 0) + QA browser di Rob:

- Registro: filetti, gutter (numero Fraunces nero / giorno Caveat grigio), barra escursione che slitta a destra sui giorni caldi, pallino rosa sui giorni con avviso.
- "Adesso" apre il foglio di oggi; ogni riga apre il proprio foglio; `Esc`/velo/× chiudono; con *riduci animazioni* niente slide.
- Foglio: condizione, barra escursione grande (gradiente acqua→oro), `.kv` (solo le statistiche disponibili), mini-grafico con sparkline temperatura + barrette pioggia; per i giorni futuri il grafico c'è (ore ora scaricate per tutti i 7 giorni).
- Nastro "Le prossime ore": scroll, ora corrente evidenziata.
- Blocco avvisi `.alert-meteo` in tinta rosa quando ci sono condizioni avverse; assente altrimenti.
- Errore API: card centrata invariata. Offline: previsione dalla cache del service worker.
- `HomeView` (striscia meteo compatta) invariata.

## Self-review

- **Placeholder:** nessuno.
- **Coerenza:** `orarieOggi` resta nell'export di `useMeteo` (computed) → MeteoView non si rompe, HomeView/dati.js non lo usano. `giorni[].ore` è additivo. `.exc*` globale usato da 2 componenti con la variante `--lg`. `excStyle` in MeteoView usa il range settimana; in MeteoGiorno è fisso 0/100% (deciso: nel foglio non c'è confronto).
- **Ambiguità risolte:** formato `wd`/`dm` in `useMeteo` (un posto solo); `.kv` ridefinita scoped in MeteoGiorno (niente globalizzazione ora); `.alert-meteo` copia scoped di `.alert-cura` (niente refactor di PiantaView); barra escursione nel foglio senza prop `range`.
- **Scope:** una view + un composable (cambio minimo) + un componente nuovo + un blocco CSS globale. Un solo piano.
