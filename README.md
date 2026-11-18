# 🔥 L'Ultima Fiamma (LastFlame) — Edizione Multiplayer 10 Zone

Progetto completo strutturato per **Roblox Studio** e **Rojo**, con supporto fino a **10 giocatori contemporanei** su 10 isole santuario indipendenti (`Zona 1` – `Zona 10`).

## 📁 Struttura delle Cartelle

- `src/shared/` → **ReplicatedStorage**
  - `GameConfig.lua` *(ModuleScript)*: Configurazione delle 10 zone, potenziamenti personaggio, 8 pulsanti a terra del braciere, spiriti, prestigio e codici promo.
  - `EconomyEngine.lua` *(ModuleScript)*: Calcolo bilanciato di click, produzione/sec, moltiplicatori, spiriti equipaggiati e zone sbloccate.
  - `NumberFormat.lua` *(ModuleScript)*: Formattazione compatta dei grandi numeri (`K`, `M`, `B`, `T`, `Qa`, `Qi`, ...).
- `src/server/` → **ServerScriptService**
  - `WorldBuilder.lua` *(ModuleScript)*: Genera proceduralmente l'Isola Centrale e le 10 Zone Individuali disposte ad anello con ponti di luce, cartelli proprietario, bracieri e pulsanti a terra.
  - `Regno1Service.lua` *(ModuleScript)*: Gestisce la corsa a tempo *Catena del Fuoco* sui 5 Bracieri Rituali individuali di ogni Zona.
  - `FlameServer.server.lua` *(Script)*: Gestisce DataStore (`LastFlame_V5`), assegnazione automatica delle 10 Zone, click sul Braciere, acquisti sui pad, evocazione/fusione Spiriti e Rinascita.
- `src/client/` → **StarterPlayer → StarterPlayerScripts**
  - `ClientWorldVisuals.lua` *(ModuleScript)*: Evidenzia localmente i pulsanti acquistabili della propria Zona, anima i Bracieri di Regno 1 e renderizza gli Spiriti in orbita attorno a tutti i giocatori nella lobby.
  - `ShopUI.lua` *(ModuleScript)*: Barra inferiore (`🏠 LA MIA ZONA`, `🧙 PERSONAGGIO`, `⚡ LUCE x2`), menù a schede (`Personaggio`, `Spiriti`, `Alba`, `Codici`) e schermata celebrativa della Vittoria.
  - `FlameClient.client.lua` *(LocalScript)*: HUD superiore, click 3D sulla propria Fiamma, numeri fluttuanti, effetti sonori, onde d'urto e notifiche.

## 🚀 Installazione Rapida in Roblox Studio

1. **Con Rojo:** esegui `rojo serve default.project.json` nella cartella principale e connetti il plugin Rojo in Roblox Studio.
2. **Manuale:**
   - Copia i 3 `ModuleScript` di `src/shared` dentro `ReplicatedStorage`.
   - Copia `WorldBuilder` e `Regno1Service` come `ModuleScript` e `FlameServer` come `Script` dentro `ServerScriptService`.
   - Copia `ClientWorldVisuals` e `ShopUI` come `ModuleScript` e `FlameClient` come `LocalScript` dentro `StarterPlayer > StarterPlayerScripts`.
   - Assicurati che **API Services** (DataStore) sia abilitato nelle impostazioni del gioco su Roblox Studio.
