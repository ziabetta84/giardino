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

# ANSI COLORS
CYAN = "\033[1;36m"
GREEN = "\033[1;32m"
RED = "\033[1;31m"
YELLOW = "\033[1;33m"
MAGENTA = "\033[1;35m"
RESET = "\033[0m"


def group_by_zone(plants):
    """Raggruppa le piante per zona/sottozona."""
    grouped = {}

    for p in plants:
        key = f"{p.zona}/{p.sottozona}" if p.sottozona else p.zona
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(p)

    return grouped


def format_section_title(title):
    return f"\n{CYAN}=== {title.upper()} ==={RESET}\n"


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
    # 3. Report
    # -------------------------
    print(f"\n🌱 {MAGENTA}GIARDINO — REPORT GIORNALIERO{RESET}\n")

    if meteo:
        print(f"{CYAN}Meteo:{RESET}")
        print(f"- 🌧️ Pioggia oggi: {meteo.get('rain_mm', 0)} mm")
        print(f"- 🌧️ Pioggia ultime 48h: {meteo.get('rain_last_48h', 0)} mm")
        print(f"- 🌡️ Temp max: {meteo.get('temp_max', 0)}°C")
        print(f"- 💨 Vento max: {meteo.get('wind_max', 0)} km/h\n")
    else:
        print(f"{YELLOW}⚠️ Meteo non disponibile{RESET}\n")

    # -------------------------
    # 4. Piante per zona
    # -------------------------
    for zone, plist in grouped.items():
        print(format_section_title(zone))

        for p in plist:
            result = evaluate_plant(p, meteo)

            print(f"{GREEN}- {p.nome} ({p.specie}){RESET}")

            if result["irrigazione"]:
                print(f"  • 💧 Irrigazione: {result['irrigazione']}")

            if result["concimazione"]:
                print(f"  • 🌱 Concimazione: {result['concimazione']}")

            if result["potatura"]:
                print(f"  • ✂️ Potatura: {result['potatura']}")

            if result["extra_alert"]:
                for a in result["extra_alert"]:
                    print(f"  • {YELLOW}⚠️ {a}{RESET}")

            print("")

    # -------------------------
    # 5. Progetti
    # -------------------------
    projects = load_projects("progetti")

    print(f"\n📌 {CYAN}PROGETTI{RESET}\n")

    for p in projects:
        print(f"{CYAN}=== {p['zona'].upper()} — {p['nome']} ==={RESET}")

        # Stato e avanzamento
        stato = p.get("stato", "n/d")
        avanz = p.get("avanzamento", 0)
        print(f"Stato: {stato} ({avanz}%)")

        # Ultimo aggiornamento
        if p["aggiornamenti"]:
            last = sorted(p["aggiornamenti"], key=lambda x: x["data"])[-1]
            print(f"Ultimo aggiornamento: {last['data']} — {last['descrizione']}")

        print("")

        # Task
        for task in p["task"]:
            stato_task = evaluate_project_task(task, p["condizioni"], meteo)

            if stato_task == "ok":
                icon = f"{GREEN}✔ consigliato oggi{RESET}"
            elif stato_task == "no":
                icon = f"{RED}✖ sconsigliato oggi{RESET}"
            else:
                icon = f"{YELLOW}⚪ valutare{RESET}"

            print(f"  • {task['nome']} → {icon}")

        print("")


if __name__ == "__main__":
    main()
