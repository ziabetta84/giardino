// docs/js/sottozona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const header = document.getElementById("zona-title");
  const container = document.getElementById("sottozone-list");
  const descrContainer = document.getElementById("zona-descrizione");

  if (!zona) {
    header.textContent = "Zona non specificata";
    return;
  }

  header.textContent = `Zona: ${zona}`;

  // Carica zone e sottozone
  const zone = await loadJSON("zone.json");
  const sottozone = await loadJSON("sottozone.json");

  if (!zone || !zone[zona]) {
    descrContainer.innerHTML = "<p><i>Zona non trovata.</i></p>";
    return;
  }

  // Mostra descrizione della zona
  descrContainer.innerHTML = zone[zona].descrizione || "";

  // Filtra sottozone appartenenti alla zona
  const sottozoneKeys = Object.keys(sottozone)
    .filter(k => sottozone[k].zona === zona)
    .sort((a, b) => {
      const nomeA = sottozone[a].nome?.toLowerCase() || a.toLowerCase();
      const nomeB = sottozone[b].nome?.toLowerCase() || b.toLowerCase();
      return nomeA.localeCompare(nomeB);
    });

  container.innerHTML = "";

  if (sottozoneKeys.length === 0) {
    container.innerHTML = "<div class='card'>Nessuna sottozona trovata.</div>";
    return;
  }

  for (const key of sottozoneKeys) {
    const s = sottozone[key];

    // CARD
    const card = document.createElement("div");
    card.className = "card";

    // LINK alla pagina piante
    const link = document.createElement("a");
    link.href = `piante.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(s.nome)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = s.nome;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.innerHTML = s.descrizione || "";

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
      window.location.href = `edit-sottozona.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(s.nome)}`;
    };

    // Assembla card
    card.appendChild(link);
    card.appendChild(btn);

    container.appendChild(card);
  }
});
