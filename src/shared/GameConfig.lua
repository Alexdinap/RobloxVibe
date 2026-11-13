local GameConfig = {}

-- Catena Progressiva: i bottoni compaiono man mano che compri i precedenti!
-- ReqId = nil -> disponibile subito all'inizio
-- ReqId = "id", ReqLvl = N -> compare appena porti "id" al livello N
GameConfig.Upgrades = {
	-- FASE 1: Inizio (Solo questo bottone è visibile all'avvio!)
	{
		Id = "u_click_add", Category = "Flame", Order = 1,
		Icon = "🔥", Name = "Soffio Ardente", Tag = "+1 Click",
		BaseCost = 10, CostMult = 1.42, MaxLevel = 30, LightPct = 0.5,
		Effect = "ClickAdd", Value = 1,
		ReqId = nil, ReqLvl = 0,
	},

	-- FASE 2: Si sbloccano comprando Soffio Ardente Liv. 1
	{
		Id = "u_click_mult", Category = "Flame", Order = 2,
		Icon = "⚡", Name = "Fiamma Concentrata", Tag = "x1.65 Click",
		BaseCost = 35, CostMult = 2.30, MaxLevel = 15, LightPct = 1,
		Effect = "ClickMult", Value = 1.65,
		ReqId = "u_click_add", ReqLvl = 1,
	},
	{
		Id = "u_braziers", Category = "World", Order = 1,
		Icon = "🔥", Name = "Regno 1", Tag = "Rituale Bracieri • x2 Click",
		BaseCost = 150, CostMult = 1, MaxLevel = 1, LightPct = 12,
		Zone = "Braziers", Effect = "ClickMult", Value = 2.0,
		ReqId = "u_click_add", ReqLvl = 1,
	},

	-- FASE 3: Si sbloccano comprando Fiamma Concentrata Liv. 1
	{
		Id = "u_radius", Category = "Flame", Order = 3,
		Icon = "☀️", Name = "Espansione Luce", Tag = "+3% Luce • x1.35 Click",
		BaseCost = 75, CostMult = 2.15, MaxLevel = 8, LightPct = 3,
		Effect = "ClickMult", Value = 1.35,
		ReqId = "u_click_mult", ReqLvl = 1,
	},
	{
		Id = "u_crit", Category = "Flame", Order = 4,
		Icon = "💥", Name = "Scintilla Critica", Tag = "+7% Critico (x12)",
		BaseCost = 110, CostMult = 2.05, MaxLevel = 10, LightPct = 0.5,
		Effect = "CritChance", Value = 0.07,
		ReqId = "u_click_mult", ReqLvl = 1,
	},

	-- FASE 4: Si sbloccano comprando Espansione Luce Liv. 1
	{
		Id = "u_autoclick", Category = "Flame", Order = 5,
		Icon = "⏱️", Name = "Battito Fiamma", Tag = "+1 Click Auto/s",
		BaseCost = 180, CostMult = 2.35, MaxLevel = 10, LightPct = 0.5,
		Effect = "AutoClick", Value = 1,
		ReqId = "u_radius", ReqLvl = 1,
	},
	{
		Id = "u_heat", Category = "Flame", Order = 6,
		Icon = "🌡️", Name = "Braci Persistenti", Tag = "Calore Max +x0.7",
		BaseCost = 300, CostMult = 2.50, MaxLevel = 6, LightPct = 1,
		Effect = "HeatMax", Value = 0.7,
		ReqId = "u_radius", ReqLvl = 1,
	},

	-- FASE 5: Si sbloccano risvegliando Regno 1
	{
		Id = "u_unlock_wisps", Category = "Flame", Order = 7,
		Icon = "✨", Name = "Altare degli Spiriti", Tag = "Sblocca Scheda Spiriti",
		BaseCost = 600, CostMult = 1, MaxLevel = 1, LightPct = 2,
		Effect = "UnlockWisps", Value = 1,
		ReqId = "u_braziers", ReqLvl = 1,
	},
	{
		Id = "u_crystals", Category = "World", Order = 2,
		Icon = "💎", Name = "Foresta Cristallo", Tag = "Cristalli Est • x2.5 Click",
		BaseCost = 1200, CostMult = 1, MaxLevel = 1, LightPct = 15,
		Zone = "Crystals", Effect = "ClickMult", Value = 2.5,
		ReqId = "u_braziers", ReqLvl = 1,
	},

	-- FASE 6: Si sbloccano risvegliando la Foresta di Cristallo
	{
		Id = "u_ember_mag", Category = "Flame", Order = 8,
		Icon = "🧲", Name = "Attrazione Luce", Tag = "Attira Sfere Vaganti",
		BaseCost = 2000, CostMult = 1, MaxLevel = 1, LightPct = 2,
		Effect = "Magnet", Value = 1,
		ReqId = "u_crystals", ReqLvl = 1,
	},
	{
		Id = "u_lanterns", Category = "World", Order = 3,
		Icon = "🏮", Name = "Giardino Lanterne", Tag = "Lanterne Cielo • x3 Click",
		BaseCost = 12000, CostMult = 1, MaxLevel = 1, LightPct = 15,
		Zone = "Lanterns", Effect = "ClickMult", Value = 3.0,
		ReqId = "u_crystals", ReqLvl = 1,
	},

	-- FASE 7: Si sbloccano risvegliando il Giardino delle Lanterne
	{
		Id = "u_wisp_slot", Category = "Flame", Order = 9,
		Icon = "🔗", Name = "Legame Spiritico", Tag = "+1 Spirito Attivo",
		BaseCost = 15000, CostMult = 4.0, MaxLevel = 2, LightPct = 2,
		Effect = "ExtraWisp", Value = 1,
		ReqId = "u_lanterns", ReqLvl = 1,
	},
	{
		Id = "u_waterfall", Category = "World", Order = 4,
		Icon = "🌊", Name = "Cascata Eterea", Tag = "Cascata Ovest • x4 Click",
		BaseCost = 90000, CostMult = 1, MaxLevel = 1, LightPct = 18,
		Zone = "Waterfall", Effect = "ClickMult", Value = 4.0,
		ReqId = "u_lanterns", ReqLvl = 1,
	},

	-- FASE 8: Si sbloccano risvegliando la Cascata Eterea
	{
		Id = "u_unlock_alba", Category = "Flame", Order = 10,
		Icon = "🌅", Name = "Rito dell'Alba", Tag = "Sblocca Grande Alba",
		BaseCost = 500000, CostMult = 1, MaxLevel = 1, LightPct = 2,
		Effect = "UnlockAlba", Value = 1,
		ReqId = "u_waterfall", ReqLvl = 1,
	},
	{
		Id = "u_temple", Category = "World", Order = 5,
		Icon = "🏛️", Name = "Tempio dell'Alba", Tag = "Sole a Nord • x6 Click",
		BaseCost = 850000, CostMult = 1, MaxLevel = 1, LightPct = 22,
		Zone = "Temple", Effect = "ClickMult", Value = 6.0,
		ReqId = "u_waterfall", ReqLvl = 1,
	},

	-- FASE 9: Potenziamento Finale dopo il Tempio
	{
		Id = "u_apotheosis", Category = "Flame", Order = 11,
		Icon = "👑", Name = "Apoteosi Solare", Tag = "x10.0 Punti Click",
		BaseCost = 1e7, CostMult = 5.0, MaxLevel = 5, LightPct = 1,
		Effect = "ClickMult", Value = 10.0,
		ReqId = "u_temple", ReqLvl = 1,
	},
}

-- Configurazione Meccanica Principale di Regno 1: Il Rituale della Catena del Fuoco
GameConfig.Regno1 = {
	Name = "Regno 1",
	TrialTitle = "Catena del Fuoco",
	UnlockUpgradeId = "u_braziers",
	BaseTime = 18.0,            -- Secondi iniziali all'accensione del Braciere I
	BonusTimePerBrazier = 2.5,  -- Secondi aggiunti accendendo i Bracieri II, III, IV
	IgniteRadius = 11.5,        -- Distanza in studs per accendere automaticamente correndo
	RetryCooldown = 3.5,        -- Secondi di attesa prima di riavviare la sfida
	PermanentBlessingMult = 1.35, -- +35% produzione permanente dopo il 1° completamento
	BuffDuration = 30.0,        -- Durata buff temporaneo "Fiamma Ruggente"
	BuffMinMult = 1.50,         -- Moltiplicatore minimo al completamento
	BuffMaxMult = 2.50,         -- Moltiplicatore massimo se completi con molto tempo residuo
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
	{ Id = "alt1", Name = "Pietra Focaia", BaseCost = 25, CostMult = 1.18, Pps = 1, ClickBonus = 0.5, Color = Color3.fromRGB(255, 165, 55), Pos = Vector3.new(-16, 1.4, 14) },
	{ Id = "alt2", Name = "Lanterna Antica", BaseCost = 140, CostMult = 1.20, Pps = 6, ClickBonus = 2, Color = Color3.fromRGB(255, 215, 80), Pos = Vector3.new(16, 1.4, 14) },
	{ Id = "alt3", Name = "Braciere Runico", BaseCost = 750, CostMult = 1.22, Pps = 30, ClickBonus = 8, Color = Color3.fromRGB(255, 105, 45), Pos = Vector3.new(-21, 1.4, -3) },
	{ Id = "alt4", Name = "Faro Crepuscolo", BaseCost = 4000, CostMult = 1.24, Pps = 150, ClickBonus = 35, Color = Color3.fromRGB(95, 220, 255), Pos = Vector3.new(21, 1.4, -3) },
	{ Id = "alt5", Name = "Specchio Solare", BaseCost = 22000, CostMult = 1.26, Pps = 800, ClickBonus = 160, Color = Color3.fromRGB(255, 240, 120), Pos = Vector3.new(0, 1.4, -20) },
	{ Id = "alt6", Name = "Fucina Stellare", BaseCost = 130000, CostMult = 1.28, Pps = 4500, ClickBonus = 850, Color = Color3.fromRGB(195, 120, 255), Pos = Vector3.new(-28, 1.4, 22) },
	{ Id = "alt7", Name = "Obelisco Alba", BaseCost = 850000, CostMult = 1.30, Pps = 25000, ClickBonus = 4500, Color = Color3.fromRGB(70, 255, 180), Pos = Vector3.new(28, 1.4, 22) },
	{ Id = "alt8", Name = "Cuore del Sole", BaseCost = 6e6, CostMult = 1.32, Pps = 150000, ClickBonus = 25000, Color = Color3.fromRGB(255, 225, 95), Pos = Vector3.new(0, 1.4, -34) },
}

-- 5 Spiriti di Luce
GameConfig.BaseWispCost = 500
GameConfig.BaseEquippedWisps = 3
GameConfig.Wisps = {
	{ Id = "w_ember", Name = "Lucciola Ambra", Chance = "50%", Weight = 500, ClickMult = 1.4, Color = Color3.fromRGB(255, 190, 60) },
	{ Id = "w_azure", Name = "Spirito Celeste", Chance = "26%", Weight = 260, ClickMult = 2.0, Color = Color3.fromRGB(70, 225, 255) },
	{ Id = "w_jade", Name = "Fata di Giada", Chance = "14%", Weight = 140, ClickMult = 3.2, Color = Color3.fromRGB(80, 255, 150) },
	{ Id = "w_aurora", Name = "Spirito Aurora", Chance = "7%", Weight = 70, ClickMult = 5.5, Color = Color3.fromRGB(220, 110, 255) },
	{ Id = "w_phoenix", Name = "Fenice Primordiale", Chance = "3%", Weight = 30, ClickMult = 12.0, Color = Color3.fromRGB(255, 255, 255) },
}

-- Prestige: Grande Alba
GameConfig.PrestigeCost = 5e7 -- 50M Punti Luce
GameConfig.StarPerks = {
	{ Id = "sp_power", Name = "Fiamma Primordiale", Desc = "Tutti i Punti x5 per livello", Cost = 1, CostMult = 2, MaxLevel = 5 },
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
