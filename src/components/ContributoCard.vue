<template>
  <!-- Biglietto di Zorba per il contributo volontario (Ko-fi). Usato come
       card in AccountView e, con `invito`, come passo subito dopo la
       registrazione, prima della schermata «Controlla la posta». -->
  <section class="contributo" :class="{ 'contributo--invito': invito }" :aria-labelledby="idTitolo">
    <div class="contributo__hd">
      <ZorbaLogo mini />
      <h2 :id="idTitolo" class="contributo__titolo">Sostieni il lavoro di Zorba in giardino</h2>
    </div>
    <p class="contributo__testo">
      Con un piccolo contributo aiuti Zorba a fare il suo lavoro
      sempre meglio, un aggiornamento alla volta.
    </p>
    <a :href="linkContributo" target="_blank" rel="noopener noreferrer" class="contributo__btn"
      aria-label="Dona un ciuffo d'erba gatta: contributo su Ko-fi (si apre in una nuova scheda)"
      @click="emit('scelta', 'dona')">
      <Icon name="erba-gatta" class="contributo__icona" />
      Dona un ciuffo d'erba gatta
    </a>
    <button v-if="invito" type="button" class="contributo__no" @click="emit('scelta', 'non_ora')">
      {{ testoNo }}
    </button>
    <p class="contributo__nota">
      <span>Su Ko-fi, con carta o PayPal: scegli tu quanto.</span>
      <span>Non è un abbonamento, solo un gesto gentile.</span>
      <span v-if="invito">Ritrovi questo angolo in Account, quando vuoi.</span>
    </p>
  </section>
</template>

<script setup>
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import { linkContributo } from '@/composables/useContributo'

const props = defineProps({
  invito: { type: Boolean, default: false },
  testoNo: { type: String, default: 'Non ora' },
})
const emit = defineEmits(['scelta'])
const idTitolo = props.invito ? 'contributo-titolo-invito' : 'contributo-titolo'
</script>

<style scoped>
/* Un biglietto di Zorba dentro il taccuino: alone ad acquerello in oro
   (rilievo positivo) e un'annotazione a mano in Caveat. Il bottone è
   secondario di proposito: non è un salvataggio, non prende il salvia pieno. */
.contributo { position: relative; overflow: hidden; }
.contributo::before {
  content: '';
  position: absolute; left: -60px; bottom: -80px;
  width: 220px; height: 200px;
  background: radial-gradient(circle, rgba(224,184,74,0.16) 0%, rgba(224,184,74,0.06) 50%, transparent 74%);
  pointer-events: none;
}
.contributo--invito::before { display: none; }
.contributo > * { position: relative; }
.contributo__hd { display: flex; align-items: center; flex-wrap: wrap; gap: 4px 10px; margin-bottom: 10px; }
.contributo :deep(.zorba-mini) { width: 26px; height: 26px; }
.contributo--invito :deep(.zorba-mini) { width: 32px; height: 32px; }
.contributo__titolo { font: 600 16px/1.2 var(--font-display); color: var(--ink); margin: 0; max-width: calc(100% - 42px); }
.contributo--invito .contributo__titolo { font-size: 20px; }
.contributo__testo { font-size: 13px; color: var(--ink-mid); line-height: 1.55; max-width: 60ch; }
.contributo--invito .contributo__testo { font-size: 14px; }
.contributo__btn {
  display: flex; align-items: center; justify-content: center; gap: 8px;
  min-height: 44px; margin-top: 16px; padding: 10px 18px;
  border-radius: 12px; border: 1px solid var(--sage-light);
  background: var(--white); color: var(--sage-ink);
  font: 600 13px/1 var(--font-sans); text-decoration: none;
  box-shadow: 0 2px 10px rgba(42,34,24,0.05);
  transition: background var(--motion-quick) var(--ease-standard),
              border-color var(--motion-quick) var(--ease-standard),
              box-shadow var(--motion-quick) var(--ease-standard),
              transform var(--motion-quick) var(--ease-standard);
}
.contributo__btn:hover { background: var(--sage-pale); border-color: var(--sage); transform: translateY(-1px); box-shadow: 0 6px 18px rgba(42,34,24,0.09); }
.contributo__btn:active { transform: scale(0.97); }
.contributo__btn:focus-visible, .contributo__no:focus-visible { outline: none; border-color: var(--gold); box-shadow: 0 0 0 3px rgba(224,184,74,0.25); }
.contributo__icona { width: 24px; height: 24px; flex: none; }
/* «Non ora»: stesso peso visivo del sì, per non spingere la scelta. */
.contributo__no {
  display: block; width: 100%; min-height: 44px; margin-top: 8px; padding: 10px 18px;
  border-radius: 12px; border: 1px solid transparent; background: var(--cream-dark);
  color: var(--ink-mid); font: 600 13px/1 var(--font-sans); cursor: pointer;
  transition: background var(--motion-quick) var(--ease-standard);
}
.contributo__no:hover { background: color-mix(in srgb, var(--cream-dark) 85%, var(--ink) 15%); }
.contributo__no:active { transform: scale(0.97); }
.contributo__nota { font-size: 12px; color: var(--ink-mid); line-height: 1.5; margin-top: 10px; text-align: center; }
.contributo__nota span { display: block; }
</style>
