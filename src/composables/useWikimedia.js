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

export function urlMiniatura(url, larghezzaMinima) {
  if (!url) return url
  const m = url.match(RE_COMMONS)
  if (!m) return url
  const [, base, dir1, dir2, file] = m
  const larghezza = STEP_LARGHEZZE.find(s => s >= larghezzaMinima) ?? STEP_LARGHEZZE[STEP_LARGHEZZE.length - 1]
  return `${base}/thumb/${dir1}/${dir2}/${file}/${larghezza}px-${file}`
}
