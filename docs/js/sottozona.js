// js/sottozona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

// Rimuove i metadati iniziali dal file .md
function stripMetadata(md) {
  const lines = md.split("\n");
  let i = 0;

  while (i < lines.length && /^[a-zA-Z0-9_-]+\s*:\s*/.test(lines[i].trim())) {
    i++;
  }
  while (i < lines.length && lines[i].trim() === "") {
    i++;
  }

  return lines.slice(i).join("\n");
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const header = document.getElementById("zona-title");
  const container = document.getElementById("sottozone-list");
  const descrContainer = document.getElementById("zona-descrizione");

  if (!zona) {
    header.textContent = "Zona non specificata";
    container.innerHTML = "<div class='card'>Parametro zona mancante.</div>";
    return;
  }

  header.textContent = `Zona: ${zona}`;
  container.innerHTML = "<div class='card'>Caricamento sottozone...</div>";

  // 1. Carica il file della zona (casa.md)
  const path = `zone/${zona}/${zona}.md`;
  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/${path}?t=${Date.now()}`;

  try {
    const res = await fetch(apiUrl, {
      headers: { "Accept": "application/vnd.github.v3+json" }
    });

    if (res.ok) {
      const fileData = await res.json();
      const md = decodeURIComponent(escape(atob(fileData.content.replace(/\n/g, ""))));
      const contenuto = stripMetadata(md);

      // Render Markdown → HTML
      descrContainer.innerHTML = marked.parse(contenuto);
    } else {
      descrContainer.innerHTML = "<p><i>Impossibile caricare la descrizione della zona.</i></p>";
    }
  } catch (e) {
    descrContainer.innerHTML = "<p><i>Errore nel caricamento della descrizione.</i></p>";
  }

  // 2. Carica le sottozone
  const items = await listDir(`zone/${zona}`);
  const dirs = items.filter(i => i.type === "dir");

  container.innerHTML = "";

  if (!dirs.length) {
    container.innerHTML = "<div class='card'>Nessuna sottozona trovata.</div>";
    return;
  }

  for (const d of dirs) {
    const sottozona = d.name;

    const a = document.createElement("a");
    a.className = "card";
    a.href = `pianta.html?zona=${encodeURIComponent(zona)}&sottozona=${encodeURIComponent(sottozona)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = sottozona;

    a.appendChild(title);
    container.appendChild(a);
  }
});
