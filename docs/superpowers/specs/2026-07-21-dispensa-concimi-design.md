# Design: dispensa concimi e suggerimento NPK per specie

## Contesto

Oggi `specie.json` gestisce la concimazione solo come cadenza temporale (`manutenzione.concimazione[stagione]`, es. "ogni 14 giorni"), senza indicare *quale* concime usare. L'utente vuole gestire una dispensa dei concimi che possiede (nome + NPK) e, per ciascuna specie, il fabbisogno NPK stagionale, così che la scheda Attività (e la scheda della singola pianta) possano consigliare automaticamente il concime più adatto tra quelli disponibili.

## Obiettivo

- Catalogo dei concimi posseduti (nome + rapporto NPK), gestibile da UI.
- Fabbisogno NPK per specie, per stagione (indipendente dalla cadenza di concimazione già esistente).
- Suggerimento automatico del concime più vicino per rapporto N:P:K, visibile nella scheda Attività (righe di concimazione) e nella scheda della singola pianta.

## Modello dati

**`public/data/concimi.json`** *(nuovo file)* — oggetto per id, come `progetti.json`:
```json
{
  "concime-1784500000000": { "nome": "Concime universale Blu", "npk": { "n": 10, "p": 10, "k": 10 } }
}
```
File iniziale: `{}`.

**`specie.json`** — nuovo campo `manutenzione.npk`, parallelo e indipendente da `manutenzione.concimazione` (non ne cambia il parsing esistente):
```json
"manutenzione": {
  "concimazione": { "primavera": "ogni 14 giorni", "estate": "...", "autunno": "...", "inverno": "..." },
  "npk": { "primavera": "10-5-5", "estate": null, "autunno": "5-10-15", "inverno": null }
}
```
`npk[stagione]` è una stringa `"N-P-K"` (es. `"10-5-5"`) o `null` — nessun fabbisogno specifico quella stagione, nessun suggerimento mostrato.

## Logica di suggerimento — `src/composables/useConcimi.js` (nuovo)

Confronto basato sul **rapporto** N:P:K normalizzato (proporzioni sommate a 1), non sui valori assoluti: un concime `5-10-5` e uno `10-20-10` sono equivalenti (stesso rapporto 1:2:1, diversa concentrazione). La concentrazione assoluta incide sul dosaggio, non sull'idoneità del concime.

```js
function parseNPK(testo) {
  if (!testo) return null
  const m = testo.match(/^(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)$/)
  if (!m) return null
  return { n: parseFloat(m[1]), p: parseFloat(m[2]), k: parseFloat(m[3]) }
}

function normalizza({ n, p, k }) {
  const somma = n + p + k
  if (somma === 0) return { n: 0, p: 0, k: 0 }
  return { n: n / somma, p: p / somma, k: k / somma }
}

function distanza(a, b) {
  const na = normalizza(a), nb = normalizza(b)
  return Math.sqrt((na.n - nb.n) ** 2 + (na.p - nb.p) ** 2 + (na.k - nb.k) ** 2)
}

const SOGLIA_DISTANZA = 0.15

export function concimeConsigliato(npkRichiestoTesto, concimi) {
  const richiesto = parseNPK(npkRichiestoTesto)
  if (!richiesto || !concimi || !Object.keys(concimi).length) return null

  let migliore = null
  for (const [id, c] of Object.entries(concimi)) {
    if (!c.npk) continue
    const d = distanza(richiesto, c.npk)
    if (!migliore || d < migliore.distanza) migliore = { id, ...c, distanza: d }
  }
  if (!migliore || migliore.distanza > SOGLIA_DISTANZA) return null
  return migliore
}
```

- Ritorna `null` se: la specie non ha fabbisogno per la stagione corrente, la dispensa è vuota, oppure il concime più vicino supera `SOGLIA_DISTANZA = 0.15` (nessun concime adatto in dispensa).
- La soglia 0.15 è restrittiva: accetta solo concimi ragionevolmente vicini al fabbisogno ideale, preferendo il silenzio a un consiglio mediocre.

## Interfaccia utente

**`ConcimiView.vue`** *(nuova, route `/concimi`)* — stesso pattern di `ProgettiView.vue`: lista di card (nome + badge NPK "10-10-10"), pulsante "＋ Aggiungi" che apre un modale (`Teleport` + overlay) con form (nome, tre input numerici N/P/K), salvataggio via `saveJSON('concimi.json', ...)`. `ModalConferma` per eliminare un concime. Voce aggiunta a `NavBar.vue` (non a `BottomNav.vue`, come già per Meteo/Progetti/Gallery).

**`EditPiantaView.vue`** — la griglia manutenzione esistente (righe irrigazione/concimazione/potatura × 4 stagioni) guadagna una quarta riga "NPK", con un input testo per stagione (`placeholder="N-P-K"`), salvata in `manutenzione.npk`.

**`AttivitaRiga.vue`** — quando `item.tipo === 'concimazione'` e `item.suggerimento` è presente, una riga extra sotto la label:
```html
<div v-if="item.tipo === 'concimazione' && item.suggerimento" style="font-size:11px;color:var(--sage-dark);margin-top:2px;">
  🌱 Consigliato: {{ item.suggerimento.nome }} ({{ item.suggerimento.npk.n }}-{{ item.suggerimento.npk.p }}-{{ item.suggerimento.npk.k }})
</div>
```
`item.suggerimento` viene calcolato in `AttivitaView.vue` dove già si costruisce la lista `items`, chiamando `concimeConsigliato(specie.manutenzione?.npk?.[stagione()], store.concimi)`. Se `null`, nessuna riga extra (lista compatta, niente "nessun concime adatto" qui).

**`PiantaView.vue`** — nella riga `concimazione` della sezione "Stato cure" (righe 60-72 attuali), stessa logica: se c'è un suggerimento per la stagione corrente, una riga in più sotto la label esistente, stesso stile. Se il fabbisogno esiste ma nessun concime supera la soglia, qui (a differenza della lista Attività) si mostra esplicitamente "Nessun concime adatto in dispensa" — c'è più spazio per un messaggio esplicito nella scheda della singola pianta.

## Store e caricamento dati

`src/stores/dati.js` — aggiunge `concimi` ai dati caricati in `caricaTutto()`, in parallelo agli altri file JSON già caricati (`piante`, `specie`, `zone`, `sottozone`, `progetti`, `settings`).

## Verifica

Nessun framework di test nel progetto: verifica manuale con `npm run dev`.

- Aggiungere 2-3 concimi in `/concimi`, modificarne uno, eliminarne uno.
- Aggiungere `manutenzione.npk` a una specie esistente (es. l'Agave, con fabbisogno tipo "5-10-10") e verificare che il suggerimento compaia in `/attivita` (riga concimazione, se urgente/in scadenza) e in `/piante/:id`.
- Verificare che con dispensa vuota, o specie senza `npk` per la stagione corrente, non compaia nulla.
- Verificare il caso "nessun concime adatto" con un fabbisogno estremo (es. "20-0-0") e un solo concime molto lontano (es. "0-0-20") in dispensa — atteso: nessun suggerimento in `/attivita`, messaggio esplicito in `/piante/:id`.
