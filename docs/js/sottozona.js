// js/sottozona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const header = document.getElementById("zona-title");
  const container = document.getElementById("sottozone-list");

  if (!zona) {
    header.textContent = "Zona non specificata";
    container.innerHTML = "<div class='card'>Parametro zona mancante.</div>";
    return;
  }

  header.textContent = `Zona: ${zona}`;
  container.innerHTML = "<div class='card'>Caricamento sottozone...</div>";

  const items = await listDir(`zone/${zona}`);
  const files = items.filter(i => i.type === "file" && i.name.endsWith(".md"));

  container.innerHTML = "";

  if (!files.length) {
    container.innerHTML = "<div class='card'>Nessuna sottozona trovata.</div>";
    return;
  }

  for (const f of files) {
    const name = f.name.replace(".md", "");
    if (name === zona) continue; // salta il file principale della zona

    const md = await getFile(`zone/${zona}/${f.name}`);
    const meta = parseMetadata(md);

    const a = document.createElement("a");
    a.className = "card";
    a.href = `pianta.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(name)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = meta.nome || name;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = meta.descrizione || "";

    a.appendChild(title);
    a.appendChild(subtitle);
    container.appendChild(a);
  }
});
