// Prezzi di listino in USD per milione di token (ottobre 2026). La cache si scrive a 1,25× l'input (durata 5 minuti).
export const PREZZI = {
  'claude-opus-5-5': { input: 4, output: 20, cacheLettura: 0.2 },
  'claude-sonnet-5-5': { input: 2, output: 10, cacheLettura: 0.2 },
}
// Un modello di ripiego che non conosciamo si conta al prezzo più alto in listino: meglio sovrastimare la spesa.
const PREZZO_IGNOTO = { input: 10, output: 50, cacheLettura: 1 }

function costoUso(modello, u) {
  const p = PREZZI[modello] ?? PREZZO_IGNOTO
  return ((u.input_tokens ?? 0) * p.input + (u.output_tokens ?? 0) * p.output
    + (u.cache_read_input_tokens ?? 0) * p.cacheLettura + (u.cache_creation_input_tokens ?? 0) * p.input * 1.25) / 1e6
}

// Somma le chiamate di una risposta (una per passaggio del ciclo). Con il ripiego, usage.iterations elenca i modelli
// che hanno lavorato davvero: si conta ciascuno al suo prezzo. modello = quello dell'ultima iterazione utile.
export function costoRisposte(risposte) {
  const tot = { costo: 0, input: 0, output: 0, cacheLettura: 0, cacheScrittura: 0, modello: null }
  for (const r of risposte) {
    const parti = Array.isArray(r.usage?.iterations) && r.usage.iterations.length ? r.usage.iterations : [r.usage ?? {}]
    for (const u of parti) {
      const modello = u.model ?? r.model
      tot.costo += costoUso(modello, u)
      tot.input += u.input_tokens ?? 0
      tot.output += u.output_tokens ?? 0
      tot.cacheLettura += u.cache_read_input_tokens ?? 0
      tot.cacheScrittura += u.cache_creation_input_tokens ?? 0
      tot.modello = modello
    }
  }
  tot.costo = Math.round(tot.costo * 1e5) / 1e5
  return tot
}
