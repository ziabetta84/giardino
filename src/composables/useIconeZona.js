// Slug delle icone selezionabili per zona/sottozona (EditZonaView, SottozoneView).
// Ogni slug corrisponde al <symbol id="i-zona-{slug}"> in IconDefs.vue ed e' il
// valore salvato in zone.icona / sottozone.icona. Nessuna label: il selettore
// mostra solo l'icona.
export const ICONE_ZONA = [
  // esistenti
  'albero', 'foglia', 'fiore', 'orto', 'prato', 'vaso', 'serra', 'laghetto', 'sentiero', 'terrazza', 'recinto',
  // natura
  'cactus', 'montagne', 'conifera', 'palma', 'tulipano', 'loto', 'pianta', 'ghianda', 'tronco', 'parco',
  'farfalla', 'insetto', 'uccello', 'orma', 'arancia', 'ciliegie', 'avocado', 'carota', 'peperone',
  // interni / stanze
  'divano', 'letto', 'vasca', 'scrivania', 'tappeto', 'pentola', 'scale', 'lego',
  // illuminazione
  'sole', 'sole-velato',
  // strutture
  'casa', 'fattoria', 'negozio', 'capannone', 'garage',
]
