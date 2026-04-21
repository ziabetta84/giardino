// js/api.js

const REPO_USER = "ziabetta84";
const REPO_NAME = "giardino";
const BRANCH = "main";

// Prepara headers con token se presente
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

// Lista i file/cartelle in una directory del repo
async function listDir(path) {
  const url = `https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/contents/${path}?t=${Date.now()}`;

  try {
    const res = await fetch(url, { headers: getAuthHeaders() });

    if (!res.ok) {
      console.error("Errore listDir", path, res.status);
      return [];
    }

    return await res.json();
  } catch (e) {
    console.error("Errore rete listDir", path, e);
    return [];
  }
}

// Ottiene un file RAW dal repo (UTF‑8 corretto)
async function getFile(path) {
  const url = `https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/contents/${path}?t=${Date.now()}`;

  try {
    const res = await fetch(url, { headers: getAuthHeaders() });

    if (!res.ok) {
      console.error("Errore getFile", path, res.status);
      return "";
    }

    const fileData = await res.json();

    // Decodifica UTF‑8 corretta
    const text = new TextDecoder("utf-8").decode(
      Uint8Array.from(atob(fileData.content), c => c.charCodeAt(0))
    );

    return text;
  } catch (e) {
    console.error("Errore rete getFile", path, e);
    return "";
  }
}
