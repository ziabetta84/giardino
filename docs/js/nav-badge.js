// docs/js/nav-badge.js
// Calcola il numero di attività da svolgere e lo mostra nel badge di nav.html.
// Usa le stesse funzioni di rules-engine.js sfruttate da docs/js/attivita.js.

document.addEventListener("DOMContentLoaded", async () => {
  const badge = document.getElementById("nav-badge-attivita");
  if (!badge) return;

  try {
    const [piante, specieData, zone, settings] = await Promise.all([
      loadJSON("piante.json"),
      loadJSON("specie.json"),
      loadJSON("zone.json"),
      loadJSON("settings.json")
    ]);

    if (!piante || !specieData) return;

    let meteo = null;
    if (settings?.location) {
      meteo = await fetchMeteoPerRegole(settings.location.lat, settings.location.lon);
    }

    let count = 0;
    for (const id of Object.keys(piante)) {
      const p = piante[id];
      const specie = specieData[p.specie];
      if (!specie) continue;
      const zonaInfo = zone?.[p.zona];

      ["irrigazione", "concimazione"].forEach(tipo => {
        if (valutaCura(p, specie, zonaInfo, meteo, tipo).daFare) count++;
      });

      if (valutaPotatura(specie).priorita > 0) count++;
    }

    if (count > 0) {
      badge.textContent = count;
      badge.style.display = "inline-block";
    }
  } catch (e) {
    console.error("Errore calcolo badge attività:", e);
  }
});
