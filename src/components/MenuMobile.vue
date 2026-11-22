<template>
  <!-- Menù principale su telefono: l'indice del taccuino a tutta pagina.
       Si apre dal pulsante in alto a destra dell'AppBar con una macchia
       d'inchiostro che si allarga dal pulsante stesso; sopra i 640px non
       esiste (c'è la sidebar). Teleport sul body: deve coprire anche
       StatusBar e toast, che vivono fuori da .app-main. -->
  <Teleport to="body">
    <Transition name="indice" @after-leave="restituisciFocus">
      <div v-if="aperto" id="menu-mobile" ref="pannello" class="indice"
        role="dialog" aria-modal="true" aria-label="Menù"
        :style="{ '--ox': origine.x + 'px', '--oy': origine.y + 'px' }"
        @keydown.esc.prevent="chiudi" @keydown.tab="intrappolaFocus">

        <div class="indice__hd">
          <span class="indice__mark">
            <ZorbaLogo mini />
            Zorba in giardino
          </span>
          <button ref="chiudiBtn" type="button" class="indice__btn" aria-label="Chiudi il menù" @click="chiudi">
            <Icon name="chiudi" />
          </button>
        </div>

        <nav class="indice__voci" aria-label="Sezioni dell'app">
          <RouterLink v-for="(v, i) in voci" :key="v.to" :to="v.to" custom v-slot="{ href, navigate, isActive, isExactActive }">
            <a :href="href" class="voce" :class="{ on: v.esatta ? isExactActive : isActive }"
              :aria-current="(v.esatta ? isExactActive : isActive) ? 'page' : undefined"
              :style="{ '--i': i }" @click="vai($event, navigate)">
              <span class="voce__ic" :class="{ 'is-zorba': v.icona === 'gatto' }"><Icon :name="v.icona" /></span>
              <span class="voce__nome">{{ v.nome }}</span>
              <span v-if="v.esatta ? isExactActive : isActive" class="voce__qui" aria-hidden="true">sei qui</span>
            </a>
          </RouterLink>
        </nav>

        <div class="indice__piede" :style="{ '--i': voci.length }">
          <RouterLink v-for="v in vociPiede" :key="v.to" :to="v.to" custom v-slot="{ href, navigate, isActive }">
            <a :href="href" class="piede" :class="{ on: isActive }" :aria-current="isActive ? 'page' : undefined"
              @click="vai($event, navigate)">
              <Icon :name="v.icona" />{{ v.nome }}
            </a>
          </RouterLink>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch, nextTick, onMounted, onBeforeUnmount } from 'vue'
import { useRoute } from 'vue-router'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'

// aperto: v-model dall'AppBar. origine: il centro del pulsante che ha aperto
// il menù, da cui parte (e in cui rientra) la macchia d'inchiostro.
const aperto = defineModel({ type: Boolean, default: false })
const props = defineProps({ origine: { type: Object, default: () => ({ x: 0, y: 0 }) } })
const origine = props.origine

// Stesse voci e stesso ordine della SideNav, così telefono e computer
// hanno lo stesso indice; in fondo, più piccole, le voci di servizio.
const voci = [
  { to: '/',          nome: 'Home',       icona: 'casa', esatta: true },
  { to: '/meteo',     nome: 'Meteo',      icona: 'meteo' },
  { to: '/zone',      nome: 'Zone',       icona: 'pin' },
  { to: '/piante',    nome: 'Piante',     icona: 'foglia' },
  { to: '/progetti',  nome: 'Progetti',   icona: 'lampadina' },
  { to: '/concimi',   nome: 'Concimi',    icona: 'provetta' },
  { to: '/attivita',  nome: 'Attività',   icona: 'campanella' },
  { to: '/agente',    nome: 'Zorba dice', icona: 'gatto' },
  { to: '/gallery',   nome: 'Gallery',    icona: 'cornice' },
]
const vociPiede = [
  { to: '/impostazioni', nome: 'Impostazioni', icona: 'chiave' },
  { to: '/account',      nome: 'Account',      icona: 'persona' },
  { to: '/feedback',     nome: "Scrivi a chi costruisce l'app", icona: 'matita' },
]

const pannello = ref(null)
const chiudiBtn = ref(null)
const emit = defineEmits(['chiuso'])

function chiudi() { aperto.value = false }

// Si naviga e si chiude insieme: la pagina nuova entra già sotto l'indice
// che si ritira. Toccare la pagina in cui si è chiude soltanto.
function vai(evento, navigate) {
  navigate(evento)
  chiudi()
}

// Indietro del telefono, link interni, redirect: qualunque cambio di rotta
// chiude il menù.
const route = useRoute()
watch(() => route.fullPath, chiudi)

// Scroll della pagina sotto bloccato; focus sul pulsante di chiusura
// all'apertura e di nuovo sul pulsante del menù alla fine dell'uscita.
watch(aperto, async (a) => {
  document.documentElement.style.overflow = a ? 'hidden' : ''
  if (a) { await nextTick(); chiudiBtn.value?.focus() }
})
function restituisciFocus() { emit('chiuso') }

// Il Tab resta dentro l'indice: è un dialogo modale a tutta pagina e dietro
// non c'è niente da raggiungere.
function intrappolaFocus(e) {
  const el = pannello.value
  if (!el) return
  const fuochi = [...el.querySelectorAll('a[href], button:not([disabled])')]
  if (!fuochi.length) return
  const primo = fuochi[0], ultimo = fuochi[fuochi.length - 1]
  if (e.shiftKey && document.activeElement === primo) { e.preventDefault(); ultimo.focus() }
  else if (!e.shiftKey && document.activeElement === ultimo) { e.preventDefault(); primo.focus() }
}

// Ruotando il tablet o allargando la finestra oltre i 640px compare la
// sidebar: il menù non ha più senso e si chiude.
const largo = window.matchMedia('(min-width: 640px)')
function suLargo() { if (largo.matches) chiudi() }
onMounted(() => largo.addEventListener('change', suLargo))
onBeforeUnmount(() => {
  largo.removeEventListener('change', suLargo)
  document.documentElement.style.overflow = ''
})
</script>

<style scoped>
/* ---------- la pagina dell'indice ---------- */
.indice {
  position: fixed; inset: 0; z-index: 200;
  display: flex; flex-direction: column;
  overflow-y: auto; overscroll-behavior: contain;
  padding: 0 0 calc(20px + env(safe-area-inset-bottom, 0px));
  background-color: var(--cream);
  /* lo stesso lavaggio d'acquerello della carta sotto ogni pagina, un po'
     più carico: qui è l'unica cosa sullo sfondo */
  background-image:
    radial-gradient(ellipse 520px 420px at 0% 8%,  color-mix(in srgb, var(--rose) 11%, transparent) 0%, transparent 70%),
    radial-gradient(ellipse 480px 460px at 100% 96%, color-mix(in srgb, var(--sage) 14%, transparent) 0%, transparent 70%),
    radial-gradient(ellipse 320px 300px at 78% 30%, color-mix(in srgb, var(--gold) 8%, transparent) 0%, transparent 70%);
}

/* stessa riga e stesse misure dell'AppBar: il pulsante non si sposta,
   cambia solo il segno (tre righe → croce) */
.indice__hd {
  position: sticky; top: 0; z-index: 1;
  display: flex; align-items: center; justify-content: space-between;
  padding: 9px 14px; min-height: 51px;
  padding-top: calc(9px + env(safe-area-inset-top, 0px));
}
.indice__mark {
  display: inline-flex; align-items: center; gap: 7px;
  font: 600 12.5px/1 var(--font-display); color: var(--ink);
}
.indice__btn {
  width: 44px; height: 44px; margin: -6px -8px -6px 0;
  display: grid; place-items: center; border-radius: 50%;
  border: none; background: none; cursor: pointer; color: var(--ink-mid);
  transition: background var(--motion-quick) var(--ease-standard);
}
.indice__btn svg { width: 20px; height: 20px; }
.indice__btn:active { background: color-mix(in srgb, var(--ink) 8%, transparent); }
.indice__btn:focus-visible { outline: 3px solid var(--gold); outline-offset: -3px; }

/* ---------- le voci ---------- */
.indice__voci {
  display: flex; flex-direction: column;
  padding: 6px 24px 0;
}
.voce {
  position: relative;
  display: flex; align-items: center; gap: 16px;
  min-height: 50px; padding: 4px 2px;
  border-bottom: 1px solid var(--cream-dark);
  text-decoration: none; color: var(--ink-mid);
  -webkit-tap-highlight-color: transparent;
}
.voce:first-child { border-top: 1px solid var(--cream-dark); }
.voce__ic { width: 26px; height: 26px; flex: none; }
.voce__ic svg { width: 100%; height: 100%; display: block; }
/* «si accende solo dove sei»: come nella sidebar, le icone delle altre
   pagine restano in inchiostro, quella della pagina aperta ha il suo colore */
.voce:not(.on) .voce__ic {
  --acqua: currentColor; --acqua-dark: currentColor; --olive: currentColor; --olive-dark: currentColor;
  --sage: currentColor; --sage-dark: currentColor; --rose: currentColor; --rose-dark: currentColor;
  --gold: currentColor; --gold-dark: currentColor;
  color: var(--ink-soft);
}
.voce__nome {
  font: 500 24px/1.1 var(--font-display);
  letter-spacing: -0.01em;
  font-variation-settings: 'opsz' 72, 'SOFT' 50;
}
.voce.on { color: var(--ink); }
.voce.on .voce__nome { font-weight: 640; }
/* l'annotazione a penna sul margine: l'unico Caveat della pagina */
.voce__qui {
  margin-left: auto; padding-right: 4px;
  font: 400 21px/1 var(--font-hand); color: var(--sage-dark);
  transform: rotate(-4deg) translateY(1px);
}
.voce:active .voce__nome { color: var(--ink); }
.voce:focus-visible { outline: none; box-shadow: inset 0 0 0 3px var(--gold); border-radius: 6px; }

/* ---------- voci di servizio ---------- */
.indice__piede {
  display: flex; flex-wrap: wrap; gap: 0 20px;
  margin-top: auto; padding: 16px 24px 0;
}
.piede {
  display: inline-flex; align-items: center; gap: 8px;
  min-height: 44px; padding: 0 2px;
  font: 500 13.5px/1.2 var(--font-sans); color: var(--ink-mid); text-decoration: none;
}
.piede svg { width: 18px; height: 18px; flex: none; }
.piede:not(.on) svg { --sage: currentColor; --sage-dark: currentColor; --gold: currentColor; --gold-dark: currentColor; color: var(--ink-soft); }
.piede.on { color: var(--ink); font-weight: 600; }
.piede:focus-visible { outline: none; box-shadow: inset 0 0 0 3px var(--gold); border-radius: 6px; }

/* ---------- apertura: una macchia d'inchiostro dal pulsante ---------- */
.indice-enter-active {
  transition: clip-path var(--motion-sheet) var(--ease-standard);
}
.indice-leave-active {
  transition: clip-path var(--motion-quick) var(--ease-standard), opacity var(--motion-quick) var(--ease-standard);
}
.indice-enter-from,
.indice-leave-to { clip-path: circle(0px at var(--ox) var(--oy)); }
.indice-enter-to,
.indice-leave-from { clip-path: circle(150vmax at var(--ox) var(--oy)); }
.indice-leave-to { opacity: .6; }

/* le voci si posano una dopo l'altra mentre la macchia si allarga */
.indice-enter-active .voce,
.indice-enter-active .indice__piede {
  animation: voce-entra var(--motion-sheet) var(--ease-standard) both;
  animation-delay: calc(60ms + var(--i) * 22ms);
}
@keyframes voce-entra {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: none; }
}

@media (prefers-reduced-motion: reduce) {
  .indice-enter-active, .indice-leave-active { transition: opacity var(--motion-quick) linear; }
  .indice-enter-from, .indice-leave-to { clip-path: none; opacity: 0; }
  .indice-enter-to, .indice-leave-from { clip-path: none; opacity: 1; }
  .indice-enter-active .voce, .indice-enter-active .indice__piede { animation: none; }
}

@media (min-width: 640px) { .indice { display: none; } }

/* schermi bassi (telefono in orizzontale, SE): voci più strette */
@media (max-height: 620px) {
  .voce { min-height: 44px; }
  .voce__nome { font-size: 21px; }
  .voce__ic { width: 23px; height: 23px; }
  .indice__voci { padding-top: 0; }
  .indice__piede { padding-top: 10px; }
}
</style>
