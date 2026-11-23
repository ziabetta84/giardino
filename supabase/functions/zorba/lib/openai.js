// Fornitori con API compatibile OpenAI (Chat Completions), per provare modelli open al posto di Claude. Il resto della
// funzione (ciclo, filo, costi) lavora nel formato di Anthropic: qui si traduce la richiesta all'andata e la risposta al
// ritorno, così il ciclo degli strumenti resta uno solo. Le funzioni solo di Anthropic (ragionamento adattivo, effort,
// cache, ripiego del modello) non hanno un equivalente e si tralasciano.

// Il modello si scrive «fornitore:nome» (per esempio ovh:qwen3.6-35b-a3b): il nome è quello del catalogo del fornitore.
export function separaModello(modello) {
  const i = String(modello).indexOf(':')
  return i < 0 ? { fornitore: 'anthropic', nome: modello } : { fornitore: modello.slice(0, i), nome: modello.slice(i + 1) }
}

function testoDi(content) {
  if (typeof content === 'string') return content
  return content.filter(b => b.type === 'text').map(b => b.text).join('')
}

// Messaggi Anthropic → messaggi OpenAI. Tutti i testi di sistema (regole in testa e contesto della richiesta in coda)
// vanno in un solo messaggio di sistema all'inizio: i modelli open (Qwen in testa) rifiutano un system dopo il primo
// messaggio. I risultati degli strumenti diventano messaggi `tool`, uno per chiamata.
export function messaggiOpenAI(system, messages) {
  const sistema = []
  for (const s of system ?? []) sistema.push(typeof s === 'string' ? s : s.text)
  const out = []
  for (const m of messages) {
    if (m.role === 'system') { sistema.push(testoDi(m.content)); continue }
    if (m.role === 'assistant') {
      if (typeof m.content === 'string') { out.push({ role: 'assistant', content: m.content }); continue }
      const testo = m.content.filter(b => b.type === 'text').map(b => b.text).join('')
      const chiamate = m.content.filter(b => b.type === 'tool_use')
        .map(b => ({ id: b.id, type: 'function', function: { name: b.name, arguments: JSON.stringify(b.input ?? {}) } }))
      out.push({ role: 'assistant', content: testo || null, ...(chiamate.length ? { tool_calls: chiamate } : {}) })
      continue
    }
    if (typeof m.content === 'string') { out.push({ role: 'user', content: m.content }); continue }
    const risultati = m.content.filter(b => b.type === 'tool_result')
    for (const r of risultati) {
      const contenuto = typeof r.content === 'string' ? r.content : testoDi(r.content ?? [])
      out.push({ role: 'tool', tool_call_id: r.tool_use_id, content: r.is_error ? `ERRORE: ${contenuto}` : contenuto })
    }
    const parti = []
    for (const b of m.content) {
      if (b.type === 'text') parti.push({ type: 'text', text: b.text })
      else if (b.type === 'image') parti.push({ type: 'image_url', image_url: { url: `data:${b.source.media_type};base64,${b.source.data}` } })
    }
    if (parti.length) out.push({ role: 'user', content: parti.length === 1 && parti[0].type === 'text' ? parti[0].text : parti })
  }
  return sistema.length ? [{ role: 'system', content: sistema.join('\n\n') }, ...out] : out
}

export function richiestaOpenAI(params) {
  const { nome } = separaModello(params.model)
  const corpo = {
    model: nome,
    max_tokens: params.max_tokens,
    messages: messaggiOpenAI(params.system, params.messages),
    stream: true,
    stream_options: { include_usage: true },
  }
  if (params.tools?.length) {
    corpo.tools = params.tools.map(t => ({ type: 'function', function: { name: t.name, description: t.description, parameters: t.input_schema } }))
    if (params.tool_choice?.type === 'none') corpo.tool_choice = 'none'
  }
  return corpo
}

// Alcuni modelli (Qwen) scrivono il ragionamento nel testo tra <think> e </think> quando il server non lo separa: non
// va mostrato né salvato. Il filtro lavora a pezzi, come arrivano dallo stream, e tiene da parte un possibile tag a metà.
export function creaFiltroPensiero() {
  let dentro = false
  let resto = ''
  return function filtra(pezzo, fine = false) {
    let s = resto + pezzo
    resto = ''
    let fuori = ''
    for (;;) {
      const tag = dentro ? '</think>' : '<think>'
      const i = s.indexOf(tag)
      if (i >= 0) {
        if (!dentro) fuori += s.slice(0, i)
        s = s.slice(i + tag.length)
        dentro = !dentro
        continue
      }
      // Un inizio di tag in fondo al pezzo resta in attesa del pezzo dopo
      let tieni = 0
      if (!fine) for (let k = Math.min(tag.length - 1, s.length); k > 0; k--) if (tag.startsWith(s.slice(-k))) { tieni = k; break }
      if (!dentro) fuori += s.slice(0, s.length - tieni)
      resto = s.slice(s.length - tieni)
      return fuori
    }
  }
}

const STOP = { tool_calls: 'tool_use', function_call: 'tool_use', length: 'max_tokens', content_filter: 'refusal', stop: 'end_turn' }

// Righe SSE (data: {...}) → messaggio nel formato di Anthropic: content con blocchi text e tool_use, stop_reason, usage.
export async function leggiStream(corpo, { modello, onTesto }) {
  const filtro = creaFiltroPensiero()
  const lettore = corpo.pipeThrough(new TextDecoderStream()).getReader()
  let buffer = ''
  let testo = ''
  let fine = null
  let usage = null
  const chiamate = []
  const emetti = (t) => { if (t) { testo += t; onTesto?.(t) } }
  const riga = (r) => {
    if (!r.startsWith('data:')) return
    const dati = r.slice(5).trim()
    if (!dati || dati === '[DONE]') return
    const ev = JSON.parse(dati)
    if (ev.error) throw new Error(`fornitore: ${ev.error.message ?? JSON.stringify(ev.error)}`)
    if (ev.usage) usage = ev.usage
    const scelta = ev.choices?.[0]
    if (!scelta) return
    const d = scelta.delta ?? {}
    if (typeof d.content === 'string') emetti(filtro(d.content))
    for (const tc of d.tool_calls ?? []) {
      const i = tc.index ?? chiamate.length
      chiamate[i] ??= { id: '', name: '', args: '' }
      if (tc.id) chiamate[i].id = tc.id
      if (tc.function?.name) chiamate[i].name += tc.function.name
      if (tc.function?.arguments) chiamate[i].args += tc.function.arguments
    }
    if (scelta.finish_reason) fine = scelta.finish_reason
  }
  for (;;) {
    const { value, done } = await lettore.read()
    if (done) break
    buffer += value
    let a
    while ((a = buffer.indexOf('\n')) >= 0) {
      riga(buffer.slice(0, a).replace(/\r$/, ''))
      buffer = buffer.slice(a + 1)
    }
  }
  if (buffer.trim()) riga(buffer.trim())
  emetti(filtro('', true))

  const content = []
  if (testo.trim()) content.push({ type: 'text', text: testo })
  chiamate.filter(Boolean).forEach((c, i) => {
    let input = {}
    try { input = c.args.trim() ? JSON.parse(c.args) : {} } catch { input = {} }
    content.push({ type: 'tool_use', id: c.id || `chiamata_${i}`, name: c.name, input })
  })
  // Alcuni server chiudono con «stop» anche quando hanno chiesto strumenti
  const stop_reason = content.some(b => b.type === 'tool_use') && (fine === 'stop' || fine == null) ? 'tool_use' : (STOP[fine] ?? 'end_turn')
  return {
    model: modello, role: 'assistant', content, stop_reason,
    usage: {
      input_tokens: (usage?.prompt_tokens ?? 0) - (usage?.prompt_tokens_details?.cached_tokens ?? 0),
      output_tokens: usage?.completion_tokens ?? 0,
      cache_read_input_tokens: usage?.prompt_tokens_details?.cached_tokens ?? 0,
      cache_creation_input_tokens: 0,
    },
  }
}

// Una chiamata del ciclo: stessa firma di quella verso Anthropic in index.ts.
export async function chiamaOpenAI({ url, chiave, params, fetch, signal, onTesto }) {
  const r = await fetch(`${url.replace(/\/$/, '')}/chat/completions`, {
    method: 'POST', signal,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${chiave}` },
    body: JSON.stringify(richiestaOpenAI(params)),
  })
  if (!r.ok || !r.body) {
    const testo = await r.text().catch(() => '')
    throw new Error(`fornitore: HTTP ${r.status} ${testo.slice(0, 300)}`)
  }
  return leggiStream(r.body, { modello: params.model, onTesto })
}
