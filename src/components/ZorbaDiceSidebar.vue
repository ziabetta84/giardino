<template>
  <aside v-if="utente" class="zds" aria-label="Storico di Zorba dice">
    <div class="zds__hd slabel">Zorba dice</div>

    <p v-if="caricamento" class="zds__stato">Carico lo storico…</p>

    <div v-else-if="richieste.length" class="feedlist">
      <RouterLink v-for="r in richieste" :key="r.id" class="feed zds__feed" :to="`/agente?id=${r.id}`">
        <span class="zds__ic"><Icon v-if="infoTipo(r.tipo).icon" :name="infoTipo(r.tipo).icon" /></span>
        <div class="feed__m">
          <div class="feed__n zds__titolo">{{ titoloRichiesta(r, store) }}</div>
          <div class="feed__d">
            <span v-if="r.stato === 'in_attesa'" class="badge badge-gold zds__badge">In attesa</span>
            <span v-else-if="r.stato === 'errore'" class="badge badge-warn zds__badge">Errore</span>
            {{ formatData(r.creata) }}
          </div>
        </div>
      </RouterLink>
    </div>

    <p v-else class="zds__stato">Nessuna richiesta ancora: chiedi un consiglio, identifica una specie, pianifica un progetto.</p>

    <RouterLink class="seeall" to="/agente">Vai a Zorba dice →</RouterLink>
  </aside>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useAuth } from '@/composables/useAuth'
import { infoTipo, titoloRichiesta, formatData, caricaRichiesteAgente } from '@/composables/useRichiesteAgente'
import Icon from '@/components/Icon.vue'

// Colonna fissa a destra, visibile solo quando c'è davvero spazio residuo
// oltre sidebar(200) + contenuto(920) — vedi il breakpoint gemello in
// App.vue (.app-main a ≥1440px) e il CSS qui sotto: nessun controllo per
// aprirla/chiuderla, appare solo dove non toglie mai spazio al contenuto
// principale (deciso in chat: "scegli l'approccio migliore").
const store = useDatiStore()
const { utente } = useAuth()

const raw = ref({})
const caricamento = ref(true)
let pollTimer = null

async function carica() {
  raw.value = await caricaRichiesteAgente()
  caricamento.value = false
}

// Le ultime 4, più recenti in cima — stesso ordinamento dello storico
// completo in AgenteView.vue, solo troncato. Non filtra per stato: una
// richiesta ancora "in_attesa" è un'informazione reale quanto una già
// risposta (badge dedicato, vedi template), nasconderla sarebbe un falso
// "tutto fatto".
const richieste = computed(() =>
  Object.entries(raw.value)
    .map(([id, r]) => ({ id, ...r }))
    .sort((a, b) => new Date(b.creata) - new Date(a.creata))
    .slice(0, 4)
)

onMounted(() => {
  carica()
  // Stesso intervallo di polling di AgenteView.vue: la sidebar può restare
  // montata per tutta la sessione (non ricompare ad ogni navigazione come la
  // view), quindi ha bisogno di un refresh proprio per non mostrare una
  // richiesta "in attesa" che altrove (AgenteView aperta in un'altra scheda,
  // o /zorbadice eseguito nel frattempo) è già stata risposta.
  pollTimer = setInterval(carica, 30000)
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
