<template>
  <div>
    <!-- Back -->
    <RouterLink to="/piante" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Piante
    </RouterLink>

    <!-- Skeleton -->
    <template v-if="store.loading">
      <div class="skeleton" style="height:28px;width:60%;margin-bottom:8px;"></div>
      <div class="skeleton" style="height:14px;width:40%;margin-bottom:24px;"></div>
      <div class="skeleton" style="height:100px;border-radius:16px;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:80px;border-radius:16px;"></div>
    </template>

    <template v-else-if="!pianta">
      <div style="text-align:center;padding:60px 0;color:var(--ink-faint);">
        <div style="font-size:40px;margin-bottom:12px;">🌾</div>
        <p>Pianta non trovata</p>
      </div>
    </template>

    <template v-else>
      <!-- Header -->
      <div style="display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:20px;gap:12px;">
        <div>
          <h1 class="title-display gradient-title" style="font-size:1.7rem;font-weight:800;line-height:1.2;">
            {{ specie?.nome ?? pianta.specie }}
          </h1>
          <p style="font-size:13px;color:var(--ink-soft);margin-top:4px;font-style:italic;">
            {{ specie?.specie }}
          </p>
          <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:8px;">
            <span class="badge badge-gold">{{ pianta.zona }}</span>
            <span v-if="pianta.sottozona" class="badge" style="background:var(--sage-pale);color:var(--sage-dark);">{{ pianta.sottozona }}</span>
          </div>
        </div>
        <RouterLink :to="`/piante/${route.params.id}/modifica`" class="btn btn-ghost"
          style="flex-shrink:0;padding:8px 14px;font-size:13px;">✏️ Modifica</RouterLink>
      </div>

      <!-- Urgenze -->
      <div v-if="cureUrgenti.length" class="card" style="padding:14px 16px;border-color:var(--rose-light);background:var(--rose-pale);margin-bottom:12px;">
        <p style="font-size:12px;font-weight:600;color:var(--rose-dark);margin-bottom:8px;">⚠ Da curare subito</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="c in cureUrgenti" :key="c.tipo" style="display:flex;align-items:center;justify-content:space-between;">
            <span style="font-size:13px;color:var(--rose-dark);">{{ c.label }}</span>
            <button @click="registraCura(c.tipo)" :disabled="salvando === c.tipo" class="btn btn-rose"
              style="font-size:11px;padding:4px 10px;min-height:28px;">
              {{ salvando === c.tipo ? '⏳' : 'Registra' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Cure -->
      <div class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Stato cure</p>
        <div style="display:flex;flex-direction:column;gap:10px;">
          <div v-for="tipo in ['irrigazione','concimazione','potatura']" :key="tipo"
            style="display:flex;align-items:center;justify-content:space-between;">
            <div>
              <div style="font-size:13px;font-weight:500;text-transform:capitalize;">{{ tipo }}</div>
              <div style="font-size:11px;color:var(--ink-soft);margin-top:2px;">
                {{ valutaCura(pianta, specie, tipo).label ?? 'Non configurata' }}
              </div>
            </div>
            <button @click="registraCura(tipo)" :disabled="salvando === tipo" class="btn btn-sage"
              style="font-size:11px;padding:4px 10px;min-height:28px;">
              {{ salvando === tipo ? '⏳' : '✓ Fatto' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Esigenze specie -->
      <div v-if="specie?.esigenze" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Esigenze</p>
        <div style="display:flex;flex-direction:column;gap:6px;">
          <div v-for="(val, chiave) in specie.esigenze" :key="chiave"
            style="display:flex;gap:8px;font-size:13px;">
            <span style="color:var(--ink-faint);text-transform:capitalize;min-width:70px;">{{ chiave }}</span>
            <span style="color:var(--ink-mid);">{{ val }}</span>
          </div>
        </div>
      </div>

      <!-- Alert specie -->
      <div v-if="specie?.alert?.length" class="card" style="padding:16px;margin-bottom:12px;border-color:var(--gold-light);background:var(--gold-pale);">
        <p class="section-label" style="margin-bottom:10px;color:var(--gold-dark);">Note tecniche</p>
        <ul style="padding-left:16px;margin:0;display:flex;flex-direction:column;gap:4px;">
          <li v-for="a in specie.alert" :key="a" style="font-size:12px;color:var(--ink-mid);">{{ a }}</li>
        </ul>
      </div>

      <!-- Note personali -->
      <div v-if="pianta.note" class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:6px;">Note</p>
        <p style="font-size:13px;color:var(--ink-mid);line-height:1.6;">{{ pianta.note }}</p>
      </div>

      <!-- Info impianto -->
      <div v-if="pianta.impianto" class="card" style="padding:14px 16px;margin-bottom:12px;">
        <p style="font-size:12px;color:var(--ink-soft);">Messa a dimora: <strong>{{ pianta.impianto }}</strong></p>
      </div>

      <!-- Elimina -->
      <div style="margin-top:24px;text-align:center;">
        <button @click="daEliminare = true" class="btn" style="font-size:13px;color:var(--rose-dark);background:transparent;border-color:var(--rose-light);">
          Elimina pianta
        </button>
      </div>
    </template>

    <ModalConferma
      :aperto="daEliminare"
      titolo="Eliminare questa pianta?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="eliminaPianta"
      @annulla="daEliminare = false"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { valutaCura, cureUrgentiPianta } from '@/composables/useCure'
import ModalConferma from '@/components/ModalConferma.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()

const salvando   = ref(null)
const daEliminare = ref(false)
const eliminando  = ref(false)

const pianta = computed(() => {
  if (!store.piante) return null
  const p = store.piante[route.params.id]
  return p ? { id: route.params.id, ...p } : null
})

const specie = computed(() =>
  pianta.value ? (store.specie?.[pianta.value.specie] ?? null) : null
)

const cureUrgenti = computed(() =>
  pianta.value ? cureUrgentiPianta(pianta.value, specie.value) : []
)

async function registraCura(tipo) {
  if (!pianta.value || salvando.value) return
  salvando.value = tipo
  const id = pianta.value.id
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      base[id] = {
        ...base[id],
        ultima_cura: {
          ...base[id].ultima_cura,
          [tipo]: new Date().toISOString().split('T')[0],
        }
      }
      return base
    })
    store.piante = nuove
  } finally {
    salvando.value = null
  }
}

async function eliminaPianta() {
  if (!pianta.value) return
  eliminando.value = true
  const id = pianta.value.id
  try {
    const nuove = await saveJSON('piante.json', (correnti) => {
      const base = { ...(correnti ?? store.piante) }
      delete base[id]
      return base
    })
    store.piante = nuove
    router.push('/piante')
  } finally {
    eliminando.value = false
  }
}
</script>
