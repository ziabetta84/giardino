// Mappe icone/etichette per cure ed esigenze, condivise da PiantaView,
// AttivitaRiga/DossierPianta e SelettoreSpecie (prima duplicate in 3 file).
export const ICONE_CURA = { irrigazione: 'goccia', concimazione: 'concimazione', potatura: 'potatura', calcio: 'uovo' }
export const LABEL_CURA = { irrigazione: 'Irrigazione', concimazione: 'Concimazione', potatura: 'Potatura', calcio: 'Calcio' }
export function iconaCura(tipo) { return ICONE_CURA[tipo] ?? 'foglia' }

export const ICONE_ESIGENZA = {
  sole: 'sole', luce: 'sole', esposizione: 'sole',
  terreno: 'foglia', suolo: 'foglia', substrato: 'foglia', ph: 'foglia',
  acqua: 'goccia', irrigazione: 'goccia', umidita: 'goccia', 'umidità': 'goccia',
  temperatura: 'caldo', clima: 'caldo', gelo: 'gelo',
  spazio: 'pin', distanza: 'pin', potatura: 'potatura', concimazione: 'concimazione',
}
export function iconaEsigenza(chiave) { return ICONE_ESIGENZA[String(chiave).toLowerCase()] ?? 'foglia' }
export function capitalizza(s) { s = String(s); return s.charAt(0).toUpperCase() + s.slice(1) }
