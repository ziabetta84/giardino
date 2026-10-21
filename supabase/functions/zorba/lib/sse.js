const codifica = new TextEncoder()

export function formattaEvento(nome, dati) {
  return `event: ${nome}\ndata: ${JSON.stringify(dati)}\n\n`
}

// Se l'utente chiude l'app, enqueue lancia: da lì in poi gli eventi si scartano, ma il lavoro continua
// (EdgeRuntime.waitUntil) e la risposta viene salvata lo stesso.
export function creaEmettitore(controller) {
  const e = {
    connesso: true,
    emetti(nome, dati) {
      if (!e.connesso) return
      try { controller.enqueue(codifica.encode(formattaEvento(nome, dati))) } catch { e.connesso = false }
    },
    chiudi() {
      if (!e.connesso) return
      e.connesso = false
      try { controller.close() } catch { /* già chiuso dal client */ }
    },
  }
  return e
}
