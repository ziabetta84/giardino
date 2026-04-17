def evaluate_project_task(task, condizioni, meteo):
    # Se task non è un dict → non valutabile
    if not isinstance(task, dict):
        return "maybe"

    # Se condizioni non è una lista → normalizza
    if not isinstance(condizioni, list):
        condizioni = [condizioni] if condizioni else []

    rain = meteo.get("rain_mm", 0) if meteo else 0
    wind = meteo.get("wind_max", 0) if meteo else 0
    temp = meteo.get("temp_max", 0) if meteo else 0

    for cond in condizioni:
        if not isinstance(cond, str):
            continue

        c = cond.lower()

        if "assenza di pioggia" in c and rain > 0:
            return "no"

        if "giornata non troppo ventosa" in c and wind > 20:
            return "no"

        if "temperatura >" in c:
            try:
                soglia = float(c.split(">")[1].replace("°c", "").strip())
                if temp < soglia:
                    return "no"
            except:
                pass

    return "ok"
