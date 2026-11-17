import { useHead } from '@unhead/vue'
import { SITO } from './percorso.js'

// Finché il sito si condivide solo con chi ha il link, ogni pagina chiede ai
// motori di ricerca di non indicizzarla. Per renderlo pubblico: VITE_SCOPRI_PUBBLICO=true
// (vedi sito/quando-pubblico/LEGGIMI.md).
export const PUBBLICO = import.meta.env.VITE_SCOPRI_PUBBLICO === 'true'

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
      ...(PUBBLICO ? [] : [{ name: 'robots', content: 'noindex, nofollow' }]),
    ],
    link: [{ rel: 'canonical', href: url }],
    script: jsonld
      ? [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonld) }]
      : [],
  })
}
