local GameConfig = {}

-- GamePass Robux
GameConfig.RobuxPasses = {
	DoubleLight = {
		GamePassId = 0, -- INSERISCI QUI L'ID DEL TUO GAMEPASS ROBLOX
		Name = "Luce x2 Permanente",
		Tag = "x2 PUNTI LUCE",
		Desc = "Raddoppia per sempre tutti i Punti Luce prodotti da click, altari, spiriti e ricompense!",
		PriceLabel = "Robux",
		Multiplier = 2.0,
	},
}

-- Catena Progressiva: i bottoni compaiono man mano che compri i precedenti!
-- ReqId = nil -> disponibile subito all'inizio
-- ReqId = "id", ReqLvl = N -> compare appena porti "id" al livello N
GameConfig.Upgrades = {
	-- FASE 1: Inizio (Solo questo bottone è visibile all'avvio!)
	{
		Id = "u_click_add", Category = "Flame", Order = 1,
		Icon = "🔥", Name = "Soffio Ardente", Tag = "+0.5 Click",
		Desc = "Aumenta i punti base ottenuti ogni volta che clicchi la Fiamma.",
		BaseCost = 20, CostMult = 1.55, MaxLevel = 30, LightPct = 0.25,
		Effect = "ClickAdd", Value = 0.5,
		ReqId = nil, ReqLvl = 0,
	},

	-- FASE 2: Si sbloccano comprando Soffio Ardente Liv. 1
	{
		Id = "u_click_mult", Category = "Flame", Order = 2,
		Icon = "⚡", Name = "Fiamma Concentrata", Tag = "x1.25 Click",
		Desc = "Moltiplica tutti i Punti Luce guadagnati dai click e dagli altari.",
		BaseCost = 60, CostMult = 2.50, MaxLevel = 15, LightPct = 0.5,
		Effect = "ClickMult", Value = 1.25,
		ReqId = "u_click_add", ReqLvl = 1,
	},
	{
		Id = "u_braziers", Category = "World", Order = 1,
		Icon = "🔥", Name = "Regno 1", Tag = "Rituale • x1.5 Click",
		Desc = "Sblocca i 5 Bracieri del Santuario per la sfida a tempo e potenzia i click.",
		BaseCost = 250, CostMult = 1, MaxLevel = 1, LightPct = 6,
		Zone = "Braziers", Effect = "ClickMult", Value = 1.5,
		ReqId = "u_click_add", ReqLvl = 1,
	},

	-- FASE 3: Si sbloccano comprando Fiamma Concentrata Liv. 1
	{
		Id = "u_radius", Category = "Flame", Order = 3,
		Icon = "☀️", Name = "Espansione Luce", Tag = "+1.5% Luce • x1.15",
		Desc = "Allarga il raggio luminoso della Fiamma nell'oscurità e potenzia i click.",
		BaseCost = 120, CostMult = 2.35, MaxLevel = 8, LightPct = 1.5,
		Effect = "ClickMult", Value = 1.15,
		ReqId = "u_click_mult", ReqLvl = 1,
	},
	{
		Id = "u_crit", Category = "Flame", Order = 4,
		Icon = "💥", Name = "Scintilla Critica", Tag = "+4% Critico (x5)",
		Desc = "Aumenta la probabilità di sferrare click critici che valgono 5 volte tanto.",
		BaseCost = 175, CostMult = 2.25, MaxLevel = 10, LightPct = 0.25,
		Effect = "CritChance", Value = 0.04,
		ReqId = "u_click_mult", ReqLvl = 1,
	},

	-- FASE 4: Si sbloccano comprando Espansione Luce Liv. 1
	{
		Id = "u_autoclick", Category = "Flame", Order = 5,
		Icon = "⏱️", Name = "Battito Fiamma", Tag = "+0.5 Click Auto/s",
		Desc = "La Fiamma pulsa autonomamente generando click automatici ogni secondo.",
		BaseCost = 300, CostMult = 2.55, MaxLevel = 10, LightPct = 0.25,
		Effect = "AutoClick", Value = 0.5,
		ReqId = "u_radius", ReqLvl = 1,
	},
	{
		Id = "u_heat", Category = "Flame", Order = 6,
		Icon = "🌡️", Name = "Braci Persistenti", Tag = "Calore Max +x0.3",
		Desc = "Aumenta il bonus massimo ottenuto riempiendo la barra del Calore Fiamma.",
		BaseCost = 450, CostMult = 2.70, MaxLevel = 6, LightPct = 0.5,
		Effect = "HeatMax", Value = 0.3,
		ReqId = "u_radius", ReqLvl = 1,
	},

	-- FASE 5: Si sbloccano risvegliando Regno 1
	{
		Id = "u_unlock_wisps", Category = "Flame", Order = 7,
		Icon = "✨", Name = "Altare degli Spiriti", Tag = "Sblocca Spiriti",
		Desc = "Apre la scheda Spiriti per evocare e fondere compagni di luce.",
		BaseCost = 950, CostMult = 1, MaxLevel = 1, LightPct = 1,
		Effect = "UnlockWisps", Value = 1,
		ReqId = "u_braziers", ReqLvl = 1,
	},
	{
		Id = "u_crystals", Category = "World", Order = 2,
		Icon = "💎", Name = "Foresta Cristallo", Tag = "Est • x1.75 Click",
		Desc = "Risveglia i cristalli a Est del Santuario e moltiplica i Punti Luce.",
		BaseCost = 2000, CostMult = 1, MaxLevel = 1, LightPct = 7.5,
		Zone = "Crystals", Effect = "ClickMult", Value = 1.75,
		ReqId = "u_braziers", ReqLvl = 1,
	},

	-- FASE 6: Si sbloccano risvegliando la Foresta di Cristallo
	{
		Id = "u_ember_mag", Category = "Flame", Order = 8,
		Icon = "🧲", Name = "Attrazione Luce", Tag = "Calamita Sfere",
		Desc = "Attira automaticamente verso di te le Sfere di Luce vaganti vicine.",
		BaseCost = 3200, CostMult = 1, MaxLevel = 1, LightPct = 1,
		Effect = "Magnet", Value = 1,
		ReqId = "u_crystals", ReqLvl = 1,
	},
	{
		Id = "u_lanterns", Category = "World", Order = 3,
		Icon = "🏮", Name = "Giardino Lanterne", Tag = "Cielo • x2.0 Click",
		Desc = "Accende le lanterne sospese in cielo e raddoppia i Punti Luce.",
		BaseCost = 18000, CostMult = 1, MaxLevel = 1, LightPct = 7.5,
		Zone = "Lanterns", Effect = "ClickMult", Value = 2.0,
		ReqId = "u_crystals", ReqLvl = 1,
	},

	-- FASE 7: Si sbloccano risvegliando il Giardino delle Lanterne
	{
		Id = "u_wisp_slot", Category = "Flame", Order = 9,
		Icon = "🔗", Name = "Legame Spiritico", Tag = "+1 Spirito Attivo",
		Desc = "Aumenta il numero massimo di Spiriti di Luce attivi attorno a te.",
		BaseCost = 25000, CostMult = 4.5, MaxLevel = 2, LightPct = 1,
		Effect = "ExtraWisp", Value = 1,
		ReqId = "u_lanterns", ReqLvl = 1,
	},
	{
		Id = "u_waterfall", Category = "World", Order = 4,
		Icon = "🌊", Name = "Cascata Eterea", Tag = "Ovest • x2.5 Click",
		Desc = "Risveglia la cascata luminosa a Ovest e potenzia i guadagni (x2.5).",
		BaseCost = 135000, CostMult = 1, MaxLevel = 1, LightPct = 9,
		Zone = "Waterfall", Effect = "ClickMult", Value = 2.5,
		ReqId = "u_lanterns", ReqLvl = 1,
	},

	-- FASE 8: Si sbloccano risvegliando la Cascata Eterea
	{
		Id = "u_unlock_alba", Category = "Flame", Order = 10,
		Icon = "🌅", Name = "Rito dell'Alba", Tag = "Sblocca Prestige",
		Desc = "Sblocca la scheda Alba per rinascere in cambio di Stelle Eterne.",
		BaseCost = 750000, CostMult = 1, MaxLevel = 1, LightPct = 1,
		Effect = "UnlockAlba", Value = 1,
		ReqId = "u_waterfall", ReqLvl = 1,
	},
	{
		Id = "u_temple", Category = "World", Order = 5,
		Icon = "🏛️", Name = "Tempio dell'Alba", Tag = "Nord • x3.0 Click",
		Desc = "Risveglia l'antico Tempio a Nord e triplica tutti i Punti Luce.",
		BaseCost = 1250000, CostMult = 1, MaxLevel = 1, LightPct = 11,
		Zone = "Temple", Effect = "ClickMult", Value = 3.0,
		ReqId = "u_waterfall", ReqLvl = 1,
	},

	-- FASE 9: Potenziamento Finale dopo il Tempio
	{
		Id = "u_apotheosis", Category = "Flame", Order = 11,
		Icon = "👑", Name = "Apoteosi Solare", Tag = "x4.0 Punti Click",
		Desc = "Potenziamento supremo: quadruplica i Punti Luce per ogni livello.",
		BaseCost = 1.5e7, CostMult = 5.5, MaxLevel = 5, LightPct = 0.5,
		Effect = "ClickMult", Value = 4.0,
		ReqId = "u_temple", ReqLvl = 1,
	},
}

-- Configurazione Meccanica Principale di Regno 1: Il Rituale della Catena del Fuoco
GameConfig.Regno1 = {
	Name = "Regno 1",
	TrialTitle = "Catena del Fuoco",
	UnlockUpgradeId = "u_braziers",
	BaseTime = 18.0,              -- Secondi iniziali all'accensione del Braciere I
	BonusTimePerBrazier = 2.5,    -- Secondi aggiunti accendendo i Bracieri II, III, IV
	IgniteRadius = 11.5,          -- Distanza in studs per accendere automaticamente correndo
	RetryCooldown = 3.5,          -- Secondi di attesa prima di riavviare la sfida
	PermanentBlessingMult = 1.35, -- +35% produzione permanente dopo il 1° completamento
	BuffDuration = 30.0,          -- Durata buff temporaneo "Fiamma Ruggente"
	BuffMinMult = 1.50,           -- Moltiplicatore minimo al completamento
	BuffMaxMult = 2.50,           -- Moltiplicatore massimo se completi con molto tempo residuo
	Braziers = {
		{ Index = 1, Numeral = "I",   Pos = Vector3.new(0, 1.0, 47),     PedestalHeight = 1.4 },
		{ Index = 2, Numeral = "II",  Pos = Vector3.new(34, 1.0, 34),    PedestalHeight = 2.2 },
		{ Index = 3, Numeral = "III", Pos = Vector3.new(48, 1.0, 0),     PedestalHeight = 3.0 },
		{ Index = 4, Numeral = "IV",  Pos = Vector3.new(34, 1.0, -34),   PedestalHeight = 2.4 },
		{ Index = 5, Numeral = "V",   Pos = Vector3.new(0, 1.0, -49),    PedestalHeight = 3.8 },
	},
}

-- 8 Altari a Terra attorno alla Fiamma
GameConfig.Altars = {
	{ Id = "alt1", Name = "Pietra Focaia", BaseCost = 40, CostMult = 1.22, Pps = 1, ClickBonus = 0.1, Color = Color3.fromRGB(255, 165, 55), Pos = Vector3.new(-16, 1.4, 14) },
	{ Id = "alt2", Name = "Lanterna Antica", BaseCost = 220, CostMult = 1.24, Pps = 6, ClickBonus = 0.5, Color = Color3.fromRGB(255, 215, 80), Pos = Vector3.new(16, 1.4, 14) },
	{ Id = "alt3", Name = "Braciere Runico", BaseCost = 1150, CostMult = 1.26, Pps = 30, ClickBonus = 2, Color = Color3.fromRGB(255, 105, 45), Pos = Vector3.new(-21, 1.4, -3) },
	{ Id = "alt4", Name = "Faro Crepuscolo", BaseCost = 6000, CostMult = 1.28, Pps = 150, ClickBonus = 8, Color = Color3.fromRGB(95, 220, 255), Pos = Vector3.new(21, 1.4, -3) },
	{ Id = "alt5", Name = "Specchio Solare", BaseCost = 32000, CostMult = 1.30, Pps = 800, ClickBonus = 35, Color = Color3.fromRGB(255, 240, 120), Pos = Vector3.new(0, 1.4, -20) },
	{ Id = "alt6", Name = "Fucina Stellare", BaseCost = 190000, CostMult = 1.32, Pps = 4500, ClickBonus = 180, Color = Color3.fromRGB(195, 120, 255), Pos = Vector3.new(-28, 1.4, 22) },
	{ Id = "alt7", Name = "Obelisco Alba", BaseCost = 1200000, CostMult = 1.34, Pps = 25000, ClickBonus = 900, Color = Color3.fromRGB(70, 255, 180), Pos = Vector3.new(28, 1.4, 22) },
	{ Id = "alt8", Name = "Cuore del Sole", BaseCost = 8.5e6, CostMult = 1.36, Pps = 150000, ClickBonus = 5000, Color = Color3.fromRGB(255, 225, 95), Pos = Vector3.new(0, 1.4, -34) },
}

-- 5 Spiriti di Luce
GameConfig.BaseWispCost = 750
GameConfig.BaseEquippedWisps = 3
GameConfig.Wisps = {
	{ Id = "w_ember", Name = "Lucciola Ambra", Chance = "50%", Weight = 500, ClickMult = 1.2, Color = Color3.fromRGB(255, 190, 60) },
	{ Id = "w_azure", Name = "Spirito Celeste", Chance = "26%", Weight = 260, ClickMult = 1.5, Color = Color3.fromRGB(70, 225, 255) },
	{ Id = "w_jade", Name = "Fata di Giada", Chance = "14%", Weight = 140, ClickMult = 2.0, Color = Color3.fromRGB(80, 255, 150) },
	{ Id = "w_aurora", Name = "Spirito Aurora", Chance = "7%", Weight = 70, ClickMult = 3.0, Color = Color3.fromRGB(220, 110, 255) },
	{ Id = "w_phoenix", Name = "Fenice Primordiale", Chance = "3%", Weight = 30, ClickMult = 5.0, Color = Color3.fromRGB(255, 255, 255) },
}

-- Prestige: Grande Alba
GameConfig.PrestigeCost = 5e7 -- 50M Punti Luce
GameConfig.StarPerks = {
	{ Id = "sp_power", Name = "Fiamma Primordiale", Desc = "Tutti i Punti x3 per livello", Cost = 1, CostMult = 2, MaxLevel = 5 },
	{ Id = "sp_start", Name = "Scintilla Ereditata", Desc = "Parti con 5.000 Punti e Soffio Liv. 5", Cost = 1, CostMult = 2, MaxLevel = 3 },
	{ Id = "sp_crit", Name = "Occhio Solare", Desc = "Moltiplicatore Critici x2", Cost = 2, CostMult = 3, MaxLevel = 3 },
	{ Id = "sp_ward", Name = "Barriera di Luce", Desc = "Respinge automaticamente le Ombre", Cost = 2, CostMult = 1, MaxLevel = 1 },
}

GameConfig.Ranks = {
	{ MinLight = 0, Name = "Portatore di Scintilla", Color = Color3.fromRGB(255, 175, 80) },
	{ MinLight = 20, Name = "Custode di Regno 1", Color = Color3.fromRGB(255, 215, 70) },
	{ MinLight = 45, Name = "Tessitore di Cristallo", Color = Color3.fromRGB(70, 240, 210) },
	{ MinLight = 70, Name = "Araldo del Crepuscolo", Color = Color3.fromRGB(130, 190, 255) },
	{ MinLight = 90, Name = "Signore dell'Alba", Color = Color3.fromRGB(255, 235, 120) },
	{ MinLight = 100, Name = "Sole Vivente", Color = Color3.fromRGB(255, 255, 255) },
}

GameConfig.PromoCodes = {
	["LUCE100"] = { Points = 250, Msg = "+250 Punti Luce riscattati!" },
	["FIAMMA"] = { Points = 1500, Msg = "+1.500 Punti Luce riscattati!" },
	["ALBA2026"] = { Points = 10000, Msg = "+10.000 Punti Luce riscattati!" },
}

return GameConfig