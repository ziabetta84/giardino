import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { VitePWA } from 'vite-plugin-pwa'
import { fileURLToPath, URL } from 'node:url'
import { execSync } from 'node:child_process'

// Commit su cui è basata questa build: confrontato a runtime con l'ultimo
// commit su main per capire se la versione caricata è quella pubblicata
// più di recente (vedi useRepoStatus.js / StatusBar.vue).
function commitBuild() {
  try {
    return execSync('git rev-parse HEAD').toString().trim()
  } catch {
    return null
  }
}

export default defineConfig({
  define: {
    __APP_COMMIT__: JSON.stringify(commitBuild()),
  },
  plugins: [
    vue(),
    tailwindcss(),
    VitePWA({
      registerType: 'prompt',
      // Registriamo il service worker a mano (src/composables/useAppUpdate.js,
      // via virtual:pwa-register/vue) invece di usare lo script iniettato
      // automaticamente: così la StatusBar può sapere con certezza quando un
      // aggiornamento è davvero pronto prima di ricaricare la pagina.
      injectRegister: false,
      includeAssets: ['favicon.ico', 'favicon-16x16.png', 'favicon-32x32.png', 'apple-touch-icon.png'],
      manifest: {
        name: 'Il Giardino di Zorba',
        short_name: 'Il Giardino di Zorba',
        description: 'Gestione del giardino di Centinarola, Fano (PU)',
        start_url: '/giardino/',
        scope: '/giardino/',
        display: 'standalone',
        theme_color: '#faf7f2',
        background_color: '#faf7f2',
        icons: [
          { src: 'android-chrome-192x192.png', sizes: '192x192', type: 'image/png' },
          { src: 'android-chrome-512x512.png', sizes: '512x512', type: 'image/png' },
        ],
      },
      workbox: {
        // Dati del giardino: rete se disponibile, altrimenti l'ultima copia salvata
        // (così l'app resta consultabile in giardino senza campo/rete).
        runtimeCaching: [
          {
            urlPattern: /\/giardino\/data\/.*\.json$/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'giardino-dati',
              networkTimeoutSeconds: 3,
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
          {
            // Zone/sottozone/piante (Fase 5) sono solo su Supabase, senza più
            // un fallback JSON statico: questa regola sostituisce quel
            // fallback per restare consultabili offline. La cache è per-URL,
            // non per-utente (il JWT viaggia nell'header, non nell'URL) —
            // svuotata al logout in useAuth.js per non mostrare offline i
            // dati dell'utente precedente su un device condiviso.
            urlPattern: /^https:\/\/ncuhhsvtjwcolhpdxbkt\.supabase\.co\/rest\/v1\/.*/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'giardino-dati-supabase',
              networkTimeoutSeconds: 3,
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 30 },
            },
          },
          {
            urlPattern: /^https:\/\/api\.open-meteo\.com\/.*/,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'giardino-meteo',
              networkTimeoutSeconds: 3,
              expiration: { maxEntries: 10, maxAgeSeconds: 60 * 60 * 6 },
            },
          },
          {
            urlPattern: /^https:\/\/fonts\.(googleapis|gstatic)\.com\/.*/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'giardino-font',
              expiration: { maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 365 },
            },
          },
        ],
      },
    }),
  ],
  base: '/giardino/',
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  // Senza questo, all'avvio il dev server cerca gli entry con il glob di
  // default `**/*.html` su tutta la cartella: `fonti/rhs_from_sitemaps/`
  // contiene ~304k pagine HTML scaricate (import sitemap RHS), esbuild le
  // scandaglia tutte e il processo va in OOM ("scanning dependencies...").
  // L'unico vero entry dell'app è index.html.
  optimizeDeps: {
    entries: ['index.html'],
  },
  server: {
    watch: {
      ignored: ['**/fonti/**', '**/backups/**', '**/scripts/**', '**/dist/**', '**/docs/**'],
    },
  },
})
