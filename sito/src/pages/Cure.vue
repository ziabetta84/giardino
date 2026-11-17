<template>
  <div class="pagina pagina--tappa">
    <TestaTappa>
      <template #titolo>Le cure, al momento giusto</template>
      L'app non ti manda a bagnare tutto il giardino il sabato mattina. Per ogni pianta guarda la scheda,
      la stagione e l'ultima cura che hai segnato, e ti mostra solo quello che è da fare.
    </TestaTappa>

    <Blocco id="b-oggi" icona="goccia" titolo="Da fare oggi">
      <p>
        In apertura trovi l'elenco delle cure in scadenza: irrigazione, concimazione e potatura, con
        quanto tempo è passato dall'ultima volta. Quelle in ritardo vengono prima. Quando hai finito
        tocchi «Fatto» e il conto di quella pianta riparte da oggi.
      </p>
      <p>
        Se hai bagnato tutta l'aiuola delle aromatiche, le segni insieme: una cura per pianta, ma un
        tocco solo.
      </p>
      <template #tavola><TavolaCure /></template>
    </Blocco>

    <Blocco id="b-stagioni" icona="sole" titolo="La stagione cambia il conto">
      <p>
        La stessa pianta non vuole le stesse cure tutto l'anno. Un limone in vaso d'estate vuole acqua
        spesso e un concime ogni due o tre settimane; d'inverno, al riparo, quasi niente. Le cadenze
        cambiano da sole con la stagione, secondo quello che dice la scheda di quella specie.
      </p>
      <p>
        Le piante coltivate in acqua, come il pothos in un vaso di vetro, non hanno l'irrigazione ma il
        ricambio dell'acqua, con la sua cadenza.
      </p>
    </Blocco>

    <Blocco id="b-concimi" icona="concimazione" titolo="La dispensa dei concimi">
      <p>
        Segni i concimi che hai in casa con il loro titolo NPK, i tre numeri sull'etichetta: azoto,
        fosforo e potassio. L'app li confronta con il fabbisogno di ogni pianta e ti dice per quali è la
        scelta migliore e per quali va bene lo stesso, così non compri un sacco nuovo per ogni vaso.
      </p>
      <p>Se l'etichetta non la capisci, la fotografi e la mandi a Zorba.</p>
      <template #tavola>
        <figure class="tavola tavola--dispensa">
          <span class="etichetta-esempio">Esempio</span>
          <p class="dispensa__nome">Concime per agrumi</p>
          <p class="dispensa__npk" aria-label="Azoto 7, fosforo 5, potassio 6">
            <span><b>7</b>N</span><span><b>5</b>P</span><span><b>6</b>K</span>
          </p>
          <p class="dispensa__voce">Scelta migliore per</p>
          <ul class="dispensa__piante"><li class="is-migliore">Limone</li><li class="is-migliore">Arancio</li></ul>
          <p class="dispensa__voce">Adatto anche per</p>
          <ul class="dispensa__piante"><li>Rosa 'Gertrude Jekyll'</li><li>Basilico</li></ul>
        </figure>
      </template>
    </Blocco>

    <Blocco id="b-impianto" icona="orologio" titolo="Se hai l'irrigazione automatica">
      <p>
        Se in giardino c'è un impianto a goccia o un programmatore, lo dici all'app: imposti ogni
        quanti giorni parte, per tutto il giardino, per una zona, per un'aiuola o per una sola pianta.
        Le piante coperte dal programma non compaiono più tra le irrigazioni da fare a mano. Quando
        è prevista pioggia sulle zone all'aperto, l'app ti segnala che il giro si può saltare.
      </p>
    </Blocco>

    <Blocco id="b-rete" icona="zona-vaso" titolo="Anche in fondo al giardino">
      <p>
        L'app si apre dal browser e si aggiunge alla schermata Home del telefono come un'app qualsiasi.
        Le tue piante e le loro schede restano consultabili anche dove il segnale non arriva: in fondo
        all'orto, in cantina, nella serra.
      </p>
    </Blocco>

    <ProssimaTappa />
  </div>
</template>

<script setup>
import { usePagina } from '../seo.js'
import TestaTappa from '../components/TestaTappa.vue'
import Blocco from '../components/Blocco.vue'
import TavolaCure from '../components/TavolaCure.vue'
import ProssimaTappa from '../components/ProssimaTappa.vue'

usePagina({
  titolo: 'Irrigazione, concimazione e potatura · Zorba in giardino',
  descrizione: "Zorba in giardino calcola quando irrigare, concimare e potare ogni pianta in base alla specie, alla stagione e all'ultima cura registrata, e abbina i concimi che hai al fabbisogno delle tue piante.",
  percorso: '/cure/',
})
</script>
