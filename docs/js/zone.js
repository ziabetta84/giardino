// js/zone.js

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("zone-list");
  container.innerHTML = "<div class='card'>Caricamento zone...</div>";

  const items = await listDir("zone");
  const zones = items.filter(i => i.type === "dir");

  container.innerHTML = "";

  if (!zones.length) {
    container.innerHTML = "<div class='card'>Nessuna zona trovata.</div>";
    return;
  }

  for (const z of zones) {
    const md = await getFile(`zone/${z.name}/${z.name}.md`);
    const meta = parseMetadata(md);

    const a = document.createElement("a");
    a.className = "card";
    a.href = `sottozona.html?zona=${encodeURIComponent(z.name)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = meta.nome || z.name;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = meta.descrizione || "";

    a.appendChild(title);
    a.appendChild(subtitle);
    container.appendChild(a);
  }
});
