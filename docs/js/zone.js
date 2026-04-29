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

  // Variabile globale per la modale
  let deleteZonaKey = null;

  // Funzioni modale
  function openDeleteModal(key) {
    deleteZonaKey = key;
    document.getElementById("delete-modal").style.display = "flex";
  }

  function closeDeleteModal() {
    deleteZonaKey = null;
    document.getElementById("delete-modal").style.display = "none";
  }

  // Pulsanti modale
  document.getElementById("modal-cancel").onclick = closeDeleteModal;

  document.getElementById("modal-confirm").onclick = async () => {
    if (!deleteZonaKey) return;

    const zoneData = await loadJSON("zone.json");
    const sottoData = await loadJSON("sottozone.json");

    // Elimina zona
    delete zoneData[deleteZonaKey];

    // Elimina sottozone collegate
    for (const sKey of Object.keys(sottoData)) {
      if (sottoData[sKey].zona === deleteZonaKey) {
        delete sottoData[sKey];
      }
    }

    notifySaving();
    const ok1 = await saveJSON("zone.json", zoneData);
    const ok2 = await saveJSON("sottozone.json", sottoData);

    if (ok1 && ok2) {
      closeDeleteModal();
      location.reload();
    } else {
      alert("Errore durante l'eliminazione.");
    }
  };

  // Generazione card zone
  for (const key of zoneKeys) {
    const z = zone[key];

    // CARD
    const card = document.createElement("div");
    card.className = "card zone-card";

    // TITOLO
    const title = document.createElement("div");
    title.className = "zone-title";
    title.textContent = z.nome || key;

    // CONTENITORE BOTTONI
    const btnRow = document.createElement("div");
    btnRow.className = "zone-btn-row";

    // Pulsante Sottozone
    const sottoBtn = document.createElement("button");
    sottoBtn.className = "zone-btn explore-btn";
    sottoBtn.textContent = "Sottozone";
    sottoBtn.onclick = () => {
      window.location.href = `sottozona.html?zona=${encodeURIComponent(z.nome)}`;
    };

    // Pulsante Piante
    const pianteBtn = document.createElement("button");
    pianteBtn.className = "zone-btn explore-btn";
    pianteBtn.textContent = "Piante";
    pianteBtn.onclick = () => {
      window.location.href = `piante.html?zona=${encodeURIComponent(z.nome)}`;
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

    // Pulsante Elimina (modale)
    const deleteBtn = document.createElement("button");
    deleteBtn.className = "zone-btn delete-btn";
    deleteBtn.textContent = "Elimina";
    deleteBtn.onclick = () => {
      const token = localStorage.getItem("github_token");
      if (!token) {
        alert("Devi effettuare il login per eliminare.");
        return;
      }
      openDeleteModal(key);
    };

    // Assembla
    btnRow.appendChild(sottoBtn);
    btnRow.appendChild(pianteBtn);
    btnRow.appendChild(editBtn);
    btnRow.appendChild(deleteBtn);

    card.appendChild(title);
    card.appendChild(btnRow);

    container.appendChild(card);
  }
});
