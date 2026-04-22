// Lista dei file da monitorare
const FILES = ["zone.json", "sottozone.json", "piante.json"];

let localCache = {};

async function fetchRemote(file) {
  const url = file + "?cb=" + Date.now();
  return await fetch(url).then(r => r.text()).catch(() => null);
}

async function checkSync() {
  let changed = false;
  let error = false;

  for (const file of FILES) {
    const remote = await fetchRemote(file);

    if (remote === null) {
      error = true;
      continue;
    }

    if (!localCache[file]) {
      localCache[file] = remote;
    } else if (localCache[file] !== remote) {
      changed = true;
      localCache[file] = remote;
    }
  }

  if (error) {
    setStatus("🔴", "Errore di connessione a GitHub");
    return;
  }

  if (changed) {
    setStatus("🔵", "Nuove modifiche disponibili");
    return;
  }

  setStatus("🟢", "Tutto sincronizzato");
}

function setStatus(icon, text) {
  document.getElementById("status-icon").textContent = icon;
  document.getElementById("status-text").textContent =
    text + " (" + new Date().toLocaleTimeString() + ")";
}

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("status-action").onclick = () => {
    location.reload(true);
  };

  // Primo controllo immediato
  checkSync();

  // Controllo ogni 5 secondi
  setInterval(checkSync, 5000);
});

// Da chiamare dopo ogni salvataggio
function notifySaving() {
  setStatus("🟡", "Sincronizzazione in corso…");
}
