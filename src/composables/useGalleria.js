// Logica condivisa per la galleria foto (GalleryView.vue e PiantaView.vue):
// lettura/eliminazione dei file su GitHub, generazione di thumbnail via
// canvas al momento del caricamento, e mappa delle thumbnail per l'elenco
// piante (una sola chiamata alla Git Trees API invece di una per pianta).
import { useApi } from '@/composables/useApi'
import { parse as parseExif } from 'exifr/dist/lite.esm.mjs'

const OWNER  = 'ziabetta84'
const REPO   = 'giardino'
const BRANCH = 'main'
const FOLDER = 'docs/gallery/piante'

function apiHeaders() {
  const token = localStorage.getItem('github_token')
  return token ? { Authorization: `Bearer ${token}` } : {}
}

function rawUrl(path) {
  return `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${path}`
}

function parseData(nome) {
  const ts = parseInt(nome.split('_')[0])
  if (!ts || isNaN(ts)) return null
  return new Date(ts)
}

function formatBreve(d) {
  if (!d) return ''
  return d.toLocaleDateString('it-IT', { day: 'numeric', month: 'short', year: '2-digit' })
}

function formatEstesa(d) {
  if (!d) return ''
  return d.toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

const RE_THUMB = /_thumb\.(jpe?g|png|webp)$/i
const RE_IMG   = /\.(jpe?g|png|gif|webp)$/i

async function listDir(path) {
  const res = await fetch(`https://api.github.com/repos/${OWNER}/${REPO}/contents/${path}`, { headers: apiHeaders() })
  if (res.status === 404) return []
  if (!res.ok) throw new Error(`Errore API GitHub: ${res.status}`)
  return res.json()
}

export function useGalleria() {
  const { uploadFile, deleteFile } = useApi()

  // Foto di una singola cartella pianta (esclude le thumbnail: sono un
  // dettaglio interno per l'elenco piante, non fanno parte della galleria).
  async function listaFoto(cartella) {
    const files = await listDir(`${FOLDER}/${cartella}`)
    return files
      .filter(f => f.type === 'file' && RE_IMG.test(f.name) && !RE_THUMB.test(f.name))
      .map(f => {
        const d = parseData(f.name)
        return {
          path: f.path,
          nome: f.name,
          sha:  f.sha,
          cartella,
          url:        rawUrl(f.path),
          dataBreve:  formatBreve(d),
          dataEstesa: formatEstesa(d),
        }
      })
      .sort((a, b) => b.nome.localeCompare(a.nome))
  }

  // Tutte le cartelle pianta con relative foto (per la Galleria completa).
  async function listaTutte() {
    const cartelle = (await listDir(FOLDER)).filter(f => f.type === 'dir')
    const risultati = await Promise.all(cartelle.map(c => listaFoto(c.name)))
    return risultati.flat()
  }

  function elimina(foto) {
    return deleteFile(foto.path, foto.sha, `Elimina foto ${foto.nome}`)
  }

  // Cancellazione best-effort di tutte le foto di una pianta (chiamata prima
  // di rimuovere la pianta stessa): se la cartella non esiste non c'è nulla
  // da fare; se una singola eliminazione fallisce non blocca le altre né la
  // cancellazione della pianta, che è l'azione principale richiesta
  // dall'utente — restare con qualche file orfano è preferibile a impedire
  // di eliminare la pianta per un problema sulle foto.
  async function eliminaCartella(cartella) {
    let files
    try {
      files = await listDir(`${FOLDER}/${cartella}`)
    } catch {
      return
    }
    await Promise.all(
      files
        .filter(f => f.type === 'file')
        .map(f => deleteFile(f.path, f.sha, `Elimina foto ${f.name}`).catch(() => {}))
    )
  }

  // Ridimensiona un'immagine via canvas (lato client, nessun servizio
  // esterno): usata per generare una thumbnail leggera da mostrare
  // nell'elenco piante invece del file originale a piena risoluzione.
  // Usa createImageBitmap con resize nativo del browser invece di un
  // singolo drawImage in downscale: su alcuni motori di rendering un
  // ridimensionamento manuale molto spinto (es. 4000px+ → 400px in un
  // solo passaggio) produce un'immagine corrotta (artefatti a strisce),
  // mentre il resize nativo in fase di decodifica è affidabile.
  async function ridimensiona(file, maxDim = 400, qualita = 0.8) {
    const originale = await createImageBitmap(file)
    let { width, height } = originale
    if (width > height && width > maxDim) {
      height = Math.round(height * maxDim / width)
      width = maxDim
    } else if (height > maxDim) {
      width = Math.round(width * maxDim / height)
      height = maxDim
    }
    originale.close()

    const bitmap = await createImageBitmap(file, { resizeWidth: width, resizeHeight: height, resizeQuality: 'high' })
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    canvas.getContext('2d').drawImage(bitmap, 0, 0)
    bitmap.close()
    return canvas.toDataURL('image/jpeg', qualita).split(',')[1]
  }

  // Legge la data di scatto dai metadati EXIF del file (DateTimeOriginal),
  // così una foto importata da un altro dispositivo/servizio (es. scaricata
  // da Google Photos) viene datata con il momento in cui è stata scattata
  // invece che con quello del caricamento nell'app. Restituisce null se il
  // file non ha EXIF leggibili (comune per screenshot, immagini già
  // rielaborate, o alcuni export che rimuovono i metadati) — non è quindi
  // una garanzia, solo un recupero quando l'informazione è disponibile.
  async function leggiDataScatto(file) {
    try {
      const exif = await parseExif(file)
      return exif?.DateTimeOriginal instanceof Date ? exif.DateTimeOriginal : null
    } catch {
      return null
    }
  }

  // Carica la foto originale e, se associata a una pianta, anche una
  // thumbnail ridotta accanto ad essa (stesso prefisso timestamp, suffisso
  // "_thumb"): mappaThumbnail() la userà per l'elenco piante. Il fallimento
  // della sola generazione/upload della thumbnail non blocca il
  // caricamento della foto originale, che resta l'obiettivo primario.
  // dataScatto (opzionale): se nota (letta da leggiDataScatto), sostituisce
  // il momento del caricamento come timestamp del file, così l'ordinamento
  // e la data mostrata riflettono quando la foto è stata scattata.
  // file: il File/Blob originale, usato da createImageBitmap per generare
  // la thumbnail (vedi commento su ridimensiona).
  async function carica(cartella, file, base64, dataScatto = null) {
    const ts   = dataScatto instanceof Date ? dataScatto.getTime() : Date.now()
    const nome = `${ts}_upload.jpg`
    const path = `${FOLDER}/${cartella}/${nome}`
    await uploadFile(path, base64, `Aggiunge foto ${nome}`)

    if (cartella && cartella !== 'generale') {
      try {
        const thumbBase64 = await ridimensiona(file)
        const thumbNome = `${ts}_thumb.jpg`
        await uploadFile(`${FOLDER}/${cartella}/${thumbNome}`, thumbBase64, `Aggiunge thumbnail ${thumbNome}`)
      } catch {
        // Vedi commento sopra: la foto originale è già stata caricata con successo.
      }
    }

    const d = new Date(ts)
    return { path, nome, cartella, url: rawUrl(path), dataBreve: formatBreve(d), dataEstesa: formatEstesa(d) }
  }

  // Una chiamata sola alla Git Trees API (ricorsiva) invece di una richiesta
  // di elenco per ciascuna pianta: essenziale per non appesantire la vista
  // Piante con decine di chiamate di rete solo per sapere quali hanno una
  // thumbnail disponibile.
  async function mappaThumbnail() {
    const res = await fetch(
      `https://api.github.com/repos/${OWNER}/${REPO}/git/trees/${BRANCH}?recursive=1`,
      { headers: apiHeaders() }
    )
    if (!res.ok) throw new Error(`Errore API GitHub: ${res.status}`)
    const { tree } = await res.json()

    const mappa = {}
    for (const voce of tree) {
      if (voce.type !== 'blob') continue
      if (!voce.path.startsWith(`${FOLDER}/`)) continue
      const resto = voce.path.slice(FOLDER.length + 1)
      const [cartella, nomeFile] = resto.split('/')
      if (!nomeFile || !RE_THUMB.test(nomeFile)) continue
      // Più thumbnail nella stessa cartella (foto multiple nel tempo): tiene
      // la più recente confrontando il prefisso timestamp nel nome file.
      if (!mappa[cartella] || nomeFile > mappa[cartella].nome) {
        mappa[cartella] = { nome: nomeFile, url: rawUrl(voce.path) }
      }
    }
    return Object.fromEntries(Object.entries(mappa).map(([cartella, v]) => [cartella, v.url]))
  }

  return { listaFoto, listaTutte, elimina, eliminaCartella, ridimensiona, carica, leggiDataScatto, mappaThumbnail, rawUrl }
}
