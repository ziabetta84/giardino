// docs/js/progetti.js

const STATO_LABELS = {
  idea: "Idea",
  pianificato: "Pianificato",
  in_corso: "In corso",
  completato: "Completato",
  archiviato: "Archiviato"
};

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("progetti-list");
  container.innerHTML = "<div class='card'>Caricamento progetti...</div>";

  const progetti = await loadJSON("progetti.json");

  if (!progetti) {
    container.innerHTML = "<div class='card'>Errore nel caricamento dei progetti.</div>";
    return;
  }

  let deleteKey = null;

  function closeDeleteModal() {
    deleteKey = null;
    document.getElementById("delete-modal").style.display = "none";
  }

  document.getElementById("modal-cancel").onclick = closeDeleteModal;

  document.getElementById("modal-confirm").onclick = async () => {
    if (!deleteKey) return;
    const data = await loadJSON("progetti.json");
    delete data[deleteKey];
    notifySaving();
    const ok = await saveJSON("progetti.json", data);
    if (ok) {
      closeDeleteModal();
      location.reload();
    } else {
      alert("Errore durante l'eliminazione.");
    }
  };

  function render(filtroStato) {
    const keys = Object.keys(progetti).filter(k =>
      !filtroStato || progetti[k].stato === filtroStato
    );

    if (keys.length === 0) {
      container.innerHTML = `<div class="card empty-state">Nessun progetto${filtroStato ? " in questo stato" : " ancora"}. Creane uno nuovo per iniziare a sviluppare un'idea.</div>`;
      return;
    }

    keys.sort((a, b) => (progetti[a].nome || "").localeCompare(progetti[b].nome || ""));

    container.innerHTML = keys.map(key => {
      const p = progetti[key];
      const stato = p.stato || "idea";
      const avanzamento = Math.max(0, Math.min(100, p.avanzamento || 0));

      return `
        <div class="card progetto-card">
          <div class="progetto-title">${p.nome || key}</div>
          <div class="progetto-meta">
            <span class="stato-badge stato-${stato}">${STATO_LABELS[stato] || stato}</span>
            ${p.zona ? `<span class="progetto-zona">📍 ${p.zona}</span>` : ""}
          </div>
          <div class="progress-bar">
            <div class="progress-bar-fill" style="width:${avanzamento}%"></div>
          </div>
          <div class="progetto-btn-row zone-btn-row">
            <button class="zone-btn explore-btn" data-action="apri" data-key="${key}">Apri</button>
            <button class="zone-btn edit-btn" data-action="modifica" data-key="${key}">Modifica</button>
            <button class="zone-btn delete-btn" data-action="elimina" data-key="${key}">Elimina</button>
          </div>
        </div>
      `;
    }).join("");

    container.querySelectorAll("[data-action]").forEach(btn => {
      const key = btn.dataset.key;
      btn.onclick = () => {
        const token = localStorage.getItem("github_token");
        if (btn.dataset.action === "apri") {
          window.location.href = `progetto.html?id=${encodeURIComponent(key)}`;
        } else if (btn.dataset.action === "modifica") {
          if (!token) return alert("Devi effettuare il login per modificare.");
          window.location.href = `edit-progetto.html?id=${encodeURIComponent(key)}`;
        } else if (btn.dataset.action === "elimina") {
          if (!token) return alert("Devi effettuare il login per eliminare.");
          deleteKey = key;
          document.getElementById("delete-modal").style.display = "flex";
        }
      };
    });
  }

  render("");

  document.getElementById("filtro-stato").onchange = (e) => render(e.target.value);
});
