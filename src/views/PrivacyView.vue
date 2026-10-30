<template>
  <!-- Informativa privacy (art. 13 GDPR) e note legali. Si legge anche senza
       account: la guardia del router la lascia passare, perché va letta
       prima di registrarsi. I dati del titolare sono in TITOLARE, qui sotto
       nello script: si cambiano lì, non nel testo. -->
  <article class="legale">
    <button type="button" class="back-link legale__indietro" @click="indietro">
      <Icon name="back" style="width:14px;height:14px;flex-shrink:0;" />Indietro
    </button>

    <h1 class="page-title">Privacy e note legali</h1>
    <p class="legale__agg">Aggiornata il {{ AGGIORNATA_IL }}</p>

    <p class="legale__intro">
      Zorba in giardino è un'app per tenere il diario del proprio giardino. Qui trovi, senza
      giri di parole, quali dati raccoglie, a che cosa servono, a chi passano e come
      riprenderteli.
    </p>

    <section class="form-card legale__sezione" aria-labelledby="p-titolare">
      <h2 id="p-titolare" class="slabel">Chi tratta i tuoi dati</h2>
      <p>
        Titolare del trattamento è <strong>{{ TITOLARE.nome }}</strong><template v-if="TITOLARE.indirizzo">, {{ TITOLARE.indirizzo }}</template><template v-if="TITOLARE.partitaIva"> (P.IVA {{ TITOLARE.partitaIva }})</template>.
        Per qualsiasi domanda sui tuoi dati scrivi a
        <a :href="`mailto:${TITOLARE.email}`">{{ TITOLARE.email }}</a>.
      </p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-dati">
      <h2 id="p-dati" class="slabel">Quali dati e perché</h2>
      <dl class="legale__voci">
        <dt>Account</dt>
        <dd>
          Email, nome con cui ti chiama Zorba e password (conservata solo in forma cifrata, nessuno
          può leggerla). Servono a farti entrare e a tenere separato il tuo giardino da quello degli
          altri. <em>Base giuridica: esecuzione del servizio che chiedi registrandoti.</em>
        </dd>

        <dt>Il tuo giardino</dt>
        <dd>
          Zone, piante, cure registrate, concimi, progetti e la posizione del giardino (coordinate e
          altitudine), che serve per il meteo e la zona climatica. Li inserisci tu e li vedi solo
          tu. <em>Base giuridica: esecuzione del servizio.</em>
        </dd>

        <dt>Foto</dt>
        <dd>
          Le foto che carichi nella galleria o mandi a Zorba. Prima del caricamento l'app le
          ridisegna e così toglie i dati nascosti del file, compresa la posizione GPS dello scatto;
          della galleria tiene solo la data in cui è stata scattata.
          Restano in uno spazio privato, visibile solo a te. <em>Base giuridica: esecuzione del
          servizio.</em>
        </dd>

        <dt>Conversazioni con Zorba</dt>
        <dd>
          Le domande, le foto e le risposte, i voti che dai alle risposte e, per ogni risposta, il
          suo costo, per rispettare i limiti di utilizzo. <em>Base giuridica: esecuzione del
          servizio.</em>
        </dd>

        <dt>Dati tecnici</dt>
        <dd>
          Quando usi l'app, i fornitori che la ospitano registrano per breve tempo l'indirizzo IP e
          i dati della richiesta, per farla funzionare e difenderla dagli abusi. La verifica
          anti-robot di accesso e registrazione fa lo stesso. <em>Base giuridica: legittimo
          interesse alla sicurezza del servizio.</em>
        </dd>
      </dl>
      <p>
        Non c'è pubblicità, non ci sono statistiche di visita né profilazione, e i tuoi dati non
        vengono venduti né usati per addestrare intelligenze artificiali.
      </p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-cookie">
      <h2 id="p-cookie" class="slabel">Cookie e memoria del browser</h2>
      <p>
        L'app non usa cookie di profilazione. Salva nel browser solo ciò che serve a funzionare:
        la sessione di accesso, il tema chiaro o scuro, l'avanzamento della guida dei primi passi
        e una copia dei dati per usare l'app senza rete. Uscendo dall'account la copia dei dati
        viene cancellata. Per questi strumenti tecnici la legge non richiede un consenso, per
        questo non vedi banner.
      </p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-fornitori">
      <h2 id="p-fornitori" class="slabel">A chi passano</h2>
      <p>I dati non vengono diffusi. Li ricevono solo i fornitori che fanno funzionare l'app, ciascuno per la sua parte:</p>
      <ul class="legale__elenco">
        <li><strong>Supabase</strong>: database, account e foto, su server nell'Unione europea (Stoccolma).</li>
        <li><strong>Cloudflare</strong>: ospita l'app e fa la verifica anti-robot (Turnstile).</li>
        <li><strong>Anthropic</strong>: il modello di intelligenza artificiale che scrive le risposte di Zorba. Riceve la domanda, le eventuali foto e i dati del giardino che servono a rispondere.</li>
        <li><strong>Pl@ntNet</strong>: riconosce le piante dalle foto inviate a Zorba per un'identificazione o una diagnosi.</li>
        <li><strong>Brevo</strong>: spedisce le mail dell'account (conferma, recupero password).</li>
        <li><strong>Open-Meteo</strong> e <strong>OpenStreetMap</strong>: ricevono le coordinate del giardino o l'indirizzo cercato, per il meteo e la posizione.</li>
        <li><strong>Ko-fi</strong>: se scegli di sostenere il progetto, il contributo avviene sul loro sito, con la loro informativa. L'app non vede né conserva i dati di pagamento.</li>
      </ul>
      <p>
        Alcuni di questi fornitori (Anthropic e Cloudflare) hanno sede negli Stati Uniti. Il
        trasferimento avviene con le garanzie previste dal GDPR: il Data Privacy Framework tra UE
        e Stati Uniti o le clausole contrattuali standard approvate dalla Commissione europea.
      </p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-tempi">
      <h2 id="p-tempi" class="slabel">Per quanto tempo</h2>
      <p>
        I dati restano finché hai l'account. Puoi cancellare quando vuoi una singola pianta, foto o
        conversazione; eliminando l'account si cancellano tutti, foto comprese. Le copie di
        sicurezza del database vengono distrutte entro {{ BACKUP_GIORNI }} giorni.
      </p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-diritti">
      <h2 id="p-diritti" class="slabel">I tuoi diritti</h2>
      <p>
        Puoi chiedere di vedere i tuoi dati, correggerli, riceverne una copia, limitarne l'uso,
        opporti al trattamento basato sul legittimo interesse o farli cancellare. Molte cose puoi
        farle direttamente nell'app; per il resto scrivi a
        <a :href="`mailto:${TITOLARE.email}`">{{ TITOLARE.email }}</a>: la risposta arriva entro un
        mese. L'account si elimina in fondo alla pagina Account. Se pensi che i tuoi
        dati siano trattati male puoi rivolgerti al
        <a href="https://www.garanteprivacy.it" target="_blank" rel="noopener">Garante per la protezione dei dati personali</a>.
      </p>
      <p>L'app è pensata per chi ha almeno {{ ETA_MINIMA }} anni.</p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-consigli">
      <h2 id="p-consigli" class="slabel">I consigli di Zorba e delle schede</h2>
      <p>
        Le risposte di Zorba sono scritte da un'intelligenza artificiale e le schede delle piante
        vengono da cataloghi botanici. Sono indicazioni generali: possono contenere errori e non
        conoscono il tuo terreno come lo conosci tu. Non sostituiscono il parere di un agronomo o
        di un vivaista.
      </p>
      <p>
        Prima di usare un prodotto fitosanitario leggi sempre l'etichetta e rispetta le dosi e le
        norme sull'uso. Sulla tossicità delle piante per persone e animali, le schede non bastano:
        in caso di ingestione chiama un centro antiveleni o il veterinario.
      </p>
    </section>

    <section class="form-card legale__sezione" aria-labelledby="p-crediti">
      <h2 id="p-crediti" class="slabel">Crediti</h2>
      <p>
        Le foto delle schede indicano autore e licenza sotto ciascuna immagine. I dati di
        posizione sono © i contributori di OpenStreetMap, il meteo viene da Open-Meteo.
      </p>
    </section>

    <p class="legale__nota">
      Quando questa pagina cambia, cambia anche la data in cima; dei cambiamenti importanti ti
      avvisiamo nell'app.
    </p>
  </article>
</template>

<script setup>
import { useRouter } from 'vue-router'
import Icon from '@/components/Icon.vue'

// Dati del titolare: da completare con quelli veri prima del rilascio.
const TITOLARE = {
  nome: 'NOME E COGNOME',
  indirizzo: '',
  partitaIva: '',
  email: 'privacy@zorbaingiardino.app',
}
const AGGIORNATA_IL = '30 ottobre 2026'
const BACKUP_GIORNI = 30
const ETA_MINIMA = 14

const router = useRouter()
// Si arriva qui dalla registrazione o da Account: si torna da dove si
// veniva, e senza una pagina precedente (link aperto da solo) ad Account.
function indietro() {
  if (window.history.state?.back) router.back()
  else router.push({ name: 'account' })
}
</script>

<style scoped>
.legale { width: 100%; max-width: 640px; margin: 0 auto; align-self: flex-start; }
.legale__indietro { background: none; border: none; padding: 0; font: inherit; cursor: pointer; margin-bottom: 12px; }
.legale__agg { margin: 4px 0 16px; font-size: 12px; color: var(--ink-mid); }
.legale__intro { font-size: 14px; line-height: 1.6; color: var(--ink-mid); margin-bottom: 16px; text-wrap: pretty; }
.legale__sezione { margin-bottom: 12px; font-size: 14px; line-height: 1.6; color: var(--ink); }
.legale__sezione h2 { margin: 0 0 10px; }
.legale__sezione p { margin: 0 0 10px; text-wrap: pretty; }
.legale__sezione p:last-child { margin-bottom: 0; }
.legale__sezione a { color: var(--sage-ink); text-underline-offset: 3px; }
.legale__voci { margin: 0 0 10px; }
.legale__voci dt { font-weight: 600; margin-top: 10px; }
.legale__voci dt:first-child { margin-top: 0; }
.legale__voci dd { margin: 2px 0 0; color: var(--ink-mid); }
.legale__voci em { font-style: normal; font-size: 12px; color: var(--ink-mid); display: block; margin-top: 2px; }
.legale__elenco { margin: 0 0 10px; padding-left: 18px; }
.legale__elenco li { margin-bottom: 6px; }
.legale__nota { font-size: 12px; line-height: 1.5; color: var(--ink-mid); margin: 16px 0 24px; }
</style>
