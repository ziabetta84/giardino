import unittest
from collections import Counter

from generi_logica import (genere_di, conta_specie_gbif, decisione, nome_genere_inat,
                           descrive_specie, slug_di, nome_libero)


class TestGeneri(unittest.TestCase):
    def test_genere_di(self):
        self.assertEqual(genere_di("Rhododendron simsii"), "Rhododendron")
        self.assertEqual(genere_di("Gerbera"), "Gerbera")
        self.assertEqual(genere_di("Rhododendron 'Eiko San'"), "Rhododendron")
        self.assertIsNone(genere_di("x Odontioda Astia"))
        self.assertIsNone(genere_di(""))
        self.assertIsNone(genere_di(None))

    def test_conta_specie_gbif_esatto(self):
        match = {"matchType": "EXACT", "status": "ACCEPTED", "rank": "GENUS", "usageKey": 7466389}
        self.assertEqual(conta_specie_gbif(match, {"count": 31}), 31)

    def test_conta_specie_gbif_non_esatto(self):
        self.assertIsNone(conta_specie_gbif({"matchType": "FUZZY", "status": "ACCEPTED", "rank": "GENUS"}, {"count": 5}))
        self.assertIsNone(conta_specie_gbif({"matchType": "EXACT", "status": "SYNONYM", "rank": "GENUS"}, {"count": 5}))
        self.assertIsNone(conta_specie_gbif({"matchType": "EXACT", "status": "ACCEPTED", "rank": "FAMILY"}, {"count": 5}))
        self.assertIsNone(conta_specie_gbif(None, None))
        self.assertIsNone(conta_specie_gbif({"matchType": "EXACT", "status": "ACCEPTED", "rank": "GENUS"}, None))

    def test_decisione(self):
        self.assertEqual(decisione(31, "Gerbera jamesonii"), "spp")
        self.assertEqual(decisione(1, "Ginkgo biloba"), "specie")
        self.assertEqual(decisione(None, "Gerbera jamesonii"), "rivedere")

    def test_decisione_gia_spp(self):
        self.assertEqual(decisione(55, "Heuchera spp."), "gia_spp")
        self.assertEqual(decisione(None, "Agave sp."), "gia_spp")

    def test_nome_genere_inat(self):
        r = {"results": [{"name": "Hydrangea", "rank": "genus", "preferred_common_name": "ortensie"},
                         {"name": "Hydrangea macrophylla", "rank": "species", "preferred_common_name": "x"}]}
        self.assertEqual(nome_genere_inat(r, "Hydrangea"), "Ortensie")
        r1 = {"results": [{"name": "Gerbera", "rank": "genus", "preferred_common_name": "gerbera"}]}
        self.assertIsNone(nome_genere_inat(r1, "Gerbera"))  # uguale al genere: non è un nome italiano distinto
        self.assertIsNone(nome_genere_inat({"results": []}, "Gerbera"))
        self.assertIsNone(nome_genere_inat(None, "Gerbera"))
        r2 = {"results": [{"name": "Rhododendron", "rank": "genus", "preferred_common_name": "Rhododendron"}]}
        self.assertIsNone(nome_genere_inat(r2, "Rhododendron"))  # uguale al genere: non è un nome italiano
        r3 = {"results": [{"name": "Ericaceae", "rank": "genus", "preferred_common_name": "Ericacee"}]}
        self.assertIsNone(nome_genere_inat(r3, "Ericaceae"))  # nome di famiglia

    def test_descrive_specie(self):
        self.assertTrue(descrive_specie("Gerbera jamesonii è una perenne sempreverde", "Gerbera jamesonii"))
        self.assertTrue(descrive_specie("  gerbera jamesonii è", "Gerbera jamesonii"))
        self.assertFalse(descrive_specie("Genere molto diffuso nelle regioni tropicali", "Impatiens walleriana"))
        self.assertFalse(descrive_specie(None, "Gerbera jamesonii"))

    def test_slug_di(self):
        self.assertEqual(slug_di("Gerbera jamesonii"), "gerbera-jamesonii")
        self.assertEqual(slug_di("Viola x wittrockiana"), "viola-x-wittrockiana")

    def test_nome_libero(self):
        self.assertTrue(nome_libero("Gerbera jamesonii", {"rosa"}))
        self.assertFalse(nome_libero("Rosa", {"rosa"}))
        self.assertFalse(nome_libero("Èrica", {"erica"}))


if __name__ == "__main__":
    unittest.main()
