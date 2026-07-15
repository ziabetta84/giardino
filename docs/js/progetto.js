// docs/js/progetto.js

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

const STATO_LABELS = {
  idea: "Idea",
  pianificato: "Pianificato",
  in_corso: "In corso",
  completato: "Completato",
  archiviato: "Archiviato"
};

const CONDIZIONE_ESITO = {
  ok: { icon: "✅", label: "condizione favorevole" },
  no: { icon: "❌", label: "condizione non soddisfatta" },
  maybe: { icon: "❓", label: "da verificare" }
};

document.addEventListener("DOMContentLoaded", async () => {
  const id = getParam("id");
  const title = document.getElementById("progetto-title");

  if (!id) {
    title.textContent = "Progetto non specificato";
    return;
  }

  const progetti = await loadJSON("progetti.json");

  if (!progetti || !progetti[id]) {
    title.textContent = "Progetto non trovato";
    return;
  }

  const p = progetti[id];
  title.textContent = p.nome || id;

  // -----------------------------
  // Meta (zona, stato, avanzamento)
  // -----------------------------
  const stato = p.stato || "idea";
  const avanzamento = Math.max(0, Math.min(100, p.avanzamento || 0));

  document.getElementById("progetto-meta").innerHTML = `
    <div class="progetto-meta">
      <span class="stato-badge stato-${stato}">${STATO_LABELS[stato] || stato}</span>
      ${p.zona ? `<span class="progetto-zona">📍 ${p.zona}</span>` : ""}
    </div>
    <div class="progress-bar">
      <div class="progress-bar-fill" style="width:${avanzamento}%"></div>
    </div>
  `;

  document.getElementById("progetto-obiettivo").innerHTML =
    p.obiettivo ? `<p>${p.obiettivo}</p>` : "<p>Nessun obiettivo definito.</p>";

  // -----------------------------
  // Condizioni (valutate col meteo attuale)
  // -----------------------------
  const condizioniContainer = document.getElementById("progetto-condizioni");
  const condizioni = p.condizioni || [];

  if (condizioni.length === 0) {
    condizioniContainer.innerHTML = "<p>Nessuna condizione da verificare.</p>";
  } else {
    const settings = await loadJSON("settings.json");
    const meteo = settings?.location
      ? await fetchMeteoPerRegole(settings.location.lat, settings.location.lon)
      : null;

    condizioniContainer.innerHTML = `<ul>${condizioni.map(c => {
      const esito = meteo ? valutaCondizioneProgetto(c, meteo) : "maybe";
      const info = CONDIZIONE_ESITO[esito] || CONDIZIONE_ESITO.maybe;
      return `<li>${info.icon} ${c} <span class="small">(${info.label})</span></li>`;
    }).join("")}</ul>`;
  }

  // -----------------------------
  // Task
  // -----------------------------
  const taskContainer = document.getElementById("progetto-task");
  const task = p.task || [];

  taskContainer.innerHTML = task.length
    ? `<ul>${task.map(t => `<li><strong>${t.nome}</strong>${t.tipo ? ` — ${t.tipo}` : ""} <span class="stato-badge stato-${t.stato || "pianificato"}">${STATO_LABELS[t.stato] || t.stato || "pianificato"}</span></li>`).join("")}</ul>`
    : "<p>Nessun task definito.</p>";

  // -----------------------------
  // Aggiornamenti (timeline)
  // -----------------------------
  const aggiornamentiContainer = document.getElementById("progetto-aggiornamenti");

  function renderAggiornamenti() {
    const aggiornamenti = [...(p.aggiornamenti || [])].sort((a, b) => (b.data || "").localeCompare(a.data || ""));
    aggiornamentiContainer.innerHTML = aggiornamenti.length
      ? `<ul class="timeline">${aggiornamenti.map(a => `<li><strong>${a.data}</strong> — ${a.descrizione}</li>`).join("")}</ul>`
      : "<p>Nessun aggiornamento registrato.</p>";
  }

  renderAggiornamenti();

  document.getElementById("add-aggiornamento-form").onsubmit = async (e) => {
    e.preventDefault();

    const token = localStorage.getItem("github_token");
    if (!token) {
      alert("Devi effettuare il login per aggiungere un aggiornamento.");
      return;
    }

    const input = document.getElementById("nuovo-aggiornamento");
    const descrizione = input.value.trim();
    if (!descrizione) return;

    p.aggiornamenti = [...(p.aggiornamenti || []), {
      data: new Date().toISOString().slice(0, 10),
      descrizione
    }];
    progetti[id] = p;

    notifySaving();
    const ok = await saveJSON("progetti.json", progetti);

    if (ok) {
      input.value = "";
      renderAggiornamenti();
    } else {
      alert("Errore durante il salvataggio.");
    }
  };

  // -----------------------------
  // Pulsante Modifica
  // -----------------------------
  document.getElementById("modifica-progetto").onclick = () => {
    const token = localStorage.getItem("github_token");
    if (!token) {
      alert("Devi effettuare il login per modificare.");
      return;
    }
    window.location.href = `edit-progetto.html?id=${encodeURIComponent(id)}`;
  };
});
