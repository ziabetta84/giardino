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

  // Carica zone.json per la descrizione
  const zone = await loadJSON("zone.json");
  if (zone && zone[zona] && zone[zona].descrizione) {
    descrContainer.innerHTML = zone[zona].descrizione;
  }

  // Carica sottozone.json
  const sottozone = await loadJSON("sottozone.json");

  // Se la zona non ha sottozone
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

    // CARD
    const card = document.createElement("div");
    card.className = "card";

    // LINK alla pagina piante
    const link = document.createElement("a");
    link.href = `piante.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(key)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = s.nome || key;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.innerHTML = s.descrizione
      ? s.descrizione.replace(/<[^>]+>/g, "").slice(0, 80) + "…"
      : "";

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
      window.location.href = `edit-sottozona.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(key)}`;
    };

    // Assembla card
    card.appendChild(link);
    card.appendChild(btn);

    container.appendChild(card);
  }
});
