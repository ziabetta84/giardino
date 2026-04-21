// js/pianta.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const sottozona = getParam("sottozona");
  const header = document.getElementById("pianta-title");
  const card = document.getElementById("pianta-card");

  if (!zona || !sottozona) {
    header.textContent = "Dati mancanti";
    card.textContent = "Manca zona o sottozona nei parametri.";
    return;
  }

  header.textContent = `${zona} / ${sottozona}`;

  const path = `zone/${zona}/${sottozona}.md`;
  const md = await getFile(path);
  const meta = parseMetadata(md);

  card.innerHTML = "";

  const title = document.createElement("div");
  title.className = "card-title";
  title.textContent = meta.nome || sottozona;

  const subtitle = document.createElement("div");
  subtitle.className = "card-subtitle";
  subtitle.textContent = meta.descrizione || "";

  card.appendChild(title);
  card.appendChild(subtitle);

  const list = document.createElement("div");
  list.style.marginTop = "10px";

  Object.keys(meta).forEach(key => {
    if (key === "nome" || key === "descrizione") return;
    const row = document.createElement("div");
    row.innerHTML = `<strong>${key}:</strong> ${meta[key]}`;
    list.appendChild(row);
  });

  card.appendChild(list);
});
