// docs/js/attivita.js

const STATO_LABELS = {
  idea: "Idea",
  pianificato: "Pianificato",
  in_corso: "In corso",
  completato: "Completato",
  archiviato: "Archiviato"
};

const CURE_ICONS = { irrigazione: "💧", concimazione: "🌱", potatura: "✂️" };

document.addEventListener("DOMContentLoaded", async () => {
  const oggiContainer = document.getElementById("attivita-oggi");
  const progettiContainer = document.getElementById("attivita-progetti");
  const meteoAlertContainer = document.getElementById("attivita-meteo-alert");
  const digestBox = document.getElementById("attivita-digest");

  oggiContainer.innerHTML = "<div class='card'>Calcolo attività in corso...</div>";
  progettiContainer.innerHTML = "<div class='card'>Caricamento progetti...</div>";

  const [settings, zone, , piante] = await Promise.all([
    loadJSON("settings.json"),
    loadJSON("zone.json"),
    loadJSON("sottozone.json"),
    loadJSON("piante.json")
  ]);
  const [specieData, progetti] = await Promise.all([
    loadJSON("specie.json"),
    loadJSON("progetti.json")
  ]);

  let meteo = null;
  if (settings?.location) {
    meteo = await fetchMeteoPerRegole(settings.location.lat, settings.location.lon);
  }

  // -----------------------------
  // Alert meteo dinamici
  // -----------------------------
  const alertiMeteo = alertMeteo(meteo);
  meteoAlertContainer.innerHTML = alertiMeteo.length
    ? `<div class="card meteo-alert-card"><ul>${alertiMeteo.map(a => `<li>${a}</li>`).join("")}</ul></div>`
    : "";

  // -----------------------------
  // Da fare oggi (raggruppate per zona)
  // -----------------------------
  const daFarePerZona = {};

  if (piante && specieData) {
    for (const id of Object.keys(piante)) {
      const p = piante[id];
      const specie = specieData[p.specie];
      if (!specie) continue;

      const zonaInfo = zone?.[p.zona];
      const azioni = [];

      ["irrigazione", "concimazione"].forEach(tipo => {
        const esito = valutaCura(p, specie, zonaInfo, meteo, tipo);
        if (esito.daFare) azioni.push({ tipo, testo: esito.testo, dettaglio: `da ${esito.giorni} giorni` });
      });

      const pot = valutaPotatura(specie);
      if (pot.priorita > 0) {
        azioni.push({ tipo: "potatura", testo: pot.testo, dettaglio: pot.priorita === 1 ? "priorità alta" : "priorità normale" });
      }

      if (azioni.length > 0) {
        const zonaKey = p.zona || "Senza zona";
        if (!daFarePerZona[zonaKey]) daFarePerZona[zonaKey] = [];
        daFarePerZona[zonaKey].push({ id, nome: specie.nome || p.specie, azioni });
      }
    }
  }

  const zoneConAzioni = Object.keys(daFarePerZona).sort();

  if (zoneConAzioni.length === 0) {
    oggiContainer.innerHTML = "<div class='card empty-state'>Nessuna attività da svolgere oggi. 🎉</div>";
  } else {
    oggiContainer.innerHTML = zoneConAzioni.map(zonaKey => `
      <div class="card zone-group-card">
        <h3>📍 ${zonaKey}</h3>
        ${daFarePerZona[zonaKey].map(pianta => `
          <div class="attivita-pianta-row">
            <a href="pianta.html?id=${encodeURIComponent(pianta.id)}"><strong>${pianta.nome}</strong></a>
            ${pianta.azioni.map(a => `
              <div class="attivita-azione">
                ${CURE_ICONS[a.tipo]} ${a.tipo} <span class="small">(${a.dettaglio})</span>
                <button type="button" class="btn-fatto" data-id="${pianta.id}" data-tipo="${a.tipo}">✅ Fatto</button>
              </div>
            `).join("")}
          </div>
        `).join("")}
      </div>
    `).join("");

    oggiContainer.querySelectorAll(".btn-fatto").forEach(btn => {
      btn.onclick = async () => {
        const token = localStorage.getItem("github_token");
        if (!token) {
          alert("Devi effettuare il login per registrare una cura.");
          return;
        }
        const id = btn.dataset.id;
        const tipo = btn.dataset.tipo;
        const piante = await loadJSON("piante.json");
        piante[id].ultima_cura = { ...(piante[id].ultima_cura || {}), [tipo]: new Date().toISOString().slice(0, 10) };
        notifySaving();
        const ok = await saveJSON("piante.json", piante);
        if (ok) location.reload();
      };
    });
  }

  // -----------------------------
  // Progetti attivi
  // -----------------------------
  const attivi = Object.entries(progetti || {}).filter(([, p]) => p.stato === "in_corso");

  if (attivi.length === 0) {
    progettiContainer.innerHTML = "<div class='card empty-state'>Nessun progetto in corso al momento.</div>";
  } else {
    progettiContainer.innerHTML = attivi.map(([key, p]) => {
      const condizioni = (p.condizioni || []).map(c => {
        const esito = meteo ? valutaCondizioneProgetto(c, meteo) : "maybe";
        const icon = esito === "ok" ? "✅" : esito === "no" ? "❌" : "❓";
        return `<li>${icon} ${c}</li>`;
      }).join("");

      const taskPendenti = (p.task || []).filter(t => t.stato !== "completato");

      return `
        <div class="card">
          <div class="progetto-title"><a href="progetto.html?id=${encodeURIComponent(key)}">${p.nome}</a></div>
          ${condizioni ? `<ul>${condizioni}</ul>` : ""}
          ${taskPendenti.length ? `<p class="small">${taskPendenti.length} task da completare</p>` : ""}
        </div>
      `;
    }).join("");
  }

  // -----------------------------
  // Digest testuale
  // -----------------------------
  const righeDigest = [`Attività del ${new Date().toLocaleDateString("it-IT")}`, ""];

  if (meteo) {
    righeDigest.push(`Meteo: pioggia 24h ${meteo.pioggia24h}mm, temp ${meteo.tempMinOggi}-${meteo.tempMaxOggi}°C, vento max ${meteo.ventoMaxOggi}km/h`);
    righeDigest.push("");
  }

  if (zoneConAzioni.length === 0) {
    righeDigest.push("Nessuna attività da svolgere oggi.");
  } else {
    zoneConAzioni.forEach(zonaKey => {
      righeDigest.push(`=== ${zonaKey} ===`);
      daFarePerZona[zonaKey].forEach(pianta => {
        pianta.azioni.forEach(a => {
          righeDigest.push(`${CURE_ICONS[a.tipo]} ${pianta.nome}: ${a.tipo} (${a.dettaglio})`);
        });
      });
      righeDigest.push("");
    });
  }

  if (attivi.length > 0) {
    righeDigest.push("=== Progetti in corso ===");
    attivi.forEach(([, p]) => righeDigest.push(`- ${p.nome}`));
  }

  digestBox.textContent = righeDigest.join("\n");
});
