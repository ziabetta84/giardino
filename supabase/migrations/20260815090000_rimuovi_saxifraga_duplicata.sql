-- saxifraga è una voce duplicata e orfana di sassifraga (stessa pianta,
-- Saxifraga arendsii), con esigenze/alert/descrizione vuoti — non usata da
-- nessuna pianta reale. Stesso pattern già visto con "stracchino" in #128.
delete from specie where slug = 'saxifraga';
