"""Prove della lettura dei titoli RHS delle cultivar (fase 4a). Uso: python3 -m unittest scripts/tassonomia/test_cultivar_titoli.py"""
import os
import sys
import unittest

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cultivar_titoli import leggi_titolo, estrai, indice_titoli  # noqa: E402


class LeggiTitolo(unittest.TestCase):
    def test_apostrofo_dentro_l_epiteto(self):
        r = leggi_titolo("Symphyotrichum novi-belgii 'King's College'")
        self.assertEqual(r['epiteto'], "King's College")
        self.assertEqual(r['base'], 'Symphyotrichum novi-belgii')

    def test_nome_commerciale_tra_quadre_ed_epiteto_tra_parentesi(self):
        r = leggi_titolo("Salvia rosmarinus [Wilma's Gold] ('Wimtim01')")
        self.assertEqual(r['epiteto'], 'Wimtim01')
        self.assertEqual(r['commerciale'], ["Wilma's Gold"])

    def test_gruppo_tra_parentesi(self):
        r = leggi_titolo("Alcea rosea (Chater's Double Group) 'Icicle'")
        self.assertEqual((r['epiteto'], r['gruppo']), ('Icicle', "Chater's Double Group"))

    def test_grex(self):
        r = leggi_titolo("Cymbidium Rio Rita gx 'Radiant'")
        self.assertEqual((r['base'], r['grex'], r['epiteto']), ('Cymbidium', 'Rio Rita', 'Radiant'))

    def test_serie_e_codici(self):
        r = leggi_titolo("Lupinus 'Gallery Pink' (Gallery Series)")
        self.assertEqual((r['epiteto'], r['serie']), ('Gallery Pink', 'Gallery Series'))
        r = leggi_titolo("Rosa [Memento] ('Dicbar') (F)")
        self.assertEqual((r['epiteto'], r['commerciale'], r['codici']), ('Dicbar', ['Memento'], ['F']))

    def test_descrittore_con_apostrofo_dopo_l_epiteto(self):
        r = leggi_titolo("Picea omorika 'Berliner's Weeper' witches' broom")
        self.assertEqual(r['epiteto'], "Berliner's Weeper")

    def test_apostrofo_seguito_da_spazio_dentro_l_epiteto(self):
        r = leggi_titolo("Rhododendron 'Rubens' Palette'")
        self.assertEqual(r['epiteto'], "Rubens' Palette")

    def test_apostrofo_finale_doppio(self):
        r = leggi_titolo("Musa acuminata 'Iholena Ula'ula'' (AAA Group) (F)")
        self.assertEqual((r['epiteto'], r['gruppo']), ("Iholena Ula'ula", 'AAA Group'))

    def test_indice_di_omonimia_non_e_un_nome_commerciale(self):
        r = leggi_titolo("Clematis 'Arabella' [1]")
        self.assertEqual((r['epiteto'], r['commerciale'], r['codici']), ('Arabella', [], ['[1]']))


class Estrai(unittest.TestCase):
    titoli = [
        "Symphyotrichum novi-belgii 'King's College'",
        "Salvia rosmarinus [Wilma's Gold] ('Wimtim01')",
        "Calluna vulgaris 'Dart's Beauty'", "Calluna vulgaris 'Dart's Hedgehog'",
        "Hedera helix 'Goldchild'", "Hedera helix 'Goldchild' (v)",
        "Geranium [Rozanne] ('Gerwat')",
    ]

    def setUp(self):
        self.indice = indice_titoli(self.titoli)

    def test_epiteto_corretto_dal_titolo(self):
        e = estrai("Symphyotrichum novi-belgii 'King'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('corretto dal titolo RHS', "King's College"))

    def test_frammento_di_nome_commerciale(self):
        e = estrai("Salvia rosmarinus 's Gold] ('", self.indice)
        self.assertEqual((e['epiteto'], e['nome_commerciale']), ('Wimtim01', "Wilma's Gold"))

    def test_uguale_anche_con_piu_titoli(self):
        e = estrai("Hedera helix 'Goldchild'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('uguale al titolo RHS', 'Goldchild'))

    def test_riga_fusa_senza_epiteto(self):
        e = estrai("Calluna vulgaris 'Dart'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('fusa: nessun titolo con questo epiteto', ''))

    def test_senza_titolo_resta_l_epiteto_di_specie(self):
        e = estrai("Chamaecyparis lawsoniana 'Minima Glauca'", self.indice)
        self.assertEqual((e['caso'], e['epiteto']), ('senza titolo RHS (altra fonte): epiteto di specie', 'Minima Glauca'))

    def test_nome_commerciale_di_una_pianta_dell_utente(self):
        e = estrai("Geranium 'Gerwat'", self.indice)
        self.assertEqual((e['epiteto'], e['nome_commerciale'], e['categoria']), ('Gerwat', 'Rozanne', 'cultivar'))

    def test_gruppo_come_epiteto(self):
        e = estrai("Narcissus 'Montongo Group'", indice_titoli([]))
        self.assertEqual(e['categoria'], 'gruppo')


if __name__ == '__main__':
    unittest.main()
