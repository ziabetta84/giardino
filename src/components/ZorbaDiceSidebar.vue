<template>
  <aside v-if="utente" class="zds" aria-label="Storico di Zorba dice">
    <div class="zds__hd slabel">Zorba dice</div>

    <p v-if="caricamento" class="zds__stato">Carico lo storico…</p>

    <div v-else-if="fili.length" class="feedlist">
      <RouterLink v-for="f in fili" :key="f.id" class="feed zds__feed" :to="`/agente?filo=${f.id}`">
        <span class="zds__ic"><Icon v-if="infoTipo(f.tipo).icon" :name="infoTipo(f.tipo).icon" /></span>
        <div class="feed__m">
          <div class="feed__n zds__titolo">{{ titoloFilo(f, store) }}</div>
          <div class="feed__d">
            <span v-if="f.nuova_risposta" class="badge badge-gold zds__badge">Nuovo</span>
            <span v-else-if="f.segnalazione_stato === 'in_attesa'" class="badge badge-gold zds__badge">In attesa</span>
            {{ formatData(f.aggiornato) }}
          </div>
        </div>
      </RouterLink>
    </div>

    <p v-else class="zds__stato">Nessuna richiesta ancora: chiedi un consiglio, identifica una specie, pianifica un progetto.</p>

    <RouterLink class="seeall" to="/agente">Vai a Zorba dice →</RouterLink>
  </aside>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useAuth } from '@/composables/useAuth'
import { useZorba } from '@/composables/useZorba'
import { infoTipo, titoloFilo, formatData } from '@/composables/useRichiesteAgente'
import Icon from '@/components/Icon.vue'

// Colonna fissa a destra, visibile solo quando c'è davvero spazio residuo
// oltre sidebar(200) + contenuto(920) — vedi il breakpoint gemello in
// App.vue (.app-main a ≥1440px) e il CSS qui sotto: nessun controllo per
// aprirla/chiuderla, appare solo dove non toglie mai spazio al contenuto
// principale (deciso in chat: "scegli l'approccio migliore").
const store = useDatiStore()
const { utente } = useAuth()
const zorba = useZorba()

const fili = ref([])
const caricamento = ref(true)
let pollTimer = null

async function carica() {
  try { fili.value = (await zorba.caricaFili()).slice(0, 4) } catch { /* offline: resta l'ultimo elenco */ }
  caricamento.value = false
}

onMounted(() => {
  carica()
  // La sidebar può restare montata per tutta la sessione: il polling serve a mostrare
  // le risposte arrivate in un'altra scheda o su un altro dispositivo.
  pollTimer = setInterval(carica, 60000)
})
onUnmounted(() => { if (pollTimer) clearInterval(pollTimer) })
</script>

<style scoped>
.zds { display: none; }

@media (min-width: 1440px) {
  .zds {
    display: flex; flex-direction: column;
    position: fixed; top: 0; bottom: 0; z-index: 40;
    right: max(16px, (100vw - 1420px) / 2);
    width: 260px;
    padding: 20px 4px 24px 16px;
    overflow-y: auto;
  }
}

.zds__hd { margin-bottom: 8px; }
.zds__stato { font: 400 12.5px/1.5 var(--font-sans); color: var(--ink-soft); padding: 4px 2px 12px; }

.zds__feed { text-decoration: none; }
.zds__ic { width: 22px; height: 22px; flex: none; color: var(--ink-soft); }
.zds__ic svg { width: 100%; height: 100%; }
.zds__titolo {
  display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical;
  overflow: hidden;
}
.zds__badge { margin-right: 6px; padding: 2px 7px; }

.zds .seeall { margin-top: 4px; }
</style>
