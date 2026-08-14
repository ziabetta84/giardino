<template>
  <nav class="navbar">
    <div class="navbar-inner no-scroll">
      <RouterLink v-for="item in nav" :key="item.id" :to="item.to" class="nav-item">
        <Icon :name="item.icona" class="nav-icon" />
        <span>{{ item.label }}</span>
        <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
      </RouterLink>
    </div>
  </nav>
</template>

<script setup>
import Icon from '@/components/Icon.vue'

const nav = [
  { id:'home',     to:'/',          icona:'casa',       label:'Home' },
  { id:'meteo',    to:'/meteo',     icona:'meteo',       label:'Meteo' },
  { id:'zone',     to:'/zone',      icona:'pin',         label:'Zone' },
  { id:'piante',   to:'/piante',    icona:'foglia',      label:'Piante' },
  { id:'progetti', to:'/progetti',  icona:'lampadina',   label:'Progetti' },
  { id:'concimi',  to:'/concimi',   icona:'provetta',    label:'Concimi' },
  { id:'attivita', to:'/attivita',  icona:'campanella',  label:'Attività', badge: null },
  { id:'agente',   to:'/agente',    icona:'gatto',       label:'Zorba dice' },
  { id:'gallery',  to:'/gallery',   icona:'cornice',     label:'Gallery' },
]
</script>

<style scoped>
.navbar {
  position: sticky; top: 0; z-index: 50;
  background: rgba(250,247,242,0.9);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}
.navbar-inner {
  max-width: 920px; margin: 0 auto;
  display: flex; align-items: center;
  padding: 0 16px; height: 52px;
  overflow-x: auto;
  border-bottom: 1px solid var(--cream-dark);
}
.nav-icon { width: 16px; height: 16px; flex-shrink: 0; }
.nav-item {
  display: flex; align-items: center; gap: 5px;
  padding: 6px 10px; height: 44px;
  font-size: 13px; font-weight: 500;
  color: var(--ink-soft);
  transition: color 0.22s ease, transform 0.15s ease; white-space: nowrap;
  text-decoration: none; position: relative; z-index: 0;
}
.nav-item:active { transform: scale(0.95); }
.nav-item::before {
  content: '';
  position: absolute; inset: 4px;
  border-radius: 5px;
  background: var(--gold-light);
  opacity: 0;
  transform: scaleX(0.3);
  transform-origin: left center;
  transition: transform 0.25s cubic-bezier(0.4,0,0.2,1), opacity 0.2s ease;
  z-index: -1;
}
.nav-item:hover { color: var(--ink); }
.nav-item:hover::before { opacity: 0.65; transform: scaleX(1); }
.nav-item.router-link-active { color: var(--rose); font-weight: 600; }
.nav-item.router-link-active::before { opacity: 0.85; transform: scaleX(1); }
.nav-badge {
  background: var(--rose); color: white;
  border-radius: 999px; font-size: 10px; font-weight: 700;
  padding: 1px 6px; line-height: 1.5;
}
@media (max-width: 640px) { .navbar { display: none; } }
</style>
