// docs/js/sottozona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");

  const header = document.getElementById("zona-title");
  const descrContainer = document.getElementById("zona-descrizione");
  const container = document.getElementById("sottozone-list");

  if (!zona) {
    header.textContent = "Zona non specificata";
    container.innerHTML = "<div class='card'>Parametro zona mancante.</div>";
    return;
  }

  header.textContent = zona;

  // 🔥 Pulsante "Aggiungi sottozona" dinamico
  const addBtn = document.getElementById("add-subzone-btn");
  addBtn.href = `edit-sottozona.html?zona=${encodeURIComponent(zona)}&sottozona=NUOVA`;

  // Carica descrizione zona
  const zone = await loadJSON("zone.json");
  if (zone && zone[zona] && zone[zona].descrizione) {
    descrContainer.innerHTML = zone[zona].descrizione;
  }

  // Carica sottozone
  const sottozone = await loadJSON("sottozone.json");

  if (!sottozone || !sottozone[zona]) {
    container.innerHTML = "<div class='card'>Nessuna sottozona trovata.</div>";
    return;
  }

  const elenco = sottozone[zona];

  // Ordina alfabeticamente
  const keys = Object.keys(elenco).sort((a, b) => {
    const nomeA = elenco[a].nome?.toLowerCase() || a.toLowerCase();
    const nomeB = elenco[b].nome?.toLowerCase() || b.toLowerCase();
    return nomeA.localeCompare(nomeB);
  });

  container.innerHTML = "";

  for (const key of keys) {
    const s = elenco[key];

    // CARD stile zone.js
    const card = document.createElement("div");
    card.className = "card sottozona-card";

    // TITOLO
    const title = document.createElement("div");
    title.className = "sottozona-title";
    title.textContent = s.nome || key;

    // BOTTONI
    const btnRow = document.createElement("div");
    btnRow.className = "sottozona-btn-row";

    // Esplora
    const exploreBtn = document.createElement("button");
    exploreBtn.className = "sottozona-btn explore-btn";
    exploreBtn.textContent = "Esplora";
    exploreBtn.onclick = () => {
      window.location.href = `piante.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(key)}`;
    };

    // Modifica
    const editBtn = document.createElement("button");
    editBtn.className = "sottozona-btn edit-btn";
    editBtn.textContent = "Modifica";
    editBtn.onclick = () => {
      const token = localStorage.getItem("github_token");
      if (!token) {
        alert("Devi effettuare il login per modificare.");
        return;
      }
      window.location.href = `edit-sottozona.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(key)}`;
    };

    btnRow.appendChild(exploreBtn);
    btnRow.appendChild(editBtn);

    card.appendChild(title);
    card.appendChild(btnRow);

    container.appendChild(card);
  }
});
