// Data "da parete" a Roma: l'Edge Function gira in UTC, ma stagioni e mesi del
// giardino (e il conteggio mensile delle risposte) seguono il calendario italiano.
// toLocaleString con timeZone dà l'ora di Roma; ricostruita come Date, i suoi
// getMonth()/getDate() restituiscono i valori di Roma qualunque sia il fuso del runtime.
export function dataRoma(adesso = new Date()) {
  return new Date(adesso.toLocaleString('en-US', { timeZone: 'Europe/Rome' }))
}

const STAGIONI = { 12: 'inverno', 1: 'inverno', 2: 'inverno', 3: 'primavera', 4: 'primavera', 5: 'primavera',
  6: 'estate', 7: 'estate', 8: 'estate', 9: 'autunno', 10: 'autunno', 11: 'autunno' }

export function stagioneRoma(adesso = new Date()) {
  return STAGIONI[dataRoma(adesso).getMonth() + 1]
}

export function inizioMeseRoma(adesso = new Date()) {
  const d = dataRoma(adesso)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}
