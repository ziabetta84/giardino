# Completamento Fase 5 (progetti, tappe, settings, concimi) — Design

**Contesto:** la Fase 5 della migrazione a Supabase (zone/sottozone/piante, vedi
`docs/superpowers/specs/2026-08-30-fase5-multitenant-design.md`) è stata
completata il 30/08/2026, ma copriva solo una parte dello scope originale
della issue [#122](https://github.com/ziabetta84/giardino/issues/122). Questa
spec copre il resto: `progetti`+`tappe`, `settings`, `concimi`, tutti
migrati da JSON/GitHub Contents API a tabelle Supabase multi-tenant con RLS
per `owner_id = auth.uid()`, seguendo lo stesso pattern già validato in
Fase 5.

**Fuori scope (deciso in brainstorming):**
- `cure_log` come tabella a parte: **non serve**. `piante.ultima_cura` (jsonb,
  solo l'ultima data per tipo) resta com'è — nessuna vista oggi legge o
  mostrerebbe uno storico completo delle cure. Punto della issue #122 chiuso
  come già soddisfatto.
- Script di importazione `coltivazione`: **non serve**. `piante.coltivato_in`
  (vaso/terra/acqua) esiste già da prima della Fase 5 ed è già valorizzato su
  tutte le 122 piante — stesso campo descritto con un altro nome nella issue.
  Punto chiuso come già soddisfatto.
- `richieste-agente.json`: resta su GitHub/JSON. Legato al comando `/elabora`,
  eseguito manualmente solo dal proprietario del progetto — non ha un
  percorso multi-utente ovvio, va ridiscusso da capo in un round futuro
  (edge function? cron?), non con lo stesso pattern delle altre tabelle.

## Architettura

Stesso pattern di Fase 5: tabelle Supabase con RLS `owner_id = auth.uid()`,
composable dedicato per dominio quando servono più punti di scrittura
(`useProgettiApi.js`), scritture dirette da Supabase nella view quando il
punto di scrittura è uno solo (`ConcimiView.vue`, come già fa
`EditZonaView.vue`). Lo store Pinia (`src/stores/dati.js`) continua a
esporre la stessa forma keyed-by-id/nome che le view già conoscono
(`store.progetti`, `store.concimi`, `store.settings`) — nessuna view cambia
la propria lettura dei dati, solo la scrittura passa dal nuovo composable
invece che da `useApi().saveJSON()`.

## Schema

```sql
create table progetti (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  titolo text not null,
  descrizione text,
  zona text,              -- testo libero, NON una FK verso la tabella zone:
                           -- oggi contiene valori come "casa / soggiorno" che
                           -- non corrispondono ai nomi delle zone giardino
  stato text not null default 'aperto'
    check (stato in ('aperto','in_corso','completato','fallito','cancellato')),
  creato date not null default current_date
);

create table tappe (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  progetto_id uuid not null references progetti(id) on delete cascade,
  data date not null,
  descrizione text not null,
  esito text not null default 'atteso'
    check (esito in ('atteso','riuscito','fallito','saltato'))
);

create table concimi (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id),
  nome text not null,
  npk jsonb not null default '{"n":0,"p":0,"k":0}',
  disponibile boolean not null default true,
  descrizione text
);

create table settings (
  owner_id uuid primary key default auth.uid() references auth.users(id),
  location jsonb,          -- {lat, lon, altitude}
  units jsonb not null default '{"temperature":"celsius","wind":"kmh","precipitation":"mm"}',
  meteo jsonb not null default '{"provider":"open-meteo","days":3}',
  ui jsonb not null default '{"theme":"auto"}',
  zona_climatica_id uuid references zone_climatiche(id)
);
```

Perché `tappe` è una tabella e non un campo `jsonb` su `progetti` (decisione
presa in brainstorming, correggendo una prima ipotesi jsonb): oggi esistono
due percorsi di scrittura indipendenti sulle tappe — `ProgettoView.vue`
riscrive l'intero form (tutte le tappe insieme) mentre `AttivitaView.vue`
(`registraTappa`) aggiorna una singola tappa per indice posizionale dalla
lista "in scadenza". Con un `UPDATE progetti SET tappe = :arrayIntero` un
`UPDATE` concorrente perderebbe silenziosamente le modifiche dell'altro
(nessun retry su conflitto come oggi ha `saveJSON` via SHA di GitHub). Una
tabella con una riga per tappa rende `registraTappa` un
`UPDATE tappe SET esito=... WHERE id=:id` — atomico, senza race possibile —
ed elimina anche il riferimento per indice posizionale (bug latente: un
indice può puntare alla tappa sbagliata se l'array cambia nel frattempo).

RLS su tutte e quattro le tabelle: `owner_id = auth.uid()` su
insert/select/update/delete — stesso pattern reale (non "aperto") già usato
per `zone`/`sottozone`/`piante`, non quello temporaneamente aperto di
`specie`.

`tappe.progetto_id on delete cascade`: eliminare un progetto elimina le sue
tappe automaticamente — diverso dal caso zone/piante di Fase 5 (dove
l'eliminazione viene bloccata se ci sono piante collegate): qui la cascata
è corretta, una tappa non ha senso senza il suo progetto.

`settings`: una riga per utente, `owner_id` è la chiave primaria stessa (non
serve un `id` a parte — un utente ha al più una riga).

## Store (`src/stores/dati.js`)

Nuove funzioni pure di mapping, sullo stesso modello di `mappaZone`/
`mappaSottozone`/`mappaPiante`:

```js
export function mappaProgetti(righeProgetti, righeTappe) {
  const tappePerProgetto = {}
  for (const t of righeTappe) {
    (tappePerProgetto[t.progetto_id] ??= []).push({
      id: t.id, data: t.data, descrizione: t.descrizione, esito: t.esito,
    })
  }
  for (const lista of Object.values(tappePerProgetto)) {
    lista.sort((a, b) => (a.data || '').localeCompare(b.data || ''))
  }
  return Object.fromEntries(righeProgetti.map(p => [p.id, {
    titolo: p.titolo, descrizione: p.descrizione, zona: p.zona,
    stato: p.stato, creato: p.creato,
    tappe: tappePerProgetto[p.id] ?? [],
  }]))
}

export function mappaConcimi(righeConcimi) {
  return Object.fromEntries(righeConcimi.map(c => [c.id, {
    nome: c.nome, npk: c.npk, disponibile: c.disponibile, descrizione: c.descrizione,
  }]))
}

export function mappaSettings(rigaSettings) {
  if (!rigaSettings) return null
  return {
    location: rigaSettings.location, units: rigaSettings.units,
    meteo: rigaSettings.meteo, ui: rigaSettings.ui,
    zona_climatica_id: rigaSettings.zona_climatica_id,
  }
}
```

Nota: `progetti` oggi è keyed by id-stringa generato client-side
(`progetto-<timestamp>`); con la tabella Supabase l'id diventa un uuid
generato server-side — le view che leggono `store.progetti[id]` per
`route.params.id` continuano a funzionare identicamente (l'id è solo una
stringa diversa nella forma, non nel ruolo).

`caricaTutto()` sostituisce le tre righe `caricaJSON('progetti.json')`,
`caricaJSON('settings.json')`, `caricaJSON('concimi.json')` con query
Supabase in `Promise.all` insieme a quelle già esistenti per
zone/sottozone/piante, poi applica i mapping sopra. `richieste-agente.json`
resta `caricaJSON` invariato.

## Composable: `useProgettiApi.js` (nuovo file)

```js
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'

export function useProgettiApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  // dati.tappe: array locale (form) con { id?, data, descrizione, esito }.
  // Tappe senza id sono nuove (insert); quelle con id il cui contenuto è
  // cambiato rispetto allo snapshot originale vengono aggiornate; quelle
  // presenti nello snapshot ma assenti dall'array locale vengono eliminate.
  async function salvaProgetto(id, dati, isNuova = false) {
    const riga = {
      titolo: dati.titolo, descrizione: dati.descrizione || null,
      zona: dati.zona || null, stato: dati.stato, creato: dati.creato,
    }

    let progettoId = id
    if (isNuova) {
      const { data, error } = await supabase.from('progetti').insert(riga).select().single()
      if (error) throw error
      progettoId = data.id
    } else {
      const { error } = await supabase.from('progetti').update(riga).eq('id', id)
      if (error) throw error
    }

    const originali = new Map((store.progetti?.[id]?.tappe ?? []).map(t => [t.id, t]))
    const localiConId = new Set(dati.tappe.filter(t => t.id).map(t => t.id))

    for (const [tappaId] of originali) {
      if (!localiConId.has(tappaId)) {
        const { error } = await supabase.from('tappe').delete().eq('id', tappaId)
        if (error) throw error
      }
    }

    const tappeFinali = []
    for (const t of dati.tappe) {
      const rigaTappa = { data: t.data, descrizione: t.descrizione.trim(), esito: t.esito || 'atteso' }
      if (t.id) {
        const originale = originali.get(t.id)
        const cambiata = !originale || originale.data !== rigaTappa.data
          || originale.descrizione !== rigaTappa.descrizione || originale.esito !== rigaTappa.esito
        if (cambiata) {
          const { error } = await supabase.from('tappe').update(rigaTappa).eq('id', t.id)
          if (error) throw error
        }
        tappeFinali.push({ id: t.id, ...rigaTappa })
      } else {
        const { data, error } = await supabase.from('tappe')
          .insert({ ...rigaTappa, progetto_id: progettoId }).select().single()
        if (error) throw error
        tappeFinali.push({ id: data.id, ...rigaTappa })
      }
    }
    tappeFinali.sort((a, b) => (a.data || '').localeCompare(b.data || ''))

    store.progetti = {
      ...store.progetti,
      [progettoId]: { ...riga, tappe: tappeFinali },
    }
    return progettoId
  }

  async function eliminaProgetto(id) {
    const { error } = await supabase.from('progetti').delete().eq('id', id)
    if (error) throw error
    const nuovi = { ...store.progetti }
    delete nuovi[id]
    store.progetti = nuovi
  }

  // Aggiorna una singola tappa per id — atomico, nessuna race con salvaProgetto.
  async function registraTappa(tappaId, esito = 'riuscito') {
    const { error } = await supabase.from('tappe').update({ esito }).eq('id', tappaId)
    if (error) throw error
    const nuovi = { ...store.progetti }
    for (const pid of Object.keys(nuovi)) {
      const tappe = nuovi[pid].tappe
      const i = tappe.findIndex(t => t.id === tappaId)
      if (i !== -1) {
        nuovi[pid] = { ...nuovi[pid], tappe: tappe.map((t, idx) => idx === i ? { ...t, esito } : t) }
        break
      }
    }
    store.progetti = nuovi
  }

  return { salvaProgetto, eliminaProgetto, registraTappa }
}
```

## `useZonaClimatica.js` (nuovo composable)

```js
// Euristica dichiaratamente approssimativa (coerente con stato_verifica
// bozza/verificato già presente su zone_climatiche stessa): fasce di
// latitudine per nord/centro/sud continentali, bounding box grezzo per
// Sicilia/Sardegna, soglia di altitudine per le varianti "-montana".
const SOGLIA_MONTANA_M = 600

// Bounding box approssimativi (lat min/max, lon min/max)
const SARDEGNA = { latMin: 38.8, latMax: 41.3, lonMin: 8.0, lonMax: 9.8 }
const SICILIA  = { latMin: 36.6, latMax: 38.3, lonMin: 12.4, lonMax: 15.7 }

function inBox(lat, lon, box) {
  return lat >= box.latMin && lat <= box.latMax && lon >= box.lonMin && lon <= box.lonMax
}

export function calcolaCodiceZonaClimatica({ lat, lon, altitude = 0 }) {
  if (lat == null || lon == null) return null
  const montana = altitude >= SOGLIA_MONTANA_M

  if (inBox(lat, lon, SARDEGNA) || inBox(lat, lon, SICILIA)) {
    return montana ? 'insulare-montana' : 'insulare'
  }
  if (lat >= 44.5) return montana ? 'nord-montana' : 'nord'
  if (lat >= 41.5) return montana ? 'centro-montana' : 'centro'
  return montana ? 'sud-montana' : 'sud'
}

export function useZonaClimatica() {
  return { calcolaCodiceZonaClimatica }
}
```

Chiamata da `useSettingsApi.salvaSettings()` (sotto) solo quando
`zona_climatica_id` è ancora `null` al momento del salvataggio — mai più
ricalcolata automaticamente dopo, anche se `location` cambia, per non
sovrascrivere una scelta manuale.

## Composable: `useSettingsApi.js` (nuovo file)

```js
import { useDatiStore } from '@/stores/dati'
import { useSupabase } from '@/composables/useSupabase'
import { calcolaCodiceZonaClimatica } from '@/composables/useZonaClimatica'

export function useSettingsApi() {
  const store = useDatiStore()
  const supabase = useSupabase()

  async function salvaSettings(dati) {
    const riga = { location: dati.location, units: dati.units, meteo: dati.meteo, ui: dati.ui }

    if (!store.settings?.zona_climatica_id && dati.location) {
      const codice = calcolaCodiceZonaClimatica(dati.location)
      if (codice) {
        const { data: zc } = await supabase.from('zone_climatiche').select('id').eq('codice', codice).single()
        if (zc) riga.zona_climatica_id = zc.id
      }
    } else {
      riga.zona_climatica_id = dati.zona_climatica_id ?? store.settings?.zona_climatica_id ?? null
    }

    // owner_id non va nel payload: la colonna ha default auth.uid() (stesso
    // pattern di zone/sottozone/piante) — ma upsert su una PK diversa da
    // "id" richiede onConflict esplicito, altrimenti PostgREST non sa su
    // quale colonna fare il confronto per decidere insert vs update.
    const { data, error } = await supabase.from('settings').upsert(riga, { onConflict: 'owner_id' }).select().single()
    if (error) throw error
    store.settings = { location: data.location, units: data.units, meteo: data.meteo, ui: data.ui, zona_climatica_id: data.zona_climatica_id }
  }

  return { salvaSettings }
}
```

## `concimi`

Nessun composable dedicato: `ConcimiView.vue` scrive direttamente su
Supabase (stesso pattern di `EditZonaView.vue`), tre operazioni sostituendo
gli attuali tre `saveJSON('concimi.json', ...)`:

```js
// crea/modifica
await supabase.from('concimi').upsert({ id, nome, npk, disponibile, descrizione }).select().single()
// toggle disponibilità
await supabase.from('concimi').update({ disponibile }).eq('id', id)
// elimina
await supabase.from('concimi').delete().eq('id', id)
```

## Migrazione dati (backfill)

Stesso approccio di Fase 5: generare un file di migration SQL con `INSERT`
letterali per le righe esistenti, `owner_id` esplicito su ognuna (stesso
uuid usato in Fase 5:
`fc227422-ece8-4dca-b706-956ec7ca9e6e`), letti dagli attuali
`public/data/progetti.json`, `settings.json`, `concimi.json` — poi quei tre
file vengono cancellati, come `zone.json`/`sottozone.json`/`piante.json` in
Fase 5.

Il campo `zona` delle tappe/progetti resta testo libero copiato
letteralmente (nessuna risoluzione a id, non essendo una FK).

## Aggiornamento pagine coinvolte

- `src/views/ProgettiView.vue`, `ProgettoView.vue` → `useProgettiApi()` al
  posto di `useApi().saveJSON`.
- `src/views/AttivitaView.vue` → `useProgettiApi().registraTappa` al posto
  del `saveJSON` locale di `registraTappa`.
- `src/views/ConcimiView.vue` → chiamate dirette Supabase al posto di
  `saveJSON`.
- Nuova `src/views/SettingsView.vue` (route `/impostazioni`, aggiunta a
  `src/router/index.js`): form minimale con `location` (lat/lon/altitude,
  numerici), `units`/`meteo`/`ui` (gli stessi campi già in
  `settings.json` oggi, nessuno nuovo), e un select per `zona_climatica_id`
  con le 8 opzioni di `zone_climatiche` (mostra il nome, es. "Toscana,
  Marche, Lazio") — precompilato dal calcolo automatico ma modificabile a
  mano, coerente con "modificabile a mano dopo" della issue. Linkata da
  `AccountView.vue` (tema "impostazioni personali", non aggiunta a
  `NavBar`/`BottomNav` per non affollare la navigazione primaria con una
  pagina a bassa frequenza d'uso). Oggi `store.settings` è solo letto
  (`HomeView.vue`, `MeteoView.vue`) — questa è la prima UI di scrittura,
  usa `useSettingsApi().salvaSettings()`.
- `src/composables/useAuth.js`: nessun cambiamento necessario — il pattern
  di pulizia cache al logout copre già l'intero dominio REST Supabase.
- `.claude/commands/elabora.md`, `CLAUDE.md`: aggiornare le sezioni che
  citano `progetti.json`/`settings.json`/`concimi.json` come JSON su
  GitHub, spostandole nella stessa sezione "Migrazione ... → Supabase" già
  esistente per zone/sottozone/piante (o una sezione dedicata "Fase 5
  completamento").
- `public/data/progetti.json`, `settings.json`, `concimi.json` → cancellati
  a fine migrazione, come già fatto per zone/sottozone/piante.

## Testing

Stesso approccio validato in Fase 5:
- Script Node puri per `mappaProgetti`/`mappaConcimi`/`mappaSettings` e per
  `calcolaCodiceZonaClimatica` (casi: Fano/PU → centro, un punto in
  Sardegna → insulare, un punto ad alta quota → variante -montana).
- `npm run build`.
- Query dirette via MCP Supabase per verificare RLS e backfill riga per
  riga (stesso numero di progetti/tappe/concimi tra JSON originale e
  tabelle).
- Verifica manuale nel browser a fine implementazione (tu), con HAR se
  emergono dubbi su rete o concorrenza — qui particolarmente rilevante per
  il flusso `registraTappa` vs `salvaProgetto` appena discusso.
