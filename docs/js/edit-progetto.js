// docs/js/edit-progetto.js

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

function slugify(text) {
  return (text || "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-+|-+$)/g, "");
}

function condizioneRow(value = "") {
  const row = document.createElement("div");
  row.className = "dynamic-row";
  row.innerHTML = `
    <input type="text" class="condizione-input" value="${value.replace(/"/g, "&quot;")}" placeholder="es. assenza di pioggia">
    <button type="button" class="remove-row-btn">✕</button>
  `;
  row.querySelector(".remove-row-btn").onclick = () => row.remove();
  return row;
}

function taskRow(task = { nome: "", tipo: "", stato: "pianificato" }) {
  const row = document.createElement("div");
  row.className = "dynamic-row task-row";
  row.innerHTML = `
    <input type="text" class="task-nome-input" value="${(task.nome || "").replace(/"/g, "&quot;")}" placeholder="Nome task">
    <input type="text" class="task-tipo-input" value="${(task.tipo || "").replace(/"/g, "&quot;")}" placeholder="Tipo (es. monitoraggio)">
    <select class="task-stato-input">
      <option value="pianificato">Pianificato</option>
      <option value="in_corso">In corso</option>
      <option value="completato">Completato</option>
    </select>
    <button type="button" class="remove-row-btn">✕</button>
  `;
  row.querySelector(".task-stato-input").value = task.stato || "pianificato";
  row.querySelector(".remove-row-btn").onclick = () => row.remove();
  return row;
}

document.addEventListener("DOMContentLoaded", async () => {
  const id = getParam("id");
  const title = document.getElementById("edit-title");
  const form = document.getElementById("edit-form");

  if (!id) {
    title.textContent = "Progetto non specificato";
    form.style.display = "none";
    return;
  }

  const [progetti, zone] = await Promise.all([
    loadJSON("progetti.json"),
    loadJSON("zone.json")
  ]);

  if (!progetti) {
    title.textContent = "Errore nel caricamento dei progetti";
    form.style.display = "none";
    return;
  }

  const isNew = id === "NUOVO";
  let current = isNew ? null : progetti[id];

  if (!isNew && !current) {
    title.textContent = "Progetto non trovato";
    form.style.display = "none";
    return;
  }

  title.textContent = isNew ? "Nuovo progetto" : `Modifica: ${current.nome}`;

  // Popola select zona
  const zonaSel = document.getElementById("zona");
  for (const key of Object.keys(zone || {})) {
    const opt = document.createElement("option");
    opt.value = zone[key].nome;
    opt.textContent = zone[key].nome;
    zonaSel.appendChild(opt);
  }

  const p = current || {
    nome: "", zona: "", stato: "idea", avanzamento: 0,
    obiettivo: "", condizioni: [], task: [], aggiornamenti: [], note: ""
  };

  document.getElementById("nome").value = p.nome || "";
  zonaSel.value = p.zona || "";
  document.getElementById("stato").value = p.stato || "idea";
  document.getElementById("avanzamento").value = p.avanzamento || 0;
  document.getElementById("obiettivo").value = p.obiettivo || "";
  document.getElementById("note").value = p.note || "";

  const condizioniList = document.getElementById("condizioni-list");
  (p.condizioni || []).forEach(c => condizioniList.appendChild(condizioneRow(c)));

  const taskList = document.getElementById("task-list");
  (p.task || []).forEach(t => taskList.appendChild(taskRow(t)));

  document.getElementById("add-condizione").onclick = () => {
    condizioniList.appendChild(condizioneRow());
  };

  document.getElementById("add-task").onclick = () => {
    taskList.appendChild(taskRow());
  };

  form.onsubmit = async (e) => {
    e.preventDefault();

    const nome = document.getElementById("nome").value.trim();
    if (!nome) {
      alert("Il nome del progetto è obbligatorio.");
      return;
    }

    const condizioni = Array.from(condizioniList.querySelectorAll(".condizione-input"))
      .map(i => i.value.trim())
      .filter(v => v);

    const task = Array.from(taskList.querySelectorAll(".task-row")).map(row => ({
      nome: row.querySelector(".task-nome-input").value.trim(),
      tipo: row.querySelector(".task-tipo-input").value.trim(),
      stato: row.querySelector(".task-stato-input").value
    })).filter(t => t.nome);

    const data = {
      ...(current || {}),
      nome,
      zona: zonaSel.value,
      stato: document.getElementById("stato").value,
      avanzamento: Math.max(0, Math.min(100, parseInt(document.getElementById("avanzamento").value, 10) || 0)),
      obiettivo: document.getElementById("obiettivo").value.trim(),
      condizioni,
      task,
      aggiornamenti: current?.aggiornamenti || [],
      note: document.getElementById("note").value.trim()
    };

    const key = isNew ? `${slugify(nome)}-${Date.now()}` : id;
    progetti[key] = data;

    notifySaving();
    const ok = await saveJSON("progetti.json", progetti);

    if (ok) {
      alert(isNew ? "Progetto creato con successo." : "Progetto aggiornato con successo.");
      window.location.href = "progetti.html";
    } else {
      alert("Errore durante il salvataggio.");
    }
  };
});
