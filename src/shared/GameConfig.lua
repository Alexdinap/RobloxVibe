local GameConfig = {}

-- Configurazione Multiplayer: 10 Zone Indipendenti
GameConfig.MaxPlots = 10
GameConfig.PlotRingRadius = 430

-- GamePass Robux
GameConfig.RobuxPasses = {
	DoubleLight = {
		GamePassId = 0, -- INSERISCI QUI L'ID DEL TUO GAMEPASS ROBLOX
		Name = "Luce x2 Permanente",
		Tag = "x2 PUNTI LUCE",
		Desc = "Raddoppia per sempre tutti i Punti Luce prodotti da personaggio, braciere e spiriti!",
		PriceLabel = "Robux",
		Multiplier = 2.0,
	},
}

-- Pulsante della Vittoria (Compare SOLO dopo aver completato tutti i potenziamenti)
GameConfig.VictoryButton = {
	Name = "PULSANTE DELLA VITTORIA",
	Cost = 5e8, -- 500M Punti Luce
	Pos = Vector3.new(0, 0.6, 26),
}

-- =========================================================================
-- POTENZIAMENTI DEL PERSONAGGIO (Solo azioni e abilità del Giocatore)
-- =========================================================================
GameConfig.Upgrades = {
	{
		Id = "u_click_add", Category = "Character", Order = 1,
		Icon = "🔥", Name = "Mano Ardente", Tag = "+1 Click Manuale",
		Desc = "Aumenta la forza base del tuo personaggio quando colpisce il Braciere.",
		BaseCost = 15, CostMult = 1.48, MaxLevel = 25, LightPct = 0.5,
		Effect = "ClickAdd", Value = 1.0,
		ReqId = nil, ReqLvl = 0,
	},
	{
		Id = "u_speed", Category = "Character", Order = 2,
		Icon = "👟", Name = "Passo del Vento", Tag = "+1.5 Velocità Corsa",
		Desc = "Aumenta la velocità di corsa del personaggio sull'isola.",
		BaseCost = 35, CostMult = 1.62, MaxLevel = 12, LightPct = 0.6,
		Effect = "WalkSpeed", Value = 1.5,
		ReqId = "u_click_add", ReqLvl = 1,
	},
	{
		Id = "u_crit", Category = "Character", Order = 3,
		Icon = "💥", Name = "Riflessi Fulminei", Tag = "+4% Prob. Critico",
		Desc = "Aumenta la probabilità del personaggio di sferrare colpi critici.",
		BaseCost = 120, CostMult = 1.95, MaxLevel = 10, LightPct = 0.7,
		Effect = "CritChance", Value = 0.04,
		ReqId = "u_speed", ReqLvl = 1,
	},
	{
		Id = "u_crit_dmg", Category = "Character", Order = 4,
		Icon = "⚔️", Name = "Colpo Solare", Tag = "+1.5x Danno Critico",
		Desc = "Aumenta il moltiplicatore dei colpi critici sferrati dal personaggio.",
		BaseCost = 320, CostMult = 2.25, MaxLevel = 8, LightPct = 0.8,
		Effect = "CritMult", Value = 1.5,
		ReqId = "u_crit", ReqLvl = 1,
	},
	{
		Id = "u_braziers", Category = "Character", Order = 5,
		Icon = "🏃", Name = "Sigillo Regno 1", Tag = "Sblocca Prova Corsa",
		Desc = "Abilita il personaggio alla corsa a tempo tra i 5 Bracieri Rituali.",
		BaseCost = 500, CostMult = 1, MaxLevel = 1, LightPct = 6,
		Zone = "Braziers", Effect = "UnlockRegno1", Value = 1,
		ReqId = "u_speed", ReqLvl = 1,
	},
	{
		Id = "u_autoclick", Category = "Character", Order = 6,
		Icon = "⏱️", Name = "Aura Pulsante", Tag = "+1 Click Auto/s",
		Desc = "Il personaggio canalizza energia generando click automatici ogni secondo.",
		BaseCost = 950, CostMult = 2.15, MaxLevel = 10, LightPct = 0.8,
		Effect = "AutoClick", Value = 1.0,
		ReqId = "u_crit_dmg", ReqLvl = 1,
	},
	{
		Id = "u_unlock_wisps", Category = "Character", Order = 7,
		Icon = "✨", Name = "Evocazione Spiriti", Tag = "Sblocca Spiriti",
		Desc = "Permette al personaggio di evocare e fondere Spiriti compagni.",
		BaseCost = 1800, CostMult = 1, MaxLevel = 1, LightPct = 4,
		Effect = "UnlockWisps", Value = 1,
		ReqId = "u_braziers", ReqLvl = 1,
	},
	{
		Id = "u_ember_mag", Category = "Character", Order = 8,
		Icon = "🧲", Name = "Calamita Eterea", Tag = "Attira Sfere",
		Desc = "Il personaggio attira automaticamente le Sfere di Luce vaganti vicine.",
		BaseCost = 5500, CostMult = 1, MaxLevel = 1, LightPct = 3,
		Effect = "Magnet", Value = 1,
		ReqId = "u_unlock_wisps", ReqLvl = 1,
	},
	{
		Id = "u_wisp_slot", Category = "Character", Order = 9,
		Icon = "🔗", Name = "Legame Spiritico", Tag = "+1 Spirito Attivo",
		Desc = "Aumenta il numero massimo di Spiriti che seguono il personaggio (fino a 6).",
		BaseCost = 22000, CostMult = 4.2, MaxLevel = 3, LightPct = 2.5,
		Effect = "ExtraWisp", Value = 1,
		ReqId = "u_unlock_wisps", ReqLvl = 1,
	},
	{
		Id = "u_char_mastery", Category = "Character", Order = 10,
		Icon = "⚡", Name = "Maestria del Custode", Tag = "x1.8 Potere Click",
		Desc = "Moltiplica x1.8 tutta la Luce generata dai click del personaggio.",
		BaseCost = 90000, CostMult = 3.1, MaxLevel = 6, LightPct = 2.5,
		Effect = "ClickPowerMult", Value = 1.8,
		ReqId = "u_ember_mag", ReqLvl = 1,
	},
	{
		Id = "u_unlock_alba", Category = "Character", Order = 11,
		Icon = "🌅", Name = "Rito dell'Alba", Tag = "Sblocca Rinascita",
		Desc = "Sblocca la scheda Alba per rinascere in cambio di Stelle Eterne.",
		BaseCost = 450000, CostMult = 1, MaxLevel = 1, LightPct = 4,
		Effect = "UnlockAlba", Value = 1,
		ReqId = "u_char_mastery", ReqLvl = 1,
	},
	{
		Id = "u_apotheosis", Category = "Character", Order = 12,
		Icon = "👑", Name = "Ascensione del Custode", Tag = "x2.5 Potere Click",
		Desc = "Potenziamento supremo del personaggio: moltiplica x2.5 i tuoi click.",
		BaseCost = 4.5e6, CostMult = 4.5, MaxLevel = 4, LightPct = 3.5,
		Effect = "ClickPowerMult", Value = 2.5,
		ReqId = "u_unlock_alba", ReqLvl = 1,
	},
}

-- Configurazione Meccanica Principale di Regno 1
GameConfig.Regno1 = {
	Name = "Regno 1",
	TrialTitle = "Catena del Fuoco",
	UnlockUpgradeId = "u_braziers",
	BaseTime = 18.0,
	BonusTimePerBrazier = 2.5,
	IgniteRadius = 11.5,
	RetryCooldown = 3.5,
	PermanentBlessingMult = 1.35,
	BuffDuration = 30.0,
	BuffMinMult = 1.50,
	BuffMaxMult = 2.50,
	Braziers = {
		{ Index = 1, Numeral = "I",   Pos = Vector3.new(0, 1.0, 47),     PedestalHeight = 1.4 },
		{ Index = 2, Numeral = "II",  Pos = Vector3.new(34, 1.0, 34),    PedestalHeight = 2.2 },
		{ Index = 3, Numeral = "III", Pos = Vector3.new(48, 1.0, 0),     PedestalHeight = 3.0 },
		{ Index = 4, Numeral = "IV",  Pos = Vector3.new(34, 1.0, -34),   PedestalHeight = 2.4 },
		{ Index = 5, Numeral = "V",   Pos = Vector3.new(0, 1.0, -49),    PedestalHeight = 3.8 },
	},
}

-- =========================================================================
-- PULSANTI A TERRA: POTENZIAMENTI DEL BRACIERE (Solo produzione, raggio, calore e colori)
-- =========================================================================
GameConfig.Altars = {
	{
		Id = "alt1", Name = "Potenza Braciere",
		BaseCost = 25, CostMult = 1.35, MaxLevel = 25,
		Pps = 3,
		Color = Color3.fromRGB(255, 165, 55), Pos = Vector3.new(-16, 0.7, 14),
	},
	{
		Id = "alt2", Name = "Moltiplicatore Fiamma",
		BaseCost = 180, CostMult = 1.45, MaxLevel = 20,
		Pps = 12, BrazierMult = 1.12,
		Color = Color3.fromRGB(255, 215, 80), Pos = Vector3.new(16, 0.7, 14),
	},
	{
		Id = "alt3", Name = "Grandezza Braciere",
		BaseCost = 850, CostMult = 1.55, MaxLevel = 15,
		Pps = 45, RadiusBonus = 1,
		Color = Color3.fromRGB(255, 115, 45), Pos = Vector3.new(-21, 0.7, -3),
	},
	{
		Id = "alt4", Name = "Fiamma Azzurra",
		BaseCost = 25000, CostMult = 1, MaxLevel = 1, IsColorButton = true, ColorTier = 1,
		BenefitTag = "x2.0 Braciere & +500/s",
		Pps = 500, BrazierMult = 2.0,
		BrazierColor = Color3.fromRGB(70, 210, 255),
		Color = Color3.fromRGB(70, 210, 255), Pos = Vector3.new(21, 0.7, -3),
	},
	{
		Id = "alt5", Name = "Nucleo Incandescente",
		BaseCost = 14000, CostMult = 1.52, MaxLevel = 15,
		Pps = 850, HeatBonus = 0.08,
		Color = Color3.fromRGB(255, 240, 120), Pos = Vector3.new(0, 0.7, -20),
	},
	{
		Id = "alt6", Name = "Fiamma Viola",
		BaseCost = 750000, CostMult = 1, MaxLevel = 1, IsColorButton = true, ColorTier = 2,
		BenefitTag = "x3.0 Braciere & +18K/s",
		Pps = 18000, BrazierMult = 3.0,
		BrazierColor = Color3.fromRGB(205, 95, 255),
		Color = Color3.fromRGB(205, 95, 255), Pos = Vector3.new(-28, 0.7, 22),
	},
	{
		Id = "alt7", Name = "Corona del Braciere",
		BaseCost = 420000, CostMult = 1.58, MaxLevel = 15,
		Pps = 28000, RadiusBonus = 1,
		Color = Color3.fromRGB(70, 255, 180), Pos = Vector3.new(28, 0.7, 22),
	},
	{
		Id = "alt8", Name = "Sole Divino",
		BaseCost = 2.5e7, CostMult = 1, MaxLevel = 1, IsColorButton = true, ColorTier = 3,
		BenefitTag = "x5.0 Braciere & +450K/s",
		Pps = 450000, BrazierMult = 5.0,
		BrazierColor = Color3.fromRGB(255, 250, 185),
		Color = Color3.fromRGB(255, 235, 120), Pos = Vector3.new(0, 0.7, -34),
	},
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
GameConfig.PrestigeCost = 5e7
GameConfig.StarPerks = {
	{ Id = "sp_power", Name = "Fiamma Primordiale", Desc = "Tutti i Punti x3 per livello", Cost = 1, CostMult = 2, MaxLevel = 5 },
	{ Id = "sp_start", Name = "Scintilla Ereditata", Desc = "Parti con 5.000 Punti e Mano Ardente Lv. 5", Cost = 1, CostMult = 2, MaxLevel = 3 },
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