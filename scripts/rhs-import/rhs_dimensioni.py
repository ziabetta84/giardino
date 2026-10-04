"""Lettura e formattazione dei campi altezza_max/diffusione_max delle pagine RHS.

Il testo RHS e' una fascia, non una misura: "1.5-2.5 metres", "Up to 10 cm",
ma anche le fasce aperte "Higher than 12 metres" (altezza) e "wider than 8
metres" (diffusione), dove il numero e' una soglia da superare. Una versione
precedente (copiata in 5 script) estraeva solo i numeri: "oltre 12 m" diventava
"12m" e i cm "10 cm" diventavano "10m" (corretti in DB il 04/10/2026).
"""
import re

_NUM = re.compile(r"\d+(?:[.,]\d+)?")


def extract_numbers(s):
    if not s:
        return []
    nums = [float(x.replace(",", ".")) for x in _NUM.findall(s)]
    if "cm" in s.lower() and "metres" not in s.lower():
        nums = [n / 100 for n in nums]
    return nums


def is_open(s):
    """True se il testo e' una fascia aperta ("Higher than ...", "wider than ...")."""
    t = (s or "").lower()
    return "higher than" in t or "wider than" in t


def fmt_range(minmax, unit="m", oltre=False):
    """"0.5-1m", "2m", oppure con oltre=True "oltre 12m" / "da 8 a oltre 12m"."""
    if not minmax:
        return None
    lo, hi = minmax
    if oltre:
        if lo == hi:
            return f"oltre {hi:g}{unit}"
        return f"da {lo:g} a oltre {hi:g}{unit}"
    if lo == hi:
        return f"{lo:g}{unit}"
    return f"{lo:g}-{hi:g}{unit}"


def con_da(testo):
    """Antepone "da " a una fascia, tranne se e' gia' "oltre ..." o "da X a oltre Y"."""
    if testo.startswith(("da ", "oltre ")):
        return testo
    return f"da {testo}"
