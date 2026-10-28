// Logica condivisa per la galleria foto (GalleryView.vue, PiantaView.vue e
// PianteView.vue): le foto stanno nel bucket privato `galleria` di Supabase
// Storage e sono elencate nella tabella `foto` (migration
// 20261028120000_galleria_foto.sql), entrambi con accesso solo alle proprie.
// Fino al 28/10/2026 stavano nel repository GitHub (docs/gallery/piante/),
// scritte con un token personale: funzionava solo per un utente.
import { parse as parseExif } from 'exifr/dist/lite.esm.mjs'
import { useSupabase } from '@/composables/useSupabase'

const supabase = useSupabase()
const BUCKET = 'galleria'
const COLONNE = 'id, pianta_id, scattata_il, percorso, percorso_media, percorso_miniatura'

// Il bucket è privato: ogni immagine si mostra con un link firmato. I link
// valgono un giorno e restano in memoria finché mancano almeno 10 minuti alla
// scadenza, così riaprire una vista non rifà le firme (e il browser ritrova
// in cache le immagini con lo stesso indirizzo).
const DURATA_FIRMA = 60 * 60 * 24
const firme = new Map()

async function firma(percorsi) {
  const ora = Date.now()
  const daFirmare = [...new Set(percorsi.filter(Boolean))]
    .filter(p => !(firme.get(p)?.scade > ora + 10 * 60 * 1000))
  if (daFirmare.length) {
    const { data, error } = await supabase.storage.from(BUCKET).createSignedUrls(daFirmare, DURATA_FIRMA)
    if (error) throw error
    for (const f of data ?? []) {
      if (f.signedUrl) firme.set(f.path, { url: f.signedUrl, scade: ora + DURATA_FIRMA * 1000 })
    }
  }
  return p => firme.get(p)?.url ?? null
}

// WebP pesa circa un quinto in meno a parità di resa, ma WebKit (Safari e
// ogni browser su iPhone/iPad) non lo sa scrivere da un canvas e restituisce
// un PNG senza errori. Si chiede al browser una volta, su un canvas di 1px,
// invece di dedurlo dallo user agent, che sbaglia (Safari su iPad si presenta
// come un Mac) e invecchia appena WebKit imparerà a farlo.
let webp = null
function scriveWebp() {
  if (webp === null) {
    const c = document.createElement('canvas')
    c.width = c.height = 1
    webp = c.toDataURL('image/webp').startsWith('data:image/webp')
  }
  return webp
}

function formatBreve(d) {
  if (!d) return ''
  return d.toLocaleDateString('it-IT', { day: 'numeric', month: 'short', year: '2-digit' })
}

function formatEstesa(d) {
  if (!d) return ''
  return d.toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

// Stessa forma di quando le foto erano file del repository: `path` resta la
// chiave della foto nelle viste, `nome` (con il timestamp di scatto davanti)
// serve all'ordinamento, `cartella` è l'id della pianta o 'generale'.
// thumbUrl è la versione media (640px), usata ovunque si mostri la foto in
// piccolo; ricade sull'originale se la media manca.
function voce(riga, url) {
  const d = new Date(riga.scattata_il)
  return {
    id:   riga.id,
    path: riga.percorso,
    nome: riga.percorso.split('/').pop(),
    cartella: riga.pianta_id ?? 'generale',
    percorsi: [riga.percorso, riga.percorso_media, riga.percorso_miniatura].filter(Boolean),
    url:      url(riga.percorso),
    thumbUrl: url(riga.percorso_media ?? riga.percorso),
    dataBreve:  formatBreve(d),
    dataEstesa: formatEstesa(d),
  }
}

async function righeConUrl(query) {
  const { data, error } = await query.order('scattata_il', { ascending: false })
  if (error) throw error
  const url = await firma(data.flatMap(r => [r.percorso, r.percorso_media ?? r.percorso]))
  return data.map(r => voce(r, url))
}

// Toglie i file dal bucket senza bloccare chi chiama: la riga è già
// cancellata, quindi la foto non si vede più; un file rimasto occupa spazio
// ma non fa danni.
async function togliFile(percorsi) {
  if (!percorsi.length) return
  try {
    await supabase.storage.from(BUCKET).remove(percorsi)
  } catch {
    // Vedi commento sopra.
  }
  for (const p of percorsi) firme.delete(p)
}

export function useGalleria() {
  // Foto di una singola pianta (o le generiche, con 'generale').
  async function listaFoto(cartella) {
    const q = supabase.from('foto').select(COLONNE)
    return righeConUrl(cartella === 'generale' ? q.is('pianta_id', null) : q.eq('pianta_id', cartella))
  }

  // Tutte le foto dell'utente (per la Galleria completa).
  async function listaTutte() {
    return righeConUrl(supabase.from('foto').select(COLONNE))
  }

  // Prima la riga, che è ciò che l'utente vede sparire, poi i file con le
  // derivate gemelle.
  async function elimina(foto) {
    const { error } = await supabase.from('foto').delete().eq('id', foto.id)
    if (error) throw error
    await togliFile(foto.percorsi ?? [foto.path])
  }

  // Cancellazione best-effort di tutte le foto di una pianta (chiamata prima
  // di rimuovere la pianta stessa): un problema sulle foto non deve impedire
  // di eliminare la pianta, che è l'azione principale richiesta dall'utente.
  // Le righe se ne andrebbero comunque con la pianta (on delete cascade); i
  // file no, per questo si tolgono qui.
  async function eliminaCartella(cartella) {
    try {
      const { data, error } = await supabase.from('foto').delete().eq('pianta_id', cartella).select(COLONNE)
      if (error) return
      await togliFile(data.flatMap(r => [r.percorso, r.percorso_media, r.percorso_miniatura].filter(Boolean)))
    } catch {
      // Vedi commento sopra.
    }
  }

  // Ridimensiona un'immagine via canvas (lato client, nessun servizio
  // esterno): usata da carica() per generare le tre varianti di ogni foto
  // (thumb 120px per l'avatar di elenco, medium 640px per hero/griglia,
  // originale limitato a 1600px per la lightbox) invece di conservare il
  // file a piena risoluzione della fotocamera ovunque venga mostrato.
  // Usa createImageBitmap con resize nativo del browser invece di un
  // singolo drawImage in downscale: su alcuni motori di rendering un
  // ridimensionamento manuale molto spinto (es. 4000px+ → 120px in un
  // solo passaggio) produce un'immagine corrotta (artefatti a strisce),
  // mentre il resize nativo in fase di decodifica è affidabile.
  async function ridimensiona(file, maxDim, qualita) {
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
    return comeBlob(canvas, scriveWebp() ? 'image/webp' : 'image/jpeg', qualita)
  }

  function comeBlob(canvas, tipo, qualita) {
    return new Promise((ok, ko) =>
      canvas.toBlob(b => (b ? ok(b) : ko(new Error('Il browser non riesce a elaborare la foto.'))), tipo, qualita)
    )
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

  async function caricaFile(base, blob) {
    const percorso = `${base}.${blob.type === 'image/webp' ? 'webp' : 'jpg'}`
    const { error } = await supabase.storage.from(BUCKET)
      .upload(percorso, blob, { contentType: blob.type, cacheControl: '31536000', upsert: false })
    if (error) throw error
    return percorso
  }

  // Carica la foto (ridotta lato client a un massimo di 1600px, invece del
  // file diretto dalla fotocamera che può arrivare a 4000px+/7MB) insieme
  // alle sue due derivate più leggere: "_thumb" (120px, per l'avatar
  // nell'elenco piante via mappaThumbnail()) e "_medium" (640px, per
  // hero/striscia/griglia). Il fallimento delle sole derivate non blocca il
  // caricamento della foto principale, che resta l'obiettivo primario.
  // dataScatto (opzionale): se nota (letta da leggiDataScatto), sostituisce
  // il momento del caricamento, così l'ordinamento e la data mostrata
  // riflettono quando la foto è stata scattata.
  async function carica(cartella, file, dataScatto = null) {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) throw new Error('Accedi per caricare le foto.')
    const ts   = dataScatto instanceof Date ? dataScatto.getTime() : Date.now()
    // Il suffisso casuale evita che due foto con lo stesso istante di scatto si sovrascrivano.
    const base = `${session.user.id}/${cartella}/${ts}_${Math.random().toString(36).slice(2, 8)}`

    const percorso = await caricaFile(base, await ridimensiona(file, 1600, 0.80))
    const [media, miniatura] = await Promise.all([
      ridimensiona(file, 640, 0.75).then(b => caricaFile(`${base}_medium`, b)).catch(() => null),
      ridimensiona(file, 120, 0.70).then(b => caricaFile(`${base}_thumb`, b)).catch(() => null),
    ])

    const { data, error } = await supabase.from('foto').insert({
      pianta_id: cartella === 'generale' ? null : cartella,
      scattata_il: new Date(ts).toISOString(),
      percorso,
      percorso_media: media,
      percorso_miniatura: miniatura,
    }).select(COLONNE).single()
    if (error) {
      await togliFile([percorso, media, miniatura].filter(Boolean))
      throw error
    }
    return voce(data, await firma([data.percorso, data.percorso_media]))
  }

  // Una query sola per tutte le piante (la più recente di ciascuna, in
  // miniatura) e una sola richiesta di firme: la vista Piante non deve fare
  // una chiamata per pianta solo per sapere quali hanno una foto.
  async function mappaThumbnail() {
    const { data, error } = await supabase.from('foto')
      .select('pianta_id, percorso, percorso_media, percorso_miniatura')
      .not('pianta_id', 'is', null)
      .order('scattata_il', { ascending: false })
    if (error) throw error
    const scelte = {}
    for (const r of data) {
      if (!scelte[r.pianta_id]) scelte[r.pianta_id] = r.percorso_miniatura ?? r.percorso_media ?? r.percorso
    }
    const url = await firma(Object.values(scelte))
    return Object.fromEntries(Object.entries(scelte).map(([id, p]) => [id, url(p)]))
  }

  return { listaFoto, listaTutte, elimina, eliminaCartella, ridimensiona, carica, leggiDataScatto, mappaThumbnail }
}
