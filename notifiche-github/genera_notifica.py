#!/usr/bin/env python3
import argparse
import json
import re
from datetime import datetime
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import urlopen
from zoneinfo import ZoneInfo


MONTHS = [
    "gennaio",
    "febbraio",
    "marzo",
    "aprile",
    "maggio",
    "giugno",
    "luglio",
    "agosto",
    "settembre",
    "ottobre",
    "novembre",
    "dicembre",
]

SEASON_BY_MONTH = {
    1: "inverno",
    2: "inverno",
    3: "primavera",
    4: "primavera",
    5: "primavera",
    6: "estate",
    7: "estate",
    8: "estate",
    9: "autunno",
    10: "autunno",
    11: "autunno",
    12: "inverno",
}

WEATHER_CODE_LABEL = {
    0: "sereno",
    1: "prevalentemente sereno",
    2: "parzialmente nuvoloso",
    3: "coperto",
    45: "nebbia",
    48: "nebbia con brina",
    51: "pioviggine debole",
    53: "pioviggine moderata",
    55: "pioviggine intensa",
    61: "pioggia debole",
    63: "pioggia moderata",
    65: "pioggia forte",
    71: "neve debole",
    73: "neve moderata",
    75: "neve forte",
    80: "rovesci deboli",
    81: "rovesci moderati",
    82: "rovesci forti",
    95: "temporale",
    96: "temporale con grandine debole",
    99: "temporale con grandine forte",
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_space(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def first_sentence(text: str, max_len: int = 260) -> str:
    text = normalize_space(text)
    if not text:
        return ""
    parts = re.split(r"(?<=[\.!?])\s+", text)
    sentence = parts[0]
    if len(sentence) <= max_len:
        return sentence
    return sentence[: max_len - 1].rstrip() + "..."


def extract_section(markdown: str, heading: str) -> str:
    pattern = re.compile(
        rf"^##+\s+{re.escape(heading)}\s*$([\s\S]*?)(?=^##+\s+|\Z)",
        re.MULTILINE,
    )
    match = pattern.search(markdown)
    return match.group(1).strip() if match else ""


def weather_description(code: int) -> str:
    return WEATHER_CODE_LABEL.get(code, f"codice meteo {code}")


def fetch_weather(config: dict) -> dict:
    params = {
        "latitude": config["latitude"],
        "longitude": config["longitude"],
        "timezone": config.get("timezone", "Europe/Rome"),
        "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max",
        "forecast_days": 2,
    }
    url = "https://api.open-meteo.com/v1/forecast?" + urlencode(params)
    with urlopen(url, timeout=20) as response:
        payload = json.loads(response.read().decode("utf-8"))

    daily = payload["daily"]
    days = []
    for i in range(len(daily["time"])):
        days.append(
            {
                "date": daily["time"][i],
                "weather_code": int(daily["weather_code"][i]),
                "temp_max": float(daily["temperature_2m_max"][i]),
                "temp_min": float(daily["temperature_2m_min"][i]),
                "rain_mm": float(daily["precipitation_sum"][i]),
                "wind_kmh": float(daily["wind_speed_10m_max"][i]),
            }
        )
    return {"days": days, "source": url}


def weather_alerts(days: list[dict]) -> list[str]:
    alerts = []
    for idx, day in enumerate(days):
        label = "oggi" if idx == 0 else "domani"
        if day["rain_mm"] >= 10:
            alerts.append(f"Pioggia prevista {label} ({day['rain_mm']:.1f} mm): ridurre o sospendere irrigazione.")
        if day["temp_min"] <= 3:
            alerts.append(f"Minima bassa {label} ({day['temp_min']:.1f}C): proteggere piante sensibili.")
        if day["temp_max"] >= 30:
            alerts.append(f"Massima alta {label} ({day['temp_max']:.1f}C): controllare stress idrico e pacciamatura.")
        if day["wind_kmh"] >= 35:
            alerts.append(f"Vento forte {label} ({day['wind_kmh']:.1f} km/h): verificare legature e tutori.")
    return alerts


def list_plant_files(repo_root: Path) -> list[Path]:
    return sorted(
        p
        for p in (repo_root / "zone").rglob("*.md")
        if "piante" in p.parts and p.name != "README.md"
    )


def list_project_files(repo_root: Path) -> list[Path]:
    return sorted(
        p
        for p in (repo_root / "progetti").glob("*.md")
        if p.name.lower() != "readme.md"
    )


def infer_zone_from_path(path: Path) -> str:
    parts = list(path.parts)
    if "zone" not in parts:
        return "zona non definita"
    zi = parts.index("zone")
    if zi + 1 < len(parts):
        return parts[zi + 1]
    return "zona non definita"


def find_relevant_care(plant_files: list[Path], now: datetime) -> list[dict]:
    month = MONTHS[now.month - 1]
    next_month = MONTHS[now.month % 12]
    season = SEASON_BY_MONTH[now.month]
    care_items = []

    for plant_file in plant_files:
        content = plant_file.read_text(encoding="utf-8", errors="ignore")
        plant_name = plant_file.stem
        zone = infer_zone_from_path(plant_file)
        section_pm = extract_section(content, "Potatura e manutenzione")
        section_colt = extract_section(content, "Coltivazione")
        merged = "\n".join([section_pm, section_colt]).strip()
        if not merged:
            continue

        low = merged.lower()
        score = 0
        if month in low:
            score += 3
        if next_month in low:
            score += 2
        if season in low:
            score += 2

        snippet = first_sentence(merged)
        if not snippet:
            continue

        if score > 0:
            care_items.append(
                {
                    "score": score,
                    "plant": plant_name,
                    "zone": zone,
                    "path": str(plant_file.relative_to(plant_file.parents[2])),
                    "snippet": snippet,
                }
            )

    care_items.sort(key=lambda item: (-item["score"], item["zone"], item["plant"]))
    return care_items[:10]


def parse_project_status(content: str) -> str:
    for heading in ["Stato attuale", "Stato"]:
        sec = extract_section(content, heading)
        if sec:
            return first_sentence(sec, max_len=300)
    return "Stato non specificato"


def parse_project_next_steps(content: str) -> list[str]:
    section = extract_section(content, "Prossimi passi")
    if not section:
        return []

    steps = []
    for line in section.splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            step = stripped[2:].strip()
            if step:
                steps.append(step)
    return steps


def find_active_projects(project_files: list[Path]) -> list[dict]:
    active = []
    for path in project_files:
        content = path.read_text(encoding="utf-8", errors="ignore")
        first_heading = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
        title = first_heading.group(1).strip() if first_heading else path.stem
        status = parse_project_status(content)
        next_steps = parse_project_next_steps(content)
        low = status.lower()
        if any(word in low for word in ["conclus", "completat", "chiuso"]):
            continue
        active.append(
            {
                "title": title,
                "status": status,
                "next_steps": next_steps,
                "path": str(path.relative_to(path.parents[1])),
            }
        )
    return active


def summarize_weather_window(days: list[dict]) -> dict:
    if not days:
        return {
            "max_temp": None,
            "min_temp": None,
            "max_rain": None,
            "max_wind": None,
        }
    return {
        "max_temp": max(day["temp_max"] for day in days),
        "min_temp": min(day["temp_min"] for day in days),
        "max_rain": max(day["rain_mm"] for day in days),
        "max_wind": max(day["wind_kmh"] for day in days),
    }


def project_timing_assessment(project_title: str, project_status: str, days: list[dict]) -> str:
    window = summarize_weather_window(days)
    if window["max_temp"] is None:
        return "meteo non disponibile: usare solo valutazione sul campo"

    title_low = project_title.lower()
    status_low = project_status.lower()
    text = f"{title_low} {status_low}"

    max_temp = window["max_temp"]
    min_temp = window["min_temp"]
    max_rain = window["max_rain"]
    max_wind = window["max_wind"]

    # Casi specifici per lavori tipici da giardino.
    if any(k in text for k in ["trapiant", "piant", "messa a dimora"]):
        if min_temp <= 4:
            return "non ideale: minime troppo basse per nuove messe a dimora"
        if max_temp >= 30:
            return "non ideale: caldo alto, rischio stress da trapianto"
        if max_rain >= 20:
            return "non ideale: pioggia intensa, suolo troppo saturo"
        return "favorevole: finestra buona per trapianti e nuove piantumazioni"

    if any(k in text for k in ["potatur", "taglio", "sfolt"]):
        if max_rain >= 5:
            return "non ideale: meglio evitare potature con pioggia prevista"
        if max_wind >= 30:
            return "non ideale: vento sostenuto per lavorazioni di precisione"
        if min_temp <= 1:
            return "non ideale: rischio freddo marcato dopo il taglio"
        return "favorevole: buona finestra per potature leggere"

    if any(k in text for k in ["irrigaz", "ala gocciolante", "impianto idrico"]):
        if max_rain >= 10:
            return "valutare rinvio: pioggia in arrivo riduce urgenza irrigua"
        if max_wind >= 35:
            return "non ideale: vento forte per lavori di impianto"
        return "favorevole: buona finestra per verifiche e piccoli interventi"

    # Regola generica per progetti non classificati.
    if max_rain >= 15 or max_wind >= 35:
        return "non ideale: meteo instabile, meglio pianificare o fare solo sopralluogo"
    if max_temp >= 30:
        return "valutare fascia oraria fresca: temperature elevate nelle ore centrali"
    return "favorevole: condizioni meteo complessivamente buone"


def step_timing_assessment(step_text: str, days: list[dict]) -> str:
    window = summarize_weather_window(days)
    if window["max_temp"] is None:
        return "meteo non disponibile: decidere dopo sopralluogo"

    text = step_text.lower()
    max_temp = window["max_temp"]
    min_temp = window["min_temp"]
    max_rain = window["max_rain"]
    max_wind = window["max_wind"]

    if any(k in text for k in ["infestanti", "diserbo", "rimozione manuale"]):
        if max_rain >= 8:
            return "da valutare: con pioggia il lavoro e meno efficace"
        if max_wind >= 35:
            return "non ideale: vento forte per lavoro di precisione"
        return "favorevole: buon momento per pulizia e rimozione infestanti"

    if any(k in text for k in ["inserimento", "messa a dimora", "trapiant", "talea", "piant"]):
        if min_temp <= 4:
            return "non ideale: minime basse per nuove messe a dimora"
        if max_temp >= 30:
            return "non ideale: caldo alto, rischio stress"
        if max_rain >= 20:
            return "da valutare: pioggia intensa, meglio attendere suolo stabile"
        return "favorevole: buona finestra per impianto"

    if any(k in text for k in ["valutare", "scegliere", "progett", "schema", "acquisto"]):
        return "favorevole: attivita di pianificazione eseguibile anche con meteo variabile"

    if max_rain >= 15 or max_wind >= 35:
        return "non ideale: meteo instabile, meglio rimandare intervento fisico"
    if max_temp >= 30:
        return "da valutare: operare in fascia fresca"
    return "favorevole: condizioni meteo complessivamente buone"


def build_actions(alerts: list[str], care_items: list[dict], active_projects: list[dict]) -> list[str]:
    actions = []
    actions.extend(alerts[:3])
    if care_items:
        p = care_items[0]
        actions.append(f"Verificare oggi {p['plant']} in zona {p['zone']}: {p['snippet']}")
    if active_projects:
        actions.append(f"Avanzare il progetto '{active_projects[0]['title']}' con almeno un micro-task.")
    if not actions:
        actions.append("Nessuna urgenza: eseguire solo monitoraggio visivo generale del giardino.")
    return actions[:5]


def build_report(config: dict, weather: dict, plants_total: int, care_items: list[dict], active_projects: list[dict]) -> tuple[str, str]:
    now = datetime.now(ZoneInfo(config.get("timezone", "Europe/Rome")))
    date_text = now.strftime("%Y-%m-%d")
    month_name = MONTHS[now.month - 1]
    season = SEASON_BY_MONTH[now.month]
    location = config.get("location_name", "Giardino")

    days = weather["days"]
    alerts = weather_alerts(days)
    actions = build_actions(alerts, care_items, active_projects)

    lines = []
    lines.append(f"# Notifica giardino - {date_text}")
    lines.append("")
    lines.append(f"Localita: **{location}**")
    lines.append(f"Contesto stagionale: **{month_name} ({season})**")
    lines.append("")
    lines.append("## Meteo (Open-Meteo)")
    lines.append("")
    for idx, day in enumerate(days):
        label = "Oggi" if idx == 0 else "Domani"
        lines.append(
            "- "
            + f"**{label} ({day['date']})**: {weather_description(day['weather_code'])}, "
            + f"min {day['temp_min']:.1f}C, max {day['temp_max']:.1f}C, "
            + f"pioggia {day['rain_mm']:.1f} mm, vento max {day['wind_kmh']:.1f} km/h"
        )
    lines.append("")
    lines.append("Avvisi meteo:")
    if alerts:
        for alert in alerts:
            lines.append(f"- {alert}")
    else:
        lines.append("- Nessun avviso meteo critico nelle prossime 48 ore.")

    lines.append("")
    lines.append("## Piante e cure")
    lines.append("")
    lines.append(f"- Piante documentate in repository: **{plants_total}**")
    lines.append("- Cure/interventi rilevati per il periodo corrente:")
    if care_items:
        for item in care_items:
            lines.append(f"  - **{item['plant']}** (zona {item['zone']}): {item['snippet']}")
    else:
        lines.append("  - Nessuna indicazione esplicita legata al mese/stagione trovata nei file pianta.")

    lines.append("")
    lines.append("## Progetti in cantiere")
    lines.append("")
    if active_projects:
        for project in active_projects:
            assessment = project_timing_assessment(project["title"], project["status"], days)
            lines.append(f"- **{project['title']}**: {project['status']}")
            lines.append(f"  - Momento per agire: **{assessment}**")
            if project.get("next_steps"):
                lines.append("  - Valutazione prossimi passi:")
                for step in project["next_steps"][:5]:
                    step_eval = step_timing_assessment(step, days)
                    lines.append(f"    - {step}")
                    lines.append(f"      - Timing: **{step_eval}**")
    else:
        lines.append("- Nessun progetto attivo individuato in /progetti.")

    lines.append("")
    lines.append("## Azioni consigliate oggi")
    lines.append("")
    for action in actions:
        lines.append(f"- {action}")

    lines.append("")
    lines.append(f"Fonte meteo: {weather['source']}")

    title_prefix = config.get("issue_title_prefix", "Notifica giardino")
    title = f"{title_prefix} {date_text}"
    body = "\n".join(lines).rstrip() + "\n"
    return title, body


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Genera notifica giardino da meteo + markdown repository")
    parser.add_argument("--repo-root", default=".", help="Path root repository")
    parser.add_argument("--config", required=True, help="File JSON di configurazione")
    parser.add_argument("--output-title", required=True, help="File output titolo")
    parser.add_argument("--output-body", required=True, help="File output markdown")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    config_path = Path(args.config).resolve()

    config = load_json(config_path)
    try:
        weather = fetch_weather(config)
    except Exception as exc:  # pragma: no cover
        weather = {
            "days": [],
            "source": f"Open-Meteo non disponibile ({exc})",
        }
    plant_files = list_plant_files(repo_root)
    care_items = find_relevant_care(plant_files, datetime.now(ZoneInfo(config.get("timezone", "Europe/Rome"))))
    project_files = list_project_files(repo_root)
    active_projects = find_active_projects(project_files)
    title, body = build_report(config, weather, len(plant_files), care_items, active_projects)

    Path(args.output_title).write_text(title + "\n", encoding="utf-8")
    Path(args.output_body).write_text(body, encoding="utf-8")


if __name__ == "__main__":
    main()