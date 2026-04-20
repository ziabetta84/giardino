import os
import sys
import json
import datetime

# Aggiunge la cartella utils al path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UTILS_DIR = os.path.join(BASE_DIR, "utils")
sys.path.append(UTILS_DIR)

from loader import load_all_plants
from weather import get_weather_data
from smart_rules import evaluate_plant


# ---------------------------------------------------------
#  FORMATTING
# ---------------------------------------------------------

def format_bool(flag):
    return "SI" if flag else "no"


def format_alerts(alerts):
    if not alerts:
        return "nessuno"
    return "\n".join(f"- {a}" for a in alerts)


# ---------------------------------------------------------
#  REPORT
# ---------------------------------------------------------

def generate_report(plants, meteo):
    today = datetime.date.today().strftime("%Y-%m-%d")
    lines = []
    lines.append(f"🌱 **Report giornaliero del {today}**")
    lines.append("")

    # Raggruppa per zona/sottozona
    grouped = {}
    for plant in plants:
        zona = plant.zona or "sconosciuta"
        sotto = plant.sottozona or "generale"
        grouped.setdefault(zona, {}).setdefault(sotto, []).append(plant)

    for zona, sottozoni in grouped.items():
        lines.append(f"## 🏡 Zona: **{zona}**")
        for sotto, plist in sottozoni.items():
            lines.append(f"### 📍 Sottozona: **{sotto}**")
            for plant in plist:
                name = plant.nome
                result = evaluate_plant(plant.to_dict(), meteo)

                lines.append(f"#### 🌿 {name}")
                lines.append(f"- Stagione: **{result['stagione']}**")
                lines.append(f"- Irrigazione: **{format_bool(result['irrigazione'])}**")
                lines.append(f"- Concimazione: **{format_bool(result['concimazione'])}**")
                lines.append(f"- Potatura: **{format_bool(result['potatura'])}**")
                lines.append(f"- Alert:")
                lines.append(format_alerts(result["alert"]))
                lines.append("")

        lines.append("")

    return "\n".join(lines)

def generate_summary(plants, meteo):
    irrig = 0
    conc = 0
    pota = 0
    alert_meteo = 0

    zone_set = set()

    for plant in plants:
        result = evaluate_plant(plant.to_dict(), meteo)

        if result["irrigazione"]:
            irrig += 1
        if result["concimazione"]:
            conc += 1
        if result["potatura"]:
            pota += 1
        if result["alert"]:
            alert_meteo += 1

        zone_set.add(plant.zona)

    lines = []
    lines.append(f"Totale piante: **{len(plants)}**")
    lines.append(f"Zone coinvolte: **{', '.join(sorted(zone_set))}**")
    lines.append("")
    lines.append(f"💧 Irrigazione consigliata: **{irrig}**")
    lines.append(f"🌿 Concimazione consigliata: **{conc}**")
    lines.append(f"✂️ Potatura consigliata: **{pota}**")
    lines.append(f"⚠️ Alert meteo: **{alert_meteo}**")

    return "\n".join(lines)


# ---------------------------------------------------------
#  MAIN
# ---------------------------------------------------------

def main():
    print("Caricamento piante...")
    plants = load_all_plants()

    print("Caricamento meteo...")
    meteo = get_weather_data()

    print("Generazione report...")
    report = generate_report(plants, meteo)

    # Scrive il report completo
    with open("report.txt", "w", encoding="utf-8") as f:
        f.write(report)

    # Mini‑riassunto vero (compatto e utile)
    summary = generate_summary(plants, meteo)
    with open("summary.txt", "w", encoding="utf-8") as f:
        f.write(summary)


    print("Report generato con successo.")


if __name__ == "__main__":
    main()
