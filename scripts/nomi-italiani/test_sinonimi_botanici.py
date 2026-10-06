import unittest

from genera_sinonimi_botanici import MAX_SINONIMI, prepara


def rec(**kw):
    base = {"slug": "x", "sci": "Genus species", "match": "EXACT", "stato": "ACCEPTED",
            "accettato": "Genus species", "key": 1, "sinonimi": ["Genus alia", "Other species"]}
    base.update(kw)
    return base


class TestPrepara(unittest.TestCase):
    def test_accettato_con_sinonimi(self):
        self.assertEqual(prepara(rec()), ("x", "Genus alia | Other species", None))

    def test_scarta_corrispondenza_non_esatta(self):
        self.assertIsNone(prepara(rec(match="FUZZY")))
        self.assertIsNone(prepara(rec(match="HIGHERRANK")))

    def test_sinonimo_mette_il_nome_accettato_per_primo(self):
        r = prepara(rec(stato="SYNONYM", accettato="Nuovo nome", sinonimi=[]))
        self.assertEqual(r, ("x", "Nuovo nome", "Nuovo nome"))

    def test_esclude_nome_scientifico_stesso_e_duplicati(self):
        r = prepara(rec(sinonimi=["genus SPECIES", "Genus alia", "genus alia"]))
        self.assertEqual(r[1], "Genus alia")

    def test_senza_sinonimi_niente(self):
        self.assertIsNone(prepara(rec(sinonimi=[])))

    def test_tetto(self):
        r = prepara(rec(sinonimi=[f"Genus s{i}" for i in range(40)]))
        self.assertEqual(len(r[1].split(" | ")), MAX_SINONIMI)

    def test_stato_sconosciuto_scartato(self):
        self.assertIsNone(prepara(rec(stato="MISAPPLIED")))


if __name__ == "__main__":
    unittest.main()
