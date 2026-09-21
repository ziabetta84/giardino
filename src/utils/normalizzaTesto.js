// Alcuni nomi (cultivar in specie/piante, es. "Hebe 'Great Orme'") in DB
// usano l'apostrofo dritto, ma tastiere con punteggiatura intelligente
// (iOS/Safari) o testo incollato da fonti esterne possono produrre apici o
// virgolette tipografiche: senza normalizzazione un confronto .includes()
// fallisce sull'intera sottostringa che li attraversa, non solo sul
// carattere diverso.
export function normalizzaApici(str) {
  return str.replace(/[‘’‛′]/g, "'").replace(/[“”″]/g, '"')
}
