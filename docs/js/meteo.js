const lat = localStorage.getItem("lat");
const lon = localStorage.getItem("lon");

fetch(`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true`)
  .then(r => r.json())
  .then(data => {
    const c = document.getElementById("meteo-container");
    const w = data.current_weather;
    c.innerHTML = `
      <div class="card">
        <h2>${w.temperature}°C</h2>
        <p>Vento: ${w.windspeed} km/h</p>
        <p>Direzione: ${w.winddirection}°</p>
      </div>
    `;
  });
