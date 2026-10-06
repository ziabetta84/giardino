import unittest

from genera_lotto8 import classifica


class TestLotto8(unittest.TestCase):
    def test_uguale_ignora_accenti_e_maiuscole(self):
        self.assertEqual(classifica({"trovato": True, "nome_it": "dafne sericea", "nome_db": "Dafne sericea"}), "uguale")

    def test_diverso(self):
        self.assertEqual(classifica({"trovato": True, "nome_it": "Dafne olivella", "nome_db": "Dafne sericea"}), "diverso")

    def test_senza_nome_o_non_trovato(self):
        self.assertIsNone(classifica({"trovato": True, "nome_it": None, "nome_db": "X"}))
        self.assertIsNone(classifica({"trovato": False, "nome_it": None, "nome_db": "X"}))


if __name__ == "__main__":
    unittest.main()
