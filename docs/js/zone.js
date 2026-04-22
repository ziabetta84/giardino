// docs/js/zone.js

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("zone-list");
  container.innerHTML = "<div class='card'>Caricamento zone...</div>";

  // Carica tutte le zone dal JSON
  const zone = await loadJSON("zone.json");

  if (!zone || Object.keys(zone).length === 0) {
    container.innerHTML = "<div class='card'>Nessuna zona trovata.</div>";
    return;
  }

  container.innerHTML = "";

  // Ordina alfabeticamente per nome leggibile
  const zoneKeys = Object.keys(zone).sort((a, b) => {
    const nomeA = zone[a].nome?.toLowerCase() || a.toLowerCase();
    const nomeB = zone[b].nome?.toLowerCase() || b.toLowerCase();
    return nomeA.localeCompare(nomeB);
  });

  for (const key of zoneKeys) {
    const z = zone[key];

    // CARD
    const card = document.createElement("div");
    card.className = "card";

    // LINK alla pagina delle sottozone
    const link = document.createElement("a");
    link.href = `sottozona.html?zona=${encodeURIComponent(key)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = z.nome || key;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.innerHTML = z.descrizione || "";

    link.appendChild(title);
    link.appendChild(subtitle);

    // Pulsante Modifica
    const btn = document.createElement("button");
    btn.className = "modifica-btn";
    btn.textContent = "Modifica";
    btn.onclick = () => {
      const token = localStorage.getItem("github_token");
      if (!token) {
        alert("Devi effettuare il login per modificare.");
        return;
      }
      window.location.href = `edit-zona.html?zona=${encodeURIComponent(key)}`;
    };

    // Assembla card
    card.appendChild(link);
    card.appendChild(btn);

    container.appendChild(card);
  }
});
