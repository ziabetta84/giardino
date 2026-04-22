// docs/js/pianta.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const nome = getParam("nome");

  const header = document.getElementById("pianta-title");
  const infoContainer = document.getElementById("pianta-info");
  const attivitaContainer = document.getElementById("pianta-attivita");
  const alertContainer = document.getElementById("pianta-alert");

  if (!nome) {
    header.textContent = "Pianta non specificata";
    return;
  }

  // Carica tutte le piante
  const piante = await loadJSON("piante.json");

  if (!piante || !piante[nome]) {
    header.textContent = "Pianta non trovata";
    return;
  }

  const p = piante[nome];

  // Titolo
  header.textContent = p.nome || nome;

  // -----------------------------
  // 1) INFO GENERALI
  // -----------------------------
  infoContainer.innerHTML = `
    <div class="info-block">
      <p><strong>Specie:</strong> ${p.specie || "-"}</p>
      <p><strong>Zona:</strong> ${p.zona || "-"}</p>
      <p><strong>Sottozona:</strong> ${p.sottozona || "-"}</p>
    </div>
  `;

  // -----------------------------
  // 2) ATTIVITÀ (irrigazione, concimazione, potatura)
  // -----------------------------
  const a = p.attivita || {};

  attivitaContainer.innerHTML = `
    <h3>Irrigazione</h3>
    <ul>
      <li><strong>Primavera:</strong> ${a.irrigazione?.primavera || "-"}</li>
      <li><strong>Estate:</strong> ${a.irrigazione?.estate || "-"}</li>
      <li><strong>Autunno:</strong> ${a.irrigazione?.autunno || "-"}</li>
      <li><strong>Inverno:</strong> ${a.irrigazione?.inverno || "-"}</li>
    </ul>

    <h3>Concimazione</h3>
    <ul>
      <li><strong>Primavera:</strong> ${a.concimazione?.primavera || "-"}</li>
      <li><strong>Estate:</strong> ${a.concimazione?.estate || "-"}</li>
      <li><strong>Autunno:</strong> ${a.concimazione?.autunno || "-"}</li>
      <li><strong>Inverno:</strong> ${a.concimazione?.inverno || "-"}</li>
    </ul>

    <h3>Potatura</h3>
    <ul>
      <li><strong>Primavera:</strong> ${a.potatura?.primavera || "-"}</li>
      <li><strong>Estate:</strong> ${a.potatura?.estate || "-"}</li>
      <li><strong>Autunno:</strong> ${a.potatura?.autunno || "-"}</li>
      <li><strong>Inverno:</strong> ${a.potatura?.inverno || "-"}</li>
    </ul>
  `;

  // -----------------------------
  // 3) ALERT (HTML libero)
  // -----------------------------
  alertContainer.innerHTML = p.alert || "<p>Nessun alert.</p>";

  // -----------------------------
  // 4) Pulsante Modifica
  // -----------------------------
  const btn = document.getElementById("modifica-pianta");
  btn.onclick = () => {
    const token = localStorage.getItem("github_token");
    if (!token) {
      alert("Devi effettuare il login per modificare.");
      return;
    }
    window.location.href = `edit-pianta.html?nome=${encodeURIComponent(nome)}`;
  };
});
