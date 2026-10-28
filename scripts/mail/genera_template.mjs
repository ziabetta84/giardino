// Genera i template delle mail di Supabase Auth in supabase/templates/.
// I testi sono qui, l'impaginazione è una sola (pagina()): modificare questo
// file e rilanciare `node scripts/mail/genera_template.mjs`, mai gli .html a mano.
// Le variabili {{ ... }} sono di Supabase (Go template) e restano come sono.
import { writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const cartella = join(dirname(fileURLToPath(import.meta.url)), '../../supabase/templates')

// Palette dell'app (src/assets/main.css), tema chiaro: le mail non seguono il tema scuro.
const c = {
  cream: '#faf7f2', carta: '#ffffff', bordo: '#ece5d8',
  ink: '#2a2218', inkMid: '#5a4e3e', inkSoft: '#9a8e7e',
  sageDark: '#5a7e62', gold: '#e0b84a',
}
const titoli = "Georgia, 'Times New Roman', serif"
const testo = "'DM Sans', Helvetica, Arial, sans-serif"

const saluto = '{{ if .Data.nome }}Ciao {{ .Data.nome }},{{ else }}Ciao,{{ end }}'

function pulsante(href, etichetta) {
  return `<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:28px 0 8px">
              <tr><td style="border-radius:999px;background:${c.sageDark}">
                <a href="${href}" style="display:inline-block;padding:14px 28px;font-family:${testo};font-size:16px;font-weight:700;color:#ffffff;text-decoration:none;border-radius:999px">${etichetta}</a>
              </td></tr>
            </table>`
}

function linkDiRiserva(href) {
  return `<p style="margin:16px 0 0;font-size:13px;line-height:1.5;color:${c.inkSoft}">Se il pulsante non funziona, copia questo indirizzo nel browser:<br><a href="${href}" style="color:${c.sageDark};word-break:break-all">${href}</a></p>`
}

function codice(token) {
  return `<p style="margin:24px 0 8px;font-family:${titoli};font-size:34px;letter-spacing:6px;color:${c.ink}">${token}</p>`
}

function pagina({ titolo, anteprima, corpo, nota }) {
  return `<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<title>${titolo}</title>
</head>
<body style="margin:0;padding:0;background:${c.cream}">
<div style="display:none;max-height:0;overflow:hidden;opacity:0">${anteprima}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:${c.cream}">
  <tr><td align="center" style="padding:32px 16px">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px">
      <tr><td style="padding:0 8px 20px;font-family:${titoli};font-size:20px;color:${c.sageDark}">
        <img src="{{ .SiteURL }}/apple-touch-icon.png" width="36" height="36" alt="" style="vertical-align:middle;border-radius:8px;margin-right:10px">Zorba in giardino
      </td></tr>
      <tr><td style="background:${c.carta};border:1px solid ${c.bordo};border-radius:16px;padding:32px 28px;font-family:${testo};font-size:16px;line-height:1.6;color:${c.ink}">
            <h1 style="margin:0 0 16px;font-family:${titoli};font-size:26px;font-weight:600;line-height:1.25;color:${c.ink}">${titolo}</h1>
            ${corpo}
      </td></tr>
      <tr><td style="padding:20px 8px 0;font-family:${testo};font-size:13px;line-height:1.5;color:${c.inkMid}">
        ${nota}
      </td></tr>
      <tr><td style="padding:12px 8px 0;font-family:${testo};font-size:12px;color:${c.inkSoft}">
        Zorba in giardino &middot; <a href="{{ .SiteURL }}" style="color:${c.inkSoft}">zorbaingiardino.app</a>
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>
`
}

const p = (t) => `<p style="margin:0 0 12px">${t}</p>`
const url = '{{ .ConfirmationURL }}'

// chiave = nome del template in Supabase (mailer_templates_<chiave>_content)
const template = {
  confirmation: {
    oggetto: 'Conferma la tua email e si entra in giardino 🌱',
    titolo: 'Manca un passo, poi si entra',
    anteprima: 'Conferma il tuo indirizzo per aprire il giardino.',
    corpo: p(`${saluto} sono Zorba. Prima di aprirti il cancello mi serve sapere che questo indirizzo è davvero tuo: basta un tocco qui sotto.`)
      + pulsante(url, 'Conferma la mia email') + linkDiRiserva(url),
    nota: 'Il link si usa una volta sola e dura poco: se è scaduto, chiedine un altro dalla pagina di accesso. Se la registrazione non l\'hai chiesta tu, ignora questa mail: senza conferma l\'account non si attiva.',
  },
  recovery: {
    oggetto: 'Una password nuova per Zorba in giardino',
    titolo: 'Scegliamo una password nuova',
    anteprima: 'Il link per cambiare la password del tuo giardino.',
    corpo: p(`${saluto} è arrivata una richiesta di cambiare la password di {{ .Email }}. Tocca il pulsante e scegline una nuova: le tue piante restano dove sono.`)
      + pulsante(url, 'Scegli la nuova password') + linkDiRiserva(url),
    nota: 'Se non l\'hai chiesto tu, ignora questa mail: la password resta quella di prima.',
  },
  magic_link: {
    oggetto: 'Il tuo link per entrare in giardino',
    titolo: 'Entra senza password',
    anteprima: 'Un link per entrare, valido una volta sola.',
    corpo: p(`${saluto} ecco il link per entrare nel tuo giardino senza digitare la password.`)
      + pulsante(url, 'Entra in giardino') + linkDiRiserva(url),
    nota: 'Il link si usa una volta sola e dura poco. Se non l\'hai chiesto tu, ignora questa mail: senza un tocco sul link non entra nessuno.',
  },
  email_change: {
    oggetto: 'Conferma il nuovo indirizzo email',
    titolo: 'Cambio di indirizzo',
    anteprima: 'Conferma lo spostamento dell\'account sul nuovo indirizzo.',
    corpo: p(`${saluto} è stato chiesto di spostare il tuo account da {{ .Email }} a {{ .NewEmail }}. Conferma con il pulsante qui sotto.`)
      + pulsante(url, 'Conferma il cambio') + linkDiRiserva(url),
    nota: 'Questa mail arriva a entrambi gli indirizzi, e il cambio vale solo quando li confermi tutti e due. Se non l\'hai chiesto tu, ignorala e l\'indirizzo resta quello di prima.',
  },
  invite: {
    oggetto: 'Ti aspetto in giardino',
    titolo: 'Un invito da Zorba',
    anteprima: 'Hai un invito per Zorba in giardino.',
    corpo: p('Ciao, sono Zorba. Hai ricevuto un invito a Zorba in giardino: l\'app che ricorda annaffiature, concimi e potature, e a cui puoi chiedere quando una pianta ti preoccupa.')
      + pulsante(url, 'Accetta l\'invito') + linkDiRiserva(url),
    nota: 'Se non aspettavi questo invito, ignora la mail: senza un tocco sul link non viene creato nessun account.',
  },
  reauthentication: {
    oggetto: '{{ .Token }} è il tuo codice per Zorba in giardino',
    titolo: 'Il tuo codice',
    anteprima: 'Il codice per confermare che sei tu.',
    corpo: p(`${saluto} per confermare che sei tu, scrivi questo codice nell'app:`) + codice('{{ .Token }}'),
    nota: 'Il codice dura poco. Se non l\'hai chiesto tu, non darlo a nessuno e cambia la password.',
  },
  password_changed_notification: {
    oggetto: 'La password di Zorba in giardino è cambiata',
    titolo: 'Password cambiata',
    anteprima: 'La password del tuo account è appena cambiata.',
    corpo: p(`${saluto} la password di {{ .Email }} è appena cambiata. Se l'hai cambiata tu, non c'è altro da fare.`)
      + p('Se non è opera tua, recuperala subito dalla pagina di accesso con «Password dimenticata».')
      + pulsante('{{ .SiteURL }}', 'Vai alla pagina di accesso'),
    nota: 'Per qualsiasi dubbio rispondi a questa mail.',
  },
  email_changed_notification: {
    oggetto: 'L\'indirizzo del tuo account è cambiato',
    titolo: 'Indirizzo cambiato',
    anteprima: 'Il tuo account usa ora un altro indirizzo email.',
    corpo: p(`${saluto} il tuo account di Zorba in giardino ora usa {{ .Email }} al posto di {{ .OldEmail }}. Se il cambio l'hai fatto tu, non c'è altro da fare.`),
    nota: 'Se non l\'hai chiesto tu, rispondi subito a questa mail.',
  },
}

const oggetti = {}
for (const [chiave, t] of Object.entries(template)) {
  writeFileSync(join(cartella, `${chiave}.html`), pagina(t))
  oggetti[chiave] = t.oggetto
}
writeFileSync(join(cartella, 'oggetti.json'), JSON.stringify(oggetti, null, 2) + '\n')
console.log(`${Object.keys(template).length} template scritti in ${cartella}`)
