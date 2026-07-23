<template>
  <div class="card" style="padding:16px;position:relative;">
    <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Specie *</label>
    <input
      v-model="specieQuery"
      @focus="dropdownAperto = true"
      @click="dropdownAperto = true"
      @blur="chiudiDropdown"
      placeholder="Cerca specie…"
      class="form-input"
      autocomplete="off"
    >
    <div v-if="dropdownAperto" class="specie-dropdown">
      <div v-for="s in specieFiltrate" :key="s.key" class="specie-opzione-riga">
        <div class="specie-opzione" @mousedown.prevent="selezionaSpecie(s)">{{ s.nome }}</div>
        <button type="button" class="icon-btn" @mousedown.prevent="apriModificaSpecie(s)" title="Modifica specie">✏️</button>
      </div>
      <p v-if="!specieFiltrate.length" style="font-size:12px;color:var(--ink-faint);padding:8px 10px;">Nessuna specie trovata</p>
      <div class="specie-opzione specie-nuova" @mousedown.prevent="apriNuovaSpecie">
        ＋ Aggiungi nuova specie{{ specieQuery.trim() ? ` "${specieQuery.trim()}"` : '' }}
      </div>
    </div>

    <!-- Modale nuova/modifica specie -->
    <Teleport to="body">
      <div v-if="mostraNuovaSpecie" class="overlay" @click.self="chiudiNuovaSpecie">
        <div class="modal-box">
          <h3 style="font-family:var(--font-serif);font-size:16px;font-weight:600;margin-bottom:16px;">
            {{ specieModificaOriginale ? 'Modifica specie' : 'Nuova specie' }}
          </h3>

          <input v-model="nuovaSpecie.nome" placeholder="Nome comune *" class="form-input" style="margin-bottom:10px;">
          <input v-model="nuovaSpecie.nomeScientifico" placeholder="Nome scientifico (es. Passiflora caerulea)" class="form-input" style="margin-bottom:10px;">
          <p v-if="erroreSpecie" style="font-size:11px;color:var(--rose-dark);margin:0 0 10px;">{{ erroreSpecie }}</p>

          <textarea v-model="nuovaSpecie.descrizione" placeholder="Descrizione (opzionale)"
            rows="2" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:10px;"></textarea>

          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:6px;">Esigenze (opzionale)</label>
          <input v-model="nuovaSpecie.luce" placeholder="Luce, es. Pieno sole" class="form-input" style="margin-bottom:8px;">
          <input v-model="nuovaSpecie.acqua" placeholder="Acqua, es. Moderata" class="form-input" style="margin-bottom:8px;">
          <input v-model="nuovaSpecie.terreno" placeholder="Terreno, es. Ben drenato" class="form-input" style="margin-bottom:8px;">

          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Avvertenze (opzionale)</label>
          <p style="font-size:11px;color:var(--ink-faint);margin:0 0 6px;">Una per riga, es. "teme ristagni", "non tollera calcare".</p>
          <textarea v-model="nuovaSpecie.alert" placeholder="Una avvertenza per riga…"
            rows="3" class="form-input" style="resize:vertical;font-family:inherit;margin-bottom:16px;"></textarea>

          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:2px;">Manutenzione (opzionale)</label>
          <p style="font-size:11px;color:var(--ink-faint);margin:0 0 8px;">Ogni quanti giorni, per stagione — vuoto = non necessario. Usata dalle Attività per segnalare le cure in scadenza.</p>
          <div class="manutenzione-grid">
            <div></div>
            <div class="stagione-header">Pri</div>
            <div class="stagione-header">Est</div>
            <div class="stagione-header">Aut</div>
            <div class="stagione-header">Inv</div>

            <div class="tipo-label">💧 Irrigazione</div>
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.primavera" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.estate" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.autunno" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.irrigazione.inverno" placeholder="gg">

            <div class="tipo-label">🌱 Concimazione</div>
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.primavera" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.estate" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.autunno" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.concimazione.inverno" placeholder="gg">

            <div class="tipo-label">🧪 NPK</div>
            <input v-model="nuovaSpecie.manutenzione.npk.primavera" placeholder="N-P-K">
            <input v-model="nuovaSpecie.manutenzione.npk.estate" placeholder="N-P-K">
            <input v-model="nuovaSpecie.manutenzione.npk.autunno" placeholder="N-P-K">
            <input v-model="nuovaSpecie.manutenzione.npk.inverno" placeholder="N-P-K">

            <div class="tipo-label">🥚 Calcio</div>
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.primavera" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.estate" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.autunno" placeholder="gg">
            <input type="number" min="1" v-model.number="nuovaSpecie.manutenzione.calcio.inverno" placeholder="gg">
          </div>
          <p style="font-size:11px;color:var(--ink-faint);margin:6px 0 0;">Calcio: da riempire solo per specie con beneficio documentato (es. marciume apicale su solanacee/cucurbitacee) — lascia vuoto per tutte le altre.</p>

          <label style="font-size:11px;font-weight:600;color:var(--ink-soft);text-transform:uppercase;letter-spacing:.05em;display:block;margin:12px 0 2px;">✂️ Potatura (opzionale)</label>
          <p style="font-size:11px;color:var(--ink-faint);margin:0 0 8px;">Non è a cadenza fissa come le altre: testo libero per stagione, es. "taglio leggero", "post-fioritura", "nessuna".</p>
          <div style="display:flex;flex-direction:column;gap:6px;">
            <input v-model="nuovaSpecie.manutenzione.potatura.primavera" placeholder="Primavera" class="form-input">
            <input v-model="nuovaSpecie.manutenzione.potatura.estate" placeholder="Estate" class="form-input">
            <input v-model="nuovaSpecie.manutenzione.potatura.autunno" placeholder="Autunno" class="form-input">
            <input v-model="nuovaSpecie.manutenzione.potatura.inverno" placeholder="Inverno" class="form-input">
          </div>

          <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:16px;">
            <button class="btn btn-ghost" @click="chiudiNuovaSpecie" style="min-height:40px;padding:8px 16px;">Annulla</button>
            <button class="btn btn-sage" @click="salvaNuovaSpecie" :disabled="!nuovaSpecie.nome.trim() || salvandoSpecie"
              style="min-height:40px;padding:8px 16px;">
              {{ salvandoSpecie ? '⏳' : (specieModificaOriginale ? 'Salva' : 'Aggiungi') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
// Selettore/creatore di specie: combobox con ricerca (~100+ specie, troppe
// per una <select> nativa comoda su mobile) più un'opzione per creare o
// modificare una specie al volo. Estratto da EditPiantaView.vue perché
// riusato identico in "Zorba dice" (richiesta "revisione specie").
import { ref, computed, watch } from 'vue'
import { useDatiStore } from '@/stores/dati'
import { useApi } from '@/composables/useApi'

const props = defineProps({
  modelValue: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const store = useDatiStore()
const { saveJSON } = useApi()

const specieQuery    = ref('')
const dropdownAperto = ref(false)

const specieFiltrate = computed(() => {
  const tutte = Object.entries(store.specie ?? {})
    .map(([key, s]) => ({ key, nome: s.nome ?? key }))
    .sort((a, b) => a.nome.localeCompare(b.nome))
  const q = specieQuery.value.trim().toLowerCase()
  if (!q) return tutte
  return tutte.filter(s => s.nome.toLowerCase().includes(q))
})

// Tiene il testo visualizzato allineato alla specie effettivamente selezionata
// (v-model esterno), sia al primo render sia quando cambia da fuori (es. il
// form padre la popola dopo un caricamento asincrono).
watch(() => props.modelValue, (val) => {
  if (!dropdownAperto.value) specieQuery.value = store.specie?.[val]?.nome ?? ''
}, { immediate: true })

function selezionaSpecie(s) {
  emit('update:modelValue', s.key)
  specieQuery.value = s.nome
  dropdownAperto.value = false
}

function chiudiDropdown() {
  // Ritardo breve: su alcuni browser mobile il blur dell'input scatta prima
  // che il tap sull'opzione (gestito da @mousedown.prevent) venga elaborato,
  // altrimenti il dropdown sparirebbe dal DOM prima della selezione.
  setTimeout(() => {
    dropdownAperto.value = false
    // Se l'utente ha digitato senza selezionare nulla dall'elenco, ripristina
    // il testo sul nome della specie effettivamente selezionata (o vuoto).
    specieQuery.value = store.specie?.[props.modelValue]?.nome ?? ''
  }, 150)
}

const mostraNuovaSpecie = ref(false)
const salvandoSpecie    = ref(false)
const erroreSpecie      = ref(null)
// Chiave della specie in modifica (null quando si sta creando una nuova
// specie): serve per sapere se salvaNuovaSpecie() deve creare o rinominare/
// aggiornare una voce esistente in specie.json.
const specieModificaOriginale = ref(null)

const STAGIONI = ['primavera', 'estate', 'autunno', 'inverno']

function manutenzioneVuota() {
  const perStagione = () => ({ primavera: '', estate: '', autunno: '', inverno: '' })
  return { irrigazione: perStagione(), concimazione: perStagione(), potatura: perStagione(), npk: perStagione(), calcio: perStagione() }
}

// Per irrigazione/concimazione il campo del form è solo numerico ("ogni N
// giorni"), ma i dati reali delle specie esistenti spesso non sono in quel
// formato pulito (es. "ogni 7-10 giorni", "minima", "una volta al mese").
// Quando in modifica il testo originale non è convertibile in un numero
// pulito, il campo numerico parte vuoto e questo testo viene tenuto come
// fallback: se l'utente lo lascia vuoto, il valore originale non viene perso;
// se digita un numero, lo sostituisce intenzionalmente.
const manutenzioneOriginale = ref({
  irrigazione: { primavera: '', estate: '', autunno: '', inverno: '' },
  concimazione: { primavera: '', estate: '', autunno: '', inverno: '' },
  calcio: { primavera: '', estate: '', autunno: '', inverno: '' },
})

function estraiGiorniPuliti(testo) {
  if (typeof testo === 'number') return testo
  const m = String(testo || '').match(/^ogni (\d+) giorni$/)
  return m ? parseInt(m[1], 10) : null
}

const nuovaSpecie = ref({ nome: '', nomeScientifico: '', descrizione: '', luce: '', acqua: '', terreno: '', alert: '', manutenzione: manutenzioneVuota() })

// Converte i giorni inseriti nella tabella manutenzione nel formato testuale
// già usato da tutte le specie esistenti e atteso da useCure.js (parseGiorni
// estrae il primo numero da stringhe come "ogni 7 giorni"): così le nuove
// specie restano compatibili senza dover cambiare la logica di valutazione
// cure o migrare i dati esistenti. Campo vuoto → stringa vuota, trattata da
// valutaCura come "non necessario" (nessuna cura mai segnalata come urgente).
//
// La potatura fa eccezione: nei dati reali delle ~100 specie esistenti non è
// quasi mai a cadenza numerica ("ogni N giorni"), ma descrittiva/stagionale
// ("taglio leggero", "post-fioritura", "nessuna") — per questo resta testo
// libero invece di essere convertita da un numero di giorni.
function generaManutenzione(struttura, originale) {
  const risultato = {}
  for (const tipo of ['irrigazione', 'concimazione', 'calcio']) {
    risultato[tipo] = {}
    for (const stagione of STAGIONI) {
      const giorni = struttura?.[tipo]?.[stagione]
      risultato[tipo][stagione] = (typeof giorni === 'number' && giorni > 0)
        ? `ogni ${giorni} giorni`
        : (originale?.[tipo]?.[stagione] || '')
    }
  }
  risultato.potatura = {}
  for (const stagione of STAGIONI) {
    risultato.potatura[stagione] = (struttura?.potatura?.[stagione] || '').trim()
  }
  risultato.npk = {}
  for (const stagione of STAGIONI) {
    const valore = (struttura?.npk?.[stagione] || '').trim()
    risultato.npk[stagione] = valore || null
  }
  return risultato
}

function slug(testo) {
  return testo
    .toLowerCase()
    .normalize('NFD').replace(/\p{Diacritic}/gu, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function apriNuovaSpecie() {
  nuovaSpecie.value = { nome: specieQuery.value.trim(), nomeScientifico: '', descrizione: '', luce: '', acqua: '', terreno: '', alert: '', manutenzione: manutenzioneVuota() }
  manutenzioneOriginale.value = {
    irrigazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    concimazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    calcio: { primavera: '', estate: '', autunno: '', inverno: '' },
  }
  specieModificaOriginale.value = null
  erroreSpecie.value = null
  dropdownAperto.value = false
  mostraNuovaSpecie.value = true
}

function apriModificaSpecie(s) {
  const record = store.specie?.[s.key]
  if (!record) return

  const manutenzione = manutenzioneVuota()
  const originale = {
    irrigazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    concimazione: { primavera: '', estate: '', autunno: '', inverno: '' },
    calcio: { primavera: '', estate: '', autunno: '', inverno: '' },
  }
  for (const tipo of ['irrigazione', 'concimazione', 'calcio']) {
    for (const stagione of STAGIONI) {
      const testo = record.manutenzione?.[tipo]?.[stagione] || ''
      const numero = estraiGiorniPuliti(testo)
      manutenzione[tipo][stagione] = numero ?? ''
      originale[tipo][stagione] = numero === null ? testo : ''
    }
  }
  for (const stagione of STAGIONI) {
    manutenzione.potatura[stagione] = record.manutenzione?.potatura?.[stagione] || ''
    manutenzione.npk[stagione] = record.manutenzione?.npk?.[stagione] || ''
  }

  nuovaSpecie.value = {
    nome: record.nome ?? s.nome,
    nomeScientifico: record.specie ?? '',
    descrizione: record.descrizione ?? '',
    luce: record.esigenze?.luce ?? '',
    acqua: record.esigenze?.acqua ?? '',
    terreno: record.esigenze?.terreno ?? '',
    alert: Array.isArray(record.alert) ? record.alert.join('\n') : (record.alert ?? ''),
    manutenzione,
  }
  manutenzioneOriginale.value = originale
  specieModificaOriginale.value = s.key
  erroreSpecie.value = null
  dropdownAperto.value = false
  mostraNuovaSpecie.value = true
}

function chiudiNuovaSpecie() {
  mostraNuovaSpecie.value = false
  erroreSpecie.value = null
}

async function salvaNuovaSpecie() {
  const nome = nuovaSpecie.value.nome.trim()
  if (!nome || salvandoSpecie.value) return
  const chiaveOriginale = specieModificaOriginale.value
  const chiave = slug(nome)
  if (!chiave) {
    erroreSpecie.value = 'Il nome della specie deve contenere almeno una lettera o un numero.'
    return
  }
  if (store.specie?.[chiave] && chiave !== chiaveOriginale) {
    erroreSpecie.value = 'Una specie con questo nome esiste già.'
    return
  }
  erroreSpecie.value = null

  salvandoSpecie.value = true
  try {
    // Se la specie viene rinominata, aggiorna prima le piante che la
    // referenziano e solo dopo la specie stessa: se questo primo passaggio
    // fallisce, specie.json non è ancora stato toccato e l'utente può
    // semplicemente riprovare. Nell'ordine opposto, un fallimento del
    // salvataggio delle piante dopo un rename già scritto lascerebbe sia
    // piante orfane (puntano a una chiave specie non più esistente) sia un
    // nuovo tentativo bloccato dal controllo duplicati (la chiave nuova
    // risulterebbe già presente in store.specie).
    if (chiaveOriginale && chiaveOriginale !== chiave) {
      const nuovePiante = await saveJSON('piante.json', (correnti) => {
        const base = { ...(correnti ?? store.piante) }
        for (const id of Object.keys(base)) {
          if (base[id].specie === chiaveOriginale) {
            base[id] = { ...base[id], specie: chiave }
          }
        }
        return base
      })
      store.piante = nuovePiante
      if (props.modelValue === chiaveOriginale) emit('update:modelValue', chiave)
    }

    const nuove = await saveJSON('specie.json', (correnti) => {
      const base = { ...(correnti ?? store.specie) }
      if (chiaveOriginale && chiaveOriginale !== chiave) {
        delete base[chiaveOriginale]
      }
      base[chiave] = {
        nome,
        specie: nuovaSpecie.value.nomeScientifico.trim() || nome,
        descrizione: nuovaSpecie.value.descrizione.trim() || '',
        esigenze: {
          luce:    nuovaSpecie.value.luce.trim()    || '',
          acqua:   nuovaSpecie.value.acqua.trim()   || '',
          terreno: nuovaSpecie.value.terreno.trim() || '',
        },
        alert: nuovaSpecie.value.alert.split('\n').map(a => a.trim()).filter(Boolean),
        manutenzione: generaManutenzione(nuovaSpecie.value.manutenzione, manutenzioneOriginale.value),
      }
      return base
    })
    store.specie = nuove

    selezionaSpecie({ key: chiave, nome })
    mostraNuovaSpecie.value = false
  } catch (e) {
    erroreSpecie.value = e.message || 'Errore durante il salvataggio della specie.'
  } finally {
    salvandoSpecie.value = false
  }
}
</script>

<style scoped>
.specie-dropdown {
  position: absolute;
  left: 16px; right: 16px;
  margin-top: 4px;
  background: var(--white);
  border: 1px solid var(--cream-dark);
  border-radius: 12px;
  box-shadow: 0 12px 32px rgba(42,34,24,0.15);
  max-height: 240px;
  overflow-y: auto;
  z-index: 50;
}
.specie-opzione {
  padding: 10px 12px;
  font-size: 13px;
  cursor: pointer;
}
.specie-opzione:hover {
  background: var(--cream);
}
.specie-nuova {
  color: var(--sage-dark);
  font-weight: 600;
  border-top: 1px solid var(--cream-dark);
}
.specie-opzione-riga {
  display: flex;
  align-items: center;
  gap: 4px;
  padding-right: 6px;
}
.specie-opzione-riga:hover {
  background: var(--cream);
}
.specie-opzione-riga .specie-opzione {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.specie-opzione-riga .icon-btn {
  background: none; border: none; cursor: pointer;
  padding: 4px 6px; border-radius: 8px; font-size: 13px; line-height: 1;
  color: var(--ink-soft); flex-shrink: 0;
}
.manutenzione-grid {
  display: grid;
  grid-template-columns: minmax(0,1fr) 44px 44px 44px 44px;
  gap: 6px;
  align-items: center;
}
.stagione-header {
  font-size: 10px;
  color: var(--ink-faint);
  text-align: center;
}
.tipo-label {
  font-size: 12px;
  color: var(--ink-mid);
}
.manutenzione-grid input {
  width: 100%;
  padding: 6px 4px;
  font-size: 12px;
  text-align: center;
  border: 1px solid var(--cream-dark);
  border-radius: 8px;
  font-family: inherit;
}
.overlay {
  position: fixed; inset: 0; z-index: 200;
  background: rgba(42,34,24,0.4);
  display: flex; align-items: center; justify-content: center; padding: 16px;
}
.modal-box {
  background: var(--white); border-radius: 20px; padding: 24px;
  width: 100%; max-width: 360px;
  max-height: 90vh; overflow-y: auto;
  box-shadow: 0 20px 60px rgba(42,34,24,0.2);
}
</style>
