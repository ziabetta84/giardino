"""Frasi approvate da Roberta il 29/10/2026 per sostituire il numero dei gruppi di potatura RHS.
Doc: https://claude.ai/artifact/8J1xM1H835x6nsSEG5GHM7
"""

CORPO1 = "si tolgono i rami secchi, malati o danneggiati e quelli che si incrociano o guastano la forma."


def g1(p="a fine inverno o inizio primavera"):
    return f"Potatura molto leggera, {p}: {CORPO1}" if p else f"Potatura molto leggera: {CORPO1}"


G1 = "Potatura molto leggera: a fine inverno o inizio primavera " + CORPO1
G2 = ("Potatura: fiorisce sui rami dell'anno precedente, quindi si pota subito dopo la fioritura, accorciando i rami "
      "che hanno fiorito fino a un germoglio vigoroso più in basso; ogni anno si toglie alla base circa un ramo vecchio su cinque.")
G3 = ("Potatura: la pianta rinnova la vegetazione dal basso; dopo la fioritura si accorciano i rami fioriti fino a un getto "
      "laterale vigoroso e ogni anno si taglia rasoterra circa un ramo vecchio su tre.")
G4 = ("Potatura: si lasciano i fiori secchi sulla pianta durante l'inverno, a protezione delle gemme; a inizio primavera si "
      "tagliano fino alla prima coppia di gemme robuste sotto il fiore e si tolgono alla base uno o due dei rami più vecchi.")
G5 = ("Potatura: fiorisce in inverno o a inizio primavera, quindi si pota subito dopo la fioritura, accorciando i rami che "
      "hanno fiorito; sopporta anche tagli energici.")
G6 = ("Potatura: fiorisce in estate o in autunno sui rami dell'anno; a inizio primavera si accorciano i rami che hanno "
      "fiorito fino a una o due gemme dalla struttura legnosa.")


def g7(p="a fine inverno o inizio primavera"):
    return (f"Potatura: si coltiva per i fusti colorati o per il fogliame; {p} si taglia a pochi centimetri da terra, "
            "o fino a una struttura bassa, per ottenere getti nuovi vigorosi.")


G7 = g7()
CORPO8 = "si tolgono i rami secchi o danneggiati e si accorciano quelli che guastano la forma."


def g8(p="dopo la fioritura"):
    return f"Potatura leggera, {p}: {CORPO8}"


def g9(p="a metà o fine primavera"):
    return f"Potatura leggera, {p}: {CORPO8}"


G8, G9 = g8(), g9()


def g10(p="dopo la fioritura o in primavera"):
    return (f"Potatura: per tenerla compatta basta una cimatura leggera ogni anno, {p}, senza tagliare nel legno vecchio, "
            "da cui spesso non ricaccia.")


G10 = g10()


def g11(p="dopo la fioritura"):
    return (f"Potatura: pianta rampicante vigorosa, che non ha bisogno di potature regolari; {p} si accorciano i rami che "
            "escono dallo spazio a disposizione e si tolgono quelli secchi.")


G11 = g11()


def g12(p=None):
    q = f", {p}," if p else ""
    return ("Potatura: pianta rampicante meno vigorosa; si legano i getti nuovi al sostegno e ogni anno" + q +
            " si accorciano i rami laterali a tre o quattro gemme dai rami principali.")


G12 = g12()
G11_12 = lambda p: (f"Potatura: pianta rampicante vigorosa, che non ha bisogno di potature regolari; {p} si accorciano i rami "
                    "che escono dallo spazio a disposizione e si tolgono quelli secchi; se serve, si accorciano anche i "
                    "rami laterali a tre o quattro gemme dai rami principali.")
SPALLIERA = ("se è allevata a spalliera, si legano i getti nuovi, si accorciano i rami laterali a due-quattro gemme dalla "
             "struttura e si tolgono quelli che crescono verso il muro o in avanti.")
G13 = ("Potatura: si legano i getti nuovi al sostegno, si accorciano i rami laterali a due-quattro gemme dalla struttura "
       "e si tolgono quelli che crescono verso il muro o in avanti.")
ALT13 = " " + SPALLIERA[0].upper() + SPALLIERA[1:]
ALT7 = (" In alternativa, per avere più fogliame giovanile, ogni anno a fine inverno o inizio primavera si taglia a pochi "
        "centimetri da terra, o fino a una struttura bassa.")
SERRA = " In serra o sotto vetro può servire una potatura di contenimento."

R17 = ("Potatura: in autunno o in inverno si legano in orizzontale i rami principali e si accorciano a due o tre gemme i rami "
       "laterali che hanno fiorito; ogni tanto un ramo vecchio si sostituisce con un getto giovane dalla base.")
R18 = ("Potatura: fiorisce una volta sola, sui rami dell'anno precedente; subito dopo la fioritura si tolgono alla base fino "
       "a un terzo dei rami più vecchi e si legano al loro posto i getti nuovi.")
R20 = "Potatura leggera, dopo la fioritura: si accorciano i rami fioriti e ogni tanto si toglie alla base un ramo vecchio."
R20_CIN = ("Potatura leggera: si accorciano i rami fioriti e ogni tanto si toglie alla base un ramo vecchio; di solito si "
           "interviene dopo la fioritura, ma se si vogliono i frutti (cinorrodi) si aspetta la fine dell'inverno.")
R21 = ("Potatura: a fine inverno si accorciano di circa un terzo i rami principali e a due o tre gemme i laterali, togliendo "
       "i rami vecchi o deboli.")
R17_ALT = (" Se è allevata come rampicante, in autunno o in inverno si legano in orizzontale i rami principali e si accorciano "
           "a due o tre gemme i laterali che hanno fiorito.")

C1 = ("Potatura: fiorisce sui rami dell'anno precedente e non ha bisogno di potature regolari; subito dopo la fioritura, a "
      "metà o fine primavera, si tolgono solo i rami secchi e si accorciano quelli che escono dallo spazio a disposizione.")
C2 = ("Potatura: a fine inverno si accorciano i rami fino alla prima coppia di gemme robuste e si tolgono quelli secchi; "
      "dopo la prima fioritura si possono accorciare i rami fioriti per avere una seconda fioritura.")
C3 = ("Potatura: fiorisce sui rami dell'anno; a fine inverno si tagliano tutti i fusti a 15-30 cm da terra, sopra una "
      "coppia di gemme robuste.")

FRASE = {1: G1, 2: G2, 3: G3, 4: G4, 5: G5, 6: G6, 7: G7, 8: G8, 9: G9, 10: G10, 11: G11, 12: G12, 13: G13}
