// Accesso GitHub API per lettura/scrittura JSON e upload foto

import { ref } from 'vue'

const OWNER = 'ziabetta84'
const REPO  = 'giardino'
const BRANCH = 'main'

// Stato a livello di modulo (stesso pattern di useAuth.js): un solo ref
// condiviso da chiunque importi questo composable, così AccountView e
// AgenteView vedono lo stesso stato del token senza bisogno di un reload.
const tokenPresente = ref(!!localStorage.getItem('github_token'))

function getToken() {
  return localStorage.getItem('github_token') || null
}

function getHeaders() {
  const token = getToken()
  return token
    ? { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
    : { 'Content-Type': 'application/json' }
}

// GitHub risponde 401 con {"message":"Bad credentials"} quando il token è
// scaduto, revocato o malformato (non un problema di permessi, quello sarebbe
// un 403). In quel caso il token salvato non è più utilizzabile: lo svuotiamo
// così l'app torna a chiedere di inserirne uno nuovo invece di ripetere
// all'infinito la stessa chiamata destinata a fallire.
function gestisciEventualeTokenInvalido(res) {
  if (res.status === 401) {
    rimuoviToken()
    throw new Error('Token GitHub non valido o scaduto: vai su Account per inserirne uno nuovo.')
  }
}

function rimuoviToken() {
  localStorage.removeItem('github_token')
  tokenPresente.value = false
}

// Legge un file dal repo tramite l'API Contents, con cache:'no-store' (vedi
// nota in saveJSON: l'API risponde con Cache-Control: public, max-age=60,
// che senza questo darebbe letture stale dopo una scrittura recente).
// Usata sia da saveJSON (che ha bisogno anche dello sha) sia da loadJSON.
async function leggiFileGitHub(path) {
  const url = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${path}`
  const info = await fetch(url, { headers: getHeaders(), cache: 'no-store' })
  if (info.status === 404) return { sha: undefined, data: null }
  gestisciEventualeTokenInvalido(info)
  if (!info.ok) throw new Error(`Errore lettura file: ${info.status}`)
  const json = await info.json()
  if (json.content) {
    // L'API GitHub restituisce il base64 con newline ogni 76 caratteri:
    // atob() lancia un'eccezione se non vengono rimossi prima.
    return { sha: json.sha, data: JSON.parse(decodeURIComponent(escape(atob(json.content.replace(/\s/g, ''))))) }
  }
  // Per i file oltre 1MB l'API Contents non include il contenuto inline: lo
  // richiediamo in formato raw con l'header Accept dedicato, riusando lo
  // stesso token (a differenza di download_url, che su repo privati è null
  // o comunque non autenticato).
  const raw = await fetch(url, {
    headers: { ...getHeaders(), Accept: 'application/vnd.github.v3.raw' },
    cache: 'no-store',
  })
  gestisciEventualeTokenInvalido(raw)
  if (!raw.ok) throw new Error(`Errore lettura file raw: ${raw.status}`)
  return { sha: json.sha, data: await raw.json() }
}

export function useApi() {

  // Legge un JSON di public/data/ direttamente da GitHub (stessa fonte usata
  // da saveJSON per scrivere), scavalcando sia la cache CDN di GitHub Pages
  // sia quella del service worker sulla copia pubblicata: usata per avere
  // dati sempre coerenti con l'ultimo salvataggio, senza aspettare che build
  // e deploy pubblichino una nuova copia statica.
  async function loadJSON(filename) {
    const { data } = await leggiFileGitHub(`public/data/${filename}`)
    if (data === null) throw new Error(`File non trovato: ${filename}`)
    return data
  }

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
      // Ottieni SHA e contenuto attuali (sha undefined, data null se il file
      // non esiste ancora → GitHub lo crea al PUT)
      const { sha, data: corrente } = await leggiFileGitHub(path)

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

      gestisciEventualeTokenInvalido(res)
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
      gestisciEventualeTokenInvalido(res)
      const err = await res.json()
      throw new Error(err.message || 'Errore upload file')
    }
    return res.json()
  }

  async function deleteFile(repoPath, sha, message = 'Elimina file') {
    const url = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${repoPath}`
    const res = await fetch(url, {
      method: 'DELETE',
      headers: getHeaders(),
      body: JSON.stringify({ message, sha, branch: BRANCH }),
    })
    if (!res.ok) {
      gestisciEventualeTokenInvalido(res)
      const err = await res.json().catch(() => ({}))
      throw new Error(err.message || 'Errore eliminazione file')
    }
    return res.json()
  }

  function isAutenticato() {
    return tokenPresente.value
  }

  function salvaToken(token) {
    localStorage.setItem('github_token', token)
    tokenPresente.value = true
  }

  return { saveJSON, loadJSON, uploadFile, deleteFile, isAutenticato, salvaToken, rimuoviToken, tokenPresente }
}
