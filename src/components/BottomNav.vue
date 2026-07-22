<template>
  <nav class="bottom-nav">
    <RouterLink v-for="item in nav" :key="item.id" :to="item.to" class="bn-item">
      <span class="bn-badge" v-if="item.badge">{{ item.badge }}</span>
      <span class="bn-emoji">{{ item.emoji }}</span>
      <span class="bn-label">{{ item.label }}</span>
    </RouterLink>
  </nav>
</template>

<script setup>
const nav = [
  { id:'home',     to:'/',         emoji:'🐈‍⬛', label:'Home' },
  { id:'piante',   to:'/piante',   emoji:'🌿',   label:'Piante' },
  { id:'attivita', to:'/attivita', emoji:'🔔',   label:'Attività', badge: null },
  { id:'agente',   to:'/agente',   emoji:'😺',   label:'Zorba dice' },
  { id:'zone',     to:'/zone',     emoji:'📍',   label:'Zone' },
]
</script>

<style scoped>
.bottom-nav {
  display: none;
  position: fixed; bottom: 0; left: 0; right: 0; z-index: 60;
  background: rgba(250,247,242,0.96);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-top: 1px solid var(--cream-dark);
  padding: 6px 0 env(safe-area-inset-bottom, 6px);
  justify-content: space-around; align-items: center;
}
.bn-item {
  display: flex; flex-direction: column; align-items: center; gap: 3px;
  min-width: 56px; min-height: 44px; padding: 4px 8px;
  font-size: 10px; font-weight: 500; color: var(--ink-soft);
  text-decoration: none; transition: color 0.18s; position: relative;
}
.bn-emoji { font-size: 20px; line-height: 1; }
.bn-label { font-size: 10px; }
.bn-item.router-link-active { color: var(--rose); font-weight: 600; }
.bn-badge {
  position: absolute; top: 2px; right: 6px;
  background: var(--rose); color: white;
  border-radius: 999px; font-size: 9px; font-weight: 700;
  padding: 1px 5px; line-height: 1.4;
}
@media (max-width: 640px) { .bottom-nav { display: flex; } }
</style>
