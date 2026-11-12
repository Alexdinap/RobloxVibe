--!nonstrict
--[[
	WorldBuilder - genera TUTTA la mappa 3D su un Baseplate vuoto.

	Fa parte di ServerScriptService.Server e viene eseguito una volta all'avvio:
	  1. elimina Baseplate e spawn di default, sistema l'illuminazione
	  2. costruisce la piattaforma fluttuante con bordi e griglia neon
	  3. costruisce il piedistallo con il Quantum Core (sfera + anelli neon)
	  4. costruisce il muro hi-tech con la SurfaceGui di sfondo dell'Upgrade Tree
	  5. costruisce i 6 pulsanti a terra con luci neon
	  6. costruisce il pannello Classifica Globale (SurfaceGui lato server)

	Nota di architettura: i nodi dell'Upgrade Tree sono PER GIOCATORE (ognuno ha
	i suoi sblocchi), quindi la SurfaceGui interattiva viene disegnata dal client
	sopra questo muro; qui creiamo la struttura e la grafica di sfondo.
	La classifica invece e' globale, quindi la sua SurfaceGui vive sul server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local MAP = GameConfig.Map
local THEME = GameConfig.Theme

local MAP_FOLDER_NAME = "QuantumCoreMap"

--------------------------------------------------------------------------------
-- HELPER DI COSTRUZIONE
--------------------------------------------------------------------------------

-- Crea una Part con le proprieta' piu' usate, in una riga sola.
local function creaPart(genitore, nome, dimensione, cframe, colore, materiale, opzioni)
	local opts = opzioni or {}
	local part = Instance.new("Part")
	part.Name = nome
	part.Size = dimensione
	part.CFrame = cframe
	part.Color = colore or THEME.Pannello
	part.Material = materiale or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = opts.canCollide ~= false
	part.CanTouch = opts.canTouch ~= false
	part.CastShadow = opts.castShadow ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if opts.shape then
		part.Shape = opts.shape
	end
	if opts.transparency then
		part.Transparency = opts.transparency
	end
	if opts.reflectance then
		part.Reflectance = opts.reflectance
	end
	part.Parent = genitore
	return part
end

-- Cilindro verticale (la Shape Cylinder ha l'asse su X, quindi ruotiamo di 90 gradi).
local function creaCilindro(genitore, nome, altezza, diametro, posizione, colore, materiale, opzioni)
	return creaPart(
		genitore,
		nome,
		Vector3.new(altezza, diametro, diametro),
		CFrame.new(posizione) * CFrame.Angles(0, 0, math.rad(90)),
		colore,
		materiale,
		opzioni
	)
end

-- Costruisce un anello neon da tanti segmenti: niente mesh o asset esterni.
local function creaAnello(genitore, nome, centro, raggio, segmenti, spessore, colore, inclinazioneX, inclinazioneZ)
	local modello = Instance.new("Model")
	modello.Name = nome

	-- Perno centrale invisibile: serve da perno di rotazione per il client.
	local perno = creaPart(modello, "Perno", Vector3.new(1, 1, 1), CFrame.new(centro), colore, Enum.Material.SmoothPlastic, {
		canCollide = false,
		canTouch = false,
		transparency = 1,
		castShadow = false,
	})

	local rotazione = CFrame.Angles(inclinazioneX or 0, 0, inclinazioneZ or 0)
	local lunghezza = 2 * raggio * math.sin(math.pi / segmenti) * 1.15

	for indice = 1, segmenti do
		local angolo = (indice / segmenti) * math.pi * 2
		local locale = Vector3.new(math.cos(angolo) * raggio, 0, math.sin(angolo) * raggio)
		local posizione = perno.Position + rotazione:VectorToWorldSpace(locale)
		local segmento = creaPart(
			modello,
			"Segmento",
			Vector3.new(lunghezza, spessore, spessore),
			CFrame.new(posizione) * CFrame.Angles(0, -angolo, 0),
			colore,
			Enum.Material.Neon,
			{ canCollide = false, canTouch = false, castShadow = false }
		)
		segmento.Locked = true
	end

	modello.PrimaryPart = perno
	modello.Parent = genitore
	return modello
end

--------------------------------------------------------------------------------
-- ILLUMINAZIONE E PULIZIA
--------------------------------------------------------------------------------

local function preparaWorkspace()
	-- Baseplate e spawn di default spariscono: la mappa e' tutta generata.
	for _, nome in { "Baseplate", "SpawnLocation" } do
		local esistente = Workspace:FindFirstChild(nome)
		if esistente then
			esistente:Destroy()
		end
	end

	-- Se il gioco viene ricaricato (Rojo live sync) ricostruiamo da zero.
	local vecchiaMappa = Workspace:FindFirstChild(MAP_FOLDER_NAME)
	if vecchiaMappa then
		vecchiaMappa:Destroy()
	end

	Workspace.Gravity = 196.2
	-- Cadere nel vuoto chiude il personaggio in fretta e lo fa respawnare.
	Workspace.FallenPartsDestroyHeight = 150

	Lighting.ClockTime = 0
	Lighting.Brightness = 1.4
	Lighting.Ambient = Color3.fromRGB(18, 20, 35)
	Lighting.OutdoorAmbient = Color3.fromRGB(22, 26, 45)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.25
	Lighting.GlobalShadows = true

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosfera = Instance.new("Atmosphere")
		atmosfera.Density = 0.35
		atmosfera.Offset = 0
		atmosfera.Color = Color3.fromRGB(30, 40, 70)
		atmosfera.Decay = Color3.fromRGB(18, 26, 55)
		atmosfera.Glare = 0.4
		atmosfera.Haze = 1.6
		atmosfera.Parent = Lighting
	end
end

--------------------------------------------------------------------------------
-- PIATTAFORMA
--------------------------------------------------------------------------------

local function costruisciPiattaforma(mappa)
	local centro = MAP.PlatformCenter
	local dimensione = MAP.PlatformSize
	local topY = MAP.PlatformTopY
	local metaX = dimensione.X / 2
	local metaZ = dimensione.Z / 2

	-- Lastra principale scura.
	creaPart(mappa, "Piattaforma", dimensione, CFrame.new(centro), THEME.PavimentoScuro, Enum.Material.Metal, {
		reflectance = 0.08,
	})

	-- Bordo neon perimetrale.
	local spessoreBordo = 2.5
	local altezzaBordo = 0.8
	local coloreBordo = THEME.Accento
	creaPart(mappa, "BordoNord", Vector3.new(dimensione.X, altezzaBordo, spessoreBordo), CFrame.new(0, topY + 0.4, -metaZ + spessoreBordo / 2), coloreBordo, Enum.Material.Neon, { canCollide = false })
	creaPart(mappa, "BordoSud", Vector3.new(dimensione.X, altezzaBordo, spessoreBordo), CFrame.new(0, topY + 0.4, metaZ - spessoreBordo / 2), coloreBordo, Enum.Material.Neon, { canCollide = false })
	creaPart(mappa, "BordoOvest", Vector3.new(spessoreBordo, altezzaBordo, dimensione.Z), CFrame.new(-metaX + spessoreBordo / 2, topY + 0.4, 0), coloreBordo, Enum.Material.Neon, { canCollide = false })
	creaPart(mappa, "BordoEst", Vector3.new(spessoreBordo, altezzaBordo, dimensione.Z), CFrame.new(metaX - spessoreBordo / 2, topY + 0.4, 0), coloreBordo, Enum.Material.Neon, { canCollide = false })

	-- Paraurti bassi (evitano cadute accidentali, restano estetici).
	for _, lato in {
		{ "BarrieraNord", Vector3.new(dimensione.X, 3, 1), CFrame.new(0, topY + 1.5, -metaZ) },
		{ "BarrieraSud", Vector3.new(dimensione.X, 3, 1), CFrame.new(0, topY + 1.5, metaZ) },
		{ "BarrieraOvest", Vector3.new(1, 3, dimensione.Z), CFrame.new(-metaX, topY + 1.5, 0) },
		{ "BarrieraEst", Vector3.new(1, 3, dimensione.Z), CFrame.new(metaX, topY + 1.5, 0) },
	} do
		creaPart(mappa, lato[1], lato[2], lato[3], THEME.PannelloChiaro, Enum.Material.SmoothPlastic, {
			transparency = 0.55,
		})
	end

	-- Griglia luminosa sul pavimento: 11 linee per asse.
	local passo = 25
	for indice = -5, 5 do
		local linea = creaPart(
			mappa,
			"GrigliaZ",
			Vector3.new(0.5, 0.35, dimensione.Z - 6),
			CFrame.new(indice * passo, topY + 0.15, 0),
			THEME.Accento,
			Enum.Material.Neon,
			{ canCollide = false, canTouch = false, transparency = 0.62, castShadow = false }
		)
		linea.Locked = true

		local lineaX = creaPart(
			mappa,
			"GrigliaX",
			Vector3.new(dimensione.X - 6, 0.35, 0.5),
			CFrame.new(0, topY + 0.15, indice * passo),
			THEME.Accento,
			Enum.Material.Neon,
			{ canCollide = false, canTouch = false, transparency = 0.62, castShadow = false }
		)
		lineaX.Locked = true
	end
end

--------------------------------------------------------------------------------
-- NUCLEO CENTRALE
--------------------------------------------------------------------------------

local function costruisciNucleo(mappa)
	local base = MAP.CorePosition

	-- Piedistallo.
	creaCilindro(mappa, "Piedistallo", MAP.CorePedestalHeight, MAP.CoreBaseRadius * 2, base + Vector3.new(0, MAP.CorePedestalHeight / 2, 0), THEME.Pannello, Enum.Material.Metal, {
		reflectance = 0.15,
	})
	creaCilindro(mappa, "PiedistalloBordo", 0.6, MAP.CoreBaseRadius * 2.3, base + Vector3.new(0, MAP.CorePedestalHeight, 0), THEME.Accento, Enum.Material.Neon, {
		canCollide = false,
		canTouch = false,
	})

	local modelloCore = Instance.new("Model")
	modelloCore.Name = "QuantumCore"
	modelloCore.Parent = mappa

	local centroCore = base + Vector3.new(0, MAP.CorePedestalHeight + 6, 0)
	local stadioIniziale = GameConfig.CoreStages[1]

	-- Sfera centrale: il client la scala e la ricolora in base ai Watt locali.
	local sfera = creaPart(
		modelloCore,
		"CoreSphere",
		Vector3.new(stadioIniziale.raggio * 2, stadioIniziale.raggio * 2, stadioIniziale.raggio * 2),
		CFrame.new(centroCore),
		stadioIniziale.colore,
		Enum.Material.Neon,
		{ canCollide = false, canTouch = false, shape = Enum.PartType.Ball }
	)
	sfera.Locked = true

	-- Guscio trasparente per dare profondita'.
	creaPart(
		modelloCore,
		"CoreShell",
		Vector3.new(stadioIniziale.raggio * 2.8, stadioIniziale.raggio * 2.8, stadioIniziale.raggio * 2.8),
		CFrame.new(centroCore),
		stadioIniziale.colore,
		Enum.Material.ForceField,
		{ canCollide = false, canTouch = false, shape = Enum.PartType.Ball, transparency = 0.55 }
	)

	-- Anelli orbitanti (il client li mostra in base allo stadio raggiunto).
	creaAnello(modelloCore, "Ring1", centroCore, stadioIniziale.raggio * 2.1, 24, 0.55, THEME.Accento, 0, math.rad(8))
	creaAnello(modelloCore, "Ring2", centroCore, stadioIniziale.raggio * 2.6, 24, 0.5, THEME.AccentoSecondario, math.rad(70), 0)
	creaAnello(modelloCore, "Ring3", centroCore, stadioIniziale.raggio * 3.1, 28, 0.45, Color3.fromRGB(190, 120, 255), math.rad(35), math.rad(50))
	creaAnello(modelloCore, "Ring4", centroCore, stadioIniziale.raggio * 3.6, 28, 0.4, Color3.fromRGB(255, 170, 40), math.rad(115), math.rad(20))

	local luce = Instance.new("PointLight")
	luce.Name = "CoreLight"
	luce.Color = stadioIniziale.colore
	luce.Brightness = 3
	luce.Range = 60
	luce.Shadows = false
	luce.Parent = sfera
end

--------------------------------------------------------------------------------
-- MURO HI-TECH + SURFACEGUI DI SFONDO
--------------------------------------------------------------------------------

local function costruisciMuro(mappa)
	-- Il muro e' ruotato di 180 gradi cosi' la faccia "Front" guarda verso lo spawn (+Z).
	local cframeMuro = CFrame.new(MAP.WallCenter) * CFrame.Angles(0, math.pi, 0)
	local muro = creaPart(mappa, "UpgradeWall", MAP.WallSize, cframeMuro, THEME.Muro, Enum.Material.Metal, {
		reflectance = 0.12,
	})
	muro.Locked = true

	local larghezza = MAP.WallSize.X
	local altezza = MAP.WallSize.Y
	local spessoreCornice = 2
	local colore = THEME.Accento

	-- Cornice neon attorno alla faccia visibile.
	creaPart(muro, "CorniceSuperiore", Vector3.new(larghezza, spessoreCornice, spessoreCornice), muro.CFrame * CFrame.new(0, altezza / 2 - 1, -MAP.WallSize.Z / 2 - 0.4), colore, Enum.Material.Neon, { canCollide = false, canTouch = false })
	creaPart(muro, "CorniceInferiore", Vector3.new(larghezza, spessoreCornice, spessoreCornice), muro.CFrame * CFrame.new(0, -altezza / 2 + 1, -MAP.WallSize.Z / 2 - 0.4), colore, Enum.Material.Neon, { canCollide = false, canTouch = false })
	creaPart(muro, "CorniceSinistra", Vector3.new(spessoreCornice, altezza, spessoreCornice), muro.CFrame * CFrame.new(-larghezza / 2 + 1, 0, -MAP.WallSize.Z / 2 - 0.4), colore, Enum.Material.Neon, { canCollide = false, canTouch = false })
	creaPart(muro, "CorniceDestra", Vector3.new(spessoreCornice, altezza, spessoreCornice), muro.CFrame * CFrame.new(larghezza / 2 - 1, 0, -MAP.WallSize.Z / 2 - 0.4), colore, Enum.Material.Neon, { canCollide = false, canTouch = false })

	-- Pannello trasparente appena davanti al muro: ospita la SurfaceGui
	-- interattiva per-giocatore (due SurfaceGui sulla stessa faccia farebbero
	-- z-fighting), quindi la teniamo 0.3 stud piu' avanti.
	local pannelloAlbero = creaPart(
		mappa,
		"UpgradeTreePanel",
		Vector3.new(larghezza - 8, altezza - 8, 0.2),
		muro.CFrame * CFrame.new(0, 0, -MAP.WallSize.Z / 2 - 0.3),
		THEME.Muro,
		Enum.Material.SmoothPlastic,
		{ transparency = 1, canCollide = false, canTouch = false, castShadow = false }
	)
	pannelloAlbero.Locked = true

	-- SurfaceGui di sfondo (statica): titolo, griglia e cornice.
	local gui = Instance.new("SurfaceGui")
	gui.Name = "UpgradeTreeBackground"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = MAP.WallPixelsPerStud
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.AlwaysOnTop = false
	gui.Parent = muro

	local sfondo = Instance.new("Frame")
	sfondo.Name = "Sfondo"
	sfondo.Size = UDim2.fromScale(1, 1)
	sfondo.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
	sfondo.BackgroundTransparency = 0.05
	sfondo.BorderSizePixel = 0
	sfondo.Parent = gui

	-- Griglia di fondo.
	for indice = 1, 19 do
		local linea = Instance.new("Frame")
		linea.Name = "Griglia"
		linea.Size = UDim2.fromScale(0.002, 1)
		linea.Position = UDim2.fromScale(indice / 20, 0)
		linea.BackgroundColor3 = THEME.Accento
		linea.BackgroundTransparency = 0.9
		linea.BorderSizePixel = 0
		linea.Parent = sfondo
	end
	for indice = 1, 9 do
		local linea = Instance.new("Frame")
		linea.Name = "Griglia"
		linea.Size = UDim2.fromScale(1, 0.002)
		linea.Position = UDim2.fromScale(0, indice / 10)
		linea.BackgroundColor3 = THEME.Accento
		linea.BackgroundTransparency = 0.9
		linea.BorderSizePixel = 0
		linea.Parent = sfondo
	end

	local titolo = Instance.new("TextLabel")
	titolo.Name = "Titolo"
	titolo.Size = UDim2.fromScale(0.55, 0.09)
	titolo.Position = UDim2.fromScale(0.02, 0.015)
	titolo.BackgroundTransparency = 1
	titolo.Font = Enum.Font.GothamBlack
	titolo.Text = GameConfig.Testi.MuroTitolo
	titolo.TextColor3 = THEME.Accento
	titolo.TextSize = 46
	titolo.TextXAlignment = Enum.TextXAlignment.Left
	titolo.Parent = sfondo

	local sottotitolo = Instance.new("TextLabel")
	sottotitolo.Name = "Sottotitolo"
	sottotitolo.Size = UDim2.fromScale(0.7, 0.05)
	sottotitolo.Position = UDim2.fromScale(0.022, 0.095)
	sottotitolo.BackgroundTransparency = 1
	sottotitolo.Font = Enum.Font.GothamMedium
	sottotitolo.Text = GameConfig.Testi.MuroSottotitolo
	sottotitolo.TextColor3 = THEME["Testo attenuato"]
	sottotitolo.TextSize = 20
	sottotitolo.TextXAlignment = Enum.TextXAlignment.Left
	sottotitolo.Parent = sfondo

	-- Etichette delle tre sezioni.
	local sezioni = {
		{ nome = "SEZIONE 1 - WATT", x = 0.05 },
		{ nome = "SEZIONE 2 - PLASMA", x = 0.56 },
		{ nome = "SEZIONE 3 - ENDGAME", x = 0.05, y = 0.34 },
	}
	for _, sezione in sezioni do
		local etichetta = Instance.new("TextLabel")
		etichetta.Name = "Sezione"
		etichetta.Size = UDim2.fromScale(0.3, 0.035)
		etichetta.Position = UDim2.fromScale(sezione.x, sezione.y or 0.16)
		etichetta.BackgroundTransparency = 1
		etichetta.Font = Enum.Font.GothamBold
		etichetta.Text = sezione.nome
		etichetta.TextColor3 = THEME.AccentoSecondario
		etichetta.TextSize = 18
		etichetta.TextXAlignment = Enum.TextXAlignment.Left
		etichetta.Parent = sfondo
	end
end

--------------------------------------------------------------------------------
-- PULSANTI A TERRA
--------------------------------------------------------------------------------

local function costruisciPulsante(mappa, pulsante)
	local cartella = Instance.new("Folder")
	cartella.Name = "Pad_" .. pulsante.id

	local posizione = pulsante.pos
	local raggio = MAP.ButtonPadRadius
	local colore = pulsante.coloreNeon

	-- Base scura.
	creaCilindro(cartella, "Base", 1.2, raggio * 2, posizione + Vector3.new(0, 0.1, 0), THEME.Pannello, Enum.Material.Metal, {
		reflectance = 0.2,
	})

	-- Disco neon esterno (trasparente).
	creaCilindro(cartella, "Alone", 0.35, raggio * 2.2, posizione + Vector3.new(0, 0.62, 0), colore, Enum.Material.Neon, {
		transparency = 0.55,
		canCollide = false,
		canTouch = false,
	})

	-- Disco neon interno: e' quello che lampeggia all'acquisto.
	creaCilindro(cartella, "Nucleo", 0.45, raggio * 1.35, posizione + Vector3.new(0, 0.7, 0), colore, Enum.Material.Neon, {
		canCollide = false,
		canTouch = false,
	})

	-- Piccolo pilastro luminoso per individuare il pad da lontano.
	creaPart(cartella, "Faro", Vector3.new(1.2, 6, 1.2), CFrame.new(posizione + Vector3.new(0, 3.6, 0)), colore, Enum.Material.Neon, {
		transparency = 0.35,
		canCollide = false,
		canTouch = false,
	})

	local luce = Instance.new("PointLight")
	luce.Name = "LucePad"
	luce.Color = colore
	luce.Brightness = 1.6
	luce.Range = 22
	luce.Shadows = false
	luce.Parent = cartella:FindFirstChild("Nucleo")

	-- Attributi letti da GameEngine e ClientEffects (nessuna dipendenza da nomi).
	cartella:SetAttribute("ButtonId", pulsante.id)
	cartella:SetAttribute("Row", pulsante.row)
	cartella:SetAttribute("Column", pulsante.column)
	cartella.Parent = mappa
	return cartella
end

local function costruisciPulsanti(mappa)
	local cartellaPulsanti = Instance.new("Folder")
	cartellaPulsanti.Name = "Buttons"
	cartellaPulsanti.Parent = mappa

	for _, pulsante in GameConfig.Buttons do
		costruisciPulsante(cartellaPulsanti, pulsante)
	end
end

--------------------------------------------------------------------------------
-- CLASSIFICA GLOBALE (SurfaceGui lato server, dato condiviso)
--------------------------------------------------------------------------------

local function costruisciClassifica(mappa)
	-- Parte ruotata in modo che la faccia Front guardi verso il centro mappa (+X).
	local cframe = CFrame.new(MAP.LeaderboardCenter) * CFrame.Angles(0, -math.pi / 2, 0)
	local pannello = creaPart(mappa, "LeaderboardBoard", MAP.LeaderboardSize, cframe, THEME.Muro, Enum.Material.Metal, {
		reflectance = 0.15,
	})
	pannello.Locked = true

	creaPart(pannello, "BordoAlto", Vector3.new(MAP.LeaderboardSize.X, 1, MAP.LeaderboardSize.Z), pannello.CFrame * CFrame.new(0, MAP.LeaderboardSize.Y / 2 - 0.6, 0), THEME.AccentoSecondario, Enum.Material.Neon, { canCollide = false, canTouch = false })
	creaPart(pannello, "BordoBasso", Vector3.new(MAP.LeaderboardSize.X, 1, MAP.LeaderboardSize.Z), pannello.CFrame * CFrame.new(0, -MAP.LeaderboardSize.Y / 2 + 0.6, 0), THEME.AccentoSecondario, Enum.Material.Neon, { canCollide = false, canTouch = false })

	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = MAP.LeaderboardPixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = pannello

	local sfondo = Instance.new("Frame")
	sfondo.Name = "Sfondo"
	sfondo.Size = UDim2.fromScale(1, 1)
	sfondo.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
	sfondo.BackgroundTransparency = 0.1
	sfondo.BorderSizePixel = 0
	sfondo.Parent = gui

	local titolo = Instance.new("TextLabel")
	titolo.Name = "Titolo"
	titolo.Size = UDim2.fromScale(0.9, 0.12)
	titolo.Position = UDim2.fromScale(0.05, 0.03)
	titolo.BackgroundTransparency = 1
	titolo.Font = Enum.Font.GothamBlack
	titolo.Text = "CLASSIFICA GLOBALE"
	titolo.TextColor3 = THEME.AccentoSecondario
	titolo.TextSize = 30
	titolo.TextXAlignment = Enum.TextXAlignment.Left
	titolo.Parent = sfondo

	local sottotitolo = Instance.new("TextLabel")
	sottotitolo.Name = "Sottotitolo"
	sottotitolo.Size = UDim2.fromScale(0.9, 0.06)
	sottotitolo.Position = UDim2.fromScale(0.05, 0.14)
	sottotitolo.BackgroundTransparency = 1
	sottotitolo.Font = Enum.Font.GothamMedium
	sottotitolo.Text = "TOP " .. tostring(GameConfig.Meta.MaxLeaderboardEntries) .. " - " .. GameConfig.Meta.LeaderboardStatLabel
	sottotitolo.TextColor3 = THEME["Testo attenuato"]
	sottotitolo.TextSize = 18
	sottotitolo.TextXAlignment = Enum.TextXAlignment.Left
	sottotitolo.Parent = sfondo

	-- 10 righe: GameEngine le riempie per nome (Row1..Row10).
	for indice = 1, GameConfig.Meta.MaxLeaderboardEntries do
		local riga = Instance.new("TextLabel")
		riga.Name = "Row" .. indice
		riga.Size = UDim2.fromScale(0.9, 0.072)
		riga.Position = UDim2.fromScale(0.05, 0.22 + (indice - 1) * 0.075)
		riga.BackgroundTransparency = 1
		riga.Font = Enum.Font.GothamBold
		riga.Text = string.format("%d. ---", indice)
		riga.TextColor3 = indice <= 3 and THEME.Oro or THEME.Testo
		riga.TextSize = 17
		riga.TextXAlignment = Enum.TextXAlignment.Left
		riga.TextTruncate = Enum.TextTruncate.AtEnd
		riga.Parent = sfondo
	end
end

--------------------------------------------------------------------------------
-- SPAWN
--------------------------------------------------------------------------------

local function creaSpawn(mappa)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = MAP.SpawnSize
	spawn.CFrame = CFrame.new(MAP.SpawnPosition)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.CanCollide = true
	spawn.Color = THEME.Accento
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.35
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = mappa

	local etichetta = Instance.new("BillboardGui")
	etichetta.Name = "EtichettaSpawn"
	etichetta.Size = UDim2.fromOffset(220, 60)
	etichetta.StudsOffset = Vector3.new(0, 6, 0)
	etichetta.AlwaysOnTop = false
	etichetta.Parent = spawn

	local testo = Instance.new("TextLabel")
	testo.Size = UDim2.fromScale(1, 1)
	testo.BackgroundTransparency = 1
	testo.Font = Enum.Font.GothamBlack
	testo.Text = "QUANTUM CORE"
	testo.TextColor3 = THEME.Accento
	testo.TextSize = 26
	testo.TextStrokeTransparency = 0.4
	testo.Parent = etichetta
end

--------------------------------------------------------------------------------
-- AVVIO
--------------------------------------------------------------------------------

preparaWorkspace()

local mappa = Instance.new("Folder")
mappa.Name = MAP_FOLDER_NAME
mappa.Parent = Workspace

costruisciPiattaforma(mappa)
costruisciNucleo(mappa)
costruisciMuro(mappa)
costruisciPulsanti(mappa)
costruisciClassifica(mappa)
creaSpawn(mappa)

print("[Quantum Core] Mappa generata: piattaforma, nucleo, muro, 6 pulsanti, classifica.")
