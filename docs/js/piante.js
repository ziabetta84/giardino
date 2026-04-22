// docs/js/piante.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const sottozona = getParam("sottozona");

  const header = document.getElementById("piante-title");
  const container = document.getElementById("piante-list");

  if (!zona) {
    header.textContent = "Zona non specificata";
    return;
  }

  header.textContent = sottozona
    ? `Piante in ${zona} / ${sottozona}`
    : `Piante in ${zona}`;

  // Carica tutte le piante
  const piante = await loadJSON("piante.json");

  if (!piante || Object.keys(piante).length === 0) {
    container.innerHTML = "<div class='card'>Nessuna pianta trovata.</div>";
    return;
  }

  // Filtra per zona e sottozona
  const keys = Object.keys(piante).filter(k => {
    const p = piante[k];
    if (p.zona !== zona) return false;
    if (sottozona && p.sottozona !== sottozona) return false;
    return true;
  });

  // Ordina alfabeticamente
  keys.sort((a, b) => {
    const nomeA = piante[a].nome?.toLowerCase() || a.toLowerCase();
    const nomeB = piante[b].nome?.toLowerCase() || b.toLowerCase();
    return nomeA.localeCompare(nomeB);
  });

  container.innerHTML = "";

  if (keys.length === 0) {
    container.innerHTML = "<div class='card'>Nessuna pianta trovata.</div>";
    return;
  }

  for (const key of keys) {
    const p = piante[key];

    // CARD
    const card = document.createElement("div");
    card.className = "card";

    // LINK alla pagina della singola pianta
    const link = document.createElement("a");
    link.href = `pianta.html?nome=${encodeURIComponent(key)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = p.nome || key;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = p.specie || "";

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
      window.location.href = `edit-pianta.html?nome=${encodeURIComponent(key)}`;
    };

    // Assembla card
    card.appendChild(link);
    card.appendChild(btn);

    container.appendChild(card);
  }
});
