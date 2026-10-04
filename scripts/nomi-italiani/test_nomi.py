import unittest
from nomi import normalizza_nome, scegli_nome, abbina_slug, sql_str, genera_migration


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


class TestAbbina(unittest.TestCase):
    def test_abbina_per_scientifico_case_insensitive(self):
        righe = [{"slug": "taraxacum-officinale", "nome_scientifico": "Taraxacum officinale"}]
        coppie, saltati = abbina_slug({"taraxacum officinale": "Tarassaco"}, righe)
        self.assertEqual(coppie, [("taraxacum-officinale", "Tarassaco")])
        self.assertEqual(saltati, [])

    def test_omonimi_saltati(self):
        righe = [
            {"slug": "a-b", "nome_scientifico": "A b"},
            {"slug": "a-b-2", "nome_scientifico": "A b"},
        ]
        coppie, saltati = abbina_slug({"a b": "Nome"}, righe)
        self.assertEqual(coppie, [])
        self.assertEqual(saltati, ["A b"])

    def test_riga_senza_proposta_ignorata(self):
        coppie, saltati = abbina_slug({}, [{"slug": "x", "nome_scientifico": "X y"}])
        self.assertEqual((coppie, saltati), ([], []))


class TestSql(unittest.TestCase):
    def test_apici_raddoppiati(self):
        self.assertEqual(sql_str("Erba dell'orso"), "'Erba dell''orso'")

    def test_migration_e_rollback(self):
        up, down = genera_migration([("rosmarino-x", "Rosmarino"), ("a-b", "Erba d'a")], "lotto1")
        self.assertIn("update specie s set nome = v.nome", up)
        self.assertIn("('rosmarino-x', 'Rosmarino')", up)
        self.assertIn("('a-b', 'Erba d''a')", up)
        self.assertIn("s.nome = s.nome_scientifico", up)
        self.assertIn("s.specie_padre_id is null", up)
        self.assertIn("set nome = nome_scientifico", down)
        self.assertIn("'rosmarino-x'", down)
        self.assertNotIn("Rosmarino", down)


if __name__ == "__main__":
    unittest.main()
