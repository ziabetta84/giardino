// Lettore di eventi SSE da un fetch in streaming (EventSource non permette POST né l'header Authorization).
export function creaLettoreSSE(onEvento) {
  let buffer = ''
  return (pezzo) => {
    buffer += pezzo
    let fine
    while ((fine = buffer.indexOf('\n\n')) !== -1) {
      const blocco = buffer.slice(0, fine)
      buffer = buffer.slice(fine + 2)
      let nome = null, dati = null
      for (const riga of blocco.split('\n')) {
        if (riga.startsWith('event: ')) nome = riga.slice(7)
        else if (riga.startsWith('data: ')) dati = riga.slice(6)
      }
      if (!nome || dati == null) continue
      try { onEvento(nome, JSON.parse(dati)) } catch { /* evento malformato: ignorato */ }
    }
  }
}
