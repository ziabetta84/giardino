# Restyle "Taccuino" — Fase 1 — Esito

Branch `restyle-taccuino`. 14 task eseguiti con sviluppo subagent-driven
(implementer + review + fix-loop per task). `npm run build` verde a ogni
task e alla chiusura.

## Fatto

| # | Task | Commit(i) | Note |
|---|------|-----------|------|
| 1 | Font Fraunces/DM Sans/Caveat in `index.html` | `bfb3b98` | Playfair + Lora rimossi |
| 2 | Token `-bg`/`-ink` per dominio + `--carta-2` | `6cf3b3b`, `62f95b2` | fix: rimosso `--gold-ink` morto (`#8a6820`), tenuto il nuovo `#7a5a15` |
| 3 | Tipografia base + rimozione classi "AI" | `d1d6cbd` | `--font-display`=Fraunces, `--font-hand`=Caveat, `--font-serif` esce; via `.gradient-title`/shine/`.title-*`/`.text-light`; `.section-label` → `var(--font-display)` |
| 4 | Classi cornice (`.appbar`/`.bottomnav`/`.sidebar`) | `74dc583`, `8e7deb9` | fix: font come token, non letterali |
| 5 | Classi liste con filetti | `c9952e4` | `.slabel`/`.wxrow`/`.zdice`/`.tasklist`/`.destlist`/`.feedlist`/`.kv`/`.prose`/`.pill-mini` |
| 6 | Header foto scheda pianta + filigrana + utility Zorba | `70c200c` | `.phead-photo`/`.gtrack`…, `.specie`/`.specie-ghost`, `.is-zorba`, `.zorba-mini`, `@keyframes z-tail/z-blink/z-breath` |
| 7 | `ZorbaLogo` variante `mini` | `4df7cab` | prop `mini`; default (boot/hero) invariato |
| 8 | Asset hero + classe `.hero` | `b79a89e` | `src/assets/hero-giardino.jpg` (~86 KB, pubblico dominio), `.hero`/`.leaf*`/`@keyframes leaf-fall` |
| 9 | Modello attività: potatura fuori, calcio dentro | `22d0095` | `useCure.js` + `AttivitaView` + `AttivitaRiga`; tipi con urgenza = `['irrigazione','concimazione','calcio']` |
| 10 | `HomeView` al linguaggio Taccuino | `548e561` | hero acquerello + Zorba nero nell'angolo + foglie; meteo/`Zorba dice` come righe; `Da fare oggi` lista; `Il giardino` lista di destinazioni |
| 11 | `PiantaView` al linguaggio Taccuino | `7dccb19` | header foto + galleria a scorrimento con pallini; nome sovrapposto; alert cura unica card; concimi `.feedlist`; sezione **"La specie"** (ex "Coltivazione") con `descrizione` + filigrana Zorba; riga "Potatura" registrabile senza urgenza |
| 12 | Cornice in `App.vue` | `3fe6a89` | `SideNav.vue` (nuovo, sidebar desktop) sostituisce `NavBar.vue` (cancellato); `AppBar.vue` (nuovo, mobile); `BottomNav.vue` riscritto; Account fuori da `StatusBar.vue` |
| 13 | `PiantaRiga` allineamento token | `1560e2f` | inline → `<style scoped>`, colori da token, via `.title-serif`/`.text-light` |
| 14 | QA di chiusura | *(questo file)* | build verde; sweep statico pulito sui file ristilizzati |

## Verifica in browser — DA FARE (Rob)

Questa fase è stata eseguita in una sessione di background **senza browser**:
il giro visivo di Task 14 non è stato fatto. Prima della merge, provare
`npm run dev` e controllare:

- **Home** (mobile ~390px e desktop): hero con l'acquerello + velatura,
  Zorba nero animato in basso a destra, foglie in caduta; riga meteo e riga
  "Zorba dice"; "Da fare oggi" come lista con filetti (niente potatura);
  "Il giardino" come lista di destinazioni con conteggi.
- **Scheda pianta** con foto (1 e >1) e senza foto: header, galleria a
  scorrimento + pallini, nome/nome-botanico sovrapposti su velatura leggera;
  alert cura (una sola card, solo icona a sinistra); "Stato cure" con la
  riga Potatura registrabile ma senza urgenza; "Concimi consigliati" lista
  piatta; "La specie" con la filigrana di Zorba dietro il paragrafo;
  `LightboxFoto` apribile dal tap su una foto; "Elimina pianta" →
  `ModalConferma`.
- **Cornice**: desktop = sidebar sinistra con voce attiva evidenziata,
  niente bottom nav; mobile = appbar in alto (mini-Zorba animato + Account)
  + bottom nav in basso (icona attiva nel suo colore, gatto sempre nero).
- **Login** (non autenticato): nessuna cornice, solo il form.
- `prefers-reduced-motion: reduce`: foglie e Zorba fermi.
- Rotte non ancora ristilizzate (Meteo, Zone, Sottozone, Progetti, Concimi,
  Gallery, Account, Impostazioni, Agente, i form di modifica): **non
  rotte**, ma con i vecchi titoli in gradiente resi come testo normale —
  atteso, si sistemano in Fase 2.

## Note / minori rinviati (per la Fase 2 o un giro di rifinitura)

- `.wxrow__s` (Home meteo) non riporta "· Centinarola" come il mockup (né lo
  faceva il codice pre-restyle).
- `.stat` (chip hero) lampeggia " specie"/" zone" prima che lo store carichi
  (sub-secondo).
- `PiantaView`: `capitalizza()` + `.kv .v` neutro → le consociazioni
  favorevoli/sfavorevoli hanno perso l'accento verde/rosso del vecchio
  blocco "Coltivazione" (cosmetico).
- `PiantaView`: ref `caricandoFoto` ora inutilizzato (cancellabile).
- `PiantaView`: bottoni cura come `.care-act` scoped invece di `.pill-mini`
  (scelta deliberata: `.pill-mini` è `cursor:default`, decorativo).
- `App.vue` desktop: `.app-main` è left-aligned contro la sidebar, non
  centrato (il commento dice il contrario — da correggere il commento o
  aggiungere un container).
- `chiave` (chiave) usata come icona di "Impostazioni" nella sidebar (manca
  un glifo ingranaggio nello sprite).
- `AppBar` e banner "token GitHub mancante" entrambi `top:0` su mobile:
  possibile sovrapposizione quando il banner è visibile.

## Fuori Fase 1 (come da spec)

Dark mode (Fase 3, con interruttore in Impostazioni), le viste rimanenti
(Fase 2), la stagionalità dell'hero (Fase 4).
