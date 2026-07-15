// docs/js/rules-engine.js
// Motore di regole condiviso per Attività, Progetti e Agente AI.
// Porta in JS la logica di scripts/utils/smart_rules.py e project_rules.py,
// senza toccare la pipeline Python esistente.

function getStagione(date = new Date()) {
  const m = date.getMonth() + 1;
  if ([3, 4, 5].includes(m)) return "primavera";
  if ([6, 7, 8].includes(m)) return "estate";
  if ([9, 10, 11].includes(m)) return "autunno";
  return "inverno";
}

function giorniDa(dateStr) {
  if (!dateStr) return 999;
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return 999;
  return Math.floor((Date.now() - d.getTime()) / 86400000);
}

// Converte un testo libero di frequenza ("ogni 5-7 giorni", "una volta al mese",
// "sospesa"...) nel numero minimo di giorni dell'intervallo, o null se non periodica.
function parseFrequency(text) {
  if (!text) return null;
  const t = text.toLowerCase();

  if (/sospes|nessuna/.test(t)) return null;

  let m = t.match(/ogni\s+(\d+)(?:\s*-\s*\d+)?\s*giorni/);
  if (m) return parseInt(m[1], 10);

  m = t.match(/ogni\s+(\d+)(?:\s*-\s*\d+)?\s*settiman/);
  if (m) return parseInt(m[1], 10) * 7;

  if (/una volta al mese|mensile/.test(t)) return 30;
  if (/una volta a settimana|settimanale/.test(t)) return 7;

  m = t.match(/(\d+)\s*giorni/);
  if (m) return parseInt(m[1], 10);

  return null;
}

// Recupera dati meteo (ultime 48h + oggi) per le soglie del motore regole.
// Query separata da js/meteo.js: qui servono past_days e variabili diverse
// (probabilità pioggia, vento, umidità) non usate dalla card meteo.
async function fetchMeteoPerRegole(lat, lon) {
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` +
    `&daily=precipitation_sum,precipitation_probability_max,temperature_2m_min,temperature_2m_max,windspeed_10m_max,relative_humidity_2m_max` +
    `&past_days=2&forecast_days=1&timezone=auto`;

  try {
    const res = await fetch(url);
    const data = await res.json();
    if (!data.daily || !data.daily.time) return null;

    const d = data.daily;
    const iOggi = d.time.length - 1;

    return {
      pioggia48h: (d.precipitation_sum[iOggi - 2] || 0) + (d.precipitation_sum[iOggi - 1] || 0),
      pioggia24h: d.precipitation_sum[iOggi - 1] || 0,
      probPioggiaOggi: d.precipitation_probability_max?.[iOggi] ?? 0,
      tempMinOggi: d.temperature_2m_min[iOggi],
      tempMaxOggi: d.temperature_2m_max[iOggi],
      ventoMaxOggi: d.windspeed_10m_max?.[iOggi] ?? 0,
      umiditaMaxOggi: d.relative_humidity_2m_max?.[iOggi] ?? 0
    };
  } catch (e) {
    console.error("Errore fetch meteo regole:", e);
    return null;
  }
}

// Valuta se una cura (irrigazione/concimazione/potatura) è da fare per una pianta.
// tipo: "irrigazione" | "concimazione" | "potatura"
function valutaCura(pianta, specie, zonaInfo, meteo, tipo) {
  const stagione = getStagione();
  const testoStagionale = specie?.manutenzione?.[tipo]?.[stagione] || "";
  const freqGiorni = parseFrequency(testoStagionale);

  if (freqGiorni === null) {
    return { daFare: false, motivo: "sospesa", testo: testoStagionale };
  }

  const giorni = giorniDa(pianta.ultima_cura?.[tipo]);
  if (giorni < freqGiorni) {
    return { daFare: false, motivo: "recente", testo: testoStagionale, giorni, freqGiorni };
  }

  if (tipo === "irrigazione" && zonaInfo?.tipo === "esterno" && meteo) {
    if (meteo.pioggia48h > 3) return { daFare: false, motivo: "pioggia recente (48h)", testo: testoStagionale };
    if (meteo.pioggia24h > 1) return { daFare: false, motivo: "pioggia recente (24h)", testo: testoStagionale };
    if (meteo.probPioggiaOggi > 40) return { daFare: false, motivo: "pioggia probabile oggi", testo: testoStagionale };
    if (meteo.tempMinOggi < 5) return { daFare: false, motivo: "temperatura bassa", testo: testoStagionale };
  }

  return { daFare: true, motivo: "scaduta", testo: testoStagionale, giorni, freqGiorni };
}

// Priorità potatura in base a parole chiave nel testo stagionale (0 = non mostrare).
function prioritaPotatura(testo) {
  if (!testo) return 0;
  const t = testo.toLowerCase();
  if (/nessuna|pulizia|rimozione foglie|parti secche/.test(t)) return 0;
  if (/drastic|contenimento|taglio forte|rimozione steli|post-fioritura/.test(t)) return 1;
  return 2;
}

// La potatura non segue una soglia "giorni da ultima cura" come irrigazione/
// concimazione: è un suggerimento stagionale con priorità (vedi prioritaPotatura).
function valutaPotatura(specie) {
  const stagione = getStagione();
  const testo = specie?.manutenzione?.potatura?.[stagione] || "";
  return { testo, priorita: prioritaPotatura(testo) };
}

// Alert dinamici generati dal meteo corrente (soglie da smart_rules.py).
function alertMeteo(meteo) {
  const alerts = [];
  if (!meteo) return alerts;
  if (meteo.pioggia48h > 20) alerts.push("⚠️ Rischio ristagno idrico (pioggia abbondante nelle ultime 48h)");
  if (meteo.tempMinOggi < 3) alerts.push("❄️ Rischio gelo (temperatura minima sotto i 3°C)");
  if (meteo.ventoMaxOggi > 40) alerts.push("💨 Rischio danni da vento forte");
  if (meteo.umiditaMaxOggi > 90) alerts.push("🍄 Rischio muffe/funghi (umidità molto alta)");
  return alerts;
}

// Valuta una condizione testuale di un progetto (es. "assenza di pioggia")
// rispetto al meteo corrente. Ritorna "ok" | "no" | "maybe".
function valutaCondizioneProgetto(testo, meteo) {
  if (!testo || !meteo) return "maybe";
  const t = testo.toLowerCase();

  if (t.includes("assenza di pioggia") && meteo.pioggia24h > 0) return "no";
  if (t.includes("non troppo ventos") && meteo.ventoMaxOggi > 20) return "no";

  const m = t.match(/temperatura\s*>\s*(\d+)/);
  if (m && meteo.tempMaxOggi < parseFloat(m[1])) return "no";

  return "ok";
}
