from dataclasses import dataclass, field
from typing import Dict, List, Optional

@dataclass
class Plant:
    nome: str = "sconosciuta"
    specie: str = "sconosciuta"
    famiglia: Optional[str] = None
    zona: str = "sconosciuta"
    sottozona: Optional[str] = "generale"
    attivita: Dict = field(default_factory=dict)
    alert: List[str] = field(default_factory=list)
    ultimo_controllo: Optional[str] = None
    path: str = ""

    # Per compatibilità con smart_rules
    def to_dict(self):
        return {
            "nome": self.nome,
            "specie": self.specie,
            "famiglia": self.famiglia,
            "zona": self.zona,
            "sottozona": self.sottozona,
            "attivita": self.attivita,
            "alert": self.alert,
            "ultimo_controllo": self.ultimo_controllo,
            "path": self.path
        }
