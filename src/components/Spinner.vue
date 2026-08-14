<template>
  <svg class="spinner" viewBox="0 0 24 24" aria-hidden="true">
    <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-dasharray="14 43" />
  </svg>
</template>

<script setup></script>

<style scoped>
.spinner {
  width: 1em;
  height: 1em;
  flex-shrink: 0;
  animation: spin 0.7s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) {
  .spinner { animation-duration: 2.2s; }
}
</style>
