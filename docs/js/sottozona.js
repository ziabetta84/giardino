// js/sottozona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

// Estrae il frontmatter YAML (tra --- e ---)
function extractFrontmatter(md) {
  const match = md.match(/^---\s*([\s\S]*?)\s*---/);
  return match ? match[1] : null;
}

// Converte YAML semplice (chiave: valore) in tabella HTML
function yamlToTable(yaml) {
  const lines = yaml.split("\n").filter(l => l.trim());
  let html = "<table class='yaml-table'>";

  for (const line of lines) {
    const idx = line.indexOf(":");
    if (idx === -1) continue;

    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim();

    html += `
      <tr>
        <th>${key}</th>
        <td>${value}</td>
      </tr>
    `;
  }

  html += "</table>";
  return html;
}

// Rimuove il frontmatter e restituisce solo il contenuto Markdown
function stripFrontmatter(md) {
  return md.replace(/^---[\s\S]*?---/, "").trim();
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const header = document.getElementById("zona-title");
  const container = document.getElementById("sottozone-list");
  const fmContainer = document.getElementById("zona-frontmatter");
  const descrContainer = document.getElementById("zona-descrizione");

  if (!zona) {
    header.textContent = "Zona non specificata";
    return;
  }

  header.textContent = `Zona: ${zona}`;

  // 1. Carica casa.md tramite GitHub API
  const path = `zone/${zona}/${zona}.md`;
  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/${path}?t=${Date.now()}`;

  try {
    const res = await fetch(apiUrl, {
      headers: { "Accept": "application/vnd.github.v3+json" }
    });

    if (res.ok) {
      const fileData = await res.json();
      const md = decodeURIComponent(escape(atob(fileData.content.replace(/\n/g, ""))));

      // Estrai frontmatter
      const fm = extractFrontmatter(md);
      if (fm) {
        fmContainer.innerHTML = yamlToTable(fm);
      }

      // Mostra contenuto Markdown
      const contenuto = stripFrontmatter(md);
      descrContainer.innerHTML = marked.parse(contenuto);
    }
  } catch (e) {
    fmContainer.innerHTML = "<p><i>Errore nel caricamento della zona.</i></p>";
  }

  // 2. Carica sottozone
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
