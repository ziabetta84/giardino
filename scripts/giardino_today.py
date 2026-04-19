#!/usr/bin/env python3
import sys, os

# Aggiunge /scripts e /scripts/utils al PYTHONPATH
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)
sys.path.append(os.path.join(BASE_DIR, "utils"))

from utils.loader import load_all_plants
from utils.weather import get_weather_today, get_weather_last_48h
from utils.smart_rules import evaluate_plant
from utils.projects import load_projects
from utils.project_rules import evaluate_project_task


ROOT = "zone"


def group_by_zone(plants):
    grouped = {}
    for p in plants:
        key = f"{p.zona}/{p.sottozona}" if p.sottozona else p.zona
        grouped.setdefault(key, []).append(p)
    return grouped


def format_section_title(title):
    return f"\n=== {title.upper()} ===\n"


def main():
    # -------------------------
    # 1. Carica piante
    # -------------------------
    plants = load_all_plants(ROOT)
    grouped = group_by_zone(plants)

    # -------------------------
    # 2. Meteo
    # -------------------------
    meteo_today = get_weather_today()
    meteo_48h = get_weather_last_48h()

    meteo = {}
    if meteo_today:
        meteo.update(meteo_today)
    if meteo_48h:
        meteo.update(meteo_48h)

    # -------------------------
    # 3. Report completo
    # -------------------------
    print("\n🌱 GIARDINO — REPORT GIORNALIERO\n")

    if meteo:
        print("Meteo:")
        print(f"- 🌧️ Pioggia oggi: {meteo.get('rain_mm', 0)} mm")
        print(f"- 🌧️ Pioggia ultime 48h: {meteo.get('rain_last_48h', 0)} mm")
        print(f"- 🌡️ Temp max: {meteo.get('temp_max', 0)}°C")
        print(f"- 💨 Vento max: {meteo.get('wind_max', 0)} km/h\n")
    else:
        print("⚠️ Meteo non disponibile\n")

    # -------------------------
    # 4. Piante per zona
    # -------------------------
    for zone, plist in grouped.items():
        print(format_section_title(zone))

        for p in plist:
            result = evaluate_plant(p, meteo)

            print(f"- {p.nome} ({p.specie})")

            if result["irrigazione"]:
                print(f"  • 💧 Irrigazione: {result['irrigazione']}")

            if result["concimazione"]:
                print(f"  • 🌱 Concimazione: {result['concimazione']}")

            if result["potatura"]:
                print(f"  • ✂️ Potatura: {result['potatura']}")

            if result["extra_alert"]:
                for a in result["extra_alert"]:
                    print(f"  • ⚠️ {a}")

            print("")

    # -------------------------
    # 5. Progetti
    # -------------------------
    projects = load_projects("progetti")

    print("\n📌 PROGETTI\n")

    for p in projects:
        print(f"=== {p['zona'].upper()} — {p['nome']} ===")

        stato = p.get("stato", "n/d")
        avanz = p.get("avanzamento", 0)
        print(f"Stato: {stato} ({avanz}%)")

        if p["aggiornamenti"]:
            last = sorted(p["aggiornamenti"], key=lambda x: x["data"])[-1]
            print(f"Ultimo aggiornamento: {last['data']} — {last['descrizione']}")

        print("")

        for task in p["task"]:
            stato_task = evaluate_project_task(task, p["condizioni"], meteo)

            if stato_task == "ok":
                icon = "✔ consigliato oggi"
            elif stato_task == "no":
                icon = "✖ sconsigliato oggi"
            else:
                icon = "⚪ valutare"

            print(f"  • {task['nome']} → {icon}")

        print("")

    # -------------------------
    # 6. Riassunto dettagliato per il workflow (ordinato per zona)
    # -------------------------
    irrig_by_zone = {}
    conc_by_zone = {}
    pot_by_zone = {}
    alert_by_zone = {}

    for zone, plist in grouped.items():
        for p in plist:
            r = evaluate_plant(p, meteo)

            if r["irrigazione"]:
                irrig_by_zone.setdefault(zone, []).append(f"{p.nome} ({p.specie})")

            if r["concimazione"]:
                conc_by_zone.setdefault(zone, []).append(f"{p.nome} ({p.specie})")

            if r["potatura"]:
                pot_by_zone.setdefault(zone, []).append(f"{p.nome} ({p.specie})")

            if r["extra_alert"]:
                for a in r["extra_alert"]:
                    alert_by_zone.setdefault(zone, []).append(f"{p.nome} — {a}")

    # Scrive summary.txt
    with open("summary.txt", "w") as f:

        f.write("Piante da irrigare:\n")
        for zone in sorted(irrig_by_zone.keys()):
            f.write(f"  {zone}:\n")
            for x in irrig_by_zone[zone]:
                f.write(f"    - {x}\n")
        f.write("\n")

        f.write("Piante da concimare:\n")
        for zone in sorted(conc_by_zone.keys()):
            f.write(f"  {zone}:\n")
            for x in conc_by_zone[zone]:
                f.write(f"    - {x}\n")
        f.write("\n")

        f.write("Piante da potare:\n")
        for zone in sorted(pot_by_zone.keys()):
            f.write(f"  {zone}:\n")
            for x in pot_by_zone[zone]:
                f.write(f"    - {x}\n")
        f.write("\n")

        f.write("Alert:\n")
        for zone in sorted(alert_by_zone.keys()):
            f.write(f"  {zone}:\n")
            for x in alert_by_zone[zone]:
                f.write(f"    - {x}\n")
        f.write("\n")


if __name__ == "__main__":
    main()
