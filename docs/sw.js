const CACHE_NAME = "zorba-cache-v1";
const OFFLINE_URL = "offline.html";

// File statici da mettere subito in cache
const STATIC_ASSETS = [
  "index.html",
  "style.css",
  "favicon.ico",
  "favicon-16x16.png",
  "favicon-32x32.png",
  "apple-touch-icon.png",
  "android-chrome-192x192.png",
  "android-chrome-512x512.png",
  "manifest.json",
  "js/status.js"
];

// Installazione: cache iniziale
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(STATIC_ASSETS);
    })
  );
  self.skipWaiting();
});

// Attivazione: pulizia vecchie cache
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

// Fetch: strategia "network first con fallback offline"
self.addEventListener("fetch", (event) => {
  const request = event.request;

  // Evita problemi con richieste esterne (GitHub API, meteo, ecc.)
  if (!request.url.startsWith(self.location.origin)) {
    return;
  }

  event.respondWith(
    fetch(request)
      .then((response) => {
        // Salva in cache la risposta fresca
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
        return response;
      })
      .catch(() => {
        // Se offline → prova la cache
        return caches.match(request).then((cached) => {
          return cached || caches.match(OFFLINE_URL);
        });
      })
  );
});
