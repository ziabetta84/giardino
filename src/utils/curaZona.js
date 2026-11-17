// Cura applicata a un'intera zona o sottozona (Attività → «Per zona»).
// Decide, pianta per pianta, se la cura va registrata: spuntata, da spuntare a
// mano o esclusa. Funzione pura (niente store né Supabase), provata con
// node --test 'src/utils/*.test.mjs'.
//
// Criteri (approvati da Roberta il 17/11/2026):
// - «Da fare»: scaduta, mai registrata o in scadenza entro 3 giorni. Spuntata.
// - «Possono riceverla»: la cadenza c'è ma non è ancora arrivata. Spuntata solo
//   se è passata almeno metà dell'intervallo, così irrigare un'aiuola intera non
//   spinge a registrare (e a ripetere) acqua su chi ne ha avuta da poco.
//   Qui finiscono anche le piante senza cadenza nella scheda, mai spuntate.
// - «Escluse»: la cura non vale per la pianta (in riposo in questa stagione,
//   coltivata in acqua per l'irrigazione, irrigazione automatica, calcio non
//   previsto dalla scheda). Non si possono spuntare.
// - Concimazione con un concime scelto: le piante il cui fabbisogno NPK della
//   stagione è lontano da quel concime (stessa soglia dei consigli) restano
//   nel loro gruppo ma senza spunta, con il concime consigliato.
// La pioggia prevista non cambia la scelta: l'avviso è nel foglio.

import { valutaCura, tipiCuraPianta, stagione } from '../../supabase/functions/zorba/condivisi/cure.js'
import { concimeConsigliato, classificaConcimiPerFabbisogno, formattaNPK, SOGLIA_DISTANZA } from '../../supabase/functions/zorba/condivisi/concimi.js'
import { programmaIrrigazioneEffettivo } from '../composables/useIrrigazioneAuto.js'
import { varietaNelTitolo } from './catalogo.js'

export const GIORNI_IN_SCADENZA = 3

export function pianteDellaZona(piante, zona, sottozona = null) {
  return Object.entries(piante ?? {}).filter(([, p]) =>
    p.zona === zona && (!sottozona || p.sottozona === sottozona)
  )
}

// true/false se il concime è adatto al fabbisogno, null se non si può dire
// (fabbisogno non indicato nella scheda o NPK del concime incompleto).
export function concimeAdatto(npkRichiesto, concime) {
  const npk = concime?.npk
  if (!npkRichiesto || !npk || [npk.n, npk.p, npk.k].some(v => v == null)) return null
  const [voce] = classificaConcimiPerFabbisogno(npkRichiesto, { scelto: concime })
  if (!voce || !Number.isFinite(voce.distanza)) return null
  return voce.distanza <= SOGLIA_DISTANZA
}

function valutaPianta({ id, p, sp, tipo, programmi, stagioneCorrente, concime, concimi }) {
  if (!tipiCuraPianta(p, sp).includes(tipo)) {
    if (tipo === 'irrigazione' && p.coltivato_in === 'acqua') {
      return { gruppo: 'escluse', motivo: "Coltivata in acqua: si registra il ricambio dell'acqua" }
    }
    if (tipo === 'calcio') return { gruppo: 'escluse', motivo: 'La scheda non prevede apporti di calcio' }
    return { gruppo: 'escluse', motivo: 'Cura non prevista per questa pianta' }
  }

  if (tipo === 'irrigazione') {
    const programma = programmaIrrigazioneEffettivo(id, p.zona, p.sottozona, programmi)
    if (programma) return { gruppo: 'escluse', motivo: `Irrigazione automatica ogni ${programma.ogniGiorni} gg` }
  }

  const regola = sp?.manutenzione?.[tipo]?.[stagioneCorrente]
  if (regola === 'mai' || regola === 'non necessario') {
    return { gruppo: 'escluse', motivo: `Non prevista in ${stagioneCorrente}: la pianta è a riposo` }
  }

  // Senza meteo: la pioggia prevista è un avviso del foglio, non un'esclusione.
  const c = valutaCura(p, sp, tipo, {})
  let esito
  if (c.giorni === null) {
    esito = { gruppo: 'possono', spuntata: false, motivo: 'La scheda non indica una cadenza' }
  } else if (c.giorni === Infinity) {
    esito = { gruppo: 'daFare', spuntata: true, motivo: 'Mai registrata' }
  } else if (c.giorni <= 0) {
    esito = { gruppo: 'daFare', spuntata: true, motivo: c.giorni === 0 ? 'Scade oggi' : `Scaduta da ${-c.giorni} gg` }
  } else if (c.giorni <= GIORNI_IN_SCADENZA) {
    esito = { gruppo: 'daFare', spuntata: true, motivo: `In scadenza tra ${c.giorni} gg` }
  } else if (c.trascorsi * 2 >= c.intervallo) {
    esito = { gruppo: 'possono', spuntata: true, motivo: `Ultima ${c.trascorsi} gg fa, cadenza ${c.intervallo} gg` }
  } else {
    esito = { gruppo: 'possono', spuntata: false, motivo: `Troppo presto: ultima ${c.trascorsi} gg fa, cadenza ${c.intervallo} gg` }
  }

  if (tipo === 'concimazione' && concime) {
    const npk = sp?.manutenzione?.npk?.[stagioneCorrente]
    const adatto = concimeAdatto(npk, concime)
    if (adatto === false) {
      const consigliato = concimeConsigliato(npk, concimi)
      esito = {
        ...esito,
        spuntata: false,
        avviso: `Fabbisogno diverso (${npk}): ${consigliato ? `meglio ${consigliato.nome} (${formattaNPK(consigliato.npk)})` : 'nessun concime adatto tra i tuoi'}`,
      }
    } else if (adatto === null && npk == null) {
      esito = { ...esito, avviso: 'Fabbisogno NPK non indicato nella scheda' }
    }
  }
  return esito
}

// piante: store.piante; vocePianta/nomePianta: le funzioni dello store;
// concimeId: il concime scelto per la concimazione (facoltativo).
export function classificaCuraZona({
  piante, zona, sottozona = null, tipo, vocePianta, nomePianta,
  programmi = null, concimi = null, concimeId = null,
}) {
  const stagioneCorrente = stagione()
  const concime = concimeId ? concimi?.[concimeId] ?? null : null
  const gruppi = { daFare: [], possono: [], escluse: [] }
  for (const [id, p] of pianteDellaZona(piante, zona, sottozona)) {
    const sp = vocePianta(p)
    const esito = valutaPianta({ id, p, sp, tipo, programmi, stagioneCorrente, concime, concimi })
    gruppi[esito.gruppo].push({
      piantaId: id,
      nome: nomePianta(p),
      varieta: varietaNelTitolo(sp, p.varieta) || null,
      sottozona: p.sottozona ?? null,
      spuntata: esito.gruppo === 'escluse' ? false : esito.spuntata,
      motivo: esito.motivo,
      avviso: esito.avviso ?? null,
    })
  }
  const perNome = (a, b) => a.nome.localeCompare(b.nome, 'it')
  for (const lista of Object.values(gruppi)) lista.sort(perNome)
  return gruppi
}
