# RobloxVibe (L'Ultima Fiamma — v5.1 • Regno 1)

## Panoramica del Gioco
Gioco incremental/clicker/exploration ambientato nel **Santuario della Fiamma** su Roblox, strutturato per **Rojo** (`default.project.json`, progetto `RobloxVibe`).
Il giocatore parte nell'oscurità attorno alla **Fiamma Primordiale** centrale, accumula **Punti Luce** cliccando la fiamma (con **Calore Fiamma** e **Critici**), costruisce **8 Altari a terra**, risveglia **Regno 1** e padroneggia la sua meccanica attiva (**Il Rituale della Catena del Fuoco**), prima di espandersi verso i regni successivi, gli **Spiriti di Luce** e il Prestige (**Grande Alba**).

## Novità v5.1 — Meccanica Principale di Regno 1
- **Regno 1 (`u_braziers` / `Zone = "Braziers"`):**
  - Oltre all'anello di 12 torce ornamentali, `WorldBuilder` costruisce **5 Bracieri Antichi Interattivi** (`RitualBrazier_1` -> `RitualBrazier_5`) su pedane rialzate attorno all'anello esterno del Santuario.
  - Una volta acquistato **Regno 1** nella scheda `Regni`, il giocatore raggiunge il **Braciere I** per assorbire la **Scintilla Viva** e avviare il timer di **18.0s**.
  - Correndo e saltando lungo il percorso fino al **Braciere V**, ogni tappa accesa (`II`, `III`, `IV`) aggiunge **+2.5s**, sprigiona un'onda d'urto luminosa e suona una nota ascendente.
  - **Ricompensa 1° Completamento:** Sblocca la **Benedizione di Regno 1** (**+35% produzione permanente**, salvata nel `DataStore`).
  - **Ricompensa Rigiocabile (Time Trial):** Assegna un premio istantaneo in Punti Luce scalato sul `PointsPerSec` + il buff temporaneo **Fiamma Ruggente** (`x1.50` – `x2.50` per `30s` in base al tempo residuo) e salva il record personale (`BestTime`).

## Architettura Modulare (12 file Lua + Rojo config)
- `default.project.json`: Configurazione Rojo per `RobloxVibe`.
- `src/shared/NumberFormat.lua`: Formattazione suffissi numerici.
- `src/shared/GameConfig.lua`: Dati di bilanciamento, 16 potenziamenti progressivi (`Regno 1` come primo regno), parametri `GameConfig.Regno1`, altari, spiriti, perk stellari e codici promo.
- `src/server/WorldBuilder.lua`: Generazione procedurale 3D del Santuario, Fiamma, 8 Altari, i 5 Bracieri Rituali di `Regno 1` e le restanti zone.
- `src/server/EconomyEngine.lua`: Calcolo puro delle statistiche incluse la **Benedizione di Regno 1 (`+35%`)** e il buff attivo **Fiamma Ruggente**.
- `src/server/Regno1Service.lua`: Logica server-authoritative della **Catena del Fuoco** di `Regno 1` (avvio, verifica sequenza e distanza anti-cheat, timer, record personale e premi).
- `src/server/FlameServer.server.lua`: Server principale, `DataStore` (`LastFlame_V5` con migrazione retrocompatibile), tick di `Regno1Service`, altari, sfere vaganti e ombre.
- `src/client/Regno1Visuals.lua`: Fascio guida 3D verso il prossimo braciere, sfera `Scintilla Viva` orbitante, esplosioni particellari e audio con scala musicale ascendente.
- `src/client/Regno1UI.lua`: Barra dedicata della sfida `Regno 1 • Catena del Fuoco` (timer, avanzamento `I–V`, `+2.5s!`) e pillola record / buff attivo.
- `src/client/PopupManager.lua`, `src/client/WorldVisuals.lua`, `src/client/ShopUI.lua`, `src/client/FlameClient.client.lua`: HUD, shop progressivo e illuminazione dinamica.
