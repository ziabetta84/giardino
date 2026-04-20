import os
import frontmatter

# Import assoluto, NON relativo
from models import Plant


def load_all_plants(root="zone"):
    """
    Carica tutte le piante scansionando le cartelle.
    Ogni pianta è un file index.md con frontmatter YAML.
    """
    plants = []

    for dirpath, dirnames, filenames in os.walk(root):
        for filename in filenames:
            if filename.endswith(".md"):
                full_path = os.path.join(dirpath, filename)

                try:
                    post = frontmatter.load(full_path)
                except Exception as e:
                    print(f"Errore nel file {full_path}: {e}")
                    continue

                data = post.metadata
                data["path"] = full_path

                # Crea oggetto Plant
                plant = Plant(**data)
                plants.append(plant)

    return plants
