<template>
  <IconDefs />
  <BootLogo />
  <NavBar />

  <!-- Banner token mancante (globale) -->
  <Transition name="page">
    <div v-if="!tokenOk && mostraBanner"
      style="position:sticky;top:0;z-index:100;background:var(--gold-pale);border-bottom:1px solid var(--gold-light);padding:10px 16px;display:flex;align-items:center;gap:10px;">
      <span style="font-size:14px;">🔑</span>
      <p style="font-size:12px;color:var(--gold-dark);flex:1;">Token GitHub non configurato — le modifiche non verranno salvate.</p>
      <RouterLink to="/agente" style="font-size:12px;font-weight:600;color:var(--gold-dark);text-decoration:none;">Configura →</RouterLink>
      <button @click="mostraBanner = false" style="background:none;border:none;color:var(--gold-dark);cursor:pointer;font-size:16px;line-height:1;">×</button>
    </div>
  </Transition>

  <main class="app-main" style="max-width:920px;margin:0 auto;padding:28px 16px 80px;position:relative;z-index:1;">
    <RouterView v-slot="{ Component }">
      <Transition name="page" mode="out-in">
        <component :is="Component" />
      </Transition>
    </RouterView>
  </main>
  <BottomNav />
  <StatusBar />
</template>

<script setup>
import IconDefs  from '@/components/IconDefs.vue'
import BootLogo  from '@/components/BootLogo.vue'
import NavBar    from '@/components/NavBar.vue'
import BottomNav from '@/components/BottomNav.vue'
import StatusBar from '@/components/StatusBar.vue'
import { ref, onMounted } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'

const store = useDatiStore()
const { isAutenticato } = useApi()

const tokenOk     = ref(isAutenticato())
const mostraBanner = ref(true)

onMounted(() => store.caricaTutto())
</script>

<style scoped>
/* Su mobile la statusbar si aggiunge sopra la BottomNav (vedi StatusBar.vue):
   serve più spazio in fondo alla pagina perché il contenuto non finisca dietro
   a entrambe. */
@media (max-width: 640px) {
  .app-main { padding-bottom: 128px; }
}
</style>
