export function raggruppaPerZona(itemsOrdinati, piante) {
  const gruppi = new Map()
  for (const item of itemsOrdinati) {
    const p = piante[item.piantaId]
    const chiave = p.sottozona ? `${p.zona}|${p.sottozona}` : p.zona
    if (!gruppi.has(chiave)) {
      gruppi.set(chiave, { chiave, zona: p.zona, sottozona: p.sottozona, items: [] })
    }
    gruppi.get(chiave).items.push(item)
  }
  // Map preserva l'ordine di inserimento: poiché itemsOrdinati è già ordinato
  // per giorni crescenti, il primo item incontrato per ogni gruppo determina
  // anche l'ordine relativo tra i gruppi (equivalente a ordinare per il minimo).
  return [...gruppi.values()]
}
