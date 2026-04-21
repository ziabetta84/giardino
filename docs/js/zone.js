// js/zone.js

function modificaZona(zona) {
  const token = localStorage.getItem("github_token");

  if (!token) {
    // Avvia login passando la zona al Worker
    window.location.href = `https://giardino.robertagenovese.workers.dev/login?zona=${zona}`;
    return;
  }

  // Se abbiamo già il token → vai direttamente alla pagina di modifica
  window.location.href = `edit-zona.html?token=${token}&zona=${zona}`;
}

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

    // CARD DELLA ZONA
    const card = document.createElement("div");
    card.className = "card";

    // LINK ALLA PAGINA SOTTOZONE
    const link = document.createElement("a");
    link.href = `sottozona.html?zona=${encodeURIComponent(z.name)}`;

    const title = document.createElement("div");
    title.className = "card-title";
    title.textContent = meta.nome || z.name;

    const subtitle = document.createElement("div");
    subtitle.className = "card-subtitle";
    subtitle.textContent = meta.descrizione || "";

    link.appendChild(title);
    link.appendChild(subtitle);

    // PULSANTE MODIFICA
    const btn = document.createElement("button");
    btn.className = "modifica-btn";
    btn.textContent = "Modifica";
    btn.onclick = () => modificaZona(z.name);

    // ASSEMBLA LA CARD
    card.appendChild(link);
    card.appendChild(btn);

    container.appendChild(card);
  }
});
