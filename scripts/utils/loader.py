import os
import frontmatter
from utils.models import Plant

def load_all_plants(root="zone"):
    plants = []

    for dirpath, dirnames, filenames in os.walk(root):
        # Carichiamo SOLO se il percorso contiene /piante/
        if "/piante/" not in dirpath.replace("\\", "/"):
            continue

        for filename in filenames:
            if not filename.endswith(".md"):
                continue

            full_path = os.path.join(dirpath, filename)

            try:
                post = frontmatter.load(full_path)
            except Exception as e:
                print(f"Errore nel file {full_path}: {e}")
                continue

            if not post.metadata:
                print(f"File ignorato (no frontmatter): {full_path}")
                continue

            data = post.metadata
            data["path"] = full_path

            plant = Plant(**data)
            plants.append(plant)

    return plants
