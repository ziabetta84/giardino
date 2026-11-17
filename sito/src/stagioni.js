// L'acquerello d'apertura cambia con la stagione, con le stesse tele della
// Home dell'app (src/assets/hero) e la stessa divisione dei mesi.
import { stagione } from '../../supabase/functions/zorba/condivisi/cure.js'
import primaveraGiorno from '@app/assets/hero/hero-primavera-giorno.webp'
import primaveraNotte from '@app/assets/hero/hero-primavera-notte.webp'
import estateGiorno from '@app/assets/hero/hero-estate-giorno.webp'
import estateNotte from '@app/assets/hero/hero-estate-notte.webp'
import autunnoGiorno from '@app/assets/hero/hero-autunno-giorno.webp'
import autunnoNotte from '@app/assets/hero/hero-autunno-notte.webp'
import invernoGiorno from '@app/assets/hero/hero-inverno-giorno.webp'
import invernoNotte from '@app/assets/hero/hero-inverno-notte.webp'

export const stagioneDi = stagione

export const HERO = {
  primavera: { giorno: primaveraGiorno, notte: primaveraNotte, alt: "Un giardino in primavera dipinto ad acquerello: tulipani e margherite in primo piano, un sentiero di pietre bianche che si perde tra gli alberi." },
  estate: { giorno: estateGiorno, notte: estateNotte, alt: "Un giardino d'estate dipinto ad acquerello: girasoli e dalie in primo piano, aiuole fiorite e una fila di alberi sullo sfondo." },
  autunno: { giorno: autunnoGiorno, notte: autunnoNotte, alt: "Un giardino d'autunno dipinto ad acquerello: dalie rosse e arancioni in primo piano, alberi dalle chiome gialle sullo sfondo." },
  inverno: { giorno: invernoGiorno, notte: invernoNotte, alt: "Un giardino d'inverno dipinto ad acquerello: ellebori e bacche rosse in primo piano, alberi spogli e prato imbiancato." },
}
