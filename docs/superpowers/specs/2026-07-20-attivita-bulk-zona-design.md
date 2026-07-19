# Design: azione bulk per zona nella vista Attività

## Contesto

`AttivitaView.vue` mostra due liste piatte di cure pendenti (irrigazione, concimazione, potatura): "Da fare" (urgenti) e "In scadenza" (entro 3 giorni). Ogni riga ha un pulsante "✓ Fatto" che registra la cura per la singola pianta. Con molte piante nella stessa zona, marcare le cure una per una è ripetitivo: manca un modo per compiere l'azione su tutta una zona in un colpo solo.

## Obiettivo

Raggruppare le attività per zona (e sottozona, quando presente) all'interno di entrambe le sezioni, con un pulsante bulk per gruppo che registra tutte le cure del gruppo in un'unica operazione.

## Componenti

- **`AttivitaRiga.vue`** *(nuovo)* — singola riga pianta+cura (icona, nome specie, label, pulsante "✓ Fatto" individuale). Props: `item`, `variante` (`urgente` | `scadenza`, per lo stile rosa vs neutro), `salvando` (id in corso di salvataggio). Emette `registra`.
- **`AttivitaGruppoZona.vue`** *(nuovo)* — intestazione zona (es. `"Casa – Soggiorno (2)"`), pulsante "✓ Segna tutto fatto", lista di `AttivitaRiga` al suo interno. Props: `gruppo`, `variante`, `salvandoGruppo`. Emette `registraGruppo`.
- **`AttivitaView.vue`** *(modificato)* — orchestratore: calcola `attivita` (lista piatta, come oggi) e i nuovi computed `gruppiDaFare` / `gruppiInScadenza` che raggruppano per zona+sottozona; gestisce `registra(item)` (esistente) e il nuovo `registraGruppo(gruppo)`.

Nessuna nuova dipendenza, nessun composable aggiuntivo: la logica di raggruppamento resta un computed in `AttivitaView.vue`.

## Logica di raggruppamento

Chiave di gruppo: `zona` da sola se la pianta non ha `sottozona`, altrimenti `"${zona}|${sottozona}"`. Piante in "Casa" senza sottozona finiscono in un gruppo "Casa" separato da "Casa – Soggiorno".

```js
function raggruppaPerZona(items, piante) {
  const gruppi = new Map()
  for (const item of items) {
    const p = piante[item.piantaId]
    const chiave = p.sottozona ? `${p.zona}|${p.sottozona}` : p.zona
    if (!gruppi.has(chiave)) {
      gruppi.set(chiave, { chiave, zona: p.zona, sottozona: p.sottozona, items: [] })
    }
    gruppi.get(chiave).items.push(item)
  }
  return [...gruppi.values()]
}
```

Ordinamento gruppi: per `Math.min(...items.map(i => i.giorni))` crescente (il gruppo con l'attività più urgente/vicina prima) — stesso criterio già usato per le singole righe. Dentro il gruppo, le righe restano ordinate per `giorni` come oggi.

Applicato a entrambe le sezioni: "Da fare" (items `urgente`) e "In scadenza" (items non urgenti, `giorni <= 3`).

## Azione bulk e salvataggio

`registraGruppo(gruppo)` applica la stessa logica di `registra()` ma a tutti gli item del gruppo in un'unica scrittura: costruisce un solo oggetto `piante` aggiornato (data odierna per ogni `piantaId`+`tipo` del gruppo) e fa **una singola chiamata `saveJSON`** — un solo commit invece di N commit separati.

```js
async function registraGruppo(gruppo) {
  if (salvandoGruppo.value) return
  salvandoGruppo.value = gruppo.chiave
  try {
    const nuove = { ...store.piante }
    const oggi = new Date().toISOString().split('T')[0]
    for (const item of gruppo.items) {
      nuove[item.piantaId] = {
        ...nuove[item.piantaId],
        ultima_cura: { ...nuove[item.piantaId].ultima_cura, [item.tipo]: oggi }
      }
    }
    await saveJSON('piante.json', nuove)
    store.piante = nuove
  } finally {
    salvandoGruppo.value = null
  }
}
```

**Stato di caricamento**: il pulsante del gruppo mostra ⏳ e si disabilita durante il salvataggio; i pulsanti individuali delle righe dentro quel gruppo si disabilitano anch'essi (evita doppio click concorrente sullo stesso dato). I pulsanti di altri gruppi restano attivi.

**Errori**: se `saveJSON` fallisce (token scaduto, rete assente), nessuna modifica locale viene applicata — comportamento identico a oggi per il singolo "Fatto", nessun error handling nuovo da aggiungere.

## Dettagli UI e casi limite

- **Gruppi con 1 sola attività**: mostrati comunque con intestazione e pulsante bulk, per coerenza visiva (niente casi speciali nel markup).
- **Stile**: intestazione di gruppo con font più piccolo dell'header di sezione ("⚠ Da fare"/"🕐 In scadenza"), per mantenere la gerarchia Sezione → Zona → Riga. Card della zona con bordo/sfondo coerente con la variante (rosa per "Da fare", neutro per "In scadenza"), stesso trattamento colore già usato oggi sulle righe.
- **Contatore**: intestazione mostra `"Vialetto (3)"` — numero di attività nel gruppo.
- **Skeleton di caricamento iniziale**: invariato (già generico, non riflette il raggruppamento).
- **Stato "Tutto ok"**: invariato.

## Verifica

Nessun framework di test nel progetto: verifica manuale con `npm run dev`.

- Caricare `/attivita` con dati reali e controllare che i gruppi per zona+sottozona si formino correttamente, ordinati per urgenza.
- Verificare che il pulsante bulk di un gruppo aggiorni tutte le sue righe (spariscono dalla lista) e lasci intatti gli altri gruppi.
- Verificare che durante il salvataggio bulk i pulsanti individuali del gruppo si disabilitino, e che gli altri gruppi restino cliccabili.
- Controllare visivamente entrambe le sezioni (rosa/neutro) e un caso con gruppo da 1 sola attività.
- Controllare un caso "Casa" con più sottozone (es. Soggiorno con l'Agave + un'altra sottozona) per confermare la separazione dei gruppi.
