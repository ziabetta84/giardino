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
    card.className = "card zone-card";

    // TITOLO (solo testo, niente link)
    const title = document.createElement("div");
    title.className = "zone-title";
    title.textContent = z.nome || key;

    // CONTENITORE BOTTONI
    const btnRow = document.createElement("div");
    btnRow.className = "zone-btn-row";

    // Pulsante Esplora
    const exploreBtn = document.createElement("button");
    exploreBtn.className = "zone-btn explore-btn";
    exploreBtn.textContent = "Esplora";
    exploreBtn.onclick = () => {
      window.location.href = `sottozona.html?zona=${encodeURIComponent(key)}`;
    };

    // Pulsante Modifica
    const editBtn = document.createElement("button");
    editBtn.className = "zone-btn edit-btn";
    editBtn.textContent = "Modifica";
    editBtn.onclick = () => {
      const token = localStorage.getItem("github_token");
      if (!token) {
        alert("Devi effettuare il login per modificare.");
        return;
      }
      window.location.href = `edit-zona.html?zona=${encodeURIComponent(key)}`;
    };

    // Assembla
    btnRow.appendChild(exploreBtn);
    btnRow.appendChild(editBtn);

    card.appendChild(title);
    card.appendChild(btnRow);

    container.appendChild(card);
  }
});
