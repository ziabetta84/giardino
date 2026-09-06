// Slug delle icone selezionabili per zona/sottozona (ZoneView, SottozoneView).
// Ogni slug corrisponde al <symbol id="i-zona-{slug}"> in IconDefs.vue ed e' il
// valore salvato in zone.icona / sottozone.icona. Nessuna label: il selettore
// mostra solo l'icona.
//
// ICONE_ZONA_GRUPPI raggruppa le stesse icone sotto un'etichetta visibile nel
// selettore (prima erano solo commenti, mai arrivati in UI): una griglia
// piatta di 45 icone forza a scorrere tutto per riconoscere quella giusta,
// mentre un titolo di categoria restringe subito la ricerca visiva.
export const ICONE_ZONA_GRUPPI = [
  { label: 'Giardino', icone: ['albero', 'foglia', 'fiore', 'orto', 'prato', 'vaso', 'serra', 'laghetto', 'sentiero', 'terrazza', 'recinto'] },
  { label: 'Natura', icone: ['cactus', 'montagne', 'conifera', 'palma', 'tulipano', 'loto', 'pianta', 'ghianda', 'tronco', 'parco', 'farfalla', 'insetto', 'uccello', 'orma', 'arancia', 'ciliegie', 'avocado', 'carota', 'peperone'] },
  { label: 'Interni', icone: ['divano', 'letto', 'vasca', 'scrivania', 'tappeto', 'pentola', 'scale', 'lego'] },
  { label: 'Luce', icone: ['sole', 'sole-velato'] },
  { label: 'Strutture', icone: ['casa', 'fattoria', 'negozio', 'capannone', 'garage'] },
]

export const ICONE_ZONA = ICONE_ZONA_GRUPPI.flatMap(g => g.icone)
