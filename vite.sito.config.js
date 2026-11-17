import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// Minisito pubblico di presentazione (cartella sito/), servito sotto /scopri/
// accanto all'app. Vue 3 + vue-router, ma ogni pagina è generata in HTML
// statico da vite-ssg al momento della build: motori di ricerca e assistenti
// AI leggono il testo senza eseguire JavaScript, il visitatore poi naviga tra
// le pagine senza ricaricare, con le transizioni.
//   npm run dev:sito   → http://localhost:5174/giardino/scopri/
//   npm run build      → dist/ (app) + dist/scopri/ (minisito)
const BASE_APP = process.env.VITE_BASE || '/giardino/'

export default defineConfig({
  root: fileURLToPath(new URL('./sito', import.meta.url)),
  envDir: fileURLToPath(new URL('.', import.meta.url)),
  base: `${BASE_APP}scopri/`,
  plugins: [vue()],
  resolve: {
    alias: {
      '@app': fileURLToPath(new URL('./src', import.meta.url)),
      '@sito': fileURLToPath(new URL('./sito/src', import.meta.url)),
    },
  },
  build: {
    outDir: fileURLToPath(new URL('./dist/scopri', import.meta.url)),
    emptyOutDir: true,
  },
  ssgOptions: {
    dirStyle: 'nested',
    formatting: 'none',
    beastiesOptions: false,
    script: 'async',
  },
  server: { port: 5174 },
})
