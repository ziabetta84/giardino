import unittest
from collections import Counter

from genera_lotto3 import n, scarto, scegli


def rec(nome_it, sci="Genus species"):
    return {"sci": sci, "nome_it": nome_it}


class TestLotto3(unittest.TestCase):
    def test_confronto_ignora_accenti_trattini_maiuscole(self):
        self.assertEqual(n("Nontiscordardimé-Alpino"), n("nontiscordardime alpino"))

    def test_sceglie_se_coincide_con_un_alternativo_e_lo_toglie(self):
        r = scegli(rec("tanaceto comune"), ["Tanaceto comune", "Erba amara"], Counter())
        self.assertEqual(r, ("Tanaceto comune", "Tanaceto comune | Erba amara", "Erba amara"))

    def test_nessun_alternativo_rimasto_diventa_null(self):
        self.assertEqual(scegli(rec("Melone"), ["Melone"], Counter())[2], None)

    def test_scarta_se_non_tra_gli_alternativi(self):
        self.assertIsNone(scegli(rec("Erba curzola"), ["Correggiola"], Counter()))

    def test_scarta_senza_nome_inat(self):
        self.assertIsNone(scegli(rec(None), ["Melone"], Counter()))

    def test_scarta_nome_gia_in_uso(self):
        self.assertIsNone(scegli(rec("Melone"), ["Melone"], Counter({n("Melone"): 1})))

    def test_scarta_genere_e_famiglia(self):
        self.assertEqual(scarto("Genus", "Genus species", Counter()), "uguale al genere")
        self.assertEqual(scarto("Asteracee", "Genus species", Counter()), "nome di famiglia")

    def test_nome_di_due_parole_con_acee_non_e_famiglia(self):
        self.assertIsNone(scarto("Pianta acee", "Genus species", Counter()))


if __name__ == "__main__":
    unittest.main()
