import requests
import datetime

# Coordinate corrette (float, senza virgola finale!)
LAT = 43.830961
LON = 12.9885673

def get_weather_data():
    """
    Restituisce un dizionario con:
    - rain_last_24h
    - rain_last_48h
    - temp
    - wind
    - humidity
    - rain_probability_today
    """

    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={LAT}&longitude={LON}"
        "&hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m"
        "&daily=precipitation_sum,precipitation_probability_max"
        "&timezone=Europe/Rome"
    )

    try:
        r = requests.get(url, timeout=10)
        data = r.json()
    except Exception as e:
        print("Errore meteo:", e)
        return {
            "rain_last_24h": 0,
            "rain_last_48h": 0,
            "temp": 15,
            "wind": 5,
            "humidity": 60,
            "rain_probability_today": 0
        }

    # --- Pioggia ultime 48h ---
    hourly = data.get("hourly", {})
    rain = hourly.get("precipitation", [])

    rain_last_24h = sum(rain[-24:]) if len(rain) >= 24 else 0
    rain_last_48h = sum(rain[-48:]) if len(rain) >= 48 else rain_last_24h

    # --- Temperatura attuale ---
    temp = hourly.get("temperature_2m", [15])[-1]

    # --- Umidità ---
    humidity = hourly.get("relative_humidity_2m", [60])[-1]

    # --- Vento ---
    wind = hourly.get("wind_speed_10m", [5])[-1]

    # --- Probabilità pioggia oggi ---
    daily = data.get("daily", {})
    rain_prob = daily.get("precipitation_probability_max", [0])[0]

    return {
        "rain_last_24h": rain_last_24h,
        "rain_last_48h": rain_last_48h,
        "temp": temp,
        "wind": wind,
        "humidity": humidity,
        "rain_probability_today": rain_prob
    }
