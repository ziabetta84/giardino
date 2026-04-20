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
        zona = plant.get("zona", "sconosciuta")
        sotto = plant.get("sottozona", "generale")
        grouped.setdefault(zona, {}).setdefault(sotto, []).append(plant)

    for zona, sottozoni in grouped.items():
        lines.append(f"## 🏡 Zona: **{zona}**")
        for sotto, plist in sottozoni.items():
            lines.append(f"### 📍 Sottozona: **{sotto}**")
            for plant in plist:
                name = plant.get("nome", "sconosciuta")
                result = evaluate_plant(plant, meteo)

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

    # Mini‑riassunto per GitHub Actions (prime 40 righe)
    summary_lines = report.split("\n")[:40]
    with open("summary.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(summary_lines))

    print("Report generato con successo.")


if __name__ == "__main__":
    main()
