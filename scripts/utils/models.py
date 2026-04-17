from dataclasses import dataclass
from typing import Dict, List, Optional

@dataclass
class Plant:
    nome: str
    specie: str
    famiglia: Optional[str]
    zona: str
    sottozona: Optional[str]
    attivita: Dict
    alert: List[str]
    ultimo_controllo: Optional[str]
    path: str
