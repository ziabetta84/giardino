// docs/js/gallery.js

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("gallery-container");

  container.innerHTML = "<div class='card'>Caricamento foto...</div>";

  const folders = [
    "gallery/zone",
    "gallery/sottozone",
    "gallery/piante"
  ];

  let html = "";

  for (const folder of folders) {
    const url = `https://api.github.com/repos/ziabetta84/giardino/contents/docs/${folder}`;

    const res = await fetch(url);
    const data = await res.json();

    if (!Array.isArray(data)) continue;

    html += `<h2>${folder.replace("gallery/", "")}</h2>`;

    html += `<div class="card-grid">`;

    for (const item of data) {
      if (item.type === "dir") {
        html += `
          <a class="home-card" href="${item.html_url}">
            <div class="icon">📁</div>
            <div class="label">${item.name}</div>
          </a>
        `;
      }
    }

    html += `</div>`;
  }

  container.innerHTML = html;
});
