import unittest
from nomi import normalizza_nome, scegli_nome


def c(nome, rank="normal", itwiki=None):
    return {"nome": nome, "rank": rank, "itwiki": itwiki}


class TestNormalizza(unittest.TestCase):
    def test_maiuscola_e_spazi(self):
        self.assertEqual(normalizza_nome("  pianta   di giada "), "Pianta di giada")

    def test_scarta_cifre_slash_vuoto_lungo(self):
        self.assertIsNone(normalizza_nome("rosa 2000"))
        self.assertIsNone(normalizza_nome("a/b"))
        self.assertIsNone(normalizza_nome("  "))
        self.assertIsNone(normalizza_nome("x" * 61))

    def test_mantiene_apostrofo(self):
        self.assertEqual(normalizza_nome("erba dell'orso"), "Erba dell'orso")


class TestScegli(unittest.TestCase):
    def test_nessun_candidato(self):
        self.assertEqual(scegli_nome("Aloe rauhii", []), (None, "nessuno"))

    def test_unico(self):
        self.assertEqual(scegli_nome("Tectona grandis", [c("teak")]), ("Teak", "unico"))

    def test_scarta_uguale_allo_scientifico(self):
        self.assertEqual(scegli_nome("Aloe rauhii", [c("aloe rauhii")]), (None, "nessuno"))

    def test_scarta_deprecati(self):
        self.assertEqual(scegli_nome("X y", [c("foo", "deprecated")]), (None, "nessuno"))

    def test_preferito(self):
        cand = [c("soffione"), c("tarassaco", "preferred")]
        self.assertEqual(scegli_nome("Taraxacum officinale", cand), ("Tarassaco", "preferito"))

    def test_itwiki_quando_nessun_preferito(self):
        cand = [c("soffione"), c("tarassaco", itwiki="Taraxacum officinale")]
        cand[1]["itwiki"] = "Tarassaco (pianta)"
        self.assertEqual(scegli_nome("Taraxacum officinale", cand), ("Tarassaco", "itwiki"))

    def test_ambiguo(self):
        cand = [c("soffione"), c("tarassaco")]
        self.assertEqual(scegli_nome("Taraxacum officinale", cand), (None, "ambiguo"))

    def test_due_preferiti_sono_ambigui(self):
        cand = [c("a", "preferred"), c("b", "preferred")]
        self.assertEqual(scegli_nome("X y", cand), (None, "ambiguo"))

    def test_duplicati_case_insensitive_sono_unico(self):
        self.assertEqual(scegli_nome("X y", [c("Teak"), c("teak")]), ("Teak", "unico"))


if __name__ == "__main__":
    unittest.main()
