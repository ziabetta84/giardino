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

  // 1) leggo il contenuto di zone/<zona>
  const items = await listDir(`zone/${zona}`);

  // 2) prendo solo le directory (le sottozone)
  const subdirs = items.filter(i => i.type === "dir");

  container.innerHTML = "";

  if (!subdirs.length) {
    container.innerHTML = "<div class='card'>Nessuna sottozona trovata.</div>";
    return;
  }

  for (const dir of subdirs) {
    const sottozona = dir.name;

    // 3) file markdown atteso: zone/<zona>/<sottozona>/<sottozona>.md
    const path = `zone/${zona}/${sottozona}/${sottozona}.md`;
    const md = await getFile(path);
    if (!md) continue;

    const meta = parseMetadata(md);

    const a = document.createElement("a");
    a.className = "card";
    a.href = `pianta.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(sottozona)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = meta.nome || sottozona;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = meta.descrizione || "";

    a.appendChild(title);
    a.appendChild(subtitle);
    container.appendChild(a);
  }
});
