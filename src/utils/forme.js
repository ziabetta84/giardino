// Disegni per forma della pianta (scripts/immagini/forme/disegna.py): li mostra una voce del catalogo senza foto,
// in base al campo «forma» della scheda (ereditato dal livello sopra come gli altri campi). Uno per forma, uguale
// per tutte le schede di quella forma. Sono disegni dell'app, non foto della pianta: nessun credito da citare.
import { fotoVoce } from '@/utils/catalogo'

const URL_FORME = import.meta.glob('../assets/forme/*.svg', { eager: true, query: '?url', import: 'default' })

const NOMI = {
  albero: 'albero', arbusto: 'arbusto', erbacea: 'pianta erbacea', bulbosa: 'pianta bulbosa', rampicante: 'rampicante',
  graminacea: 'graminacea', orchidea: 'orchidea', succulenta: 'succulenta', felce: 'felce', conifera: 'conifera',
  palma: 'palma', acquatica: 'pianta acquatica',
}

// { url, alt } del disegno della voce, o null se la voce ha una foto da mostrare (fotoVoce) o non ha una forma nota
export function disegnoForma(voce) {
  if (fotoVoce(voce) || !voce?.forma) return null
  const url = URL_FORME[`../assets/forme/${voce.forma}.svg`]
  return url ? { url, alt: `Disegno di ${NOMI[voce.forma] ?? 'pianta'}` } : null
}
