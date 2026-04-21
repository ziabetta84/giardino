// js/progetto.js

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("progetti-list");
  container.innerHTML = "<div class='card'>Caricamento progetti...</div>";

  const items = await listDir("progetti").catch(() => []);
  if (!items || !items.length) {
    container.innerHTML = "<div class='card'>Nessun progetto trovato.</div>";
    return;
  }

  const files = items.filter(i => i.type === "file" && i.name.endsWith(".md"));
  container.innerHTML = "";

  if (!files.length) {
    container.innerHTML = "<div class='card'>Nessun file progetto .md trovato.</div>";
    return;
  }

  for (const f of files) {
    const name = f.name.replace(".md", "");
    const md = await getFile(`progetti/${f.name}`);
    const meta = parseMetadata(md);

    const card = document.createElement("div");
    card.className = "card";

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = meta.nome || name;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = meta.descrizione || "";

    card.appendChild(title);
    card.appendChild(subtitle);
    container.appendChild(card);
  }
});
