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

def generate_action_report(plants, meteo):
    irrig_by_zone = {}
    conc_by_zone = {}
    pota_by_zone = {}

    for plant in plants:
        result = evaluate_plant(plant.to_dict(), meteo)
        zona = plant.zona or "sconosciuta"
        nome = plant.nome

        # Irrigazione
        if result["irrigazione"]:
            irrig_by_zone.setdefault(zona, []).append(nome)

        # Concimazione
        if result["concimazione"]:
            conc_by_zone.setdefault(zona, []).append(nome)

        # Potatura (solo priorità 1 e 2)
        if result["potatura"]:
            prio = result["potatura_priority"]
            pota_by_zone.setdefault(zona, []).append((prio, nome))

    lines = []

    # IRRIGAZIONE
    lines.append("## 💧 Piante da irrigare")
    if irrig_by_zone:
        for zona in sorted(irrig_by_zone.keys()):
            lines.append(f"### {zona}")
            for p in sorted(irrig_by_zone[zona]):
                lines.append(f"- {p}")
    else:
        lines.append("Nessuna")

    lines.append("")

    # CONCIMAZIONE
    lines.append("## 🌿 Piante da concimare")
    if conc_by_zone:
        for zona in sorted(conc_by_zone.keys()):
            lines.append(f"### {zona}")
            for p in sorted(conc_by_zone[zona]):
                lines.append(f"- {p}")
    else:
        lines.append("Nessuna")

    lines.append("")

    # POTATURA (ordinata per priorità)
    lines.append("## ✂️ Piante da potare")
    if pota_by_zone:
        for zona in sorted(pota_by_zone.keys()):
            lines.append(f"### {zona}")
            # ordina per priorità (1 → 2)
            for prio, p in sorted(pota_by_zone[zona], key=lambda x: x[0]):
                lines.append(f"- {p}")
    else:
        lines.append("Nessuna")

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

    # Report operativo (solo piante su cui intervenire)
    action_report = generate_action_report(plants, meteo)
    with open("summary.txt", "w", encoding="utf-8") as f:
        f.write(action_report + "\n")

    print("Report generato con successo.")


if __name__ == "__main__":
    main()
