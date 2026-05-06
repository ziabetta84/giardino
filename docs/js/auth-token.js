// js/auth-token.js
(function () {
  try {
    const urlParams = new URLSearchParams(window.location.search);
    const token = urlParams.get("token");

    if (token) {
      console.log("[auth-token] Token ricevuto, salvo nel localStorage…");
      localStorage.setItem("github_token", token);

      // Ricarica la pagina SENZA parametri (fondamentale per la PWA)
      const cleanUrl = window.location.origin + window.location.pathname;
      window.location.replace(cleanUrl);
      return;
    }

    // Debug utile: mostra se il token è presente o no
    const existing = localStorage.getItem("github_token");
    if (!existing) {
      console.warn("[auth-token] Nessun token trovato nel localStorage.");
    } else {
      console.log("[auth-token] Token già presente nel localStorage.");
    }
  } catch (err) {
    console.error("[auth-token] Errore:", err);
  }
})();
