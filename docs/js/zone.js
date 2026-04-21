// js/zone.js

function modificaZona(zona) {
  const token = localStorage.getItem("github_token");

  if (!token) {
    // Avvia login passando la zona al Worker
    window.location.href = `https://giardino.robertagenovese.workers.dev/login?zona=${zona}`;
    return;
  }

  // Se abbiamo già il token → vai direttamente alla pagina di modifica
  window.location.href = `edit-zona.html?token=${token}&zona=${zona}`;
}

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("zone-list");
  container.innerHTML = "<div class='card'>Caricamento zone...</div>";

  // Prepara headers con token se presente
  const token = localStorage.getItem("github_token");
  const headers = { "Accept": "application/vnd.github.v3+json" };
  if (token) headers["Authorization"] = `Bearer ${token}`;

  // Carica la lista delle zone
  const items = await listDir("zone");
  const zones = items.filter(i => i.type === "dir");

  container.innerHTML = "";

  if (!zones.length) {
    container.innerHTML = "<div class='card'>Nessuna zona trovata.</div>";
    return;
  }

  for (const z of zones) {
    const mdPath = `zone/${z.name}/${z.name}.md`;
    const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/${mdPath}?t=${Date.now()}`;

    let meta = {};

    try {
      const res = await fetch(apiUrl, { headers });

      if (res.ok) {
        const fileData = await res.json();

        // Decodifica UTF‑8 corretta
        const md = new TextDecoder("utf-8").decode(
          Uint8Array.from(atob(fileData.content), c => c.charCodeAt(0))
        );

        // Estrai frontmatter YAML
        const match = md.match(/^---\s*([\s\S]*?)\s*---/);
        if (match) {
          const yamlObj = jsyaml.load(match[1]);
          meta = yamlObj || {};
        }
      }
    } catch (e) {
      console.error("Errore caricamento metadata zona:", z.name, e);
    }

    // CARD DELLA ZONA
    const card = document.createElement("div");
    card.className = "card";

    // TITOLO
    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = meta.nome || z.name;

    // SOTTOTITOLO
    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = meta.descrizione || "";

    // LINK ALLA PAGINA SOTTOZONE
    const link = document.createElement("a");
    link.href = `sottozona.html?zona=${encodeURIComponent(z.name)}`;
    link.appendChild(title);
    link.appendChild(subtitle);

    // PULSANTE MODIFICA
    const btn = document.createElement("button");
    btn.className = "modifica-btn";
    btn.textContent = "Modifica";
    btn.onclick = () => modificaZona(z.name);

    // ASSEMBLA LA CARD
    card.appendChild(link);
    card.appendChild(btn);

    container.appendChild(card);
  }
});
