import os
import frontmatter
from utils.models import Plant

def load_all_plants(root="zone"):
    plants = []

    for dirpath, dirnames, filenames in os.walk(root):
        for filename in filenames:
            # Carichiamo SOLO i file pianta
            if filename != "index.md":
                continue

            full_path = os.path.join(dirpath, filename)

            try:
                post = frontmatter.load(full_path)
            except Exception as e:
                print(f"Errore nel file {full_path}: {e}")
                continue

            # Se il file non ha frontmatter, ignoralo
            if not post.metadata:
                print(f"File ignorato (no frontmatter): {full_path}")
                continue

            data = post.metadata
            data["path"] = full_path

            plant = Plant(**data)
            plants.append(plant)

    return plants
