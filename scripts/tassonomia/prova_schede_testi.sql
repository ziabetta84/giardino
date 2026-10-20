-- Prove delle funzioni di schede_testi.sql (fase 4b) su esempi reali presi da specie. Sola lettura. Errore al primo
-- caso che non torna.
do $$
declare c record;
begin
  for c in select * from (values
      ('Scheda in bozza, importata automaticamente da Plants For A Future (pfaf.org): dati non verificati manualmente, da controllare prima di considerarli affidabili', null),
      ('Nome comune (inglese, fonte PFAF): Cretan Thyme', null),
      ('Rischi segnalati dalla fonte (testo originale in inglese, non tradotto per non alterarne il significato): None known', 'Rischi: nessuno noto'),
      ('Rischi segnalati dalla fonte (testo originale in inglese, non tradotto per non alterarne il significato): This plant is reputed to be poisonous to cattle, sheep and pigs[155].',
       'Rischi (testo in inglese): This plant is reputed to be poisonous to cattle, sheep and pigs.'),
      ('Nessun rischio noto segnalato dalla fonte.', 'Rischi: nessuno noto'),
      ('Rischi segnalati dalla fonte: pianta velenosa.', 'Rischi: pianta velenosa.'),
      ('Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m', 'Dimensioni a maturità: altezza 0.5-1m, diffusione 0.1-0.5m'),
      ('Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)', 'Rusticità: minime fino a -10 °C'),
      ('Rusticità RHS: H1C, H4 (scala UK, vedi H1-H7 nella documentazione RHS)', 'Rusticità: minime non sotto i 5 °C'),
      ('Propagazione (RHS, testo originale in inglese): "Propagate by seed, layering or semi- hardwood cuttings"',
       'Propagazione (testo in inglese): Propagate by seed, layering or semi- hardwood cuttings'),
      ('Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"',
       'Parassiti (testo in inglese): Generally pest-free; Malattie: Generally disease-free'),
      ('nota tassonomica: famiglia classificata oggi come Primulaceae (APG); tradizionalmente/in molte fonti più datate inclusa in Myrsinaceae', null)
    ) v(prima, dopo) loop
    if col.alert_elemento(c.prima) is distinct from c.dopo then
      raise exception 'avviso «%»: atteso «%», ottenuto «%»', left(c.prima, 60), c.dopo, col.alert_elemento(c.prima);
    end if;
  end loop;
  if col.alert_nota(array['Rischi: x', 'nota tassonomica: famiglia Primulaceae']) <> 'nota tassonomica: famiglia Primulaceae' then
    raise exception 'la nota tassonomica non va nella nota';
  end if;
  if col.alert_pulito(array['Scheda in bozza, importata automaticamente da Plants For A Future (pfaf.org): dati', 'Dimensioni RHS a maturità: altezza 1m'])
     <> array['Dimensioni a maturità: altezza 1m'] then raise exception 'alert_pulito'; end if;
  for c in select * from (values
      ('Da RHS, descrizione del genere (testo originale in inglese): "Allium are bulbous herbaceous perennials."', 'Descrizione del genere: Allium are bulbous herbaceous perennials.'),
      ('Da RHS (testo originale in inglese): "A deciduous shrub with white flowers."', 'A deciduous shrub with white flowers.'),
      ('Melo da fiore, arborea caducifoglia. Da RHS (testo originale in inglese): "A small tree with glossy red fruits that persist into winter"', 'Melo da fiore, arborea caducifoglia.'),
      ('Pianta erbacea perenne con fiori blu.', 'Pianta erbacea perenne con fiori blu.')
    ) v(prima, dopo) loop
    if col.descrizione_pulita(c.prima) is distinct from c.dopo then
      raise exception 'descrizione «%»: attesa «%», ottenuta «%»', left(c.prima, 60), c.dopo, col.descrizione_pulita(c.prima);
    end if;
  end loop;
  if col.esigenze_pulite('{"luce": "Non specificato dalla fonte", "acqua": "Moderata", "terreno": "Non specificato dalla fonte; terriccio universale"}')
     <> '{"acqua": "Moderata", "terreno": "terriccio universale"}' then raise exception 'esigenze: %', col.esigenze_pulite('{"luce": "Non specificato dalla fonte", "acqua": "Moderata", "terreno": "Non specificato dalla fonte; terriccio universale"}'); end if;
  if col.immagine_pulita('{"url": "https://upload.wikimedia.org/a/Mertensia_maritima_4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original", "fonte": "Wikimedia Commons", "licenza": "CC BY-SA 3.0", "attribuzione": "No machine-readable author provided. Dlanglois assumed (based on copyright claims).", "fonte_pagina": "https://commons.wikimedia.org/wiki/File:Mertensia_maritima_4.jpg"}')
     <> '{"url": "https://upload.wikimedia.org/a/Mertensia_maritima_4.jpg", "licenza": "CC BY-SA 3.0", "attribuzione": "Dlanglois", "fonte_pagina": "https://commons.wikimedia.org/wiki/File:Mertensia_maritima_4.jpg"}'
    then raise exception 'immagine'; end if;
  raise notice 'TESTI DELLE SCHEDE CORRETTI';
end $$;
