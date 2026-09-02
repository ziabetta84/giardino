# Restyle UI/UX — direzione "Taccuino" — Design

**Contesto:** nato da una richiesta diretta in sessione ("rendere l'UI più
accattivante"), non da una issue. Dopo aver scartato due direzioni troppo
"asciutte/editoriali", la direzione scelta è **"Taccuino"**: calda, a colori,
da diario di giardino. La fase esplorativa è stata condotta su un mockup
Artifact iterato ~11 volte; il mockup è la **fonte visiva di verità** per
Home e Scheda pianta ed è versionato in
`docs/superpowers/specs/assets/2026-09-02-restyle-taccuino-mockup.html`
(link live: https://claude.ai/code/artifact/98a45f69-60ed-4e32-bcca-9ab0a7dca0b6).

Questa spec copre: il **design system** (token, tipografia, regole del
linguaggio, componenti globali), lo stato-obiettivo di **Home** e **Scheda
pianta** viste per viste, i **principi** per applicare lo stesso linguaggio
alle viste non ancora disegnate, e il **piano a fasi**. Il breakdown
granulare dei task è demandato a writing-plans.

## Fuori scope (per questa spec / da fare in fasi successive)

- **Viste non ancora disegnate nel mockup**: Zone, Sottozone, Progetti/Progetto,
  Concimi, Gallery, Meteo, Account, "Zorba dice" (Agente), Impostazioni,
  `EditPiantaView`, `EditZonaView`, `SelettoreSpecie`. Qui la spec dà solo
  principi e note; il target visivo preciso si definisce in Fase 2, con un
  mockup veloce per quelle non ovvie (Progetti, Gallery, nav desktop).
- **NavBar desktop → sidebar sinistra** (deciso, §6). Il target visivo
  preciso della sidebar si verifica in browser durante la Fase 1 (unico
  pezzo di layout desktop non visualizzato nel mockup).
- **Dark mode**: workstream a sé (oggi non esiste), con **interruttore
  esplicito** in Impostazioni (§3). L'impianto a token va predisposto in
  Fase 1; valori scuri, toggle e QA sono Fase 3.
- **Stagionalità dell'hero**: l'acquerello che cambia con la stagione
  (3–4 immagini o filtro CSS per mese) è un raffinamento successivo. Fase 1
  usa l'immagine "inizio autunno" scelta, fissa.
- **Boot splash / StatusBar / banner token**: restano funzionalmente com'è;
  si allineano a token e tipografia in Fase 2, senza redesign.
- Nessun cambio di **dati, store, routing, API**. È un intervento di sola
  presentazione: template + CSS. **Unica eccezione logica** (decisa in
  review, §9.1): la **potatura** esce dai feed "attività" e resta solo
  un'azione registrabile nella scheda pianta; il **calcio** entra nei feed.

## 1. La direzione "Taccuino"

Un diario di giardino: caldo, personale, illustrato, ma **ordinato**. Zorba —
gatto nero realmente esistito, sepolto nel giardino, a cui l'app è dedicata —
resta il cuore dell'identità.

Cosa **è**:
- Colore usato come **sistema**, non come decorazione: 5 tinte coordinate
  (acqua / olive / rose / sage / gold), una per dominio, portate soprattutto
  dalle **icone acquerellate**.
- **Liste con filetti sottili** come struttura di default; il border-radius
  vive quasi solo sulle **pill** (filtri, azioni brevi).
- Un **hero illustrato** (acquerello del giardino) con Zorba nero animato
  davanti.
- Tipografia con carattere: display **Fraunces**, una data **annotata a mano**
  (Caveat).

Cosa **non è**:
- Non è un dashboard di card arrotondate tutte uguali (era il difetto
  dell'app attuale e delle prime bozze).
- Non è "editoriale spoglio" a due inchiostri (direzione scartata).
- Non toglie colore: lo organizza.

## 2. Token colore

Base: la palette dell'app resta (`src/assets/main.css`), riorganizzata per
**ruoli**. Le 5 tinte-dominio riusano i valori esistenti `--rose/--sage/
--olive/--gold/--acqua` e i loro `-dark`. Vanno aggiunti, per ciascuna,
`-bg` (fondo-tinta per bande/chip) e `-ink` (testo AA sul fondo-tinta):

| Tinta  | base (esiste) | dark (esiste) | `-bg` (light)      | `-ink` (light)    |
|--------|---------------|---------------|--------------------|-------------------|
| acqua  | `#6f9fc0`     | `#4c7793`     | `#e2edf3` (=tile)  | `#2b566e`         |
| olive  | `#9aaa5a`     | `#6d7a3e`     | `#ececd8` (=tile)  | `#545e2a`         |
| rose   | `#cc6e6e`     | `#b85f5f`     | `#f6e3e1` (=tile)  | `#8a3f3a`         |
| sage   | `#7a9e82`     | `#5a7e62`     | `#e4ede4` (=tile)  | `#37543f`         |
| gold   | `#e0b84a`     | `#b8902a`     | `#f7ecd0` (=tile)  | `#7a5a15`         |

Mappatura dominio → tinta (coerente con `TINTE_CURA` in `PiantaView.vue`):
irrigazione = acqua, concimazione = olive, potatura = rose, calcio = sage;
zone = acqua (icone zona già "acquerellate blu"), piante = olive, progetti =
gold, concimi = sage, attività = rose, gallery = sage.

Neutri "carta" (leggermente caldi, già presenti come `--cream/--cream-dark/
--ink*`): confermati. Aggiungere `--carta-2` (off-white per bande di tono, se
servirà — nel mockup finale non è più usato ma resta utile).

**Dark mode**: **interruttore esplicito** nelle Impostazioni (deciso in
review — Rob non è amante del dark mode). Default **chiaro**; l'app **non**
segue automaticamente `prefers-color-scheme`. Il tema si applica via
`:root[data-theme="dark"]` (scelta salvata in `settings` o `localStorage`);
il blocco `@media (prefers-color-scheme: dark)` **non** si usa. In Fase 1 si
predispone solo la struttura a token (tutti i valori chiari definiti su
`:root`, i componenti leggono i token, mai letterali); i valori scuri e il
toggle sono Fase 3.

## 3. Tipografia

| Ruolo | Face | Uso |
|---|---|---|
| Display | **Fraunces** (var. opsz+wght, + italic) | titoli pagina, `.pname`, `.slabel` in alcune viste, nomi in liste "narrative" (specie in corsivo) |
| Body / UI | **DM Sans** (400/500/600/700) | tutto il resto |
| Annotazione | **Caveat** (500/600) | solo la data dell'hero Home, usata con parsimonia |

- Playfair Display esce (era il default "sa di AI"). Lora esce (Fraunces
  copre il ruolo serif con più carattere).
- Il `<link>` Google Fonts in `index.html` va aggiornato:
  `Fraunces:ital,opsz,wght@…` + `DM Sans:wght@400;500;600;700` +
  `Caveat:wght@500;600`. Rimuovere Playfair e Lora.
- Scala tipografica di riferimento (px): 27/24 (hero), 15/14 (titoli riga),
  13.5/13 (body), 12/11.5 (meta), 11/10.5 (label). Una sola rampa, niente
  dimensioni arbitrarie inline.
- Le classi globali `.title-display`, `.gradient-title`, `.title-serif`,
  `.text-light`, `.title-settle`, `.gradient-title.title-settle` (shine)
  **escono**: il titolo in gradiente + effetto shine è la firma più
  "generata" ed è rimossa.

## 4. Regole del linguaggio (da rispettare in ogni vista)

1. **Non tutto è una card.** Bordo, fondo, radius e ombra dicono "oggetto
   separato": spenderli per ruolo, non stamparli su ogni blocco. Default =
   riga in una lista con filetto (`border-top: 1px solid var(--linea)`).
2. **Card solo dove un oggetto va sollevato**: un alert cura, la riga-pianta
   con miniatura. Radius contenuto (12–18px), un'ombra soft, non su tutto.
3. **Border-radius 999px solo sulle pill** (filtri zona, azioni brevi tipo
   "Fatto"/"Registra", chip). Le pill sono accettate come vezzo, non
   moltiplicate.
4. **Il colore vive nelle icone.** Le icone acquerellate (`IconDefs.vue`,
   silhouette piena Phosphor + accento del pigmento clippato) portano la
   tinta del dominio; niente accenti di colore sparsi altrove.
5. **Sezioni** introdotte da una `.slabel` (etichetta) con spazio verticale
   generoso sopra; dentro la sezione lo spazio è compatto. Il ritmo lo dà
   l'alternanza spazio-fra / spazio-dentro, non i riquadri.
6. **Stili inline → classi.** Nessuna nuova regola in `style=""`. I
   componenti vivono in `main.css` (o `<style scoped>` quando davvero locali).
7. **Motion sobrio**: transizioni brevi, `@media (prefers-reduced-motion:
   reduce)` sempre rispettato. Le animazioni "shine" e stagger aggressivi
   escono; restano il fade di pagina, il wag/blink lento di Zorba, le foglie
   in caduta nell'hero (disattivate a reduced-motion).

## 5. Zorba

- **Sempre nero** (`#141414`/`#000`) in ogni raffigurazione: logo hero
  animato (`ZorbaLogo.vue`), icona `i-gatto`, mini-Zorba della barra. È
  l'**unica eccezione** alla palette. In dark mode, dove il nero sparirebbe,
  aggiungere un **alone chiaro** (`filter: drop-shadow(0 0 1px
  rgba(242,232,216,.9))`), **non** schiarire il gatto.
- **Unica eccezione consentita** (decisa da Rob): la **filigrana** dietro il
  paragrafo di "La specie" nella scheda pianta — silhouette (corpo + coda),
  colore tono-carta molto tenue (`opacity` sull'`<svg>` intero, non sui
  singoli path, per non vedere la cucitura sulla giuntura della coda),
  posizionata in basso nella sezione.
- **Mini-Zorba** nella barra in alto: le path body/tail/eye di `ZorbaLogo`
  in ~21px, animazione lenta (coda ~4.6s, blink ~6.2s), occhio verde
  `#7cc491` mantenuto. Va estratto come componente riusabile (`ZorbaMini.vue`
  o prop `size`/`variant` su `ZorbaLogo`).
- Il `#pattern` dorato del logo si mantiene nell'hero grande e nel boot; nel
  mini si può omettere (invisibile a 21px).

## 6. Cornice (chrome)

**Barra in alto** (`.appbar`): marchio "Il Giardino di Zorba" (Fraunces
12.5px) preceduto dal **mini-Zorba animato**; a destra la sola icona
**Account** = `i-persona` dell'app (non un'icona nuova). **Niente** link
all'agente in barra. Sticky, fondo carta translucido + blur, filetto sotto.
Sostituisce l'attuale `NavBar.vue` su mobile (dove oggi non c'è) e la
`StatusBar.vue` per l'accesso Account.

**Nav in basso** (`.bottomnav`, mobile <640px): Home / Zone / Piante /
Concimi / Attività / Zorba dice. Icona della voce **attiva** nel suo
**colore originale** (es. casa gold, foglia olive), etichetta in
`--inchiostro`; voci inattive **monocromatiche** tenui (`--faint`). Il gatto
di "Zorba dice" resta **nero** in entrambi gli stati. Ricalca `BottomNav.vue`
attuale, restilizzata.

**Desktop (≥640px)** — DECISO: **sidebar sinistra**.
`NavBar.vue` (barra orizzontale a scorrimento, 10 voci) è sostituita da una
**sidebar sinistra** fissa (~200px): mini-Zorba + marchio in alto, le voci
in colonna (Home / Meteo / Zone / Piante / Progetti / Concimi / Attività /
Zorba dice / Gallery), Impostazioni + Account in fondo; voce attiva
evidenziata (fondo tinta tenue del dominio + testo `--inchiostro`).
Il contenuto passa a colonna singola centrata (~720px). Su mobile (<640px)
niente sidebar: `.appbar` in alto + `.bottomnav` in basso come sopra.
`.appbar` su desktop può ridursi o sparire (marchio e Account sono nella
sidebar) — da rifinire in implementazione. Da verificare in browser durante
la Fase 1 (unico pezzo di layout desktop non ancora visualizzato in mockup).

## 7. Hero Home

- **Scena di sfondo**: l'acquerello del giardino scelto (pubblico dominio,
  publicdomainpictures.net). Asset ridotto a ~720px / ~86 KB già preparato
  in `docs/superpowers/specs/assets/2026-09-02-hero-giardino.jpg`; in Fase 1
  va spostato in `src/assets/` e referenziato via `background-image` (non
  data-URI). `background-size: cover; background-position: center 30%`.
- **Velatura**: `::after` con gradiente `--carta` da sinistra (leggibilità
  del testo) e dal basso (raccordo con la pagina). In dark, `filter:
  brightness(.5) saturate(.82)` sulla scena.
- **Zorba animato** (`ZorbaLogo`, ~106px) ancorato **in basso a destra**
  dell'hero, layer separato sopra la scena. Nero, con l'animazione lenta
  (wag/blink/"respiro").
- **Foglie in caduta**: 2–3 `i-foglia` (oliva / oro / rosa) che scendono
  lentamente, `@keyframes`, disattivate a reduced-motion.
- Testo: data (Caveat) · "Buongiorno, Rob" (Fraunces) · chip di stato
  ("74 specie", "4 zone", "3 da curare").

## 8. Componenti globali da introdurre (in `main.css`)

Ognuno sostituisce blocchi di stile inline oggi ripetuti. Markup di
riferimento: il mockup. Nome → scopo:

- `.appbar`, `.appbar__mark`, `.appbar__btn` — barra in alto.
- `.bottomnav`, `.bn-ic` (+ override monocromatico su `:not(.on)`) — nav in
  basso.
- `.slabel` — etichetta di sezione (uppercase tracked, `--faint`, con filetto
  di coda).
- `.wxrow` — riga meteo (Home): filetti sopra/sotto, icona meteo, temp,
  pioggia/vento, chevron.
- `.zdice` — riga "Zorba dice": icona gatto nera (`.is-zorba`), titolo +
  sottotitolo, chevron.
- `.tasklist` / `.task` (`.task__ic/__m/__n/__d`) — lista "Da fare oggi":
  righe con filetto, icona acquerellata col colore del tipo di cura, nome in
  Fraunces, nota, pill "Fatto". `.seeall` per "Vedi tutte le N →".
- `.destlist` / `.dest` (`.dest__ic/__n/__c/__chev`) — lista destinazioni
  "Il giardino": icona + nome + stato (`.dest__c.urg` in `--rose-ink`) +
  chevron.
- `.feedlist` / `.feed` (`.feed__rank[--dim]/__m/__n/__d/__tag/__npk`) —
  concimi consigliati: classifica (num. tabulare, 1 in `--sage-dark`),
  disponibilità (`.feed__tag` "terminato" in `--rose-ink`), NPK a destra.
- `.kv` — coppie chiave/valore (esigenze, dati specie): `.k` in `--faint`
  con icona opzionale, `.v` in `--seppia`.
- `.prose` — paragrafo discorsivo (descrizione specie): line-height ~1.62.
- `.pill` — azione breve / filtro (999px, outline).
- `.chip` — tag su fondo scuro (overlay foto): zona · sottozona.
- `.phead-photo` + `.gtrack/.gslide/.gimg` + `.phead-scrim` + `.pbtn[--back/
  --edit]` + `.phead-cap` (`.pname/.pbino/.tag-inline`) + `.gdots` — header
  foto della scheda pianta, con galleria a scorrimento orizzontale
  (scroll-snap) e pallini sincronizzati; caption **sovrapposta** in basso su
  velatura leggera, non testo bianco su foto scurita a blocco.
- `.specie` + `.specie-ghost` (`.sg`) — sezione "La specie" con la filigrana
  di Zorba (`isolation:isolate`, ghost `z-index:-1`, `opacity` sull'svg).
- `.is-zorba` — utility: forza nero + alone chiaro in dark, per ogni gatto.
- `.zorba-mini` (`.zm-body/.zm-tail/.zm-eye`) — cat piccolo animato.
- `.card` / `.hover-card` — **restano** ma ridimensionati: usati solo per
  `PiantaRiga` e per l'alert cura. Radius e ombra ridotti, niente
  `translateY` aggressivo.
- `.card-grid` / `.card-item*` della HomeView attuale — **rimosse**
  (sostituite da `.destlist`).

## 9. Viste — stato obiettivo

### 9.1 HomeView.vue (definita)

Dal mockup. Ordine: `appbar` · **hero** (scena acquerello + Zorba + foglie +
testo) · **meteo** (`.wxrow`) · **"Zorba dice"** (`.zdice`) · `slabel "Da
fare oggi"` + `.tasklist` (max 5 voci) + `.seeall` verso `/attivita` ·
`slabel "Il giardino"` + `.destlist` (Zone/Piante/Progetti/
Concimi/Attività/Gallery con conteggi) · `bottomnav`.
Rimosse: `ZorbaLogo` grande centrato nell'hero (Zorba si sposta nell'angolo),
i 4 puntini colorati, la griglia di 6 quadrati, il titolo in gradiente+shine.

**Modello attività (deciso in review).** Le "attività" con cadenza temporale
che compaiono nei feed ("Da fare oggi" in Home, `AttivitaView`) sono
**irrigazione, concimazione, calcio**. La **potatura** non ha cadenza: è
un'etichetta testuale, resta un'azione **registrabile** ("Fatto") nella
sezione "Stato cure" della scheda pianta (con la data dell'ultima), ma **non
entra mai** nel calcolo delle urgenze né nei feed. In pratica:
- `useCure.js`: la lista canonica dei tipi con urgenza diventa
  `['irrigazione','concimazione','calcio']`; `cureUrgentiPianta` /
  `valutaCura` non valutano più `potatura`.
- `HomeView.daFareOggi` e `AttivitaView`: iterano la nuova lista (oggi
  `HomeView.vue:149` fa `['irrigazione','concimazione','potatura']`).
- `PiantaView` "Stato cure": mostra irrigazione/concimazione + calcio se
  `specie.manutenzione.calcio`, **più** una riga "Potatura" sempre
  registrabile ma senza stato di urgenza (solo "ultima: N giorni fa").
- `PiantaRiga` (badge urgenza): usa la nuova lista.

### 9.2 PiantaView.vue (definita)

Dal mockup. `appbar` · **header foto** (`.phead-photo`): galleria a
scorrimento se >1 foto, pallini, pulsanti tondi indietro/Modifica sopra
l'immagine, **caption sovrapposta** in basso (chip "Zona · Sottozona",
`.pname` in Fraunces bianco, `.pbino` in corsivo + tag "in terra"); fallback
su immagine specie Wikimedia, poi su header testuale senza foto ·
**alert cura** (unica `.card`, tinta olive, radius, **solo icona a
sinistra** — via il watermark di sfondo) · `slabel "Stato cure"` + righe
(irrigazione/concimazione/potatura/calcio) con chip-icona colorato + stato +
pill "Fatto" · `slabel "Concimi consigliati"` + riga fabbisogno + `.feedlist`
(classifica, disponibilità, NPK) · `slabel "La specie"` (rinomina della
sezione **"Coltivazione"**, nome fuorviante) dentro `.specie`: `.prose` con
la **descrizione naturalizzata** (campo `specie.descrizione`) + filigrana
Zorba in basso + `.kv` coi dati botanici; per specie annuali/biennali la
stessa sezione assorbe semina/trapianto/raccolta/consociazioni (oggi in
`PiantaView.vue` "Coltivazione") · `slabel "Esigenze"` + `.kv` (sole/terreno/
acqua) · link "Elimina pianta" · `bottomnav`.
Note tecniche: il blocco "Alert specie" (`specie.alert`, note tecniche/
sicurezza) resta ma si allinea allo stile `.prose`/lista; le "Note personali"
(`pianta.note`) idem; la sezione Foto separata sotto sparisce (le foto sono
nell'header-galleria).

### 9.3 Altre viste — principi

Applicare §4 con queste note:

- **PianteView / PiantaRiga**: `PiantaRiga` resta una `.card` (oggetto
  sollevato: ha miniatura). Restyle a token; i filtri zona/sottozona già
  usano `.pill` — confermato. Sezione "Da curare" e "Tutte" come `slabel`.
- **ZoneView / SottozoneView**: liste di zone/sottozone come `.destlist`
  (icona zona acquerellata + nome + conteggio piante + chevron); il selettore
  icona (griglia `.pill-icona`) resta. Pulsante elimina come `.pill` ghost.
- **ProgettiView / ProgettoView**: lista progetti come righe con filetto +
  stato come `.pill`/badge; le tappe come `.tasklist`-simile con data. **Serve
  un mockup veloce** (la timeline tappe non è banale).
- **ConcimiView**: lista concimi come `.feedlist`/righe con NPK + stato
  disponibilità; form di aggiunta con `.form-input` (già esiste, allineare).
- **GalleryView**: griglia foto — **serve un mockup veloce**; probabilmente
  griglia serrata senza card, lightbox già ok (`LightboxFoto`).
- **MeteoView**: previsioni come righe/colonne con le icone meteo
  acquerellate; niente card per giorno.
- **AccountView / SettingsView**: form con `.form-input`, `.pill`/`.btn`
  allineati; niente card decorative.
- **AgenteView ("Zorba dice")**: la più complessa (608 righe). Restyle
  conservativo a token/tipografia; lo storico richieste come lista con
  filetti. Mockup consigliato.
- **EditPiantaView / EditZonaView / SelettoreSpecie**: form. Allineare
  `.form-input`, `.search-input`, `.pill`, `.btn*` (già classi globali) ai
  nuovi token; `SelettoreSpecie` (1033 righe) è un capitolo a sé, ultimo.
- **ModalConferma / LightboxFoto / MiniEditor / AttivitaRiga /
  AttivitaGruppoZona**: allineamento token, nessun redesign.

## 10. Piano a fasi

**Fase 1 — Fondamenta + due viste**
1. `main.css`: token colore completi (light + predisposizione dark), rampa
   tipografica, rimozione classi `gradient-title`/shine/`title-*`.
2. `index.html`: `<link>` font (Fraunces / DM Sans / Caveat; via Playfair,
   Lora).
3. Componenti globali di §8 in `main.css`.
4. `ZorbaLogo.vue`: variante `mini` (o `ZorbaMini.vue`); animazione idle
   lenta; regola `.is-zorba` (nero + alone dark).
5. Modello attività: `useCure.js` + `AttivitaView` + `AttivitaRiga` +
   `PiantaRiga` alla lista `['irrigazione','concimazione','calcio']` (§9.1).
6. Asset hero in `src/assets/`; `HomeView.vue` riscritta al target 9.1.
7. `PiantaView.vue` riscritta al target 9.2; rinomina "Coltivazione" → "La
   specie" con `specie.descrizione` integrata; riga potatura registrabile
   senza urgenza.
8. Cornice: `App.vue` + `BottomNav.vue` (mobile) + nuova **sidebar** desktop
   (sostituisce `NavBar.vue`) + `.appbar` + assorbimento accesso Account da
   `StatusBar.vue`.
9. `PiantaRiga.vue`: allineo token.
10. Verifica in browser: mobile (appbar + bottomnav) e desktop (sidebar),
    tema chiaro.

**Fase 2 — Viste rimanenti**
- Mockup veloci per: Progetti/Progetto, Gallery, eventualmente Agente.
- Restyle vista per vista in piccoli lotti seguendo §9.3.

**Fase 3 — Dark mode**
- Valori scuri sui token; **interruttore esplicito** in `SettingsView`
  (scelta salvata, default chiaro, niente auto da sistema); audit di ogni
  colore letterale rimasto inline; QA su ogni vista in scuro.

**Fase 4 — Raffinamenti**
- Stagionalità hero; boot/StatusBar; micro-interazioni.

Ogni fase su un branch dedicato; la merge su `main` (deploy automatico) la
decide Rob a fase pronta.

## 11. File toccati (Fase 1)

- `src/assets/main.css` (grosso: token + componenti)
- `index.html` (link font)
- `src/views/HomeView.vue` (riscrittura)
- `src/views/PiantaView.vue` (riscrittura)
- `src/components/ZorbaLogo.vue` (+ eventuale `ZorbaMini.vue`)
- `src/components/NavBar.vue`, `BottomNav.vue`, `StatusBar.vue`
- `src/components/PiantaRiga.vue` (allineo token — usato da PianteView)
- `src/assets/` (+ immagine hero)
- `src/App.vue` — la cornice (NavBar/BottomNav/StatusBar) è renderizzata qui
  attorno a `<RouterView>`: va adattata alla nuova `.appbar` + `.bottomnav`
  (nel mockup stanno dentro la schermata, nell'app restano in App.vue)
- `src/composables/useCure.js` — lista tipi con urgenza →
  `['irrigazione','concimazione','calcio']` (fuori `potatura`); vedi §9.1.
- `src/views/AttivitaView.vue`, `src/components/AttivitaRiga.vue` — nuova
  lista tipi; `PiantaRiga.vue` idem per il badge urgenza.

## 12. Decisioni prese (review 02/09/2026)

1. **Potatura**: fuori dai feed attività ovunque; resta azione registrabile
   nella scheda pianta senza urgenza. Nei feed: irrigazione, concimazione,
   **calcio**. (§9.1)
2. **Nav desktop**: **sidebar sinistra**. (§6)
3. **Dark mode**: **interruttore esplicito** in Impostazioni, default chiaro,
   nessun auto da `prefers-color-scheme`. (§3, Fase 3)
4. **Licenza immagine hero**: pubblico dominio; sostituibile in futuro con
   un'illustrazione propria/stagionale.

## 13. Verifica

- Ogni vista ritoccata: prova manuale in browser mobile **e** desktop.
- `prefers-reduced-motion`: nessuna animazione essenziale persa.
- Contrasto AA su testo/`-ink` sopra i `-bg`.
- Zorba nero ovunque (tranne la filigrana); leggibile in dark con alone.
- Nessuna regressione funzionale: dati, link, form si comportano come prima.
  Unica modifica di comportamento attesa: la potatura non compare più nei
  feed attività / urgenze (resta registrabile nella scheda pianta); il
  calcio compare nei feed. Verificare Home, `AttivitaView`, badge
  `PiantaRiga`, "Stato cure" della scheda pianta.
