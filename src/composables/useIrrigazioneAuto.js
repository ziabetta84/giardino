// Risoluzione della cascata giardino → zona → sottozona → pianta per
// l'irrigazione automatica: la pianta vince se ha un programma proprio,
// poi la sua sottozona (se ne ha una), poi la sua zona, poi il default
// dell'intero giardino. null quando nessun livello ha un programma — in
// quel caso l'irrigazione resta valutata da specie/stagione come prima di
// questa funzionalità (vedi useCure.js).
export function programmaIrrigazioneEffettivo(piantaId, zonaNome, sottozonaNome, programmi) {
  if (!programmi) return null
  if (programmi.piante?.[piantaId]) return { ...programmi.piante[piantaId], livello: 'pianta' }
  if (zonaNome && sottozonaNome && programmi.sottozone?.[`${zonaNome}|${sottozonaNome}`]) {
    return { ...programmi.sottozone[`${zonaNome}|${sottozonaNome}`], livello: 'sottozona' }
  }
  if (zonaNome && programmi.zone?.[zonaNome]) return { ...programmi.zone[zonaNome], livello: 'zona' }
  if (programmi.giardino) return { ...programmi.giardino, livello: 'giardino' }
  return null
}
