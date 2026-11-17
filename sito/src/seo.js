import { useHead } from '@unhead/vue'
import { SITO } from './percorso.js'

// Titolo, descrizione, indirizzo canonico e dati strutturati di una pagina.
// vite-ssg li scrive nell'HTML statico di ognuna.
export function usePagina({ titolo, descrizione, percorso, jsonld }) {
  const url = `${SITO}${percorso}`
  useHead({
    title: titolo,
    meta: [
      { name: 'description', content: descrizione },
      { property: 'og:title', content: titolo },
      { property: 'og:description', content: descrizione },
      { property: 'og:url', content: url },
    ],
    link: [{ rel: 'canonical', href: url }],
    script: jsonld
      ? [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonld) }]
      : [],
  })
}
