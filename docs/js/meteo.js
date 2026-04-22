// docs/js/meteo.js

document.addEventListener("DOMContentLoaded", async () => {
  const container = document.getElementById("meteo-container");
  container.innerHTML = "<div class='card'>Caricamento meteo...</div>";

  // 1) Carica settings.json
  const settings = await loadJSON("settings.json");

  if (!settings || !settings.location) {
    container.innerHTML = "<div class='card'>Errore: settings.json non valido.</div>";
    return;
  }

  const { lat, lon } = settings.location;
  const days = settings.meteo?.days || 3;

  // 2) Costruisci URL Open-Meteo
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode&timezone=auto&forecast_days=${days}`;

  // 3) Fetch meteo
  let data;
  try {
    const res = await fetch(url);
    data = await res.json();
  } catch (e) {
    container.innerHTML = "<div class='card'>Errore nel caricamento dei dati meteo.</div>";
    return;
  }

  if (!data.daily) {
    container.innerHTML = "<div class='card'>Dati meteo non disponibili.</div>";
    return;
  }

  // 4) Mappa codici meteo → icone/testi
  const WMO = {
    0: "☀️ Sereno",
    1: "🌤 Poco nuvoloso",
    2: "⛅ Parzialmente nuvoloso",
    3: "☁️ Coperto",
    45: "🌫 Nebbia",
    48: "🌫 Nebbia ghiacciata",
    51: "🌦 Pioviggine leggera",
    53: "🌦 Pioviggine",
    55: "🌧 Pioviggine intensa",
    61: "🌦 Pioggia leggera",
    63: "🌧 Pioggia",
    65: "🌧 Pioggia forte",
    71: "🌨 Neve leggera",
    73: "🌨 Neve",
    75: "❄️ Neve forte",
    95: "⛈ Temporale",
    96: "⛈ Temporale con grandine",
    99: "⛈ Grandine forte"
  };

  // 5) Render UI
  container.innerHTML = "";

  for (let i = 0; i < days; i++) {
    const date = data.daily.time[i];
    const tMin = data.daily.temperature_2m_min[i];
    const tMax = data.daily.temperature_2m_max[i];
    const rain = data.daily.precipitation_sum[i];
    const code = data.daily.weathercode[i];

    const card = document.createElement("div");
    card.className = "card meteo-card";

    card.innerHTML = `
      <div class="meteo-date">${formatDate(date)}</div>
      <div class="meteo-icon">${WMO[code] || "❓"}</div>
      <div class="meteo-temp">
        <strong>${tMax}°C</strong> / ${tMin}°C
      </div>
      <div class="meteo-rain">💧 ${rain} mm</div>
    `;

    container.appendChild(card);
  }
});

// ------------------------------
// Utility: formatta data
// ------------------------------
function formatDate(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString("it-IT", {
    weekday: "long",
    day: "numeric",
    month: "long"
  });
}
