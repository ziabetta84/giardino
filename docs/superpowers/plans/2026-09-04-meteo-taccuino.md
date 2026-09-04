# MeteoView redesign "Taccuino" — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ridisegnare `/meteo` in stile "Taccuino": registro verticale (una riga/giorno) al posto della griglia di card, apertura "Adesso" editoriale, blocco avvisi `.alert-meteo`, dettaglio giorno nel `FoglioLaterale` con mini-grafico orario. `useMeteo` passa dall'usare 1 giorno di previsione oraria a tutti i 7.

**Architecture:** Tre unità. (1) `useMeteo.js` — raggruppa le ore per giorno (`giorni[].ore`) invece di `slice(0, 24)`; `orarieOggi` diventa un `computed`. (2) `MeteoGiorno.vue` (nuovo) — corpo del foglio di un giorno: barra escursione grande, statistiche `.kv`, mini-grafico SVG. (3) `MeteoView.vue` — riscrittura: `.slabel` "Oggi" / "Le prossime ore" / "I prossimi giorni", `.adesso`, `.ribbon`, `.alert-meteo`, `.ledger`/`.day` con barra escursione, `<FoglioLaterale>`. CSS globale nuovo: solo il blocco `.exc*` in `main.css` (usato da registro + foglio).

**Tech Stack:** Vue 3 `<script setup>` SFC, Vite, Pinia (`useDatiStore`), Open-Meteo REST (no key), CSS custom properties in `src/assets/main.css`. Nessun runner di test.

**Spec:** `docs/superpowers/specs/2026-09-04-meteo-taccuino-design.md` — mockup `docs/superpowers/specs/assets/2026-09-04-meteo-taccuino-mockup.html`. La spec è la fonte: in caso di conflitto vince la spec.

## Global Constraints

- **Lingua:** testi UI, commenti, messaggi di commit in **italiano**.
- **Zorba** sempre nero — non toccato qui.
- **Niente blocchi dark-mode** (`@media (prefers-color-scheme: dark)`, `:root[data-theme]`) — è Fase 3.
- **Verifica automatica = solo `npm run build` (exit 0).** Non esiste `npm test`. Nessun test da scrivere o cercare.
- **Palette/font solo token:** `--rose`/`--gold`/`--sage`/`--olive`/`--acqua`/`--cream` e derivati; `--font-display` (Fraunces) / `--font-sans` (DM Sans) / `--font-hand` (Caveat). Un unico literal ammesso: `#000` su `.day__dm` (scelta esplicita di Rob per l'àncora della data).
- **`useMeteo` è usato anche da `HomeView.vue` e `stores/dati.js`**, entrambi solo con `{ giorni, carica }`: le modifiche devono restare additive per `giorni` e non toccare l'export `carica`. `orarieOggi` resta nell'export (come `computed`).
- **Nessun cambio all'URL Open-Meteo** — `forecast_days=7` vale già anche per `hourly`, la risposta contiene già 168 punti orari.
- **Non si globalizza `.alert-cura`** da `PiantaView`: `.alert-meteo` è una copia scoped in tinta rosa.
- **`.slabel` e `.kv` sono già globali in `main.css`** — si usano così come sono.
- **Commit:** messaggi in italiano, ognuno chiude con:
  ```
  Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
  ```
- **Branch:** `meteo-taccuino` da `main`. Nessun commit diretto su `main`. Merge solo su ok esplicito di Rob.

---

## File Structure

| File | Modifica |
|------|----------|
| `src/composables/useMeteo.js` | **Modifica** — nuova fn modulo `oreDelGiorno(h, dataGiorno)`; ogni giorno di `giorni` guadagna `ore`, `wd`, `dm`; `orarieOggi` da `ref` a `computed(() => giorni.value[0]?.ore ?? [])`; rimosso il blocco `orarieOggi.value = … slice(0,24)`. |
| `src/assets/main.css` | **Modifica** — append del blocco `.exc*` (barra escursione, con variante `.exc--lg`). |
| `src/components/MeteoGiorno.vue` | **Crea** — corpo del foglio di un giorno. Prop `{ giorno: Object }`, nessun emit. |
| `src/views/MeteoView.vue` | **Riscrivi** — nuovo `<template>` (slabel + adesso + ribbon + alert-meteo + ledger + FoglioLaterale), `<script setup>` aggiornato, `<style scoped>` rifatto. |

Nessun file di test.

---

### Task 1: `useMeteo.js` — ore per giorno + `.exc*` in `main.css`

**Files:**
- Modify: `src/composables/useMeteo.js`
- Modify: `src/assets/main.css`

**Interfaces:**
- Produce: `giorni.value[i].ore` = array di `{ ora, label, icona, descrizione, temp, pioggiaProb, vento, umidita, umiditaSuolo }` (stessa forma degli attuali item di `orarieOggi`). `giorni.value[i].wd` (stringa, giorno settimana abbreviato minuscolo) e `.dm` (stringa, numero del mese). `orarieOggi` resta esportato, ora `computed`.
- Produce: classi globali `.exc` / `.exc__lo` / `.exc__hi` / `.exc__track` / `.exc__fill` / `.exc--lg`, consumate da Task 2 e Task 3.

- [ ] **Step 1: `useMeteo.js` — funzione `oreDelGiorno`**

In `src/composables/useMeteo.js`, subito dopo la funzione `mediaGiorno` (che finisce con `return conteggio ? somma / conteggio : null }`), aggiungere:

```js
// Le 24 ore che cadono in un giorno (stringa "YYYY-MM-DD"): stessa forma
// usata finora da orarieOggi. La risposta Open-Meteo contiene già 7×24
// punti orari (forecast_days vale anche per hourly), prima ne usavamo solo 24.
function oreDelGiorno(h, dataGiorno) {
  if (!h?.time) return []
  const ore = []
  for (let i = 0; i < h.time.length; i++) {
    if (!h.time[i].startsWith(dataGiorno)) continue
    ore.push({
      ora: h.time[i],
      label: h.time[i].slice(11, 16),
      icona: WMO[h.weathercode[i]] ?? 'meteo',
      descrizione: WMO_LABEL[h.weathercode[i]] ?? '',
      temp: Math.round(h.temperature_2m[i]),
      pioggiaProb: h.precipitation_probability?.[i] ?? null,
      vento: Math.round(h.windspeed_10m[i]),
      umidita: h.relative_humidity_2m?.[i] ?? null,
      umiditaSuolo: h.soil_moisture_0_to_1cm?.[i] != null ? Math.round(h.soil_moisture_0_to_1cm[i] * 100) : null,
    })
  }
  return ore
}
```

- [ ] **Step 2: `useMeteo.js` — `orarieOggi` da `ref` a `computed`**

Nella funzione `useMeteo()`, rimuovere la riga:

```js
  const orarieOggi  = ref([])
```

- [ ] **Step 3: `useMeteo.js` — campi `ore` / `wd` / `dm` sul giorno**

Dentro `carica`, nel `giorni.value = d.time.map((data, i) => { … })`, l'oggetto restituito passa da:

```js
        return {
          data,
          label: new Date(data).toLocaleDateString('it-IT', { weekday:'short', day:'numeric', month:'short' }),
          codice: d.weathercode[i],
          icona: WMO[d.weathercode[i]] ?? 'meteo',
          descrizione: WMO_LABEL[d.weathercode[i]] ?? '',
          tMax: Math.round(d.temperature_2m_max[i]),
          tMin: Math.round(d.temperature_2m_min[i]),
          pioggia: d.precipitation_sum[i]?.toFixed(1) ?? '0',
          vento: Math.round(d.windspeed_10m_max[i]),
          umidita: umidita != null ? Math.round(umidita) : null,
          umiditaSuolo: umiditaSuolo != null ? Math.round(umiditaSuolo * 100) : null,
          evapotraspirazione: d.et0_fao_evapotranspiration?.[i]?.toFixed(1) ?? null,
        }
```

a:

```js
        const giornoDate = new Date(data)
        return {
          data,
          label: giornoDate.toLocaleDateString('it-IT', { weekday:'short', day:'numeric', month:'short' }),
          wd: giornoDate.toLocaleDateString('it-IT', { weekday:'short' }),
          dm: giornoDate.toLocaleDateString('it-IT', { day:'numeric' }),
          codice: d.weathercode[i],
          icona: WMO[d.weathercode[i]] ?? 'meteo',
          descrizione: WMO_LABEL[d.weathercode[i]] ?? '',
          tMax: Math.round(d.temperature_2m_max[i]),
          tMin: Math.round(d.temperature_2m_min[i]),
          pioggia: d.precipitation_sum[i]?.toFixed(1) ?? '0',
          vento: Math.round(d.windspeed_10m_max[i]),
          umidita: umidita != null ? Math.round(umidita) : null,
          umiditaSuolo: umiditaSuolo != null ? Math.round(umiditaSuolo * 100) : null,
          evapotraspirazione: d.et0_fao_evapotranspiration?.[i]?.toFixed(1) ?? null,
          ore: oreDelGiorno(h, data),
        }
```

- [ ] **Step 4: `useMeteo.js` — rimuovere il vecchio `orarieOggi.value = …`**

Subito dopo `oggi.value = giorni.value[0] ?? null`, rimuovere l'intero blocco:

```js
      orarieOggi.value = h?.time ? h.time.slice(0, 24).map((ora, i) => ({
        ora,
        label: ora.slice(11, 16),
        icona: WMO[h.weathercode[i]] ?? 'meteo',
        descrizione: WMO_LABEL[h.weathercode[i]] ?? '',
        temp: Math.round(h.temperature_2m[i]),
        pioggiaProb: h.precipitation_probability?.[i] ?? null,
        vento: Math.round(h.windspeed_10m[i]),
        umidita: h.relative_humidity_2m?.[i] ?? null,
        umiditaSuolo: h.soil_moisture_0_to_1cm?.[i] != null ? Math.round(h.soil_moisture_0_to_1cm[i] * 100) : null,
      })) : []
```

- [ ] **Step 5: `useMeteo.js` — `orarieOggi` come `computed`**

Subito dopo la dichiarazione `const avvisi = computed(() => …)` (e prima del `return`), aggiungere:

```js
  // Le ore di oggi: prima era un ref popolato a mano, ora deriva dal primo
  // giorno (che ha già il suo array `ore`). Export invariato.
  const orarieOggi = computed(() => giorni.value[0]?.ore ?? [])
```

Il `return { giorni, oggi, orarieOggi, avvisi, loading, errore, carica }` resta identico.

- [ ] **Step 6: Build**

Run: `npm run build`
Expected: exit 0.

- [ ] **Step 7: `main.css` — blocco `.exc*`**

Append in fondo a `src/assets/main.css`:

```css

/* ===== Barra escursione min–max — registro Meteo + foglio del giorno ===== */
.exc { display:flex; align-items:center; gap:8px; }
.exc__lo, .exc__hi { flex:none; font:600 11.5px/1 var(--font-display); color:var(--ink-mid); }
.exc__track { position:relative; flex:1; height:5px; border-radius:999px; background:var(--cream-dark); }
.exc__fill { position:absolute; top:0; bottom:0; border-radius:999px;
  background:linear-gradient(90deg, var(--acqua), var(--gold)); }
.exc--lg { gap:12px; }
.exc--lg .exc__lo { color:var(--acqua-ink); font-size:15px; }
.exc--lg .exc__hi { color:var(--gold-ink); font-size:15px; }
.exc--lg .exc__track { height:8px; }
.exc--lg .exc__fill { left:0; right:0; }
```

- [ ] **Step 8: Build**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo.

- [ ] **Step 9: Verifica di lettura**

- `grep -n "slice(0, 24)\|slice(0,24)" src/composables/useMeteo.js` → **nessun risultato**.
- `grep -n "orarieOggi" src/composables/useMeteo.js` → solo la dichiarazione `const orarieOggi = computed(...)` e il `return`.
- `grep -n "ore: oreDelGiorno\|wd:\|dm:" src/composables/useMeteo.js` → presenti nel map dei giorni.
- `grep -n "\.exc" src/assets/main.css` → il nuovo blocco.

- [ ] **Step 10: Commit**

```bash
git add src/composables/useMeteo.js src/assets/main.css
git commit -m "$(cat <<'EOF'
useMeteo: ore per tutti i 7 giorni + .exc (barra escursione)

La risposta Open-Meteo conteneva già 7×24 punti orari ma se ne usavano
24 (oggi). Ora ogni giorno di `giorni` porta il suo array `ore` (+ le
etichette `wd`/`dm` per il gutter del registro); `orarieOggi` diventa un
computed sul primo giorno, export invariato. In main.css il blocco .exc*
per la barra escursione min–max (registro + foglio del giorno).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 2: `MeteoGiorno.vue` (nuovo)

**Files:**
- Create: `src/components/MeteoGiorno.vue`

**Interfaces:**
- Consuma: `giorno` prop con `{ icona, descrizione, tMin, tMax, pioggia, vento, umidita, umiditaSuolo, evapotraspirazione, ore }` (da Task 1). `ore` = array di `{ temp, pioggiaProb, … }`.
- Consuma: classi globali `.slabel`, `.kv`, `.exc` / `.exc--lg` (Task 1).
- Consuma: `Icon.vue`, icone `goccia` / `vento` / `umidita` / `umidita-suolo` / `evapotraspirazione` / le icone WMO passate in `giorno.icona`.
- Produce: componente usato da `MeteoView.vue` (Task 3).

- [ ] **Step 1: Creare il file**

Creare `src/components/MeteoGiorno.vue` con esattamente:

```vue
<template>
  <div class="mg">
    <div class="mg__hd">
      <span class="mg__ic"><Icon :name="giorno.icona" /></span>
      <div class="mg__cond">{{ giorno.descrizione }}</div>
    </div>

    <div class="exc exc--lg">
      <span class="exc__lo">{{ giorno.tMin }}°</span>
      <span class="exc__track"><span class="exc__fill"></span></span>
      <span class="exc__hi">{{ giorno.tMax }}°</span>
    </div>

    <div class="kv mg__kv">
      <div v-for="s in stat" :key="s.label">
        <span class="k"><Icon :name="s.icona" />{{ s.label }}</span><span class="v">{{ s.valore }}</span>
      </div>
    </div>

    <div v-if="chart" class="mg-chart">
      <div class="mg-chart__lab">Temperatura e probabilità di pioggia, ora per ora</div>
      <svg :viewBox="`0 0 ${chart.W} ${chart.H}`" preserveAspectRatio="none"
        role="img" aria-label="Andamento orario di temperatura e probabilità di pioggia">
        <g class="mg-chart__rain">
          <rect v-for="(b, i) in chart.rainBars" :key="i" :x="b.x" :y="b.y" width="8" :height="b.h" />
        </g>
        <polyline class="mg-chart__temp" fill="none" :points="chart.tempPoints" />
        <circle class="mg-chart__dot" :cx="chart.first.x" :cy="chart.first.y" r="3" />
        <circle class="mg-chart__dot" :cx="chart.last.x" :cy="chart.last.y" r="3" />
      </svg>
      <div class="mg-chart__x"><span>00</span><span>06</span><span>12</span><span>18</span><span>23</span></div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import Icon from '@/components/Icon.vue'

const props = defineProps({
  giorno: { type: Object, required: true },
})

// Statistiche del giorno: pioggia e vento sempre, le altre solo se presenti
// (stessa logica del vecchio statisticheDettaglio in MeteoView).
const stat = computed(() => {
  const g = props.giorno
  const s = [
    { icona: 'goccia', label: 'Pioggia', valore: `${g.pioggia} mm` },
    { icona: 'vento', label: 'Vento max', valore: `${g.vento} km/h` },
  ]
  if (g.umidita != null) s.push({ icona: 'umidita', label: 'Umidità aria', valore: `${g.umidita}%` })
  if (g.umiditaSuolo != null) s.push({ icona: 'umidita-suolo', label: 'Umidità suolo', valore: `${g.umiditaSuolo}%` })
  if (g.evapotraspirazione != null) s.push({ icona: 'evapotraspirazione', label: 'Evapotraspirazione', valore: `${g.evapotraspirazione} mm` })
  return s
})

// Mini-grafico orario: sparkline della temperatura + barrette della
// probabilità di pioggia nella banda inferiore. viewBox fisso, il CSS lo
// scala a larghezza piena.
const chart = computed(() => {
  const ore = props.giorno?.ore ?? []
  if (ore.length < 2) return null
  const W = 320, H = 88, pad = 6, bandaPioggia = 22
  const temps = ore.map(o => o.temp)
  const tMin = Math.min(...temps)
  const tMax = Math.max(...temps)
  const tSpan = (tMax - tMin) || 1
  const x = i => pad + (i / (ore.length - 1)) * (W - 2 * pad)
  const y = t => pad + (1 - (t - tMin) / tSpan) * (H - 2 * pad - bandaPioggia)
  const tempPoints = ore.map((o, i) => `${x(i).toFixed(1)},${y(o.temp).toFixed(1)}`).join(' ')
  const rainBars = ore.map((o, i) => {
    const h = ((o.pioggiaProb ?? 0) / 100) * bandaPioggia
    return { x: (x(i) - 4).toFixed(1), y: (H - pad - h).toFixed(1), h: h.toFixed(1) }
  })
  return {
    W, H, tempPoints, rainBars,
    first: { x: x(0).toFixed(1), y: y(ore[0].temp).toFixed(1) },
    last: { x: x(ore.length - 1).toFixed(1), y: y(ore[ore.length - 1].temp).toFixed(1) },
  }
})
</script>

<style scoped>
.mg { padding: 4px 16px 22px; }
@media (min-width: 640px) { .mg { padding: 4px 18px 24px; } }
.mg__hd { display: flex; align-items: center; gap: 14px; margin-bottom: 16px; }
.mg__ic { width: 58px; height: 58px; flex: none; }
.mg__ic svg { width: 100%; height: 100%; display: block; }
.mg__cond { font-size: 13px; color: var(--ink-mid); }
.mg__kv { margin: 18px 0 22px; }
.mg-chart { background: var(--cream); border: 1px solid var(--cream-dark); border-radius: 14px; padding: 12px 12px 10px; }
.mg-chart__lab { font: italic 400 11px/1.3 var(--font-display); color: var(--ink-soft); margin-bottom: 8px; }
.mg-chart svg { width: 100%; height: auto; display: block; }
.mg-chart__temp { stroke: var(--gold-dark); stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round; }
.mg-chart__rain rect { fill: var(--acqua); opacity: .28; }
.mg-chart__dot { fill: var(--gold-dark); }
.mg-chart__x { display: flex; justify-content: space-between; font-size: 9px; color: var(--ink-faint); margin-top: 3px; padding: 0 2px; }
</style>
```

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0. Il componente non è ancora referenziato da nessuno — il build deve comunque passare (Vue compila l'SFC).

- [ ] **Step 3: Commit**

```bash
git add src/components/MeteoGiorno.vue
git commit -m "$(cat <<'EOF'
MeteoGiorno: corpo del foglio di un giorno

Barra escursione grande, statistiche .kv (solo quelle disponibili) e
mini-grafico orario (sparkline temperatura + barrette probabilità
pioggia) da giorno.ore. Prop { giorno }, nessun emit. Non ancora
referenziato — lo aggancia MeteoView nel task successivo.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

### Task 3: `MeteoView.vue` — riscrittura

**Files:**
- Modify (rewrite): `src/views/MeteoView.vue`

**Interfaces:**
- Consuma: `useMeteo()` → `{ giorni, orarieOggi, avvisi, loading, errore, carica }` con `giorni[].ore`/`.wd`/`.dm` (Task 1).
- Consuma: `MeteoGiorno.vue` (Task 2), `FoglioLaterale.vue` (esistente), `Icon.vue`, `useDatiStore`.
- Consuma: classi globali `.slabel`, `.exc` (Task 1), `.page-title`, `.card`.

- [ ] **Step 1: Riscrivere l'intero file**

Sostituire tutto il contenuto di `src/views/MeteoView.vue` con:

```vue
<template>
  <div>
    <h1 class="page-title" style="margin-bottom:20px">Meteo</h1>

    <div v-if="loading" class="ledger">
      <div v-for="i in 6" :key="i" class="day-skel">
        <div class="skeleton day-skel__ic"></div>
        <div class="day-skel__m">
          <div class="skeleton" style="height:12px;width:55%"></div>
          <div class="skeleton" style="height:10px;width:80%;margin-top:8px"></div>
        </div>
      </div>
    </div>

    <div v-else-if="errore" class="card" style="padding:24px;text-align:center;color:var(--rose-dark);">
      <div style="width:44px;height:44px;border-radius:50%;background:var(--rose-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 10px;">
        <Icon name="meteo-errore" style="width:22px;height:22px;" />
      </div>
      <p>{{ errore }}</p>
    </div>

    <template v-else>
      <div class="slabel">Oggi</div>
      <div v-if="adessoMeteo" class="adesso" role="button" tabindex="0"
        @click="apriDettaglio(giorni[0])" @keydown.enter="apriDettaglio(giorni[0])">
        <span class="adesso__ic"><Icon :name="adessoMeteo.icona" /></span>
        <div class="adesso__m">
          <div class="adesso__label">adesso</div>
          <div class="adesso__temp">{{ adessoMeteo.temp }}<sup>°</sup></div>
          <div class="adesso__desc">
            <b>{{ adessoMeteo.descrizione }}</b><template v-if="adessoMeteo.umidita != null"> · umidità {{ adessoMeteo.umidita }}%</template><template v-if="adessoMeteo.vento != null"> · vento {{ adessoMeteo.vento }} km/h</template>
          </div>
        </div>
      </div>

      <template v-if="orarieDaAdesso.length">
        <div class="slabel">Le prossime ore</div>
        <div class="ribbon">
          <div v-for="o in orarieDaAdesso" :key="o.ora" class="hour" :class="{ now: oraCorrente(o) }">
            <div class="hour__t">{{ o.label }}</div>
            <span class="hour__i"><Icon :name="o.icona" /></span>
            <div class="hour__d">{{ o.temp }}°</div>
            <div v-if="o.pioggiaProb !== null" class="hour__r"><Icon name="goccia" />{{ o.pioggiaProb }}%</div>
          </div>
        </div>
      </template>

      <div v-if="avvisi.length" class="alert-meteo">
        <span class="alert-meteo__ic"><Icon name="allerta" /></span>
        <div class="alert-meteo__main">
          <div class="alert-meteo__title">Occhio a questi giorni</div>
          <div class="alert-meteo__rows">
            <div v-for="a in avvisi" :key="a.key" class="alert-meteo__row">
              <Icon :name="a.icona" /><span><b>{{ a.giorno }}</b> — {{ a.testo }}</span>
            </div>
          </div>
        </div>
      </div>

      <div class="slabel">I prossimi giorni</div>
      <div class="ledger">
        <div v-for="g in giorniSuccessivi" :key="g.data" class="day" role="button" tabindex="0"
          @click="apriDettaglio(g)" @keydown.enter="apriDettaglio(g)">
          <span v-if="haAvviso(g)" class="day__flag" aria-hidden="true"></span>
          <div class="day__gut">
            <div class="day__wd">{{ g.wd }}</div>
            <div class="day__dm">{{ g.dm }}</div>
          </div>
          <span class="day__i"><Icon :name="g.icona" /></span>
          <div class="day__desc">
            <span class="nm">{{ g.descrizione }}</span>
            <span class="day__rain">{{ g.pioggia }} mm</span>
          </div>
          <div class="exc">
            <span class="exc__lo">{{ g.tMin }}°</span>
            <span class="exc__track"><span class="exc__fill" :style="excStyle(g)"></span></span>
            <span class="exc__hi">{{ g.tMax }}°</span>
          </div>
        </div>
      </div>
    </template>

    <FoglioLaterale
      :model-value="!!giornoSelezionato"
      @update:model-value="v => { if (!v) chiudiDettaglio() }"
      :titolo="giornoSelezionato ? titoloGiorno(giornoSelezionato) : ''"
    >
      <MeteoGiorno v-if="giornoSelezionato" :giorno="giornoSelezionato" />
    </FoglioLaterale>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { useMeteo } from '@/composables/useMeteo'
import { useDatiStore } from '@/stores/dati'
import Icon from '@/components/Icon.vue'
import FoglioLaterale from '@/components/FoglioLaterale.vue'
import MeteoGiorno from '@/components/MeteoGiorno.vue'

const { giorni, orarieOggi, avvisi, loading, errore, carica } = useMeteo()
const store = useDatiStore()

const giorniSuccessivi = computed(() => giorni.value.slice(1))

const adesso = ref(new Date())
let timer = null
onMounted(() => { timer = setInterval(() => { adesso.value = new Date() }, 60000) })
onUnmounted(() => { if (timer) clearInterval(timer) })

function chiaveOra(d) {
  const oggiStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  const oraStr = String(d.getHours()).padStart(2, '0')
  return `${oggiStr}T${oraStr}:00`
}

const orarieDaAdesso = computed(() => {
  const chiave = chiaveOra(adesso.value)
  return orarieOggi.value.filter(o => o.ora >= chiave)
})
const adessoMeteo = computed(() => orarieDaAdesso.value[0] ?? null)
function oraCorrente(o) { return o.ora === chiaveOra(adesso.value) }

// Range termico dei 7 giorni: la barra d'escursione di ogni giorno è
// posizionata su questo intervallo, così i giorni più caldi slittano a destra.
const rangeSettimana = computed(() => {
  const gs = giorni.value
  if (!gs.length) return { min: 0, max: 1 }
  let min = Infinity, max = -Infinity
  for (const g of gs) {
    if (g.tMin < min) min = g.tMin
    if (g.tMax > max) max = g.tMax
  }
  if (min === max) max = min + 1
  return { min, max }
})
function excStyle(g) {
  const { min, max } = rangeSettimana.value
  const span = max - min
  return {
    left: `${((g.tMin - min) / span) * 100}%`,
    right: `${((max - g.tMax) / span) * 100}%`,
  }
}

function haAvviso(g) {
  return avvisi.value.some(a => a.key.startsWith(`${g.data}-`))
}
function titoloGiorno(g) {
  return new Date(g.data).toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long' })
}

const giornoSelezionato = ref(null)
function apriDettaglio(g) { giornoSelezionato.value = g }
function chiudiDettaglio() { giornoSelezionato.value = null }

onMounted(async () => {
  await store.caricaTutto()
  const s = store.settings
  carica(s?.location?.lat ?? 43.8309, s?.location?.lon ?? 12.9860)
})
</script>

<style scoped>
/* Apertura "Adesso" */
.adesso { display: flex; align-items: center; gap: 18px; padding: 2px 2px 4px; cursor: pointer; }
.adesso__ic { width: 76px; height: 76px; flex: none; }
.adesso__ic svg { width: 100%; height: 100%; display: block; }
.adesso__m { min-width: 0; }
.adesso__label { font-family: var(--font-hand); font-size: 20px; color: var(--ink-soft); line-height: 1; }
.adesso__temp { font-family: var(--font-display); font-weight: 600; font-size: 52px; line-height: .95; letter-spacing: -.02em; margin: 2px 0 3px; }
.adesso__temp sup { font-size: .42em; font-weight: 500; top: -.75em; margin-left: 2px; }
.adesso__desc { font-size: 13px; color: var(--ink-mid); }
.adesso__desc b { color: var(--ink); font-weight: 600; }

/* Nastro orario */
.ribbon { display: flex; gap: 8px; overflow-x: auto; padding: 0 4px 6px; margin: 0 -4px; }
.hour { flex: none; width: 52px; text-align: center; padding: 8px 4px; border-radius: 12px; background: var(--white); border: 1px solid var(--cream-dark); }
.hour.now { background: var(--gold-pale); border-color: var(--gold-light); }
.hour__t { font-size: 10.5px; color: var(--ink-soft); }
.hour__i { display: block; width: 24px; height: 24px; margin: 3px auto 2px; }
.hour__i svg { width: 100%; height: 100%; display: block; }
.hour__d { font-family: var(--font-display); font-weight: 600; font-size: 12.5px; }
.hour__r { display: flex; align-items: center; justify-content: center; gap: 2px; font-size: 9px; color: var(--acqua-ink); margin-top: 1px; }
.hour__r svg { width: 8px; height: 8px; }

/* Blocco avvisi — stessa struttura di .alert-cura in PiantaView, tinta rosa */
.alert-meteo { display: flex; gap: 12px; align-items: flex-start; padding: 14px 15px; margin: 22px 0 2px;
  background: var(--rose-bg); border: 1px solid color-mix(in srgb, var(--rose) 28%, transparent); border-radius: 16px; }
.alert-meteo__ic { flex: none; width: 36px; height: 36px; border-radius: 11px; display: flex; align-items: center; justify-content: center;
  background: color-mix(in srgb, var(--rose) 16%, var(--cream)); color: var(--rose-ink); }
.alert-meteo__ic svg { width: 20px; height: 20px; }
.alert-meteo__main { flex: 1; min-width: 0; }
.alert-meteo__title { font: 600 14px/1.25 var(--font-display); color: var(--rose-ink); }
.alert-meteo__rows { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.alert-meteo__row { display: flex; align-items: center; gap: 8px; font: 400 12.5px/1.4 var(--font-sans); color: var(--rose-ink); }
.alert-meteo__row svg { width: 15px; height: 15px; flex: none; }

/* Registro giorni */
.ledger { margin-top: 4px; }
.day { position: relative; display: grid; grid-template-columns: 38px 34px 1fr; grid-template-rows: auto auto;
  column-gap: 12px; align-items: center; padding: 13px 4px; cursor: pointer; }
.day + .day { border-top: 1px solid var(--cream-dark); }
.day:hover { background: var(--white); }
.day__flag { position: absolute; top: 10px; right: 2px; width: 6px; height: 6px; border-radius: 50%; background: var(--rose); }
.day__gut { grid-row: 1 / 3; text-align: center; line-height: 1.05; }
.day__wd { font-family: var(--font-hand); font-weight: 600; font-size: 12.5px; text-transform: capitalize; color: var(--ink-soft); }
.day__dm { font-family: var(--font-display); font-size: 18px; color: #000; }
.day__i { grid-row: 1 / 3; width: 34px; height: 34px; }
.day__i svg { width: 100%; height: 100%; display: block; }
.day__desc { display: flex; align-items: baseline; gap: 8px; min-width: 0; font-size: 12.5px; color: var(--ink-mid); }
.day__desc .nm { color: var(--ink); font-weight: 500; }
.day__rain { font-size: 10.5px; color: var(--acqua-ink); white-space: nowrap; }

/* Skeleton nella forma del registro */
.day-skel { display: flex; align-items: center; gap: 12px; padding: 13px 4px; }
.day-skel + .day-skel { border-top: 1px solid var(--cream-dark); }
.day-skel__ic { width: 34px; height: 34px; border-radius: 50%; flex: none; }
.day-skel__m { flex: 1; }
</style>
```

- [ ] **Step 2: Build**

Run: `npm run build`
Expected: exit 0, nessun warning nuovo.

- [ ] **Step 3: Verifica di lettura**

- `grep -n "meteo-overlay\|meteo-dettaglio\|meteo-hero\|meteo-giorni-grid\|ora-box\|Teleport\|statisticheDettaglio" src/views/MeteoView.vue` → **nessun risultato** (tutta la vecchia modale + griglia rimossa).
- `grep -n "FoglioLaterale\|MeteoGiorno\|excStyle\|rangeSettimana\|haAvviso" src/views/MeteoView.vue` → presenti.
- `grep -rn "MeteoView" src/router/index.js` → la route `/meteo` esiste ancora e punta a `MeteoView.vue` (non modificata).

- [ ] **Step 4: Commit**

```bash
git add src/views/MeteoView.vue
git commit -m "$(cat <<'EOF'
MeteoView: registro verticale stile Taccuino

Via la griglia di card identiche. Sezioni con .slabel (Oggi / Le
prossime ore / I prossimi giorni), apertura "Adesso" editoriale, nastro
orario, blocco avvisi .alert-meteo (copia di .alert-cura in rosa),
registro con una riga per giorno e barra escursione min–max sul range
dei 7 giorni. Il dettaglio del giorno è ora un FoglioLaterale con
MeteoGiorno, non più un overlay centrato.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01EFqaFDLxs8JxGFodn5eWg9
EOF
)"
```

---

## Note di verifica per il QA nel browser (dopo il merge)

- **Registro**: filetti tra le righe; gutter con numero in Fraunces nero e giorno in Caveat grigio; la barra escursione riempie di più i giorni caldi (slitta a destra) e di meno i freddi; pallino rosa sui giorni con avviso.
- **"Adesso"**: icona acquerello grande, temperatura in Fraunces, riga "descrizione · umidità · vento"; tap apre il foglio di oggi.
- **Foglio del giorno**: si apre da destra (desktop ≥640) / dal basso (mobile); titolo = giorno per esteso; condizione, barra escursione grande (gradiente acqua→oro, sempre piena), `.kv` con solo le statistiche disponibili, mini-grafico (sparkline oro + barrette acqua tenui) — presente anche per i giorni futuri (ore ora scaricate per tutti e 7). `Esc` / velo / × chiudono; con *riduci animazioni* niente slide.
- **"Le prossime ore"**: scroll orizzontale, ora corrente su sfondo `--gold-pale`.
- **Avvisi**: blocco `.alert-meteo` rosa quando ci sono condizioni avverse; assente altrimenti.
- **Errore API**: card centrata invariata. **Offline**: previsione dalla cache del service worker (stesso URL).
- **HomeView**: la striscia meteo compatta della Home è invariata (usa solo `giorni`/`carica`).
- **Loading**: 6 righe skeleton nella forma del registro, non la vecchia griglia.

## Fuori scope

- Sottotitolo con località/orario sotto "Meteo" (la spec lo dà "se disponibile"; non c'è un place-name in `settings`, solo lat/lon) — eventuale round successivo.
- "Temperatura percepita" nell'apertura "Adesso" (richiederebbe `apparent_temperature` nella fetch) — si mostrano umidità + vento, già disponibili.
- Migration RLS `specie`; Fase 3 dark mode (`.exc`/`.alert-meteo`/`.mg-chart` avranno bisogno degli override); Fase 4.
- Unificare `.kv` / `.alert-cura` come classi davvero condivise (oggi `.kv` è globale, `.alert-cura` è scoped in PiantaView e `.alert-meteo` ne è una copia) — pulizia a parte.

## Self-review

- **Copertura spec:** livello dati (`ore` per 7 giorni, `orarieOggi` computed) → Task 1 Step 1-5; `.exc*` globale → Task 1 Step 7; `MeteoGiorno.vue` (escursione grande + `.kv` + mini-grafico) → Task 2; riscrittura MeteoView (slabel, adesso, ribbon, alert-meteo, ledger, FoglioLaterale, skeleton) → Task 3. Rimozione overlay/griglia/`statisticheDettaglio` → Task 3 Step 1 + verifica Step 3.
- **Placeholder:** nessuno — ogni step ha il codice completo.
- **Coerenza tipi/nomi:** `giorno.ore` prodotto in Task 1 (`oreDelGiorno`), consumato in Task 2 (`chart`) e Task 3 (`orarieOggi` computed → `orarieDaAdesso`). `giorno.wd`/`.dm` prodotti in Task 1, usati in Task 3 (`.day__wd`/`.day__dm`). `.exc`/`.exc--lg` definiti in Task 1, usati in Task 2 (`exc--lg`, fill di default) e Task 3 (`.exc` + `:style="excStyle(g)"`). `excStyle` vive solo in MeteoView (range settimana); MeteoGiorno usa `.exc--lg .exc__fill { left:0; right:0 }` dal CSS globale, niente prop `range`. `stat` in MeteoGiorno replica l'ex `statisticheDettaglio`. `avvisi[].key` è `` `${g.data}-${a.testo}` `` (invariato da `useMeteo`), `haAvviso` fa `startsWith(` `${g.data}-` `)`.
- **Ordine:** Task 1 (dati + CSS) → Task 2 (componente, usa `ore`) → Task 3 (view, usa entrambi). Ogni task builda da solo (`MeteoGiorno` compila anche se non ancora referenziato).
