<template>
  <IconDefs />

  <!-- Senza login: solo il form di accesso, senza il resto del vestito
       dell'app (nav, statusbar, banner) — la guardia del router (vedi
       router/index.js) tiene comunque bloccata ogni altra rotta. -->
  <main v-if="!caricamento && !utente" class="app-main-slogata">
    <RouterView />
  </main>

  <template v-else>
    <BootLogo />
    <SideNav />
    <AppBar />

    <!-- Banner token mancante (globale) -->
    <Transition name="page">
      <div v-if="!tokenOk && mostraBanner"
        style="position:sticky;top:0;z-index:100;background:var(--gold-pale);border-bottom:1px solid var(--gold-light);padding:10px 16px;display:flex;align-items:center;gap:10px;">
        <Icon name="chiave" style="width:16px;height:16px;flex-shrink:0;" />
        <p style="font-size:12px;color:var(--gold-dark);flex:1;">Token GitHub non configurato — le modifiche non verranno salvate.</p>
        <RouterLink to="/agente" style="font-size:12px;font-weight:600;color:var(--gold-dark);text-decoration:none;">Configura →</RouterLink>
        <button @click="mostraBanner = false" style="background:none;border:none;color:var(--gold-dark);cursor:pointer;font-size:16px;line-height:1;">×</button>
      </div>
    </Transition>

    <main class="app-main">
      <RouterView v-slot="{ Component }">
        <Transition name="page" mode="out-in">
          <component :is="Component" />
        </Transition>
      </RouterView>
    </main>
    <BottomNav />
    <StatusBar />
  </template>
</template>

<script setup>
import IconDefs  from '@/components/IconDefs.vue'
import BootLogo  from '@/components/BootLogo.vue'
import SideNav   from '@/components/SideNav.vue'
import AppBar    from '@/components/AppBar.vue'
import BottomNav from '@/components/BottomNav.vue'
import StatusBar from '@/components/StatusBar.vue'
import Icon      from '@/components/Icon.vue'
import { ref, onMounted, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { useAuth } from '@/composables/useAuth'

const store = useDatiStore()
const { isAutenticato } = useApi()
const { utente, caricamento } = useAuth()

const tokenOk     = ref(isAutenticato())
const mostraBanner = ref(true)

// Zone/sottozone/piante (Fase 5) vivono nello store Pinia, che App.vue carica
// una sola volta con caricaTutto() — ma App.vue non fa remount quando un
// utente si scollega e un altro accede nella stessa tab (SPA): senza questo
// watch, i dati del primo utente resterebbero visibili (e scrivibili, es.
// zona_id di una zona del primo utente) al secondo.
//
// idUtenteCaricato va catturato SOLO dopo che il caricamento iniziale è
// completato, non subito in setup(): a quel punto utente.value è sempre
// null (la sessione arriva da un await su localStorage, ancora in corso),
// non un valore "reale" che poi non cambia. Catturarlo comunque e registrare
// il watch subito produceva un doppio caricamento a ogni apertura dell'app
// già autenticata: quando la sessione si risolveva (pochi millisecondi
// dopo), il watch la vedeva come un cambio null→id e rilanciava
// store.aggiorna() in parallelo al caricaTutto() dell'onMounted già in
// corso. Registrando il watch qui sotto, dopo l'await, i due non corrono
// mai insieme.
let idUtenteCaricato = null

onMounted(async () => {
  await store.caricaTutto()
  idUtenteCaricato = utente.value?.id ?? null

  // Confrontiamo solo l'id (stringa primitiva), non l'intero oggetto utente:
  // onAuthStateChange riemette un nuovo oggetto anche per eventi che non
  // cambiano l'identità (es. TOKEN_REFRESHED) — guardare l'id evita di
  // ricaricare lo store per un utente che in realtà non è cambiato.
  watch(() => utente.value?.id, (nuovoId) => {
    const id = nuovoId ?? null
    if (id === idUtenteCaricato) return
    idUtenteCaricato = id
    store.aggiorna()
  })
})
</script>

<style scoped>
.app-main-slogata {
  min-height: 100vh;
  display: flex; align-items: center; justify-content: center;
  padding: 24px 16px;
}
</style>

<style scoped>
.app-main {
  max-width: 920px;
  margin: 0 auto;
  padding: 28px 16px 80px;
  position: relative;
  z-index: 1;
}

/* Su mobile la statusbar si aggiunge sopra la BottomNav (vedi StatusBar.vue):
   serve più spazio in fondo alla pagina perché il contenuto non finisca dietro
   a entrambe. */
@media (max-width: 640px) {
  .app-main { padding-bottom: 128px; }
}

/* Da 640px in su la sidebar è fissa a sinistra (200px): il contenuto le sta
   accanto e resta centrato nello spazio rimanente. */
@media (min-width: 640px) {
  .app-main {
    margin-left: 200px;
    margin-right: auto;
    padding-top: 20px;
  }
}
</style>
