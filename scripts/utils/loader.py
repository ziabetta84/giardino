import os
import frontmatter
from .models import Plant

REQUIRED_FIELDS = ["nome", "specie", "zona", "attivita", "alert"]

def load_plant_from_file(path: str) -> Plant | None:
    try:
        post = frontmatter.load(path)
    except Exception:
        return None

    meta = post.metadata

    # Validazione minima
    for field in REQUIRED_FIELDS:
        if field not in meta:
            return None

    return Plant(
        nome=meta["nome"],
        specie=meta["specie"],
        famiglia=meta.get("famiglia"),
        zona=meta["zona"],
        sottozona=meta.get("sottozona"),
        attivita=meta["attivita"],
        alert=meta["alert"],
        ultimo_controllo=meta.get("ultimo_controllo"),
        path=path
    )


def load_all_plants(root_dir: str) -> list[Plant]:
    plants = []

    for root, _, files in os.walk(root_dir):
        for f in files:
            if f.endswith(".md"):
                full_path = os.path.join(root, f)
                plant = load_plant_from_file(full_path)
                if plant:
                    plants.append(plant)

    return plants
