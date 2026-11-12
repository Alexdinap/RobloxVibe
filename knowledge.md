# Regole di Sviluppo Roblox + Rojo

## Struttura e Nomenclatura Rojo (CRITICO)
- Controlla SEMPRE `default.project.json` prima di creare o richiedere moduli per conoscere i percorsi esatti in `ReplicatedStorage`, `ServerScriptService` e `StarterPlayerScripts`.
- Rispetta rigorosamente le estensioni di Rojo:
  * `NomeScript.server.luau` (o `.server.lua`) -> diventa un `Script` lato Server. Se ometti `.server`, Rojo crea un `ModuleScript` che non verrà mai eseguito!
  * `NomeScript.client.luau` (o `.client.lua`) -> diventa un `LocalScript` lato Client.
  * `NomeModulo.luau` (o `.lua`) -> diventa un `ModuleScript`.

## Best Practice Luau & Roblox
- Usa sempre la libreria moderna `task` (`task.wait`, `task.spawn`, `task.delay`) invece dei vecchi `wait()`, `spawn()`, `delay()`.
- Usa `:WaitForChild()` quando accedi a istanze o moduli in `ReplicatedStorage` da client o server.
- Non usare librerie Lua standard inesistenti su Roblox (`io`, `os.execute`, `require("percorso/stringa")`). Usa sempre `require(percorso.istanza.Modulo)`.
- Sicurezza: tutta l'economia, i salvataggi (`DataStoreService`) e la validazione degli acquisti devono avvenire esclusivamente lato Server.