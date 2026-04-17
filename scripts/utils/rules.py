from datetime import date

def get_current_season() -> str:
    m = date.today().month
    if m in (12, 1, 2):
        return "inverno"
    if m in (3, 4, 5):
        return "primavera"
    if m in (6, 7, 8):
        return "estate"
    return "autunno"


def get_tasks_for_plant(plant) -> dict:
    season = get_current_season()
    tasks = {}

    if "irrigazione" in plant.attivita:
        tasks["irrigazione"] = plant.attivita["irrigazione"].get(season)

    if "concimazione" in plant.attivita:
        tasks["concimazione"] = plant.attivita["concimazione"].get(season)

    if "potatura" in plant.attivita:
        tasks["potatura"] = plant.attivita["potatura"].get(season)

    return tasks


def get_alerts(plant) -> list[str]:
    return plant.alert
