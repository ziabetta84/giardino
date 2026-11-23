#!/usr/bin/env node
// Prova alla cieca dei modelli di Zorba. Per ogni domanda apre un filo nuovo con ciascun modello, attraverso la funzione
// vera (stesse regole, stessi strumenti, i dati del tuo giardino), salva risposte, tempi e costi, cancella i fili di
// prova e prepara una pagina in cui votare le risposte senza sapere quale modello le ha scritte.
//
// Uso (dalla cartella del repository, sul Mac):
//   ZORBA_JWT=… node scripts/zorba/prova_cieca.mjs DOMANDE.json CARTELLA_USCITA
//   ZORBA_JWT=… node scripts/zorba/prova_cieca.mjs --pagina CARTELLA_USCITA   (rifà solo la pagina)
//
// ZORBA_JWT: il token di accesso del curatore (solo il curatore può scegliere il modello di un filo). Nell'app aperta
// e con l'accesso fatto, dalla console del browser:
//   JSON.parse(localStorage[Object.keys(localStorage).find(k => k.endsWith('-auth-token'))]).access_token
// Dura un'ora: se scade a metà, si rilancia con un token nuovo e lo script riprende da dove era arrivato.
//
// MODELLI (facoltativo): elenco separato da virgole. «predefinito» = il modello che l'app sceglie per quel tipo
// (Opus per identificazioni e diagnosi, Sonnet per il resto). Predefinito: «predefinito,ovh:qwen3.6-35b-a3b».
// --tieni: non cancella i fili di prova (restano tra le conversazioni di Zorba nell'app).
//
// DOMANDE.json: [{ "tipo": "consiglio_cura", "testo": "…", "foto": "percorso/locale.jpg" | "zorba-foto:FILO/MESSAGGIO.jpg" }]
// Tipi ammessi: identifica_specie (con foto), consiglio_cura, consiglio_concimazione, diagnosi, altro. Niente
// pianifica_progetto (scriverebbe tappe nei progetti) né segnalazione_scheda (creerebbe segnalazioni).
// Le foto «zorba-foto:» sono quelle già mandate a Zorba, nella tua cartella del bucket.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs'
import { join, resolve } from 'node:path'

const TIPI_AMMESSI = ['identifica_specie', 'consiglio_cura', 'consiglio_concimazione', 'diagnosi', 'altro']

function leggiEnv() {
  const valori = {}
  for (const f of ['.env', '.env.local']) {
    if (!existsSync(f)) continue
    for (const r of readFileSync(f, 'utf8').split('\n')) {
      const m = /^([A-Z_]+)=(.*)$/.exec(r.trim())
      if (m) valori[m[1]] = m[2].replace(/^["']|["']$/g, '')
    }
  }
  return { ...valori, ...process.env }
}

// Eventi SSE della funzione (event: nome / data: json) → testo finale, errore, filo
export async function leggiRisposta(corpo) {
  const dec = new TextDecoder()
  let buffer = ''
  let testo = ''
  const esito = { filo: null, testo: '', errore: null, fine: null }
  const evento = (blocco) => {
    const nome = /^event: (.*)$/m.exec(blocco)?.[1]
    const dati = /^data: (.*)$/m.exec(blocco)?.[1]
    if (!nome || dati == null) return
    const d = JSON.parse(dati)
    if (nome === 'filo') esito.filo = d.id
    else if (nome === 'testo') testo += d.t
    else if (nome === 'annulla_testo') testo = ''
    else if (nome === 'errore') esito.errore = `${d.codice}: ${d.messaggio}`
    else if (nome === 'fine') esito.fine = d
  }
  for await (const pezzo of corpo) {
    buffer += dec.decode(pezzo, { stream: true })
    let i
    while ((i = buffer.indexOf('\n\n')) >= 0) { evento(buffer.slice(0, i)); buffer = buffer.slice(i + 2) }
  }
  if (buffer.trim()) evento(buffer)
  esito.testo = testo.trim()
  return esito
}

async function main() {
  const args = process.argv.slice(2)
  const tieni = args.includes('--tieni')
  const soloPagina = args.includes('--pagina')
  const posizionali = args.filter(a => !a.startsWith('--'))
  if (soloPagina) {
    const cartella = resolve(posizionali[0] ?? '')
    scriviPagina(cartella, JSON.parse(readFileSync(join(cartella, 'risultati.json'), 'utf8')))
    return
  }
  const [fileDomande, cartellaUscita] = posizionali
  if (!fileDomande || !cartellaUscita) { console.error('Uso: node scripts/zorba/prova_cieca.mjs DOMANDE.json CARTELLA_USCITA'); process.exit(1) }
  const env = leggiEnv()
  const jwt = env.ZORBA_JWT
  const url = env.SUPABASE_URL || env.VITE_SUPABASE_URL
  const anon = env.SUPABASE_ANON_KEY || env.VITE_SUPABASE_ANON_KEY
  if (!jwt || !url || !anon) { console.error('Servono ZORBA_JWT e l\'indirizzo e la chiave pubblica di Supabase (.env)'); process.exit(1) }
  const utente = JSON.parse(Buffer.from(jwt.split('.')[1], 'base64url').toString()).sub
  const modelli = (env.MODELLI || 'predefinito,ovh:qwen3.6-35b-a3b').split(',').map(s => s.trim()).filter(Boolean)
  const domande = JSON.parse(readFileSync(fileDomande, 'utf8'))
  for (const [i, d] of domande.entries()) {
    if (!TIPI_AMMESSI.includes(d.tipo)) throw new Error(`domanda ${i + 1}: tipo «${d.tipo}» non ammesso nella prova`)
    if (d.tipo === 'identifica_specie' && !d.foto) throw new Error(`domanda ${i + 1}: identifica_specie vuole una foto`)
  }
  mkdirSync(cartellaUscita, { recursive: true })
  const fileRisultati = join(cartellaUscita, 'risultati.json')
  const risultati = existsSync(fileRisultati) ? JSON.parse(readFileSync(fileRisultati, 'utf8')) : { modelli, risposte: [] }
  const intestazioni = { apikey: anon, Authorization: `Bearer ${jwt}` }
  const funzione = `${url}/functions/v1/zorba`

  // Lo stato dice se il token è del curatore: gli altri non possono scegliere il modello
  const stato = await fetch(`${funzione}/stato`, { headers: intestazioni })
  if (!stato.ok) throw new Error(`stato: HTTP ${stato.status} (token scaduto?)`)
  if (!(await stato.json()).curatore) throw new Error('Il token non è del curatore: il modello scelto verrebbe ignorato.')

  const fotoCache = new Map()
  async function foto(rif) {
    if (!rif) return null
    if (fotoCache.has(rif)) return fotoCache.get(rif)
    let byte
    if (rif.startsWith('zorba-foto:')) {
      const r = await fetch(`${url}/storage/v1/object/authenticated/zorba-foto/${utente}/${rif.slice(11)}`, { headers: intestazioni })
      if (!r.ok) throw new Error(`foto ${rif}: HTTP ${r.status}`)
      byte = Buffer.from(await r.arrayBuffer())
    } else byte = readFileSync(rif)
    const b64 = byte.toString('base64')
    fotoCache.set(rif, b64)
    return b64
  }

  for (const [i, d] of domande.entries()) {
    for (const modello of modelli) {
      if (risultati.risposte.some(r => r.domanda === i && r.modello === modello && !r.errore)) continue
      process.stdout.write(`${i + 1}/${domande.length} ${modello}… `)
      const corpo = { nuovo: { tipo: d.tipo, ...(modello === 'predefinito' ? {} : { modello }) }, testo: d.testo ?? '' }
      const f = await foto(d.foto)
      if (f) corpo.foto = f
      const inizio = Date.now()
      const r = await fetch(funzione, { method: 'POST', headers: { ...intestazioni, 'Content-Type': 'application/json' }, body: JSON.stringify(corpo) })
      let esito
      if (!r.ok) esito = { errore: `HTTP ${r.status}: ${await r.text()}`, testo: '', filo: null }
      else esito = await leggiRisposta(r.body)
      const secondi = Math.round((Date.now() - inizio) / 100) / 10
      let consumo = null
      if (esito.filo) {
        const m = await fetch(`${url}/rest/v1/zorba_messaggi?filo_id=eq.${esito.filo}&ruolo=eq.zorba&select=modello_effettivo,costo_usd,input_token,output_token,cache_lettura_token,cache_scrittura_token,strumenti`, { headers: intestazioni })
        consumo = m.ok ? (await m.json())[0] ?? null : null
        if (!tieni) {
          const c = await fetch(`${funzione}/filo/${esito.filo}`, { method: 'DELETE', headers: intestazioni })
          if (!c.ok) console.error(`\n  filo ${esito.filo} non cancellato: HTTP ${c.status}`)
        }
      }
      risultati.risposte = risultati.risposte.filter(x => !(x.domanda === i && x.modello === modello))
      risultati.risposte.push({ domanda: i, tipo: d.tipo, testo_domanda: d.testo, con_foto: !!d.foto, modello,
        modello_effettivo: consumo?.modello_effettivo ?? null, risposta: esito.testo, errore: esito.errore, secondi,
        costo_usd: consumo?.costo_usd ?? null, token: consumo, strumenti: consumo?.strumenti ?? null })
      writeFileSync(fileRisultati, JSON.stringify(risultati, null, 2))
      console.log(esito.errore ? `errore (${esito.errore})` : `${secondi} s, ${consumo?.costo_usd ?? '?'} $`)
    }
  }
  scriviPagina(cartellaUscita, risultati)
  console.log(`\nFatto. Apri ${join(cartellaUscita, 'pagina.html')} nel browser per votare.`)
}

// Pagina autonoma per votare: per ogni domanda le risposte in ordine casuale, etichettate A, B, C…; i voti restano nel
// browser (localStorage) e si scaricano in JSON; «Svela» mostra i modelli e il riepilogo solo alla fine.
export function scriviPagina(cartella, risultati) {
  const domande = new Map()
  for (const r of risultati.risposte) {
    if (!domande.has(r.domanda)) domande.set(r.domanda, { tipo: r.tipo, testo: r.testo_domanda, con_foto: r.con_foto, risposte: [] })
    domande.get(r.domanda).risposte.push({ modello: r.modello_effettivo ?? r.modello, testo: r.errore ? `(Errore: ${r.errore})` : r.risposta, secondi: r.secondi, costo: r.costo_usd })
  }
  const dati = [...domande.entries()].sort((a, b) => a[0] - b[0]).map(([i, d]) => {
    const risposte = [...d.risposte]
    for (let k = risposte.length - 1; k > 0; k--) { const j = Math.floor(Math.random() * (k + 1)); [risposte[k], risposte[j]] = [risposte[j], risposte[k]] }
    return { id: i, ...d, risposte }
  })
  const html = `<!doctype html>
<html lang="it"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Prova alla cieca di Zorba</title>
<style>
:root{--cream:#faf7f2;--ink:#2f2a24;--sage:#7a9e82;--rose:#cc6e6e;--gold:#e0b84a;--line:#e4ddd2;--card:#fff}
@media (prefers-color-scheme:dark){:root{--cream:#1d1b18;--ink:#ece6dc;--line:#3a352f;--card:#26231f}}
body{margin:0;background:var(--cream);color:var(--ink);font:16px/1.55 system-ui,sans-serif}
main{max-width:1100px;margin:0 auto;padding:24px 16px 80px}
h1{font-size:1.6rem;margin:0 0 4px}.nota{opacity:.75;margin:0 0 24px}
section{border-top:1px solid var(--line);padding:20px 0}
.dom{font-weight:600}.tipo{font-size:.8rem;text-transform:uppercase;letter-spacing:.05em;color:var(--sage)}
.ris{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));margin:12px 0}
.r{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px;white-space:pre-wrap}
.r h3{margin:0 0 6px;font-size:1rem}.svelato{display:none;font-size:.85rem;color:var(--rose)}
body.svela .svelato{display:block}
.voto{display:flex;flex-wrap:wrap;gap:8px 16px;align-items:center}
textarea{width:100%;box-sizing:border-box;margin-top:8px;font:inherit;background:var(--card);color:inherit;border:1px solid var(--line);border-radius:8px;padding:6px}
button{font:inherit;padding:8px 14px;border-radius:8px;border:1px solid var(--sage);background:var(--sage);color:#fff;cursor:pointer;margin-right:8px}
#riepilogo{display:none;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 16px;margin-top:16px}
body.svela #riepilogo{display:block}
</style></head><body><main>
<h1>Prova alla cieca di Zorba</h1>
<p class="nota">Per ogni domanda scegli la risposta migliore (o «pari»). I voti restano in questo browser. Solo alla fine premi «Svela».</p>
<div id="domande"></div>
<p><button id="svela">Svela i modelli</button><button id="scarica">Scarica i voti</button></p>
<div id="riepilogo"></div>
</main><script>
const DATI = ${JSON.stringify(dati).replace(/</g, '\\u003c')};
const CHIAVE = 'zorba-prova-cieca';
let voti = {};
try { voti = JSON.parse(localStorage.getItem(CHIAVE) || '{}'); } catch {}
const salva = () => { try { localStorage.setItem(CHIAVE, JSON.stringify(voti)); } catch {} };
const lettera = i => String.fromCharCode(65 + i);
const el = document.getElementById('domande');
for (const d of DATI) {
  const s = document.createElement('section');
  const v = voti[d.id] || {};
  s.innerHTML = '<div class="tipo"></div><div class="dom"></div><div class="ris"></div><div class="voto"></div><textarea rows="2" placeholder="Nota (facoltativa): errori, cose inventate, tono…"></textarea>';
  s.querySelector('.tipo').textContent = d.tipo.replace('_', ' ') + (d.con_foto ? ' · con foto' : '');
  s.querySelector('.dom').textContent = (d.id + 1) + '. ' + (d.testo || '(solo foto)');
  d.risposte.forEach((r, i) => {
    const c = document.createElement('div'); c.className = 'r';
    const h = document.createElement('h3'); h.textContent = 'Risposta ' + lettera(i);
    const sv = document.createElement('div'); sv.className = 'svelato';
    sv.textContent = r.modello + ' · ' + r.secondi + ' s · ' + (r.costo == null ? '?' : (r.costo * 100).toFixed(2) + ' cent $');
    c.append(h, sv, document.createTextNode(r.testo || '(vuota)'));
    s.querySelector('.ris').append(c);
  });
  const vt = s.querySelector('.voto');
  [...d.risposte.map((_, i) => lettera(i)), 'pari'].forEach(o => {
    const l = document.createElement('label');
    l.innerHTML = '<input type="radio" name="v' + d.id + '"> ' + (o === 'pari' ? 'pari' : 'meglio ' + o);
    const inp = l.querySelector('input'); inp.checked = v.scelta === o;
    inp.onchange = () => { voti[d.id] = { ...(voti[d.id] || {}), scelta: o }; salva(); };
    vt.append(l);
  });
  const ta = s.querySelector('textarea'); ta.value = v.nota || '';
  ta.oninput = () => { voti[d.id] = { ...(voti[d.id] || {}), nota: ta.value }; salva(); };
  el.append(s);
}
function voteConModelli() {
  return DATI.map(d => { const v = voti[d.id] || {}; const i = v.scelta && v.scelta !== 'pari' ? v.scelta.charCodeAt(0) - 65 : -1;
    return { domanda: d.id + 1, tipo: d.tipo, scelta: v.scelta || null, vincitore: v.scelta === 'pari' ? 'pari' : (d.risposte[i]?.modello ?? null), nota: v.nota || '' }; });
}
document.getElementById('svela').onclick = () => {
  document.body.classList.add('svela');
  const conti = {}; let costi = {};
  for (const x of voteConModelli()) if (x.vincitore) conti[x.vincitore] = (conti[x.vincitore] || 0) + 1;
  for (const d of DATI) for (const r of d.risposte) { const c = costi[r.modello] ||= { n: 0, costo: 0, sec: 0 }; c.n++; c.costo += r.costo || 0; c.sec += r.secondi || 0; }
  const rp = document.getElementById('riepilogo'); rp.innerHTML = '<h2>Riepilogo</h2>';
  const ul = document.createElement('ul');
  for (const [m, c] of Object.entries(costi)) { const li = document.createElement('li');
    li.textContent = m + ': ' + (conti[m] || 0) + ' vittorie · costo medio ' + (c.costo / c.n * 100).toFixed(2) + ' cent $ · ' + (c.sec / c.n).toFixed(0) + ' s di media'; ul.append(li); }
  const li = document.createElement('li'); li.textContent = 'pari: ' + (conti.pari || 0); ul.append(li);
  rp.append(ul);
};
document.getElementById('scarica').onclick = () => {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([JSON.stringify(voteConModelli(), null, 2)], { type: 'application/json' }));
  a.download = 'voti-prova-cieca.json'; a.click();
};
</script></body></html>`
  writeFileSync(join(cartella, 'pagina.html'), html)
}

if (import.meta.url === `file://${process.argv[1]}`) main().catch(e => { console.error(`\n${e.message}`); process.exit(1) })
