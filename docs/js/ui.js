function saveSettings() {
  localStorage.setItem("lat", document.getElementById("lat").value);
  localStorage.setItem("lon", document.getElementById("lon").value);
  localStorage.setItem("theme", document.getElementById("theme").value);
  alert("Impostazioni salvate");
}
