// Riscrive un URL "originale" di Wikimedia Commons (a piena risoluzione,
// spesso diversi MB) nel formato thumb ufficiale del sito, generato da
// Wikimedia al volo alla prima richiesta — nessuna chiamata di rete o
// elaborazione a carico nostro. Se l'URL non è nel formato Commons atteso
// (dato esterno, non garantito) viene restituito invariato.
const RE_COMMONS = /^(https:\/\/upload\.wikimedia\.org\/wikipedia\/commons)\/([^/]+)\/([^/]+)\/([^/?]+)/i

// Le richieste dirette (hotlink, non tramite l'API MediaWiki) vengono
// rifiutate con 400 se la larghezza non è tra le "standard sizes" di
// produzione Wikimedia — verificato empiricamente (250/500 funzionano,
// 160/300/640/800 no). Si arrotonda quindi per eccesso allo step valido
// più vicino: https://www.mediawiki.org/wiki/Common_thumbnail_sizes
const STEP_LARGHEZZE = [20, 40, 60, 120, 250, 330, 500, 960, 1280, 1920, 3840]

// Le foto di iNaturalist (…/photos/<id>/large.jpg) esistono già in più misure, indicate dal lato lungo:
// small 240, medium 500, large 1024 px. Con «large» anche una miniatura da 48 px scaricava circa 600 KB.
const RE_INAT = /^(https:\/\/(?:inaturalist-open-data\.s3\.amazonaws\.com|static\.inaturalist\.org)\/photos\/\d+)\/(?:square|small|medium|large|original)(\.\w+)$/i
const MISURE_INAT = [[240, 'small'], [500, 'medium'], [1024, 'large']]

export function urlMiniatura(url, larghezzaMinima) {
  if (!url) return url
  const inat = url.match(RE_INAT)
  if (inat) {
    const [, misura] = MISURE_INAT.find(([lato]) => lato >= larghezzaMinima) ?? MISURE_INAT[MISURE_INAT.length - 1]
    return `${inat[1]}/${misura}${inat[2]}`
  }
  const m = url.match(RE_COMMONS)
  if (!m) return url
  const [, base, dir1, dir2, file] = m
  const larghezza = STEP_LARGHEZZE.find(s => s >= larghezzaMinima) ?? STEP_LARGHEZZE[STEP_LARGHEZZE.length - 1]
  return `${base}/thumb/${dir1}/${dir2}/${file}/${larghezza}px-${file}`
}
