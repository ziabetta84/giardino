<template>
  <div class="mini-editor">
    <div class="mini-editor-toolbar">
      <button type="button" class="mini-editor-btn" :class="{ attivo: stato.bold }"
        @mousedown.prevent="formatta('bold')" title="Grassetto"><b>B</b></button>
      <button type="button" class="mini-editor-btn" :class="{ attivo: stato.italic }"
        @mousedown.prevent="formatta('italic')" title="Corsivo"><i>I</i></button>
    </div>
    <div
      ref="editabileEl"
      class="mini-editor-content form-input"
      contenteditable="true"
      :data-placeholder="placeholder"
      @input="onInput"
      @keyup="aggiornaStato"
      @mouseup="aggiornaStato"
      @focus="aggiornaStato"
      @blur="onInput"
    ></div>
  </div>
</template>

<script setup>
// Editor WYSIWYG minimo: solo paragrafi, grassetto e corsivo. Pensato per
// sostituire le textarea su descrizione/microclima di zone e sottozone,
// che in passato finivano per contenere HTML incollato a mano (o peggio,
// markup scaricato da pagine GitHub renderizzate — vedi pulizia dati in
// "Rimuove l'HTML incorporato da zone/sottozone/specie"). L'output è
// sempre passato da sanitizza(), che ammette solo p/br/b/strong/i/em senza
// alcun attributo: nessun tag/attributo arbitrario può finire nei dati,
// quindi è sicuro visualizzarlo in futuro con v-html.
import { ref, onMounted, watch } from 'vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  placeholder: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue'])

const editabileEl = ref(null)
const stato = ref({ bold: false, italic: false })

const TAG_CONSENTITI = new Set(['P', 'BR', 'B', 'STRONG', 'I', 'EM'])

function sanitizza(html) {
  const contenitore = document.createElement('div')
  contenitore.innerHTML = html

  function pulisciNodo(nodo) {
    ;[...nodo.childNodes].forEach(figlio => {
      if (figlio.nodeType !== 1) return // testo/commenti: lasciati stare

      // I browser contenteditable spesso usano <div> per i paragrafi: li
      // trattiamo come equivalenti a <p>.
      const tag = figlio.tagName === 'DIV' ? 'P' : figlio.tagName

      if (!TAG_CONSENTITI.has(tag)) {
        // Tag non ammesso: ne conserviamo solo il contenuto testuale/inline
        while (figlio.firstChild) nodo.insertBefore(figlio.firstChild, figlio)
        nodo.removeChild(figlio)
        return
      }

      if (figlio.tagName === 'DIV') {
        const p = document.createElement('p')
        p.innerHTML = figlio.innerHTML
        nodo.replaceChild(p, figlio)
        pulisciNodo(p)
        return
      }

      // Rimuove tutti gli attributi (style, class, ecc.)
      ;[...figlio.attributes].forEach(attr => figlio.removeAttribute(attr.name))
      pulisciNodo(figlio)
    })
  }

  pulisciNodo(contenitore)
  return contenitore.innerHTML
}

function onInput() {
  emit('update:modelValue', sanitizza(editabileEl.value.innerHTML))
}

function formatta(comando) {
  document.execCommand(comando, false, null)
  editabileEl.value.focus()
  aggiornaStato()
  onInput()
}

function aggiornaStato() {
  stato.value.bold = document.queryCommandState('bold')
  stato.value.italic = document.queryCommandState('italic')
}

onMounted(() => {
  try { document.execCommand('defaultParagraphSeparator', false, 'p') } catch { /* browser più vecchi: ignorato */ }
  editabileEl.value.innerHTML = props.modelValue || ''
})

// Riallinea il contenuto se il valore esterno cambia per motivi non legati
// alla digitazione (es. reset del form, caricamento di un altro record).
watch(() => props.modelValue, (nuovo) => {
  if (editabileEl.value && nuovo !== editabileEl.value.innerHTML) {
    editabileEl.value.innerHTML = nuovo || ''
  }
})
</script>

<style scoped>
.mini-editor-toolbar {
  display: flex;
  gap: 6px;
  margin-bottom: 6px;
}
.mini-editor-btn {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  border: 1px solid var(--cream-dark, #ddd);
  background: var(--white, #fff);
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.mini-editor-btn.attivo {
  background: var(--sage-pale, #e4ede4);
  border-color: var(--sage, #7a9e82);
}
.mini-editor-content {
  min-height: 90px;
  overflow-y: auto;
  line-height: 1.5;
}
.mini-editor-content :deep(p) {
  margin: 0 0 8px 0;
}
.mini-editor-content :deep(p:last-child) {
  margin-bottom: 0;
}
.mini-editor-content:empty::before {
  content: attr(data-placeholder);
  color: var(--ink-faint, #999);
}
</style>
