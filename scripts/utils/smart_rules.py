import datetime

# ---------------------------------------------------------
#  UTILITIES
# ---------------------------------------------------------

def parse_frequency(text):
    """
    Converte stringhe tipo:
    - "ogni 7-10 giorni"
    - "ogni 2 settimane"
    - "una volta al mese"
    - "sospesa"
    in un numero di giorni (int) oppure None.
    """
    if not text:
        return None  # se manca la frequenza, non si fa l'attività

    text = text.lower().strip()

    if "sospesa" in text:
        return None

    if "una volta al mese" in text:
        return 30

    if "settimane" in text:
        parts = text.split()
        for p in parts:
            if p.isdigit():
                return int(p) * 7

    if "giorni" in text:
        nums = []
        for token in text.replace("ogni", "").replace("giorni", "").split():
            token = token.strip()
            if "-" in token:
                a, b = token.split("-")
                if a.isdigit():
                    nums.append(int(a))
            elif token.isdigit():
                nums.append(int(token))
        if nums:
            return min(nums)

    return None

def get_stagione(today):
    """
    Restituisce la stagione in base alla data.
    """
    mese = today.month
    if mese in (3, 4, 5):
        return "primavera"
    if mese in (6, 7, 8):
        return "estate"
    if mese in (9, 10, 11):
        return "autunno"
    return "inverno"


def giorni_da(data_str):
    """
    Ritorna quanti giorni sono passati da data_str (YYYY-MM-DD).
    """
    if not data_str:
        return 999  # se manca la data, consideriamo "tanto tempo"
    d = datetime.datetime.strptime(data_str, "%Y-%m-%d").date()
    return (datetime.date.today() - d).days


# ---------------------------------------------------------
#  IRRIGAZIONE
# ---------------------------------------------------------

def evaluate_irrigazione(plant, meteo, stagione):
    """
    Determina se la pianta va irrigata.
    Tiene conto di:
    - frequenza stagionale
    - ultimo_controllo
    - meteo (solo se esterno)
    """
    att = plant.get("attivita", {}).get("irrigazione", {})
    freq_text = att.get(stagione)
    freq_days = parse_frequency(freq_text)

    if freq_days is None:
        return False  # es. "sospesa"

    giorni = giorni_da(plant.get("ultimo_controllo"))

    # Regole meteo (solo se esterno)
    zona = plant.get("zona", "").lower()
    esterno = zona not in ("casa", "interno", "appartamento")

    if esterno:
        pioggia_24h = meteo.get("rain_last_24h", 0)
        pioggia_48h = meteo.get("rain_last_48h", 0)
        prob_pioggia_oggi = meteo.get("rain_probability_today", 0)
        temperatura = meteo.get("temp", 15)

        if pioggia_48h > 3:
            return False
        if pioggia_24h > 1:
            return False
        if prob_pioggia_oggi > 40:
            return False
        if temperatura < 5:
            return False

    return giorni >= freq_days


# ---------------------------------------------------------
#  CONCIMAZIONE
# ---------------------------------------------------------

def evaluate_concimazione(plant, stagione):
    att = plant.get("attivita", {}).get("concimazione", {})
    freq_text = att.get(stagione)
    freq_days = parse_frequency(freq_text)

    if freq_days is None:
        return False  # es. "sospesa"

    giorni = giorni_da(plant.get("ultimo_controllo"))
    return giorni >= freq_days


# ---------------------------------------------------------
#  POTATURA
# ---------------------------------------------------------

def evaluate_potatura(plant, stagione):
    att = plant.get("attivita", {}).get("potatura", {})
    text = att.get(stagione, "").lower()

    if "nessuna" in text or text.strip() == "":
        return False

    # Se c'è una descrizione, significa che la potatura è prevista
    return True


# ---------------------------------------------------------
#  ALERT
# ---------------------------------------------------------

def evaluate_alert(plant, meteo):
    alerts = []

    # Alert statici dal file
    statici = plant.get("alert", [])
    alerts.extend(statici)

    # Alert dinamici
    pioggia_48h = meteo.get("rain_last_48h", 0)
    temperatura = meteo.get("temp", 15)
    vento = meteo.get("wind", 0)
    umidita = meteo.get("humidity", 50)

    if pioggia_48h > 20:
        alerts.append("pioggia intensa recente: rischio ristagno")

    if temperatura < 3:
        alerts.append("temperature molto basse: rischio gelo")

    if vento > 40:
        alerts.append("vento forte: rischio danni")

    if umidita > 90:
        alerts.append("umidità molto alta: rischio muffe")

    return alerts


# ---------------------------------------------------------
#  FUNZIONE PRINCIPALE
# ---------------------------------------------------------

def evaluate_plant(plant, meteo):
    today = datetime.date.today()
    stagione = get_stagione(today)

    return {
        "stagione": stagione,
        "irrigazione": evaluate_irrigazione(plant, meteo, stagione),
        "concimazione": evaluate_concimazione(plant, stagione),
        "potatura": evaluate_potatura(plant, stagione),
        "alert": evaluate_alert(plant, meteo)
    }
