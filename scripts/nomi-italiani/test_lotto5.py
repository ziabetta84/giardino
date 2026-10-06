import unittest

from genera_lotto5 import sposta


class TestLotto5(unittest.TestCase):
    def test_sposta_sinonimo_gbif(self):
        self.assertEqual(sposta("Atragene alpina | Clematide alpina", "", "Clematis alpina", ["Atragene alpina"]),
                         ("Clematide alpina", "Atragene alpina"))

    def test_nessun_alternativo_rimasto_diventa_null(self):
        self.assertEqual(sposta("Atragene alpina", "Altro", "Clematis alpina", ["Atragene alpina"]),
                         (None, "Altro | Atragene alpina"))

    def test_non_duplica_se_gia_nei_sinonimi(self):
        self.assertEqual(sposta("Aira cespitosa", "Aira cespitosa", "X y", ["aira cespitosa"]), (None, "Aira cespitosa"))

    def test_uguale_al_nome_scientifico_viene_solo_tolto(self):
        self.assertEqual(sposta("Avena Barbata", "", "Avena barbata", ["Avena barbata"]), (None, None))

    def test_nulla_da_spostare(self):
        self.assertIsNone(sposta("Iva comune", "", "Ajuga reptans", ["Ajuga genevensis"]))


if __name__ == "__main__":
    unittest.main()
