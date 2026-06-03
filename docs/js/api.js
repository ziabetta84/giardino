// docs/js/api.js

const REPO_USER = "ziabetta84";
const REPO_NAME = "giardino";
const BRANCH = "main";

// ------------------------------
// Utility: headers con token
// ------------------------------
function getAuthHeaders() {
  const token = localStorage.getItem("github_token");

  const headers = {
    "Accept": "application/vnd.github.v3+json"
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  return headers;
}

// ------------------------------
// 1) LEGGERE JSON da /docs/data/
// ------------------------------
async function loadJSON(filename) {
  const apiUrl = `https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/contents/docs/data/${filename}`;
  const token = localStorage.getItem("github_token");

  try {
    let res = await fetch(apiUrl, { headers: getAuthHeaders() });

    if (res.status === 401 && token) {
      console.warn("loadJSON: token GitHub non valido, rimuovo e riprovo senza token", filename);
      localStorage.removeItem("github_token");
      res = await fetch(apiUrl, { headers: { "Accept": "application/vnd.github.v3+json" } });
    }

    if (!res.ok) {
      console.error("Errore loadJSON:", filename, res.status);
      return null;
    }

    const file = await res.json();

    // Decodifica Base64 → UTF‑8 → JSON
    const decoded = decodeURIComponent(escape(atob(file.content)));
    return JSON.parse(decoded);

  } catch (e) {
    console.error("Errore rete loadJSON:", filename, e);
    return null;
  }
}


// ------------------------------
// 2) SCRIVERE JSON nel repo
// ------------------------------
async function saveJSON(filename, data) {
  const token = localStorage.getItem("github_token");

  if (!token) {
    alert("Token mancante. Devi effettuare il login.");
    return false;
  }

  const path = `docs/data/${filename}`;
  const apiUrl = `https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/contents/${path}`;

  try {
    // 1. Recupera SHA del file esistente
    let getRes = await fetch(apiUrl, { headers: getAuthHeaders() });

    if (getRes.status === 401) {
      console.warn("saveJSON: token GitHub non valido, rimuovo e richiedo di nuovo", filename);
      localStorage.removeItem("github_token");
      getRes = await fetch(apiUrl, { headers: { "Accept": "application/vnd.github.v3+json" } });
    }

    if (!getRes.ok) {
      console.error("Errore nel recupero SHA:", filename, getRes.status);
      return false;
    }

    const fileData = await getRes.json();

    // 2. Prepara contenuto JSON
    const jsonText = JSON.stringify(data, null, 2);

    // 3. Codifica base64 UTF‑8
    const encoded = btoa(unescape(encodeURIComponent(jsonText)));

    // 4. Commit
    notifySaving();

    const putRes = await fetch(apiUrl, {
      method: "PUT",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
        "Accept": "application/vnd.github.v3+json"
      },
      body: JSON.stringify({
        message: `Aggiorna ${filename}`,
        content: encoded,
        sha: fileData.sha
      })
    });

    if (putRes.ok) notifySaving();
    return putRes.ok;

  } catch (e) {
    console.error("Errore salvataggio JSON:", filename, e);
    return false;
  }
}

// ------------------------------
// 3) Helper: carica TUTTI i dati
// ------------------------------
async function loadAllData() {
  const settings = await loadJSON("settings.json");
  const zone = await loadJSON("zone.json");
  const sottozone = await loadJSON("sottozone.json");
  const piante = await loadJSON("piante.json");

  return { settings, zone, sottozone, piante };
}
