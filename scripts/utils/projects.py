import os
import frontmatter

def load_projects(root_dir="progetti"):
    projects = []

    for fname in os.listdir(root_dir):
        if not fname.endswith(".md"):
            continue

        path = os.path.join(root_dir, fname)
        post = frontmatter.load(path)

        zona = post.get("zona")
        progetti = post.get("progetti", [])

        for p in progetti:
            projects.append({
                "zona": zona,
                "file": fname,
                "nome": p["nome"],
                "stato": p.get("stato"),
                "avanzamento": p.get("avanzamento", 0),
                "obiettivo": p.get("obiettivo"),
                "condizioni": p.get("condizioni", []),
                "aggiornamenti": p.get("aggiornamenti", []),
                "task": p.get("task", [])
            })

    return projects
