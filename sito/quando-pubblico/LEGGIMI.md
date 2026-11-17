# Quando il minisito diventa pubblico

Dal 17/11/2026 il minisito /scopri/ si condivide solo con chi ha il link. Per renderlo pubblico:

1. Rimettere `sitemap.xml` e `llms.txt` in `public/` (sono qui per non annunciare il sito).
2. In `public/robots.txt` aggiungere `Sitemap: https://zorbaingiardino.app/sitemap.xml`.
3. In `public/_headers` togliere il blocco `/scopri/*` con `X-Robots-Tag`.
4. Impostare `VITE_SCOPRI_PUBBLICO=true` nella build (`.env` o il workflow): toglie il meta `noindex` dalle pagine e mostra il link «Che cos'è Zorba in giardino» nella pagina di accesso dell'app.
5. In `index.html` si può rimettere nel `<noscript>` il link a `%BASE_URL%scopri/`.
