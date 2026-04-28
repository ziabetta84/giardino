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
    list.innerHTML = "<div class='card'>Nessuna pianta in questa zona.</div>";
    return;
  }

  list.innerHTML = "";

  // 🔥 Variabile globale per la modale
  let deleteId = null;

  // 🔥 Funzioni modale
  function openDeleteModal(id) {
    deleteId = id;
    document.getElementById("delete-modal").style.display = "flex";
  }

  function closeDeleteModal() {
    deleteId = null;
    document.getElementById("delete-modal").style.display = "none";
  }

  // Pulsanti modale
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

  // 🔥 Generazione card piante
  for (const id of keys) {
    const p = piante[id];
    const sp = specie[p.specie];

    const card = document.createElement("div");
    card.className = "card plant-card";

    const titleDiv = document.createElement("div");
    titleDiv.className = "card-title";
    titleDiv.textContent = sp.nome + (p.varieta ? ` (${p.varieta})` : "");

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = `${p.zona}${p.sottozona ? " / " + p.sottozona : ""}`;

    // Pulsanti
    const btnRow = document.createElement("div");
    btnRow.className = "sottozona-btn-row";

    const viewBtn = document.createElement("button");
    viewBtn.className = "sottozona-btn explore-btn";
    viewBtn.textContent = "Scheda";
    viewBtn.onclick = () => {
      window.location.href = `pianta.html?specie=${p.specie}`;
    };

    const editBtn = document.createElement("button");
    editBtn.className = "sottozona-btn edit-btn";
    editBtn.textContent = "Modifica";
    editBtn.onclick = () => {
      window.location.href = `edit-pianta.html?id=${id}`;
    };

    const delBtn = document.createElement("button");
    delBtn.className = "sottozona-btn delete-btn";
    delBtn.textContent = "Elimina";
    delBtn.onclick = () => openDeleteModal(id);

    btnRow.appendChild(viewBtn);
    btnRow.appendChild(editBtn);
    btnRow.appendChild(delBtn);

    card.appendChild(titleDiv);
    card.appendChild(subtitle);
    card.appendChild(btnRow);

    list.appendChild(card);
  }
});
