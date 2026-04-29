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

  // Filtra istanze
  const keys = Object.keys(piante).filter(id => {
    const p = piante[id];

    if (zona && p.zona !== zona) return false;
    if (sottozona && p.sottozona !== sottozona) return false;

    return true;
  });

  if (keys.length === 0) {
    list.innerHTML = "<div class='card'>Nessuna pianta trovata.</div>";
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
  // 🔥 RAGGRUPPAMENTO PER SOTTOZONA
  // -----------------------------
  const gruppi = {};

  for (const id of keys) {
    const p = piante[id];
    const key = p.sottozona || "Senza sottozona";

    if (!gruppi[key]) gruppi[key] = [];
    gruppi[key].push({ id, ...p });
  }

  // -----------------------------
  // 🔥 GENERAZIONE CARD PER SOTTOZONA
  // -----------------------------
  for (const sotto of Object.keys(gruppi)) {
    const sottoCard = document.createElement("div");
    sottoCard.className = "card zone-group-card";

    const sottoTitle = document.createElement("h2");
    sottoTitle.textContent = "📍 " + sotto;
    sottoCard.appendChild(sottoTitle);

    for (const p of gruppi[sotto]) {
      const sp = specie[p.specie];

      const item = document.createElement("div");
      item.className = "plant-item";

      item.innerHTML = `
        <strong>${sp.nome}${p.varieta ? " (" + p.varieta + ")" : ""}</strong>
        <div class="small">${p.zona}</div>
      `;

      // Click → scheda pianta
      item.onclick = () => {
        window.location.href = `pianta.html?id=${p.id}`;
      };

      // Pulsante modifica
      const editBtn = document.createElement("button");
      editBtn.className = "edit-inline-btn";
      editBtn.textContent = "✏️";
      editBtn.onclick = (e) => {
        e.stopPropagation();
        window.location.href = `edit-pianta.html?id=${p.id}`;
      };

      // Pulsante elimina
      const delBtn = document.createElement("button");
      delBtn.className = "delete-inline-btn";
      delBtn.textContent = "🗑️";
      delBtn.onclick = (e) => {
        e.stopPropagation();
        openDeleteModal(p.id);
      };

      item.appendChild(editBtn);
      item.appendChild(delBtn);
      sottoCard.appendChild(item);
    }

    list.appendChild(sottoCard);
  }


buildZoneMenu();
});

async function buildZoneMenu() {
  const zonaAttiva = new URLSearchParams(location.search).get("zona");
  const container = document.getElementById("zone-submenu");

  const zone = await loadJSON("zone.json");
  if (!zone) return;

  // Link "Tutte"
  const allLink = document.createElement("a");
  allLink.href = "piante.html";
  allLink.textContent = "Tutte";
  allLink.className = "zone-link";
  if (!zonaAttiva) allLink.classList.add("active");
  container.appendChild(allLink);

  // Link dinamici per ogni zona
  for (const key of Object.keys(zone)) {
    const z = zone[key];
    const link = document.createElement("a");

    link.href = `piante.html?zona=${encodeURIComponent(z.nome)}`;
    link.textContent = z.nome;
    link.className = "zone-link";

    if (zonaAttiva === z.nome) {
      link.classList.add("active");
    }

    container.appendChild(link);
  }
}

