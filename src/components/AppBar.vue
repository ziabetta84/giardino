<template>
  <header class="appbar">
    <RouterLink to="/" class="appbar__mark" aria-label="Zorba in giardino, vai alla Home">
      <ZorbaLogo mini />
      Zorba in giardino
    </RouterLink>
    <button ref="menuBtn" type="button" class="appbar__menu"
      aria-label="Apri il menù" aria-controls="menu-mobile" :aria-expanded="menuAperto ? 'true' : 'false'"
      @click="apri">
      <Icon name="lista" />
    </button>
  </header>

  <MenuMobile v-model="menuAperto" :origine="origine" @chiuso="menuBtn?.focus()" />
</template>

<script setup>
import { ref, reactive } from 'vue'
import Icon from '@/components/Icon.vue'
import ZorbaLogo from '@/components/ZorbaLogo.vue'
import MenuMobile from '@/components/MenuMobile.vue'

// Su telefono la navigazione sta tutta nel menù a tutta pagina (MenuMobile):
// la barra in basso non c'è più. Sopra i 640px l'AppBar è nascosta e
// resta la sidebar.
const menuAperto = ref(false)
const menuBtn = ref(null)
const origine = reactive({ x: 0, y: 0 })

function apri() {
  const r = menuBtn.value.getBoundingClientRect()
  origine.x = Math.round(r.left + r.width / 2)
  origine.y = Math.round(r.top + r.height / 2)
  menuAperto.value = true
}
</script>
