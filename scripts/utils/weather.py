import requests
from datetime import date

# Coordinate corrette (float, senza virgola finale!)
LAT = 43.830961
LON = 12.9885673

def get_weather_today():
    """
    Restituisce un dizionario con:
    - pioggia totale di oggi (mm)
    - temperatura massima di oggi (°C)
    - temperatura minima di oggi (°C)
    - vento massimo di oggi (km/h)
    """

    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={LAT}&longitude={LON}"
        "&daily=precipitation_sum,temperature_2m_max,temperature_2m_min,windspeed_10m_max"
        "&timezone=Europe/Rome"
    )

    try:
        r = requests.get(url, timeout=10)
        data = r.json()
    except Exception:
        return None

    # Se l'API non restituisce daily, esci senza crash
    if "daily" not in data:
        return None

    today = date.today().isoformat()

    # Se la data non è presente, esci senza crash
    if today not in data["daily"]["time"]:
        return None

    idx = data["daily"]["time"].index(today)

    return {
        "rain_mm": data["daily"]["precipitation_sum"][idx],
        "temp_max": data["daily"]["temperature_2m_max"][idx],
        "temp_min": data["daily"]["temperature_2m_min"][idx],
        "wind_max": data["daily"]["windspeed_10m_max"][idx],
    }


def get_weather_last_48h():
    """
    Restituisce la pioggia totale delle ultime 48 ore.
    """

    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={LAT}&longitude={LON}"
        "&hourly=precipitation"
        "&past_days=2"
        "&timezone=Europe/Rome"
    )

    try:
        r = requests.get(url, timeout=10)
        data = r.json()
    except Exception:
        return None

    if "hourly" not in data or "precipitation" not in data["hourly"]:
        return None

    rain_values = data["hourly"]["precipitation"]
    total_rain = sum(rain_values)

    return {
        "rain_last_48h": total_rain
    }
