# Last Flame — Project Backup & Studio Setup

## Folder Structure
- `src/shared/GameConfig.lua` -> `ReplicatedStorage.GameConfig` (ModuleScript)
- `src/shared/NumberFormat.lua` -> `ReplicatedStorage.NumberFormat` (ModuleScript)
- `src/shared/Localization.lua` -> `ReplicatedStorage.Localization` (ModuleScript - Full EN / IT translation)
- `src/shared/EconomyEngine.lua` -> `ReplicatedStorage.EconomyEngine` (ModuleScript)
- `src/server/WorldBuilder.lua` -> `ServerScriptService.WorldBuilder` (ModuleScript)
- `src/server/Regno1Service.lua` -> `ServerScriptService.Regno1Service` (ModuleScript)
- `src/server/ShadowDefenseService.lua` -> `ServerScriptService.ShadowDefenseService` (ModuleScript)
- `src/server/FlameServer.server.lua` -> `ServerScriptService.FlameServer` (Script)
- `src/client/ClientWorldVisuals.lua` -> `StarterPlayer.StarterPlayerScripts.ClientWorldVisuals` (ModuleScript)
- `src/client/ShopUI.lua` -> `StarterPlayer.StarterPlayerScripts.ShopUI` (ModuleScript)
- `src/client/FlameClient.client.lua` -> `StarterPlayer.StarterPlayerScripts.FlameClient` (LocalScript)

## Roblox Studio Checklist Before Publishing
1. **Max Players**: Set to `10` in *Game Settings -> Places -> Edit*.
2. **API Services**: Enable *Studio Access to API Services* in *Game Settings -> Security* for DataStore saves.
3. **StreamingEnabled**: Uncheck `Workspace.StreamingEnabled` so all 10 zones load immediately on join.
4. **GamePass ID**: Paste your Double Light GamePass ID in `GameConfig.RobuxPasses.DoubleLight.GamePassId`.
