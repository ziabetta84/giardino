// Le tappe del giro, nell'ordine del sentiero: la navigazione, i link
// «tappa precedente / prossima» e la direzione delle transizioni vengono da qui.
export const TAPPE = [
  { nome: 'giro', percorso: '/', etichetta: 'Il giro', icona: 'zona-parco', colore: 'sage' },
  { nome: 'aiuole', percorso: '/aiuole/', etichetta: 'Le aiuole', icona: 'zona-tulipano', colore: 'rose' },
  { nome: 'schede', percorso: '/schede/', etichetta: 'Le schede', icona: 'foglia', colore: 'olive' },
  { nome: 'cure', percorso: '/cure/', etichetta: 'Le cure', icona: 'goccia', colore: 'acqua' },
  { nome: 'zorba', percorso: '/zorba/', etichetta: 'Zorba', icona: 'erba-gatta', colore: 'gold' },
  { nome: 'dati', percorso: '/dati/', etichetta: 'I tuoi dati', icona: 'chiave', colore: 'uovo' },
  { nome: 'domande', percorso: '/domande/', etichetta: 'Domande', icona: 'lampadina', colore: 'sage' },
]

export const tappa = (nome) => TAPPE.find((t) => t.nome === nome) || TAPPE[0]

export const indiceTappa = (nome) => TAPPE.findIndex((t) => t.nome === nome)

export const SITO = 'https://zorbaingiardino.app/scopri'

// L'app sta un livello sopra il minisito (/giardino/ o / a seconda del deploy).
export const APP = import.meta.env.BASE_URL.replace(/scopri\/$/, '')
export const REGISTRATI = `${APP}#/account?registrati`
export const PRIVACY = `${APP}#/privacy`
export const KOFI = import.meta.env.VITE_LINK_CONTRIBUTO || 'https://ko-fi.com/'
