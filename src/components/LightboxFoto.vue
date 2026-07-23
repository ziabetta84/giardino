<template>
  <Teleport to="body">
    <div v-if="foto" @click.self="$emit('chiudi')"
      style="position:fixed;inset:0;z-index:300;background:rgba(0,0,0,0.94);display:flex;flex-direction:column;align-items:center;justify-content:center;">

      <!-- Header -->
      <div style="position:absolute;top:0;left:0;right:0;padding:14px 16px;display:flex;align-items:center;gap:10px;">
        <span style="font-size:13px;font-weight:600;color:rgba(255,255,255,0.9);flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ titolo }}</span>
        <span style="font-size:11px;color:rgba(255,255,255,0.5);">{{ foto.dataEstesa }}</span>
        <button @click="$emit('elimina')" aria-label="Elimina foto" title="Elimina foto"
          style="background:rgba(255,255,255,0.12);border:none;border-radius:50%;width:32px;height:32px;color:white;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="3 6 5 6 21 6"></polyline>
            <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"></path>
            <path d="M10 11v6"></path>
            <path d="M14 11v6"></path>
            <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"></path>
          </svg>
        </button>
        <button @click="$emit('chiudi')" aria-label="Chiudi"
          style="background:rgba(255,255,255,0.12);border:none;border-radius:50%;width:32px;height:32px;color:white;font-size:18px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;">×</button>
      </div>

      <!-- Immagine -->
      <img :src="foto.url" :alt="foto.nome"
        style="max-width:100%;max-height:calc(100vh - 100px);object-fit:contain;border-radius:8px;padding:56px 8px 44px;">

      <!-- Navigazione prev/next -->
      <button v-if="haPrecedente" @click="$emit('naviga', -1)" aria-label="Foto precedente"
        style="position:absolute;left:8px;top:50%;transform:translateY(-50%);background:rgba(255,255,255,0.12);border:none;border-radius:50%;width:40px;height:40px;color:white;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;">‹</button>
      <button v-if="haSuccessivo" @click="$emit('naviga', 1)" aria-label="Foto successiva"
        style="position:absolute;right:8px;top:50%;transform:translateY(-50%);background:rgba(255,255,255,0.12);border:none;border-radius:50%;width:40px;height:40px;color:white;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;">›</button>

      <!-- Contatore -->
      <div v-if="indice != null && totale != null" style="position:absolute;bottom:14px;left:0;right:0;text-align:center;">
        <span style="font-size:11px;color:rgba(255,255,255,0.4);">{{ indice + 1 }} / {{ totale }}</span>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
// Lightbox condiviso tra GalleryView.vue e PiantaView.vue: mostra una foto a
// piena pagina con navigazione prev/next ed eliminazione. Non contiene una
// propria conferma di eliminazione: emette solo "elimina" e lascia che il
// chiamante gestisca ModalConferma, come fanno già tutti gli altri flussi di
// cancellazione dell'app (nessun pattern nuovo da imparare).
defineProps({
  foto:         { type: Object,  default: null },
  titolo:       { type: String,  default: '' },
  haPrecedente: { type: Boolean, default: false },
  haSuccessivo: { type: Boolean, default: false },
  indice:       { type: Number,  default: null },
  totale:       { type: Number,  default: null },
})
defineEmits(['chiudi', 'naviga', 'elimina'])
</script>
