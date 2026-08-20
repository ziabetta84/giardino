-- Sistema la scheda del pesco (prunus-persica), importata automaticamente
-- da PFAF con nome comune rimasto in latino: "nome" era "Prunus persica",
-- per questo cercando "pesco" nel selettore specie non compariva alcun
-- risultato. Corretto in "Pesco", tradotta la descrizione (era testo
-- templato in inglese) e l'alert sui rischi del seme (acido cianidrico),
-- ripulita la formattazione di esigenze.terreno.
--
-- Resta stato_verifica = "bozza": questa è solo una pulizia di
-- localizzazione, non una verifica su fonte orticola reale (RHS) — i dati
-- di coltivazione (manutenzione, ciclo_colturale, vaso) restano da
-- compilare quando arriveremo a questa specie nella coda di verifica.

update specie set
  nome = $t$Pesco$t$,
  descrizione = $t$Albero da frutto a foglia caduca, portamento arrotondato, alto fino a circa 6 m. Fioritura primaverile (da inizio a metà primavera) con fiori rosa, rossi o bianchi.$t$,
  esigenze = esigenze || '{"terreno": "Tollera diversi tipi di terreno: sabbioso/leggero, medio, argilloso/pesante"}'::jsonb,
  alert = ARRAY[$t$Scheda in bozza, importata automaticamente da Plants For A Future (pfaf.org): dati non verificati manualmente, da controllare prima di considerarli affidabili$t$, $t$Nome comune (inglese, fonte PFAF): Peach, Flowering Peach, Ornamental Peach, Common Peach$t$, $t$Rischi segnalati dalla fonte: il seme può contenere alti livelli di acido cianidrico, la stessa tossina che dà alle mandorle il loro sapore caratteristico. Si riconosce facilmente dal gusto amaro ed è di solito presente in quantità troppo modeste per fare danno, ma semi o frutti molto amari non andrebbero mangiati. In piccole quantità l'acido cianidrico stimolerebbe la respirazione e la digestione, ma in eccesso può causare insufficienza respiratoria e persino la morte.$t$]
where slug = $t$prunus-persica$t$;
