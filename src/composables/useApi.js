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

  async function saveJSON(filename, data) {
    const path = `public/data/${filename}`
    const url  = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${path}`

    // Ottieni SHA attuale (null se il file non esiste ancora)
    let sha
    const info = await fetch(url, { headers: getHeaders() })
    if (info.ok) {
      sha = (await info.json()).sha
    } else if (info.status !== 404) {
      throw new Error(`Errore lettura file: ${info.status}`)
    }
    // Se 404 → sha rimane undefined → GitHub crea il file

    const content = btoa(unescape(encodeURIComponent(JSON.stringify(data, null, 2))))

    const body = { message: `Aggiorna ${filename}`, content, branch: BRANCH }
    if (sha) body.sha = sha

    const res = await fetch(url, {
      method: 'PUT',
      headers: getHeaders(),
      body: JSON.stringify(body),
    })
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.message || `Errore salvataggio ${filename}`)
    }
    return res.json()
  }

  async function uploadFile(repoPath, base64Content, message = 'Upload file') {
    const url = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${repoPath}`

    // Controlla se esiste già (per ottenere SHA)
    let sha
    const check = await fetch(url, { headers: getHeaders() })
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
