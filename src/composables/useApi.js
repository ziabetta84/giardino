// Accesso GitHub API per lettura/scrittura JSON e upload foto

const OWNER = 'ziabetta84'
const REPO  = 'giardino'
const BRANCH = 'main'

function getToken() {
  return localStorage.getItem('github_token') || null
}

function getHeaders() {
  const token = getToken()
  return token
    ? { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
    : { 'Content-Type': 'application/json' }
}

export function useApi() {

  // dataOrUpdater può essere:
  // - un oggetto già pronto da scrivere (comportamento storico)
  // - una funzione (contenutoAttuale) => nuovoContenuto: viene chiamata con il
  //   contenuto RIMOSSO più recente letto da GitHub subito prima di scrivere,
  //   e se GitHub rifiuta il PUT per conflitto di SHA (qualcun altro ha
  //   scritto lo stesso file nel frattempo — un altro tab/dispositivo, o la
  //   sessione Claude Code che elabora la coda), la funzione viene richiamata
  //   di nuovo sul contenuto aggiornato invece di fallire subito. Ritorna i
  //   dati effettivamente scritti, così il chiamante può allineare lo store
  //   locale allo stato reale (non a quello, potenzialmente superato, con cui
  //   aveva calcolato la modifica).
  async function saveJSON(filename, dataOrUpdater, { retries = 4 } = {}) {
    const path = `public/data/${filename}`
    const url  = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${path}`
    const isUpdater = typeof dataOrUpdater === 'function'

    for (let tentativo = 0; ; tentativo++) {
      // Ottieni SHA e contenuto attuali (null/undefined se il file non esiste ancora)
      let sha
      let corrente = null
      // cache: 'no-store' è essenziale qui: l'API Contents risponde con
      // Cache-Control: public, max-age=60, quindi senza disabilitare la
      // cache del browser una scrittura seguita a breve da un'altra
      // rileggerebbe lo SHA precedente alla prima scrittura, causando un
      // conflitto "does not match" che i retry non risolvono (rileggono
      // la stessa risposta cache-stale).
      const info = await fetch(url, { headers: getHeaders(), cache: 'no-store' })
      if (info.ok) {
        const json = await info.json()
        sha = json.sha
        if (json.content) {
          // L'API GitHub restituisce il base64 con newline ogni 76 caratteri:
          // atob() lancia un'eccezione se non vengono rimossi prima.
          corrente = JSON.parse(decodeURIComponent(escape(atob(json.content.replace(/\s/g, '')))))
        } else {
          // Per i file oltre 1MB l'API Contents non include il contenuto
          // inline: lo richiediamo in formato raw con l'header Accept
          // dedicato, riusando lo stesso token (a differenza di download_url,
          // che su repo privati è null o comunque non autenticato).
          const raw = await fetch(url, {
            headers: { ...getHeaders(), Accept: 'application/vnd.github.v3.raw' },
            cache: 'no-store',
          })
          if (!raw.ok) throw new Error(`Errore lettura file raw: ${raw.status}`)
          corrente = await raw.json()
        }
      } else if (info.status !== 404) {
        throw new Error(`Errore lettura file: ${info.status}`)
      }
      // Se 404 → sha rimane undefined → GitHub crea il file

      const data = isUpdater ? dataOrUpdater(corrente) : dataOrUpdater
      const content = btoa(unescape(encodeURIComponent(JSON.stringify(data, null, 2))))

      const body = { message: `Aggiorna ${filename}`, content, branch: BRANCH }
      if (sha) body.sha = sha

      const res = await fetch(url, {
        method: 'PUT',
        headers: getHeaders(),
        body: JSON.stringify(body),
      })
      if (res.ok) return data

      const err = await res.json().catch(() => ({}))
      const conflitto = res.status === 409 || /does not match/.test(err.message || '')
      // Riprova solo se abbiamo una funzione di aggiornamento: con un oggetto
      // fisso, ripetere la stessa scrittura rischierebbe di sovrascrivere una
      // modifica concorrente invece di combinarsi con essa.
      if (conflitto && isUpdater && tentativo < retries) continue
      throw new Error(err.message || `Errore salvataggio ${filename}`)
    }
  }

  async function uploadFile(repoPath, base64Content, message = 'Upload file') {
    const url = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${repoPath}`

    // Controlla se esiste già (per ottenere SHA)
    let sha
    const check = await fetch(url, { headers: getHeaders(), cache: 'no-store' })
    if (check.ok) {
      const existing = await check.json()
      sha = existing.sha
    }

    const body = { message, content: base64Content, branch: BRANCH }
    if (sha) body.sha = sha

    const res = await fetch(url, {
      method: 'PUT',
      headers: getHeaders(),
      body: JSON.stringify(body)
    })
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.message || 'Errore upload file')
    }
    return res.json()
  }

  function isAutenticato() {
    return !!getToken()
  }

  function salvaToken(token) {
    localStorage.setItem('github_token', token)
  }

  return { saveJSON, uploadFile, isAutenticato, salvaToken }
}
