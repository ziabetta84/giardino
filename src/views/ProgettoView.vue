<template>
  <div>
    <RouterLink to="/progetti" style="display:inline-flex;align-items:center;gap:6px;font-size:13px;color:var(--ink-soft);text-decoration:none;margin-bottom:20px;">
      ← Progetti
    </RouterLink>

    <template v-if="store.loading">
      <div class="skeleton" style="height:28px;width:60%;margin-bottom:8px;"></div>
      <div class="skeleton" style="height:14px;width:40%;margin-bottom:24px;"></div>
      <div class="skeleton" style="height:160px;border-radius:16px;margin-bottom:12px;"></div>
      <div class="skeleton" style="height:120px;border-radius:16px;"></div>
    </template>

    <template v-else-if="!form">
      <div style="text-align:center;padding:60px 0;color:var(--ink-faint);">
        <div style="font-size:40px;margin-bottom:12px;">🗂️</div>
        <p>Progetto non trovato</p>
      </div>
    </template>

    <template v-else>
      <!-- Dati principali -->
      <div class="card" style="padding:16px;margin-bottom:12px;">
        <input v-model="form.titolo" placeholder="Titolo" class="form-input title-serif"
          style="font-size:17px;font-weight:600;margin-bottom:10px;">

        <div style="display:flex;gap:8px;align-items:center;margin-bottom:10px;flex-wrap:wrap;">
          <select v-model="form.stato" class="form-input" style="width:auto;">
            <option v-for="(label, chiave) in LABEL_STATO" :key="chiave" :value="chiave">{{ label }}</option>
          </select>
          <span class="badge" :style="badgeStato(form.stato)">{{ labelStato(form.stato) }}</span>
        </div>

        <input v-model="form.zona" placeholder="Zona (opzionale)" class="form-input" style="margin-bottom:10px;">

        <MiniEditor v-model="form.descrizione" placeholder="Descrizione, contesto, note…" />

        <p style="font-size:11px;color:var(--ink-faint);margin-top:8px;">Creato il {{ formatData(form.creato) }}</p>
        <p v-if="scadenza" style="font-size:11px;color:var(--ink-faint);margin-top:2px;">📅 Scadenza (dall'ultima tappa): {{ formatData(scadenza) }}</p>
      </div>

      <!-- Tappe -->
      <div class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:10px;">Tappe</p>

        <div v-if="!form.tappe.length" style="font-size:12px;color:var(--ink-faint);margin-bottom:12px;">
          Nessuna tappa ancora — aggiungine una qui sotto.
        </div>

        <div v-else style="display:flex;flex-direction:column;gap:10px;margin-bottom:14px;">
          <div v-for="(t, i) in form.tappe" :key="i"
            style="padding:10px;border:1px solid var(--cream-dark);border-radius:10px;">
            <div style="display:flex;gap:6px;align-items:center;margin-bottom:6px;">
              <input type="date" v-model="t.data" class="form-input" style="flex:1;min-width:130px;">
              <select v-model="t.esito" class="form-input" style="flex:1;min-width:110px;">
                <option value="atteso">Atteso</option>
                <option value="riuscito">Riuscito</option>
                <option value="fallito">Fallito</option>
                <option value="saltato">Saltato</option>
              </select>
              <button type="button" @click="form.tappe.splice(i, 1)" aria-label="Rimuovi tappa"
                style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;padding:0 4px;flex-shrink:0;">×</button>
            </div>
            <textarea v-model="t.descrizione" placeholder="Cosa aspettarti / cosa fare" rows="2"
              class="form-input" style="resize:vertical;font-family:inherit;"></textarea>
          </div>
        </div>

        <div style="display:flex;gap:6px;flex-wrap:wrap;">
          <input type="date" v-model="nuovaTappa.data" class="form-input" style="flex:1;min-width:130px;">
          <input v-model="nuovaTappa.descrizione" placeholder="Nuova tappa…" class="form-input" style="flex:3;min-width:160px;"
            @keyup.enter="aggiungiTappa">
          <button type="button" @click="aggiungiTappa" class="btn btn-ghost" style="flex-shrink:0;">+ Aggiungi</button>
        </div>
      </div>

      <p v-if="errore" style="font-size:12px;color:var(--rose-dark);margin-bottom:10px;">⚠ {{ errore }}</p>

      <div style="display:flex;gap:10px;">
        <button @click="daEliminare = true" class="btn" style="font-size:13px;color:var(--rose-dark);background:transparent;border-color:var(--rose-light);">
          🗑 Elimina progetto
        </button>
        <button @click="salva" :disabled="!form.titolo.trim() || salvando" class="btn btn-sage" style="flex:1;">
          {{ salvando ? '⏳ Salvataggio…' : 'Salva modifiche' }}
        </button>
      </div>
    </template>

    <ModalConferma
      :aperto="daEliminare"
      titolo="Eliminare questo progetto?"
      messaggio="Questa azione non può essere annullata."
      :caricamento="eliminando"
      @conferma="eliminaProgetto"
      @annulla="daEliminare = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'
import { scadenzaCalcolata } from '@/composables/useProgetti'
import ModalConferma from '@/components/ModalConferma.vue'
import MiniEditor from '@/components/MiniEditor.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()

const form = ref(null)
const nuovaTappa = ref({ data: '', descrizione: '' })
const salvando = ref(false)
const errore = ref(null)
const daEliminare = ref(false)
const eliminando = ref(false)

const LABEL_STATO = {
  aperto: 'Aperto', in_corso: 'In corso', completato: 'Completato',
  fallito: 'Fallito', cancellato: 'Cancellato',
}
const STILI_STATO = {
  aperto:     'background:var(--cream-dark);color:var(--ink-soft);',
  in_corso:   'background:var(--gold-pale);color:var(--gold-dark);',
  completato: 'background:var(--sage-pale);color:var(--sage-dark);',
  fallito:    'background:var(--rose-pale);color:var(--rose-dark);',
  cancellato: 'background:var(--cream-dark);color:var(--ink-faint);',
}
function badgeStato(stato) { return STILI_STATO[stato] ?? STILI_STATO.aperto }
function labelStato(stato) { return LABEL_STATO[stato] ?? 'Aperto' }

function formatData(d) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('it-IT', { day: 'numeric', month: 'long', year: 'numeric' })
}

// Non un campo a parte da tenere allineato a mano: è la data dell'ultima
// tappa, ricalcolata mentre si modificano le tappe nel form (non serve
// salvare per vederla aggiornata).
const scadenza = computed(() => form.value ? scadenzaCalcolata(form.value) : null)

// Copia locale modificabile: il salvataggio è esplicito (bottone "Salva
// modifiche") invece che automatico a ogni campo, per non moltiplicare le
// scritture su GitHub mentre si sistemano più tappe in una volta.
function caricaForm() {
  const p = store.progetti?.[route.params.id]
  form.value = p ? { ...p, tappe: (p.tappe || []).map(t => ({ ...t })) } : null
}
watch(() => [store.progetti, route.params.id], caricaForm, { immediate: true })

function aggiungiTappa() {
  if (!nuovaTappa.value.data || !nuovaTappa.value.descrizione.trim()) return
  form.value.tappe.push({ data: nuovaTappa.value.data, descrizione: nuovaTappa.value.descrizione.trim(), esito: 'atteso' })
  form.value.tappe.sort((a, b) => (a.data || '').localeCompare(b.data || ''))
  nuovaTappa.value = { data: '', descrizione: '' }
}

async function salva() {
  if (!form.value.titolo.trim() || salvando.value) return
  salvando.value = true
  errore.value = null
  const id = route.params.id
  try {
    const nuovi = await saveJSON('progetti.json', (correnti) => ({
      ...(correnti ?? store.progetti),
      [id]: {
        titolo: form.value.titolo.trim(),
        descrizione: form.value.descrizione.trim() || null,
        zona: form.value.zona.trim() || null,
        stato: form.value.stato,
        creato: form.value.creato,
        tappe: form.value.tappe
          .filter(t => t.data && t.descrizione.trim())
          .map(t => ({ data: t.data, descrizione: t.descrizione.trim(), esito: t.esito || 'atteso' })),
      }
    }))
    store.progetti = nuovi
  } catch (e) {
    errore.value = e.message
  } finally {
    salvando.value = false
  }
}

async function eliminaProgetto() {
  eliminando.value = true
  const id = route.params.id
  try {
    const nuovi = await saveJSON('progetti.json', (correnti) => {
      const base = { ...(correnti ?? store.progetti) }
      delete base[id]
      return base
    })
    store.progetti = nuovi
    router.push('/progetti')
  } finally {
    eliminando.value = false
  }
}
</script>
