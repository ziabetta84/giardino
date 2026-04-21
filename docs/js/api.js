// js/api.js

const REPO_USER = "ziabetta84";
const REPO_NAME = "giardino";
const BRANCH = "main";

async function listDir(path) {
  const url = `https://api.github.com/repos/${REPO_USER}/${REPO_NAME}/contents/${path}`;
  const res = await fetch(url);
  if (!res.ok) {
    console.error("Errore listDir", path, res.status);
    return [];
  }
  return await res.json();
}

async function getFile(path) {
  const url = `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/${BRANCH}/${path}`;
  const res = await fetch(url);
  if (!res.ok) {
    console.error("Errore getFile", path, res.status);
    return "";
  }
  return await res.text();
}
