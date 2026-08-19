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
        <div style="width:56px;height:56px;border-radius:50%;background:var(--gold-tile);display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
          <Icon name="lampadina" style="width:24px;height:24px;" />
        </div>
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
        <p v-if="scadenza" style="display:flex;align-items:center;gap:5px;font-size:11px;color:var(--ink-faint);margin-top:2px;">
          <Icon name="bandiera" style="width:11px;height:11px;flex-shrink:0;" />Scadenza (dall'ultima tappa): {{ formatData(scadenza) }}
        </p>
      </div>

      <!-- Tappe -->
      <div class="card" style="padding:16px;margin-bottom:12px;">
        <p class="section-label" style="margin-bottom:14px;">Tappe</p>

        <div class="tl">
          <!-- inserimento prima della prima tappa -->
          <div class="tl-insert">
            <button v-if="inserimentoIndex !== 0" type="button"
              :class="form.tappe.length ? 'tl-insert-btn' : 'tl-insert-btn tl-insert-btn--empty'"
              @click="apriInserimento(0)">
              {{ form.tappe.length ? '+' : '+ Aggiungi tappa' }}
            </button>
            <div v-else class="tl-insert-form">
              <input type="date" v-model="nuovaTappaInserimento.data" class="form-input" style="flex:1;min-width:120px;">
              <input v-model="nuovaTappaInserimento.descrizione" placeholder="Cosa aspettarti / cosa fare" class="form-input"
                style="flex:2;min-width:140px;" @keyup.enter="confermaInserimento">
              <button type="button" class="btn btn-sage" style="flex-shrink:0;padding:8px 14px;font-size:13px;" @click="confermaInserimento">Aggiungi</button>
              <button type="button" @click="inserimentoIndex = null" aria-label="Annulla"
                style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;padding:0 4px;flex-shrink:0;">×</button>
            </div>
          </div>

          <template v-for="(t, i) in form.tappe" :key="i">
            <div class="tl-item">
              <span class="tl-dot" :style="{ background: coloreEsito(t.esito), borderColor: coloreEsito(t.esito) }"></span>

              <div v-if="tappaApertaIndex === i" class="tl-edit">
                <div style="display:flex;gap:6px;align-items:center;margin-bottom:6px;">
                  <input type="date" v-model="t.data" class="form-input" style="flex:1;min-width:120px;">
                  <select v-model="t.esito" class="form-input" style="flex:1;min-width:100px;">
                    <option value="atteso">Atteso</option>
                    <option value="riuscito">Riuscito</option>
                    <option value="fallito">Fallito</option>
                    <option value="saltato">Saltato</option>
                  </select>
                </div>
                <textarea v-model="t.descrizione" placeholder="Cosa aspettarti / cosa fare" rows="2"
                  class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:8px;"></textarea>
                <div style="display:flex;gap:10px;align-items:center;">
                  <button type="button" @click="tappaApertaIndex = null" class="btn btn-sage" style="flex:1;font-size:13px;padding:7px;">Fatto</button>
                  <button type="button" @click="rimuoviTappa(i)" style="background:none;border:none;color:var(--rose-dark);font-size:12px;cursor:pointer;">Elimina</button>
                </div>
              </div>

              <button v-else type="button" class="tl-card" @click="tappaApertaIndex = i">
                <div class="tl-card-head">
                  <span class="tl-date">{{ formatData(t.data) }}</span>
                  <span class="tl-esito" :style="{ color: coloreEsito(t.esito) }">{{ labelEsito(t.esito) }}</span>
                </div>
                <p class="tl-desc">{{ t.descrizione }}</p>
              </button>
            </div>

            <div class="tl-insert">
              <button v-if="inserimentoIndex !== i + 1" type="button" class="tl-insert-btn" @click="apriInserimento(i + 1)">+</button>
              <div v-else class="tl-insert-form">
                <input type="date" v-model="nuovaTappaInserimento.data" class="form-input" style="flex:1;min-width:120px;">
                <input v-model="nuovaTappaInserimento.descrizione" placeholder="Cosa aspettarti / cosa fare" class="form-input"
                  style="flex:2;min-width:140px;" @keyup.enter="confermaInserimento">
                <button type="button" class="btn btn-sage" style="flex-shrink:0;padding:8px 14px;font-size:13px;" @click="confermaInserimento">Aggiungi</button>
                <button type="button" @click="inserimentoIndex = null" aria-label="Annulla"
                  style="background:none;border:none;color:var(--ink-faint);font-size:20px;line-height:1;cursor:pointer;padding:0 4px;flex-shrink:0;">×</button>
              </div>
            </div>
          </template>
        </div>
      </div>

      <p v-if="errore" style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--rose-dark);margin-bottom:10px;">
        <Icon name="campanella" style="width:13px;height:13px;flex-shrink:0;" />{{ errore }}
      </p>

      <div style="display:flex;gap:10px;">
        <button @click="daEliminare = true" class="btn" style="font-size:13px;color:var(--rose-dark);background:transparent;border-color:var(--rose-light);">
          Elimina progetto
        </button>
        <button @click="salva" :disabled="!form.titolo.trim() || salvando" class="btn btn-sage" style="flex:1;">
          <Spinner v-if="salvando" />{{ salvando ? 'Salvataggio…' : 'Salva modifiche' }}
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
import Icon from '@/components/Icon.vue'
import Spinner from '@/components/Spinner.vue'

const route  = useRoute()
const router = useRouter()
const store  = useDatiStore()
const { saveJSON } = useApi()

const form = ref(null)
const tappaApertaIndex = ref(null)
const inserimentoIndex = ref(null)
const nuovaTappaInserimento = ref({ data: '', descrizione: '' })
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
  tappaApertaIndex.value = null
  inserimentoIndex.value = null
}
watch(() => [store.progetti, route.params.id], caricaForm, { immediate: true })

const LABEL_ESITO = { atteso: 'Atteso', riuscito: 'Riuscito', fallito: 'Fallito', saltato: 'Saltato' }
const COLORE_ESITO = {
  atteso: 'var(--gold-dark)', riuscito: 'var(--sage-dark)',
  fallito: 'var(--rose-dark)', saltato: 'var(--ink-faint)',
}
function labelEsito(esito) { return LABEL_ESITO[esito] ?? LABEL_ESITO.atteso }
function coloreEsito(esito) { return COLORE_ESITO[esito] ?? COLORE_ESITO.atteso }

// L'indice serve solo per sapere quale "+" ha aperto il mini-form: la
// posizione finale della tappa è sempre determinata dalla data (le tappe
// restano ordinate cronologicamente), non dalla posizione cliccata — così
// funziona identicamente per un inserimento in fondo o in mezzo alla lista.
function apriInserimento(indice) {
  inserimentoIndex.value = indice
  nuovaTappaInserimento.value = { data: '', descrizione: '' }
}
function confermaInserimento() {
  if (!nuovaTappaInserimento.value.data || !nuovaTappaInserimento.value.descrizione.trim()) return
  form.value.tappe.push({
    data: nuovaTappaInserimento.value.data,
    descrizione: nuovaTappaInserimento.value.descrizione.trim(),
    esito: 'atteso',
  })
  form.value.tappe.sort((a, b) => (a.data || '').localeCompare(b.data || ''))
  inserimentoIndex.value = null
}
function rimuoviTappa(i) {
  form.value.tappe.splice(i, 1)
  tappaApertaIndex.value = null
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

<style scoped>
.tl { position: relative; }

.tl-item { position: relative; padding-left: 26px; margin-bottom: 2px; }

.tl-item::before {
  content: '';
  position: absolute;
  left: 5px; top: 14px; bottom: 0;
  width: 2px;
  background: var(--cream-dark);
}

.tl-dot {
  position: absolute;
  left: 0; top: 14px;
  width: 12px; height: 12px;
  border-radius: 50%;
  border: 2px solid;
  background: var(--white);
  box-sizing: border-box;
}

.tl-card {
  display: block;
  width: 100%;
  text-align: left;
  background: var(--white);
  border: 1px solid var(--cream-dark);
  border-radius: 10px;
  padding: 10px 12px;
  cursor: pointer;
  font: inherit;
  color: inherit;
}

.tl-card:hover { border-color: var(--gold-light); }

.tl-card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 3px;
}

.tl-date { font-size: 12px; font-weight: 600; color: var(--ink-mid); }
.tl-esito { font-size: 11px; font-weight: 600; letter-spacing: 0.01em; }
.tl-desc { margin: 0; font-size: 13px; color: var(--ink-soft); line-height: 1.4; }

.tl-edit {
  padding: 10px;
  border: 1px solid var(--cream-dark);
  border-radius: 10px;
}

.tl-insert {
  position: relative;
  padding-left: 26px;
  min-height: 18px;
  display: flex;
  align-items: center;
}

/* prosegue la linea della timeline attraverso ogni riga di inserimento,
   tranne l'ultima (dopo l'ultima tappa, non c'è altro da collegare) */
.tl-insert:not(:last-child)::before {
  content: '';
  position: absolute;
  left: 5px; top: 0; bottom: 0;
  width: 2px;
  background: var(--cream-dark);
}

.tl-insert-btn {
  background: none;
  border: none;
  color: var(--ink-faint);
  font-size: 13px;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 6px;
  line-height: 1;
}

.tl-insert-btn:hover { color: var(--sage-dark); background: var(--sage-pale); }

.tl-insert-btn--empty {
  font-size: 13px;
  font-weight: 600;
  color: var(--ink-soft);
  padding: 8px 10px;
  border: 1px dashed var(--cream-dark);
  border-radius: 8px;
}

.tl-insert-form {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  width: 100%;
  padding: 6px 0;
}
</style>
