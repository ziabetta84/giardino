#!/usr/bin/env python3

import json
from utils.loader import load_all_plants
from utils.rules import get_tasks_for_plant, get_alerts

ROOT = "plants/zone"

def main():
    plants = load_all_plants(ROOT)

    output = []

    for p in plants:
        tasks = get_tasks_for_plant(p)
        alerts = get_alerts(p)

        output.append({
            "nome": p.nome,
            "specie": p.specie,
            "zona": p.zona,
            "sottozona": p.sottozona,
            "tasks": tasks,
            "alert": alerts,
            "file": p.path
        })

    print(json.dumps(output, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
