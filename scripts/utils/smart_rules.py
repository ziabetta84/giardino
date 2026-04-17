from datetime import date

# -------------------------
#  STAGIONE
# -------------------------

def get_current_season() -> str:
    m = date.today().month
    if m in (12, 1, 2):
        return "inverno"
    if m in (3, 4, 5):
        return "primavera"
    if m in (6, 7, 8):
        return "estate"
    return "autunno"


# -------------------------
#  REGOLE INTELLIGENTI
# -------------------------

def evaluate_irrigation(plant, season, meteo):
    """Restituisce una decisione sull'irrigazione."""

    rain_48 = meteo.get("rain_last_48h", 0)
    rain_today = meteo.get("rain_mm", 0)
    temp_max = meteo.get("temp_max", 0)

    base = plant.attivita.get("irrigazione", {}).get(season)

    # Nessuna regola definita → nessuna attività
    if not base:
        return None

    # Regola 1: pioggia abbondante → niente irrigazione
    if rain_48 > 8:
        return f"non irrigare (pioggia {rain_48:.1f} mm nelle ultime 48h)"

    # Regola 2: pioggia moderata → ridurre irrigazione
    if rain_48 > 3:
        return f"irrigazione ridotta (pioggia {rain_48:.1f} mm)"

    # Regola 3: caldo → aumentare irrigazione
    if temp_max >= 26:
        return f"{base} — aumentare leggermente (T° {temp_max}°C)"

    # Regola 4: piante xerofile → irrigare raramente
    if "xerofila" in " ".join(plant.alert).lower():
        if rain_48 > 0:
            return "non irrigare (pianta xerofila + pioggia recente)"
        return "irrigare solo se terreno completamente asciutto"

    # Regola 5: piante palustri → irrigazione costante
    if "palustre" in " ".join(plant.alert).lower():
        if rain_48 > 10:
            return "OK, terreno già molto umido"
        return base

    # Default
    return base


def evaluate_fertilization(plant, season, meteo):
    """Restituisce una decisione sulla concimazione."""

    base = plant.attivita.get("concimazione", {}).get(season)
    if not base:
        return None

    temp_max = meteo.get("temp_max", 0)

    # Freddo → evitare concimazione
    if temp_max < 10:
        return "rimandare (temperature troppo basse)"

    # Pioggia → evitare concime liquido
    if meteo.get("rain_mm", 0) > 3:
        return "rimandare (pioggia prevista)"

    return base


def evaluate_pruning(plant, season, meteo):
    """Restituisce una decisione sulla potatura."""

    base = plant.attivita.get("potatura", {}).get(season)
    if not base:
        return None

    wind = meteo.get("wind_max", 0)

    # Vento forte → evitare potature
    if wind > 40:
        return "evitare potature (vento forte)"

    return base


def evaluate_extra_alerts(plant, meteo):
    """Alert aggiuntivi basati sul meteo."""

    alerts = []

    rain_48 = meteo.get("rain_last_48h", 0)
    temp_max = meteo.get("temp_max", 0)

    # Ristagni
    if rain_48 > 12 and "ristagni" in " ".join(plant.alert).lower():
        alerts.append("attenzione ai ristagni (molta pioggia recente)")

    # Stress da caldo
    if temp_max > 30:
        alerts.append("possibile stress da caldo")

    return alerts


# -------------------------
#  FUNZIONE PRINCIPALE
# -------------------------

def evaluate_plant(plant, meteo):
    """
    Restituisce un dizionario con:
    - irrigazione
    - concimazione
    - potatura
    - alert aggiuntivi
    """

    season = get_current_season()

    return {
        "irrigazione": evaluate_irrigation(plant, season, meteo),
        "concimazione": evaluate_fertilization(plant, season, meteo),
        "potatura": evaluate_pruning(plant, season, meteo),
        "extra_alert": evaluate_extra_alerts(plant, meteo),
    }
