// docs/js/piante.js

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const sottozona = getParam("sottozona");

  const title = document.getElementById("page-title");
  const list = document.getElementById("piante-list");
  const addBtn = document.getElementById("add-plant-btn");

  // Titolo dinamico
  if (zona && sottozona) {
    title.textContent = `${zona} / ${sottozona}`;
    addBtn.href = `edit-pianta.html?zona=${zona}&sottozona=${sottozona}`;
  } else if (zona) {
    title.textContent = zona;
    addBtn.href = `edit-pianta.html?zona=${zona}`;
  } else {
    title.textContent = "Tutte le piante";
    addBtn.href = `edit-pianta.html`;
  }

  // Carica dati
  const specie = await loadJSON("specie.json");
  const piante = await loadJSON("piante.json");

  if (!piante) {
    list.innerHTML = "<div class='card'>Nessuna pianta trovata.</div>";
    return;
  }

  // Filtra istanze in base ai parametri
  const keys = Object.keys(piante).filter(id => {
    const p = piante[id];

    if (zona && p.zona !== zona) return false;
    if (sottozona && p.sottozona !== sottozona) return false;

    return true;
  });

  if (keys.length === 0) {
    list.innerHTML = "<div class='card'>Nessuna pianta in questa zona.</div>";
    return;
  }

  list.innerHTML = "";

  // -----------------------------
  // 🔥 MODALE ELIMINAZIONE
  // -----------------------------
  let deleteId = null;

  function openDeleteModal(id) {
    deleteId = id;
    document.getElementById("delete-modal").style.display = "flex";
  }

  function closeDeleteModal() {
    deleteId = null;
    document.getElementById("delete-modal").style.display = "none";
  }

  document.getElementById("modal-cancel").onclick = closeDeleteModal;

  document.getElementById("modal-confirm").onclick = async () => {
    if (!deleteId) return;

    delete piante[deleteId];
    const saved = await saveJSON("piante.json", piante);

    if (saved) {
      closeDeleteModal();
      location.reload();
    } else {
      alert("Errore durante l'eliminazione.");
    }
  };

  // -----------------------------
  // 🔥 RAGGRUPPAMENTO PER ZONA
  // -----------------------------
  const gruppi = {};

  for (const id of keys) {
    const p = piante[id];
    if (!gruppi[p.zona]) gruppi[p.zona] = [];
    gruppi[p.zona].push({ id, ...p });
  }

  // -----------------------------
  // 🔥 GENERAZIONE CARD PER ZONA
  // -----------------------------
  for (const zonaNome of Object.keys(gruppi)) {
    const zonaCard = document.createElement("div");
    zonaCard.className = "card zone-group-card";

    const zonaTitle = document.createElement("h2");
    zonaTitle.textContent = "📍 " + zonaNome;
    zonaCard.appendChild(zonaTitle);

    // Lista piante della zona
    for (const p of gruppi[zonaNome]) {
      const sp = specie[p.specie];

      const item = document.createElement("div");
      item.className = "plant-item";

      item.innerHTML = `
        <strong>${sp.nome}${p.varieta ? " (" + p.varieta + ")" : ""}</strong>
        <div class="small">${p.sottozona || ""}</div>
      `;

      // Click → scheda pianta
      item.onclick = () => {
        window.location.href = `pianta.html?specie=${p.specie}`;
      };

      // Pulsante elimina
      const delBtn = document.createElement("button");
      delBtn.className = "delete-inline-btn";
      delBtn.textContent = "🗑️";
      delBtn.onclick = (e) => {
        e.stopPropagation();
        openDeleteModal(p.id);
      };

      item.appendChild(delBtn);
      zonaCard.appendChild(item);
    }

    list.appendChild(zonaCard);
  }
});
