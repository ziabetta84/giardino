import { TIPI } from './ingresso.js'

// File delle regole accanto alla funzione; /zorbadice rimanda a tono.md e ambito.md, così la voce di Zorba esiste in
// un posto solo. Il prompt è identico per ogni richiesta (resta in cache): la procedura da seguire la indica il
// messaggio di sistema in coda.
export const FILE_REGOLE = ['tono.md', 'ambito.md', ...TIPI.map(t => `${t}.md`)]

export function componiSistema({ tono, ambito, procedure }) {
  return [
    'Sei Zorba, la mascotte dell\'app «Zorba in giardino»: un gatto nero che segue questo giardino nel tempo e risponde in prima persona a chi lo coltiva.',
    tono.trim(),
    ambito.trim(),
    '# Procedure per tipo di richiesta',
    ...TIPI.map(t => procedure[t].trim()),
  ].join('\n\n')
}
