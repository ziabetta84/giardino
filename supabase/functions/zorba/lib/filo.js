import { dataRoma, stagioneRoma } from '../condivisi/date.js'

// Il filo per Claude è sempre e solo in aggiunta: messaggi dell'utente (foto prima del testo) e risposte finali di
// Zorba come testo semplice. Mai blocchi di ragionamento o di strumenti dei turni passati: così la cronologia non
// cambia tra una chiamata e l'altra (cache) e non tocca il controllo del ragionamento preservato. Le risposte non
// riuscite (errore, in corso) non entrano.
export function messaggiDalFilo(storia) {
  const out = []
  for (const m of storia) {
    if (m.ruolo === 'utente') {
      const content = []
      if (m.fotoBase64) content.push({ type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: m.fotoBase64 } })
      content.push({ type: 'text', text: m.testo || '(solo foto, nessun testo)' })
      out.push({ role: 'user', content })
    } else if (m.esito === 'completata' && m.testo) {
      out.push({ role: 'assistant', content: m.testo })
    }
  }
  return out
}

const MESI = ['gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre']

// Normalizza stringhe interpolate nel contesto di sistema per prevenire iniezioni di newline
function normalizza(s) {
  return String(s || '').replace(/\s+/g, ' ').trim()
}

// Contesto della richiesta corrente, come messaggio di sistema in coda: cambia a ogni richiesta, quindi resta fuori
// dal prompt di sistema in cache; ha autorità di operatore e l'utente non può imitarlo scrivendo nel testo.
export function contestoSistema({ adesso = new Date(), tipo, nomeVoce, voce, progetto, titoloProgetto, plantnet }) {
  const d = dataRoma(adesso)
  const righe = [
    `Oggi è il ${d.getDate()} ${MESI[d.getMonth()]} ${d.getFullYear()} (${stagioneRoma(adesso)}).`,
    `Tipo della richiesta: ${tipo}. Segui la procedura «${tipo}» delle tue regole.`,
  ]
  if (voce) righe.push(`Voce del catalogo segnalata: ${normalizza(nomeVoce)} (chiave ${voce}).`)
  if (progetto) righe.push(`Progetto del filo: ${normalizza(progetto.titolo)} (id ${progetto.id}). Le tappe vanno in questo progetto.`)
  else if (titoloProgetto) righe.push(`Progetto nuovo da creare con salva_piano, titolo: «${normalizza(titoloProgetto)}».`)
  if (plantnet) righe.push(`Riscontro automatico sulla foto (non nominarne mai la fonte): ${normalizza(plantnet)}`)
  return righe.join('\n')
}

// Con il ripiego del modello, i blocchi prima dell'ultimo `fallback` sono del modello che ha rifiutato: si scartano.
export function testoFinale(content) {
  let inizio = 0
  content.forEach((b, i) => { if (b.type === 'fallback') inizio = i + 1 })
  return content.slice(inizio).filter(b => b.type === 'text').map(b => b.text).join('').trim()
}

export const MESSAGGI_ERRORE = {
  richiesta_non_valida: 'Qualcosa non torna nella richiesta: ricarica la pagina e riprova.',
  testo_mancante: 'Scrivi qualcosa per Zorba.',
  testo_troppo_lungo: 'Il messaggio è troppo lungo: stai sotto i 4.000 caratteri.',
  foto_mancante: 'Per identificare una pianta serve una foto.',
  foto_non_valida: 'La foto non è in un formato leggibile: riprova a sceglierla.',
  foto_troppo_grande: 'La foto è troppo pesante anche dopo il ridimensionamento.',
  progetto_non_trovato: 'Quel progetto non esiste più.',
  voce_non_trovata: 'Quella pianta non è nel catalogo.',
  filo_inesistente: 'Questa conversazione non esiste più.',
  filo_chiuso: 'Questo filo è concluso: apri una nuova richiesta per continuare.',
  in_elaborazione: 'Zorba sta già rispondendo in questo filo.',
  riprova_prima: 'L\'ultima risposta non è riuscita: usa Riprova prima di scrivere ancora.',
  niente_da_ritentare: 'Non c\'è nessuna risposta da ritentare.',
  abbonamento_richiesto: 'Hai usato le risposte di prova: Zorba è riservato agli abbonati.',
  tetto_mese: 'Hai usato tutte le risposte di questo mese.',
  in_pausa_mese: 'Zorba è in pausa per questo mese.',
  in_pausa: 'Zorba è in pausa in questo momento.',
  claude_non_disponibile: 'Zorba non riesce a rispondere adesso: riprova tra poco.',
  rifiuto: 'Su questa richiesta Zorba non può aiutarti. Prova a riformularla.',
  troppo_lunga: 'La risposta è venuta troppo lunga: riprova.',
  tempo_scaduto: 'Zorba ci ha messo troppo: riprova.',
  interno: 'Qualcosa è andato storto: riprova tra poco.',
}
