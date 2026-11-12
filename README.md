# Quantum Core ⚡

Gioco incrementale Sci-Fi/Neon per Roblox. **Tutta la mappa 3D, le UI e la logica sono generate via codice** su un Baseplate vuoto: nessun asset esterno, nessun modello salvato nel place.

- 6 pulsanti a terra su 2 file ordinate → sali di livello restandoci sopra
- Albero di 15 nodi sul muro → Watt → Plasma → prestige
- 5 stadi evolutivi del nucleo centrale
- Sfere di Sovraccarico (boost x2), auto-buyer, classifica globale, salvataggio + guadagno offline

## Come aprirlo in Roblox Studio

Il progetto usa [Rojo](https://rojo.space).

Live sync (consigliato per modificare):

```bash
rojo serve
```

Poi in Studio: plugin **Rojo** → *Connect*.

Oppure genera un place da aprire con doppio click:

```bash
rojo build -o QuantumCore.rbxlx
```

Premi **Play**: `WorldBuilder` cancella il Baseplate e costruisce la mappa, `GameEngine` avvia l'economia.

> In Studio senza API DataStore attive il gioco funziona lo stesso: profili in memoria e classifica basata sulla sessione (tutti i `pcall` falliscono in modo pulito).

## Struttura (allineata a `default.project.json`)

| Percorso Rojo | File su disco |
| --- | --- |
| `ReplicatedStorage.Shared` | `src/shared/` |
| `ServerScriptService.Server` | `src/server/` |
| `StarterPlayer.StarterPlayerScripts.Client` | `src/client/` |

```
src/shared/BigNum.luau                formattazione 1e3..1e308+ con suffissi K..Dc e notazione scientifica
src/shared/GameConfig.luau            SOLO dati: valute, 6 pulsanti, 15 nodi, stadi del nucleo, mappa, tema
src/server/WorldBuilder.server.luau   genera piattaforma, nucleo, muro, pulsanti, classifica, spawn
src/server/GameEngine.server.luau     remotes, DataStore, economia, prestige, sfere bonus, classifica
src/client/ClientEffects.client.luau HUD, albero sul muro, billboard, nucleo, juice
```

## Economia in breve

| Valuta | Come si ottiene | A cosa serve |
| --- | --- | --- |
| **Watt** | pulsanti a terra, boost, offline | livelli dei pulsanti e nodi iniziali |
| **Plasma** | passivo dopo l'**Iniettore al Plasma** | nodi avanzati (auto-buyer, moltiplicatori) |
| **Materia Oscura** | **Collasso Quantistico** (richiede 1e15 Watt) | moltiplicatore permanente `2^DM` + aura attorno all'avatar |

Il Plasma non richiede reset: si sblocca con un nodo e continua a salire insieme ai Watt.

### Albero (15 nodi, nessun reset forzato)

- **Ramo Watt**: Bobina di Sovraccarico → Circuito Refrigerante → Risonanza Armonica → Componenti Riciclati → Rilevatore di Anomalie → Overclock → Chip di Contrattazione
- **Nodo centrale**: Iniettore al Plasma (sblocca Plasma/s)
- **Ramo Plasma**: Condotto di Plasma → Lente al Plasma → Auto-Buyer Base → Auto-Buyer Avanzato → Specchio Quantistico → Singolarita
- **Finale**: Collasso Quantistico → prestige ripetibile, +Materia Oscura

L'acquisto continuo funziona restando **sopra** un pad: il server compra un livello ogni 0.15s mentre accumuli Watt.

## Dove mettere le mani

- Bilanciamento, costi, posizioni, colori, testi → `src/shared/GameConfig.luau`
- Nuove regole/effetti → `src/server/GameEngine.server.luau` (funzione `calcolaStatistiche` per i moltiplicatori, `acquistaNodo` per i nodi)
- Nuova grafica della mappa → `src/server/WorldBuilder.server.luau`
- Nuova UI → `src/client/ClientEffects.client.luau`

## Nota sull'architettura per-giocatore

L'economia è 100% server-side: il client invia solo richieste e riceve lo stato ogni 0.2s. Due elementi sono disegnati lato client perché devono essere **diversi per ogni giocatore**:

- l'Upgrade Tree interattivo (una `SurfaceGui` agganciata al pannello sul muro, dentro `PlayerGui`): gli sblocchi sono personali, una `SurfaceGui` creata dal server sarebbe condivisa da tutti;
- le `BillboardGui` dei 6 pulsanti con livello e costo del singolo giocatore.

La classifica globale invece è condivisa: la sua `SurfaceGui` è creata dal server in `WorldBuilder` e aggiornata da `GameEngine`.
