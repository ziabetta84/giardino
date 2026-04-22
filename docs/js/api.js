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

  try {
    const res = await fetch(apiUrl, { headers: getAuthHeaders() });

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
    const getRes = await fetch(apiUrl, { headers: getAuthHeaders() });

    if (!getRes.ok) {
      console.error("Errore nel recupero SHA:", filename);
      return false;
    }

    const fileData = await getRes.json();

    // 2. Prepara contenuto JSON
    const jsonText = JSON.stringify(data, null, 2);

    // 3. Codifica base64 UTF‑8
    const encoded = btoa(unescape(encodeURIComponent(jsonText)));

    // 4. Commit
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
