// Le tappe del giro, nell'ordine del sentiero: la navigazione, i link
// «tappa precedente / prossima» e la direzione delle transizioni vengono da qui.
export const TAPPE = [
  { nome: 'giro', percorso: '/', etichetta: 'Il giro' },
  { nome: 'aiuole', percorso: '/aiuole/', etichetta: 'Le aiuole' },
  { nome: 'schede', percorso: '/schede/', etichetta: 'Le schede' },
  { nome: 'cure', percorso: '/cure/', etichetta: 'Le cure' },
  { nome: 'zorba', percorso: '/zorba/', etichetta: 'Zorba' },
  { nome: 'dati', percorso: '/dati/', etichetta: 'I tuoi dati' },
  { nome: 'domande', percorso: '/domande/', etichetta: 'Domande' },
]

export const indiceTappa = (nome) => TAPPE.findIndex((t) => t.nome === nome)

export const SITO = 'https://zorbaingiardino.app/scopri'

// L'app sta un livello sopra il minisito (/giardino/ o / a seconda del deploy).
export const APP = import.meta.env.BASE_URL.replace(/scopri\/$/, '')
export const REGISTRATI = `${APP}#/account?registrati`
export const PRIVACY = `${APP}#/privacy`
export const KOFI = import.meta.env.VITE_LINK_CONTRIBUTO || 'https://ko-fi.com/'
