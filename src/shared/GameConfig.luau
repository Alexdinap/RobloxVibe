--!nonstrict
--[[
	GameConfig - SOLO tabelle dati.

	Qui non c'e' una riga di logica: tutto il bilanciamento, le posizioni sulla
	mappa e i colori del tema stanno in questo modulo, cosi' il resto del codice
	(GameEngine, WorldBuilder, ClientEffects) legga soltanto.

	Convenzioni:
	- i costi sono sempre numeri (i Watt possono essere enormi, vedi BigNum)
	- "Pos" dei pulsanti e' la posizione MONDIALE del centro del pad a terra
	- "position" dei nodi e' normalizzata 0..1 sul pannello del muro (x a destra, y in basso)
]]

local GameConfig = {}

--------------------------------------------------------------------------------
-- META
--------------------------------------------------------------------------------

GameConfig.Meta = {
	GameName = "Quantum Core",
	DataStoreName = "QuantumCore_v1",
	LeaderboardStoreName = "QuantumCoreLeaderboard_v1",
	LeaderboardStatLabel = "Watt totali",
	MaxLeaderboardEntries = 10,
}

--------------------------------------------------------------------------------
-- VALUTE
--------------------------------------------------------------------------------

GameConfig.Currencies = {
	Watt = {
		id = "Watt",
		nome = "Watt",
		sigla = "W",
		colore = Color3.fromRGB(0, 245, 255),
		descrizione = "Valuta base, generata dai pulsanti a terra.",
	},
	Plasma = {
		id = "Plasma",
		nome = "Plasma",
		sigla = "PL",
		colore = Color3.fromRGB(255, 60, 230),
		descrizione = "Valuta secondaria sbloccabile, non resetta i Watt.",
	},
	MateriaOscura = {
		id = "MateriaOscura",
		nome = "Materia Oscura",
		sigla = "DM",
		colore = Color3.fromRGB(165, 90, 255),
		descrizione = "Valuta di prestigio, ottenuta col Collasso Quantistico.",
	},
}

--------------------------------------------------------------------------------
-- ECONOMIA
--------------------------------------------------------------------------------

GameConfig.Economy = {
	TickInterval = 0.1, -- loop principale del server
	SyncInterval = 0.2, -- invio stato ai client
	PurchaseCooldown = 0.15, -- livelli/s mentre si resta sopra un pulsante
	AutoBuyInterval = 1, -- gli Auto-Buyer comprano 1 livello al secondo
	SaveInterval = 60, -- autosalvataggio
	LeaderboardInterval = 60, -- refresh classifica globale

	BonusInterval = 20, -- secondi base tra una Sfera di Sovraccarico e l'altra
	BonusLifetime = 25, -- secondi in cui la sfera resta raccoglibile
	BonusDuration = 30, -- durata del boost x2
	BonusMultiplier = 2,
	BonusCollectRadius = 7,

	OfflineEfficiency = 0.25, -- quota del rate accreditata offline
	OfflineMaxSeconds = 8 * 3600, -- tetto di 8 ore

	MaxLevels = 5000, -- limite di sicurezza per i livelli dei pulsanti

	-- Watt regalati a un profilo nuovo: senza questi il primo pulsante
	-- (che costa 10) sarebbe impossibile da comprare con 0 produzione.
	StartingWatt = 25,
}

--------------------------------------------------------------------------------
-- PRESTIGE
--------------------------------------------------------------------------------

GameConfig.Prestige = {
	NodeId = "CollassoQuantistico",
	RequiredWatt = 1e15,
	GainExponent = 0.5, -- materia oscura = floor((watt / soglia) ^ 0.5)
	MultiplierPerDarkMatter = 2, -- moltiplicatore globale = 2 ^ materia oscura
	MaxMultiplier = 1e300, -- tetto per non arrivare a inf
}

--------------------------------------------------------------------------------
-- MAPPA (coordinate mondiali)
--------------------------------------------------------------------------------

GameConfig.Map = {
	PlatformCenter = Vector3.new(0, 300, 0),
	PlatformSize = Vector3.new(300, 10, 300),
	PlatformTopY = 305,

	SpawnPosition = Vector3.new(0, 306, 120),
	SpawnSize = Vector3.new(26, 1, 26),

	CorePosition = Vector3.new(0, 305, 45),
	CorePedestalHeight = 6,
	CoreBaseRadius = 4,

	WallCenter = Vector3.new(0, 365, -140),
	WallSize = Vector3.new(240, 120, 10),
	WallPixelsPerStud = 8, -- risoluzione della SurfaceGui: 1920x960

	LeaderboardCenter = Vector3.new(-140, 340, 20),
	LeaderboardSize = Vector3.new(4, 60, 90),
	LeaderboardPixelsPerStud = 6,

	ButtonPadRadius = 9, -- raggio visivo del pad
	ButtonDetectRadius = 12, -- raggio di attivazione lato server
	ButtonPadY = 305.4,

	-- Area in cui possono apparire le Sfere di Sovraccarico.
	BonusAreaMin = Vector3.new(-120, 0, -105),
	BonusAreaMax = Vector3.new(120, 0, 100),
	BonusHeight = 3.5,
}

--------------------------------------------------------------------------------
-- PULSANTI A TERRA (2 file ordinate da 3)
--------------------------------------------------------------------------------

GameConfig.Buttons = {
	{
		id = "GeneratoreBase",
		nome = "Generatore Base",
		descrizione = "+1 Watt/s per livello",
		baseCost = 10,
		costMultiplier = 1.15,
		effectType = "WattPerSecond",
		value = 1,
		coloreNeon = Color3.fromRGB(0, 245, 255),
		row = 1,
		column = 1,
		pos = Vector3.new(-70, 305.4, -15),
	},
	{
		id = "Amplificatore",
		nome = "Amplificatore",
		descrizione = "+5 Watt/s per livello",
		baseCost = 140,
		costMultiplier = 1.17,
		effectType = "WattPerSecond",
		value = 5,
		coloreNeon = Color3.fromRGB(110, 255, 120),
		row = 1,
		column = 2,
		pos = Vector3.new(0, 305.4, -15),
	},
	{
		id = "Condensatore",
		nome = "Condensatore",
		descrizione = "x1.25 Watt totali per livello",
		baseCost = 900,
		costMultiplier = 1.22,
		effectType = "WattMultiplier",
		value = 1.25,
		coloreNeon = Color3.fromRGB(255, 200, 60),
		row = 1,
		column = 3,
		pos = Vector3.new(70, 305.4, -15),
	},
	{
		id = "TurbinaQuantica",
		nome = "Turbina Quantica",
		descrizione = "+50 Watt/s per livello",
		baseCost = 7500,
		costMultiplier = 1.2,
		effectType = "WattPerSecond",
		value = 50,
		coloreNeon = Color3.fromRGB(255, 80, 210),
		row = 2,
		column = 1,
		pos = Vector3.new(-70, 305.4, -60),
	},
	{
		id = "Sovralimentatore",
		nome = "Sovralimentatore",
		descrizione = "x1.5 Watt totali per livello",
		baseCost = 60000,
		costMultiplier = 1.25,
		effectType = "WattMultiplier",
		value = 1.5,
		coloreNeon = Color3.fromRGB(255, 120, 60),
		row = 2,
		column = 2,
		pos = Vector3.new(0, 305.4, -60),
	},
	{
		id = "Sintetizzatore",
		nome = "Sintetizzatore",
		descrizione = "+500 Watt/s per livello",
		baseCost = 500000,
		costMultiplier = 1.23,
		effectType = "WattPerSecond",
		value = 500,
		coloreNeon = Color3.fromRGB(190, 120, 255),
		row = 2,
		column = 3,
		pos = Vector3.new(70, 305.4, -60),
	},
}

--------------------------------------------------------------------------------
-- ALBERO DEI POTENZIAMENTI SUL MURO (15 nodi)
-- kind supportati:
--   GeneratorPower   moltiplica la produzione Watt/s dei pulsanti
--   CostReduction    moltiplica (riduce) il costo dei pulsanti
--   GlobalWatt       moltiplica il Watt/s finale
--   BonusFrequency   moltiplica la frequenza delle Sfere di Sovraccarico
--   PlasmaRate       aggiunge Plasma/s
--   PlasmaMultiplier moltiplica il Plasma/s
--   AutoBuyLevels    quanti pulsanti vengono comprati automaticamente
--   Prestige         nodo azione: esegue il Collasso Quantistico
--------------------------------------------------------------------------------

GameConfig.Nodes = {
	{
		id = "BobinaSovraccarico",
		nome = "Bobina di Sovraccarico",
		descrizione = "+25% potenza dei generatori",
		currency = "Watt",
		cost = 60,
		requires = {},
		branch = "Watt",
		position = Vector2.new(0.10, 0.80),
		effects = { { kind = "GeneratorPower", value = 1.25 } },
	},
	{
		id = "CircuitoRefrigerante",
		nome = "Circuito Refrigerante",
		descrizione = "-10% costo dei pulsanti",
		currency = "Watt",
		cost = 400,
		requires = { "BobinaSovraccarico" },
		branch = "Watt",
		position = Vector2.new(0.10, 0.58),
		effects = { { kind = "CostReduction", value = 0.90 } },
	},
	{
		id = "RisonanzaArmonica",
		nome = "Risonanza Armonica",
		descrizione = "+25% potenza dei generatori",
		currency = "Watt",
		cost = 2500,
		requires = { "BobinaSovraccarico" },
		branch = "Watt",
		position = Vector2.new(0.27, 0.86),
		effects = { { kind = "GeneratorPower", value = 1.25 } },
	},
	{
		id = "ComponentiRiciclati",
		nome = "Componenti Riciclati",
		descrizione = "-15% costo dei pulsanti",
		currency = "Watt",
		cost = 1.5e4,
		requires = { "CircuitoRefrigerante" },
		branch = "Watt",
		position = Vector2.new(0.27, 0.62),
		effects = { { kind = "CostReduction", value = 0.85 } },
	},
	{
		id = "RilevatoreAnomalie",
		nome = "Rilevatore di Anomalie",
		descrizione = "+30% frequenza Sfere di Sovraccarico",
		currency = "Watt",
		cost = 8e4,
		requires = { "RisonanzaArmonica" },
		branch = "Watt",
		position = Vector2.new(0.45, 0.88),
		effects = { { kind = "BonusFrequency", value = 1.30 } },
	},
	{
		id = "Overclock",
		nome = "Overclock",
		descrizione = "+50% potenza dei generatori",
		currency = "Watt",
		cost = 4e5,
		requires = { "RisonanzaArmonica" },
		branch = "Watt",
		position = Vector2.new(0.45, 0.72),
		effects = { { kind = "GeneratorPower", value = 1.50 } },
	},
	{
		id = "ChipContrattazione",
		nome = "Chip di Contrattazione",
		descrizione = "-25% costo dei pulsanti",
		currency = "Watt",
		cost = 2e6,
		requires = { "ComponentiRiciclati" },
		branch = "Watt",
		position = Vector2.new(0.45, 0.52),
		effects = { { kind = "CostReduction", value = 0.75 } },
	},
	{
		id = "IniettoreAlPlasma",
		nome = "Iniettore al Plasma",
		descrizione = "Sblocca +1 Plasma/s (i Watt restano)",
		currency = "Watt",
		cost = 1.2e7,
		requires = { "Overclock", "ChipContrattazione" },
		branch = "Plasma",
		position = Vector2.new(0.61, 0.60),
		effects = { { kind = "PlasmaRate", value = 1 } },
	},
	{
		id = "CondottoPlasma",
		nome = "Condotto di Plasma",
		descrizione = "+1.5 Plasma/s",
		currency = "Plasma",
		cost = 40,
		requires = { "IniettoreAlPlasma" },
		branch = "Plasma",
		position = Vector2.new(0.74, 0.84),
		effects = { { kind = "PlasmaRate", value = 1.5 } },
	},
	{
		id = "AutoBuyerBase",
		nome = "Auto-Buyer Base",
		descrizione = "Compra da solo i primi 3 pulsanti, senza Watt",
		currency = "Plasma",
		cost = 150,
		requires = { "IniettoreAlPlasma" },
		branch = "Plasma",
		position = Vector2.new(0.74, 0.46),
		effects = { { kind = "AutoBuyLevels", value = 3 } },
	},
	{
		id = "LentePlasma",
		nome = "Lente al Plasma",
		descrizione = "x2 Watt totali",
		currency = "Plasma",
		cost = 900,
		requires = { "CondottoPlasma" },
		branch = "Plasma",
		position = Vector2.new(0.90, 0.86),
		effects = { { kind = "GlobalWatt", value = 2 } },
	},
	{
		id = "AutoBuyerAvanzato",
		nome = "Auto-Buyer Avanzato",
		descrizione = "Compra da solo tutti e 6 i pulsanti",
		currency = "Plasma",
		cost = 4000,
		requires = { "AutoBuyerBase", "LentePlasma" },
		branch = "Plasma",
		position = Vector2.new(0.89, 0.68),
		effects = { { kind = "AutoBuyLevels", value = 6 } },
	},
	{
		id = "SpecchioQuantistico",
		nome = "Specchio Quantistico",
		descrizione = "x5 Watt totali",
		currency = "Plasma",
		cost = 3e5,
		requires = { "AutoBuyerAvanzato" },
		branch = "Plasma",
		position = Vector2.new(0.90, 0.42),
		effects = { { kind = "GlobalWatt", value = 5 } },
	},
	{
		id = "Singolarita",
		nome = "Singolarita",
		descrizione = "x10 Watt e x2 Plasma",
		currency = "Plasma",
		cost = 2e7,
		requires = { "SpecchioQuantistico" },
		branch = "Plasma",
		position = Vector2.new(0.74, 0.26),
		effects = {
			{ kind = "GlobalWatt", value = 10 },
			{ kind = "PlasmaMultiplier", value = 2 },
		},
	},
	{
		id = "CollassoQuantistico",
		nome = "Collasso Quantistico",
		descrizione = "Prestige: resetta Watt e Plasma in Materia Oscura permanente",
		currency = "Watt",
		cost = 1e15,
		requires = { "Singolarita" },
		branch = "Prestige",
		isPrestige = true,
		position = Vector2.new(0.36, 0.20),
		effects = { { kind = "Prestige", value = 1 } },
	},
}

--------------------------------------------------------------------------------
-- 5 STADI EVOLUTIVI DEL NUCLEO (in base ai Watt del giocatore)
--------------------------------------------------------------------------------

GameConfig.CoreStages = {
	{
		soglia = 0,
		raggio = 3.5,
		colore = Color3.fromRGB(0, 245, 255),
		velocitaRotazione = 0.6,
		anelli = 1,
		scalaAnelli = 1.0,
	},
	{
		soglia = 1e3,
		raggio = 4.4,
		colore = Color3.fromRGB(0, 200, 255),
		velocitaRotazione = 0.9,
		anelli = 2,
		scalaAnelli = 1.1,
	},
	{
		soglia = 1e6,
		raggio = 5.4,
		colore = Color3.fromRGB(120, 90, 255),
		velocitaRotazione = 1.35,
		anelli = 2,
		scalaAnelli = 1.25,
	},
	{
		soglia = 1e9,
		raggio = 6.6,
		colore = Color3.fromRGB(255, 60, 230),
		velocitaRotazione = 1.9,
		anelli = 3,
		scalaAnelli = 1.45,
	},
	{
		soglia = 1e12,
		raggio = 7.8,
		colore = Color3.fromRGB(255, 170, 40),
		velocitaRotazione = 2.6,
		anelli = 4,
		scalaAnelli = 1.65,
	},
}

--------------------------------------------------------------------------------
-- TEMA / COLORI / TESTI
--------------------------------------------------------------------------------

GameConfig.Theme = {
	Sfondo = Color3.fromRGB(8, 10, 18),
	Pannello = Color3.fromRGB(14, 18, 30),
	PannelloChiaro = Color3.fromRGB(24, 30, 48),
	Bordo = Color3.fromRGB(55, 70, 105),
	Testo = Color3.fromRGB(235, 240, 255),
	["Testo attenuato"] = Color3.fromRGB(140, 155, 185),
	Accento = Color3.fromRGB(0, 245, 255),
	AccentoSecondario = Color3.fromRGB(255, 60, 230),
	MateriaOscura = Color3.fromRGB(165, 90, 255),
	Successo = Color3.fromRGB(80, 255, 170),
	Pericolo = Color3.fromRGB(255, 90, 120),
	PavimentoScuro = Color3.fromRGB(14, 16, 24),
	PavimentoChiaro = Color3.fromRGB(22, 26, 38),
	Muro = Color3.fromRGB(10, 12, 20),
	Oro = Color3.fromRGB(255, 200, 60),
}

GameConfig.Testi = {
	HudWatt = "WATT",
	HudRate = "al secondo",
	HudPlasma = "PLASMA",
	HudMateriaOscura = "MATERIA OSCURA",
	HudBoost = "SOVRACCARICO x2",
	Suggerimento = "Cammina sui pulsanti per comprare livelli - clicca i nodi sul muro",
	OfflineTitolo = "BENTORNATO, OPERATORE",
	OfflineTesto = "Il nucleo ha continuato a produrre mentre eri via:",
	OfflineBottone = "RISCUOTI",
	PrestigeTitolo = "COLLASSO QUANTISTICO",
	PrestigePronto = "PRONTO AL COLLASSO",
	PrestigeBloccato = "Richiede 1e15 Watt",
	MuroTitolo = "UPGRADE TREE",
	MuroSottotitolo = "POTENZIA IL NUCLEO - NESSUNA PERDITA DI PROGRESSO",
	NodoBloccato = "BLOCCATO",
	NodoAttivo = "ATTIVO",
	NodoAcquistabile = "ACQUISTA",
}

return GameConfig
