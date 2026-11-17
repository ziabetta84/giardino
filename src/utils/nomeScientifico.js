// Nome scientifico scritto secondo le convenzioni botaniche (ICN e ICNCP): genere ed epiteti in corsivo; in tondo
// gli indicatori di rango (subsp., var., f., spp.…), il segno dell'ibrido ×, l'epiteto della cultivar tra apici,
// il nome di grex e Gruppi (parole maiuscole dopo il genere). Restituisce i pezzi da mostrare, ognuno con
// «corsivo» vero o falso; gli spazi stanno nei pezzi, così il testo concatenato è identico all'originale.

const RANGHI = new Set(['subsp.', 'ssp.', 'var.', 'subvar.', 'f.', 'subf.', 'forma', 'cv.', 'agg.', 'spp.', 'sp.',
  'aff.', 'cf.', 'sect.', 'subg.', 'nothosubsp.', 'nothovar.', 'nothof.', 'grex', 'gruppo', 'group'])
const APICE = /^['‘’]/

export function partiNomeScientifico(nome) {
  const testo = String(nome ?? '').trim()
  if (!testo) return []
  const parti = []
  const aggiungi = (t, corsivo) => {
    const ultima = parti[parti.length - 1]
    if (ultima && ultima.corsivo === corsivo) ultima.testo += t
    else parti.push({ testo: t, corsivo })
  }
  const parole = testo.split(/(\s+)/)  // le parole e, tra loro, gli spazi
  let genereVisto = false, tondoFinoInFondo = false
  for (const p of parole) {
    if (!p) continue
    if (/^\s+$/.test(p)) { aggiungi(p, false); continue }   // gli spazi in tondo; sotto si uniscono ai corsivi
    let corsivo
    if (tondoFinoInFondo) corsivo = false
    else if (APICE.test(p)) { corsivo = false; tondoFinoInFondo = true }   // 'Cultivar' e tutto ciò che segue
    else if (p === '×' || p.toLowerCase() === 'x' && genereVisto) corsivo = false
    else if (RANGHI.has(p.toLowerCase())) corsivo = false
    else if (!genereVisto) { corsivo = true; genereVisto = true }        // il genere (anche dopo un ×)
    else if (/^[a-zà-ÿ]/.test(p)) corsivo = true                           // epiteto
    else { corsivo = false; tondoFinoInFondo = true }                      // grex o Gruppo: maiuscola dopo il genere
    aggiungi(p, corsivo)
  }
  // Uno spazio tra due parti in corsivo va dentro il corsivo (si legge come un nome solo)
  const unite = []
  for (let i = 0; i < parti.length; i++) {
    const p = parti[i]
    if (!p.corsivo && /^\s+$/.test(p.testo) && unite.at(-1)?.corsivo && parti[i + 1]?.corsivo) {
      unite.at(-1).testo += p.testo + parti[i + 1].testo
      i++
    } else unite.push({ ...p })
  }
  return unite
}

// Il nome comune italiano da mostrare sotto il nome scientifico, oppure '' quando la voce non ne ha uno (il nome
// mostrato dal catalogo è allora il nome scientifico stesso). Per una cultivar il nome è «Nome comune 'Epiteto'»:
// si toglie la parte finale in comune con il nome scientifico, che il titolo mostra già.
export function nomeComuneVoce(voce) {
  const nome = String(voce?.nome ?? '').trim()
  const sci = String(voce?.specie ?? '').trim()
  if (!nome || !sci) return ''
  if (nome.toLowerCase() === sci.toLowerCase()) return ''
  if (voce.tipo !== 'cultivar') return nome
  const a = nome.split(' '), b = sci.split(' ')
  let n = 0
  while (n < a.length - 1 && n < b.length - 1 && a[a.length - 1 - n] === b[b.length - 1 - n]) n++
  const base = a.slice(0, a.length - n).join(' ')
  const baseSci = b.slice(0, b.length - n).join(' ')
  return base.toLowerCase() === baseSci.toLowerCase() ? '' : base
}
