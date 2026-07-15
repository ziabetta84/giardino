// docs/js/pianta.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

const STAGIONI = ["primavera", "estate", "autunno", "inverno"];
const CURE = [
  { tipo: "irrigazione", label: "Irrigazione", icon: "💧" },
  { tipo: "concimazione", label: "Concimazione", icon: "🌱" },
  { tipo: "potatura", label: "Potatura", icon: "✂️" }
];

document.addEventListener("DOMContentLoaded", async () => {
  const id = getParam("id");

  const header = document.getElementById("pianta-title");
  const infoContainer = document.getElementById("pianta-info");
  const attivitaContainer = document.getElementById("pianta-attivita");
  const alertContainer = document.getElementById("pianta-alert");

  if (!id) {
    header.textContent = "Pianta non specificata";
    return;
  }

  const piante = await loadJSON("piante.json");

  if (!piante || !piante[id]) {
    header.textContent = "Pianta non trovata";
    return;
  }

  const [specieData, zoneData, sottozoneData, settings] = await Promise.all([
    loadJSON("specie.json"),
    loadJSON("zone.json"),
    loadJSON("sottozone.json"),
    loadJSON("settings.json")
  ]);

  const p = piante[id];
  const specie = specieData?.[p.specie];
  const zonaInfo = zoneData?.[p.zona];

  let meteo = null;
  if (settings?.location) {
    meteo = await fetchMeteoPerRegole(settings.location.lat, settings.location.lon);
  }

  // -----------------------------
  // Titolo
  // -----------------------------
  header.textContent = specie?.nome || p.specie || id;

  // -----------------------------
  // 1) INFO GENERALI
  // -----------------------------
  infoContainer.innerHTML = `
    <div class="info-block">
      <p><strong>Specie:</strong> ${specie?.nome || p.specie || "-"}</p>
      <p><strong>Zona:</strong> ${p.zona || "-"}</p>
      <p><strong>Sottozona:</strong> ${p.sottozona || "-"}</p>
      ${p.varieta ? `<p><strong>Varietà:</strong> ${p.varieta}</p>` : ""}
      ${p.impianto ? `<p><strong>Impianto:</strong> ${p.impianto}</p>` : ""}
      ${p.note ? `<p><strong>Note:</strong> ${p.note}</p>` : ""}
    </div>
  `;

  // -----------------------------
  // 2) ATTIVITÀ (irrigazione, concimazione, potatura)
  // -----------------------------
  if (!specie) {
    attivitaContainer.innerHTML = "<p>Specie non trovata: nessuna indicazione di cura disponibile.</p>";
  } else {
    attivitaContainer.innerHTML = CURE.map(({ tipo, label, icon }) => {
      const stagioneTabs = STAGIONI.map(s => `
        <li><strong>${s.charAt(0).toUpperCase() + s.slice(1)}:</strong> ${specie.manutenzione?.[tipo]?.[s] || "-"}</li>
      `).join("");

      let stato;
      if (tipo === "potatura") {
        // La potatura è un suggerimento stagionale con priorità, non una soglia a giorni.
        const { priorita } = valutaPotatura(specie);
        if (priorita === 0) {
          stato = `<span class="cura-badge cura-badge-off">nessuna azione richiesta</span>`;
        } else if (priorita === 1) {
          stato = `<span class="cura-badge cura-badge-due">priorità alta</span>`;
        } else {
          stato = `<span class="cura-badge cura-badge-ok">priorità normale</span>`;
        }
      } else {
        const esito = valutaCura(p, specie, zonaInfo, meteo, tipo);
        if (esito.motivo === "sospesa") {
          stato = `<span class="cura-badge cura-badge-off">sospesa in questa stagione</span>`;
        } else if (esito.daFare) {
          stato = `<span class="cura-badge cura-badge-due">da fare (${esito.giorni} giorni)</span>`;
        } else {
          stato = `<span class="cura-badge cura-badge-ok">${esito.motivo === "recente" ? `fatta ${esito.giorni} giorni fa` : esito.motivo}</span>`;
        }
      }

      return `
        <div class="cura-item">
          <h3>${icon} ${label} ${stato}</h3>
          <ul>${stagioneTabs}</ul>
          <button type="button" class="btn-fatto" data-tipo="${tipo}">✅ Fatto oggi</button>
        </div>
      `;
    }).join("");

    attivitaContainer.querySelectorAll(".btn-fatto").forEach(btn => {
      btn.onclick = async () => {
        const token = localStorage.getItem("github_token");
        if (!token) {
          alert("Devi effettuare il login per registrare una cura.");
          return;
        }

        const prevText = btn.textContent;
        btn.disabled = true;
        btn.textContent = "⏳ Salvataggio...";

        try {
          const tipo = btn.dataset.tipo;
          const pianteAggiornate = await loadJSON("piante.json");
          if (!pianteAggiornate || !pianteAggiornate[id]) {
            throw new Error("Pianta non trovata (dati non aggiornati?).");
          }
          pianteAggiornate[id].ultima_cura = { ...(pianteAggiornate[id].ultima_cura || {}), [tipo]: new Date().toISOString().slice(0, 10) };
          notifySaving();
          const ok = await saveJSON("piante.json", pianteAggiornate);
          if (!ok) throw new Error("Salvataggio non riuscito. Controlla di essere ancora loggato e riprova.");
          location.reload();
        } catch (err) {
          alert(`Errore: ${err.message}`);
          btn.disabled = false;
          btn.textContent = prevText;
        }
      };
    });
  }

  // -----------------------------
  // 3) ALERT (statici da specie + dinamici da meteo)
  // -----------------------------
  const alertStatici = specie?.alert || [];
  const alertDinamici = alertMeteo(meteo);
  const tuttiAlert = [...alertStatici, ...alertDinamici];

  alertContainer.innerHTML = tuttiAlert.length
    ? `<ul>${tuttiAlert.map(a => `<li>${a}</li>`).join("")}</ul>`
    : "<p>Nessun alert.</p>";

  // -----------------------------
  // 4) Pulsanti azione
  // -----------------------------
  const btn = document.getElementById("modifica-pianta");
  btn.onclick = () => {
    const token = localStorage.getItem("github_token");
    if (!token) {
      alert("Devi effettuare il login per modificare.");
      return;
    }
    window.location.href = `edit-pianta.html?id=${encodeURIComponent(id)}`;
  };

  const agenteLink = document.getElementById("agente-pianta-link");
  agenteLink.href = `agente.html?pianta=${encodeURIComponent(id)}&azione=salute`;
});
