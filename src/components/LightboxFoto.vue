<template>
  <Teleport to="body">
    <div v-if="foto" ref="box" role="dialog" aria-modal="true" :aria-label="titolo || 'Foto'" tabindex="-1"
      class="lightbox"
      @click.self="$emit('chiudi')" @keydown.esc="$emit('chiudi')"
      @keydown.left="haPrecedente && $emit('naviga', -1)" @keydown.right="haSuccessivo && $emit('naviga', 1)">

      <!-- Header -->
      <div class="lightbox__hd">
        <span class="lightbox__titolo">{{ titolo }}</span>
        <span class="lightbox__data">{{ foto.dataEstesa }}</span>
        <button type="button" class="lightbox__btn" @click="$emit('elimina')" aria-label="Elimina foto" title="Elimina foto">
          <Icon name="cestino" />
        </button>
        <button type="button" class="lightbox__btn lightbox__btn--chiudi" @click="$emit('chiudi')" aria-label="Chiudi">×</button>
      </div>

      <!-- Immagine -->
      <img class="lightbox__img" :src="foto.url" :alt="foto.nome">

      <!-- Navigazione prev/next: stessa icona "back" del resto dell'app,
           ruotata 180° per "avanti" (vedi .wxrow__chev/.dest__chev/.zdice__chev). -->
      <button v-if="haPrecedente" type="button" class="lightbox__btn lightbox__nav lightbox__nav--prev"
        @click="$emit('naviga', -1)" aria-label="Foto precedente">
        <Icon name="back" />
      </button>
      <button v-if="haSuccessivo" type="button" class="lightbox__btn lightbox__nav lightbox__nav--next"
        @click="$emit('naviga', 1)" aria-label="Foto successiva">
        <Icon name="back" style="transform:rotate(180deg)" />
      </button>

      <!-- Contatore -->
      <div v-if="indice != null && totale != null" class="lightbox__contatore">
        <span>{{ indice + 1 }} / {{ totale }}</span>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue'
import Icon from './Icon.vue'

// Lightbox condiviso tra GalleryView.vue e PiantaView.vue: mostra una foto a
// piena pagina con navigazione prev/next ed eliminazione. Non contiene una
// propria conferma di eliminazione: emette solo "elimina" e lascia che il
// chiamante gestisca ModalConferma, come fanno già tutti gli altri flussi di
// cancellazione dell'app (nessun pattern nuovo da imparare).
const props = defineProps({
  foto:         { type: Object,  default: null },
  titolo:       { type: String,  default: '' },
  haPrecedente: { type: Boolean, default: false },
  haSuccessivo: { type: Boolean, default: false },
  indice:       { type: Number,  default: null },
  totale:       { type: Number,  default: null },
})
defineEmits(['chiudi', 'naviga', 'elimina'])

// Stesso pattern di ModalConferma.vue: sposta il focus sul contenitore
// all'apertura (altrimenti resta sulla miniatura sottostante, invisibile
// dietro l'overlay), cosicché Tab/Esc/frecce funzionino da subito invece di
// dover prima raggiungere il lightbox a tentoni. Si rifocalizza anche ad
// ogni prev/next: è quello che tiene le frecce da tastiera utilizzabili in
// sequenza senza dover ritornare sul contenitore a mano.
const box = ref(null)
watch(() => props.foto, (v) => {
  if (v) nextTick(() => box.value?.focus())
})
</script>

<style scoped>
.lightbox {
  position: fixed; inset: 0; z-index: 300;
  background: rgba(0, 0, 0, 0.94);
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  outline: none;
}

.lightbox__hd {
  position: absolute; top: 0; left: 0; right: 0;
  padding: 14px 16px; display: flex; align-items: center; gap: 10px;
}
.lightbox__titolo {
  font-size: 13px; font-weight: 600; color: rgba(255, 255, 255, 0.9);
  flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.lightbox__data { font-size: 11px; color: rgba(255, 255, 255, 0.5); }

/* 44px minimo di tocco (era 32-40px): stesso standard di .btn/.care-act
   adottato nel resto dell'app in questa stessa sessione di lavoro. */
.lightbox__btn {
  background: rgba(255, 255, 255, 0.12); border: none; border-radius: 50%;
  width: 44px; height: 44px; color: white; cursor: pointer; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  transition: background var(--motion-quick) var(--ease-standard),
              transform var(--motion-quick) var(--ease-standard);
}
.lightbox__btn:hover { background: rgba(255, 255, 255, 0.2); }
.lightbox__btn:active { transform: scale(0.92); }
.lightbox__btn :deep(svg) { width: 18px; height: 18px; }
.lightbox__btn--chiudi { font-size: 17px; line-height: 1; }

.lightbox__img {
  max-width: 100%; max-height: calc(100vh - 100px); object-fit: contain;
  border-radius: 8px; padding: 56px 8px 44px;
}

.lightbox__nav { position: absolute; top: 50%; transform: translateY(-50%); }
.lightbox__nav:active { transform: translateY(-50%) scale(0.92); }
.lightbox__nav--prev { left: 8px; }
.lightbox__nav--next { right: 8px; }

.lightbox__contatore {
  position: absolute; bottom: 14px; left: 0; right: 0; text-align: center;
  font-size: 11px; color: rgba(255, 255, 255, 0.5);
}
</style>
