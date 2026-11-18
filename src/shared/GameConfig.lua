local GameConfig = {}

-- Multiplayer Configuration: 10 Independent Plots
GameConfig.MaxPlots = 10
GameConfig.PlotRingRadius = 430

-- Robux GamePass
GameConfig.RobuxPasses = {
	DoubleLight = {
		GamePassId = 0, -- INSERT YOUR ROBLOX GAMEPASS ID HERE
		Name = "Permanent x2 Light",
		Name_it = "Luce x2 Permanente",
		Multiplier = 2.0,
	},
}

-- Final Dawn Button (Appears ONLY after maxing all Character & Brazier upgrades)
GameConfig.VictoryButton = {
	Name = "FINAL DAWN BUTTON",
	Name_it = "BOTTONE DELL'ALBA FINALE",
	Cost = 5e8, -- 500M Light Points
	BaseAlbaReward = 1,
	Pos = Vector3.new(0, 0.6, 26),
}

-- =========================================================================
-- CHARACTER UPGRADES (Player actions & abilities only)
-- =========================================================================
GameConfig.Upgrades = {
	{
		Id = "u_click_add", Category = "Character", Order = 1,
		Icon = "🔥",
		Name = "Kindling Touch", Name_it = "Mano Ardente",
		Tag = "+1 Manual Click", Tag_it = "+1 Click Manuale",
		Desc = "Increases your character's base power when striking the Brazier.",
		Desc_it = "Aumenta la forza base del personaggio quando colpisce il Braciere.",
		BaseCost = 15, CostMult = 1.48, MaxLevel = 25, LightPct = 0.5,
		Effect = "ClickAdd", Value = 1.0,
		ReqId = nil, ReqLvl = 0,
	},
	{
		Id = "u_speed", Category = "Character", Order = 2,
		Icon = "👟",
		Name = "Wind Step", Name_it = "Passo del Vento",
		Tag = "+1.5 Walk Speed", Tag_it = "+1.5 Velocità Corsa",
		Desc = "Increases your character's movement speed across the island.",
		Desc_it = "Aumenta la velocità di corsa del personaggio sull'isola.",
		BaseCost = 35, CostMult = 1.62, MaxLevel = 12, LightPct = 0.6,
		Effect = "WalkSpeed", Value = 1.5,
		ReqId = "u_click_add", ReqLvl = 1,
	},
	{
		Id = "u_crit", Category = "Character", Order = 3,
		Icon = "💥",
		Name = "Swift Reflexes", Name_it = "Riflessi Fulminei",
		Tag = "+4% Crit Chance", Tag_it = "+4% Prob. Critico",
		Desc = "Increases your chance to land critical hits on the Brazier.",
		Desc_it = "Aumenta la probabilità di sferrare colpi critici.",
		BaseCost = 120, CostMult = 1.95, MaxLevel = 10, LightPct = 0.7,
		Effect = "CritChance", Value = 0.04,
		ReqId = "u_speed", ReqLvl = 1,
	},
	{
		Id = "u_crit_dmg", Category = "Character", Order = 4,
		Icon = "⚔️",
		Name = "Solar Strike", Name_it = "Colpo Solare",
		Tag = "+1.5x Crit Power", Tag_it = "+1.5x Danno Critico",
		Desc = "Increases the multiplier of critical hits landed by your character.",
		Desc_it = "Aumenta il moltiplicatore dei colpi critici sferrati.",
		BaseCost = 320, CostMult = 2.25, MaxLevel = 8, LightPct = 0.8,
		Effect = "CritMult", Value = 1.5,
		ReqId = "u_crit", ReqLvl = 1,
	},
	{
		Id = "u_braziers", Category = "Character", Order = 5,
		Icon = "🏃",
		Name = "Realm 1 Seal", Name_it = "Sigillo Regno 1",
		Tag = "Unlock Speed Trial", Tag_it = "Sblocca Prova Corsa",
		Desc = "Unlocks the timed sprint challenge across the 5 Ritual Braziers.",
		Desc_it = "Abilita la corsa a tempo tra i 5 Bracieri Rituali.",
		BaseCost = 500, CostMult = 1, MaxLevel = 1, LightPct = 6,
		Zone = "Braziers", Effect = "UnlockRegno1", Value = 1,
		ReqId = "u_speed", ReqLvl = 1,
	},
	{
		Id = "u_autoclick", Category = "Character", Order = 6,
		Icon = "⏱️",
		Name = "Pulsing Aura", Name_it = "Aura Pulsante",
		Tag = "+1 Auto-Click/s", Tag_it = "+1 Click Auto/s",
		Desc = "Your character channels energy, generating automatic clicks per second.",
		Desc_it = "Il personaggio canalizza energia generando click automatici al secondo.",
		BaseCost = 950, CostMult = 2.15, MaxLevel = 10, LightPct = 0.8,
		Effect = "AutoClick", Value = 1.0,
		ReqId = "u_crit_dmg", ReqLvl = 1,
	},
	{
		Id = "u_unlock_wisps", Category = "Character", Order = 7,
		Icon = "✨",
		Name = "Spirit Summoning", Name_it = "Evocazione Spiriti",
		Tag = "Unlock Wisps", Tag_it = "Sblocca Spiriti",
		Desc = "Allows your character to summon and forge companion Light Wisps.",
		Desc_it = "Permette di evocare e fondere Spiriti compagni.",
		BaseCost = 1800, CostMult = 1, MaxLevel = 1, LightPct = 4,
		Effect = "UnlockWisps", Value = 1,
		ReqId = "u_braziers", ReqLvl = 1,
	},
	{
		Id = "u_ember_mag", Category = "Character", Order = 8,
		Icon = "🧲",
		Name = "Ethereal Magnet", Name_it = "Calamita Eterea",
		Tag = "Pull Light Orbs", Tag_it = "Attira Sfere",
		Desc = "Automatically pulls nearby wandering Light Orbs toward your character.",
		Desc_it = "Attira automaticamente le Sfere di Luce vaganti vicine.",
		BaseCost = 5500, CostMult = 1, MaxLevel = 1, LightPct = 3,
		Effect = "Magnet", Value = 1,
		ReqId = "u_unlock_wisps", ReqLvl = 1,
	},
	{
		Id = "u_wisp_slot", Category = "Character", Order = 9,
		Icon = "🔗",
		Name = "Spirit Bond", Name_it = "Legame Spiritico",
		Tag = "+1 Active Wisp", Tag_it = "+1 Spirito Attivo",
		Desc = "Increases max orbiting Wisps following your character (up to 6).",
		Desc_it = "Aumenta il numero massimo di Spiriti attivi (fino a 6).",
		BaseCost = 22000, CostMult = 4.2, MaxLevel = 3, LightPct = 2.5,
		Effect = "ExtraWisp", Value = 1,
		ReqId = "u_unlock_wisps", ReqLvl = 1,
	},
	{
		Id = "u_char_mastery", Category = "Character", Order = 10,
		Icon = "⚡",
		Name = "Keeper Mastery", Name_it = "Maestria del Custode",
		Tag = "x1.8 Click Power", Tag_it = "x1.8 Potere Click",
		Desc = "Multiplies all Light generated by your character's clicks by x1.8.",
		Desc_it = "Moltiplica x1.8 tutta la Luce generata dai click del personaggio.",
		BaseCost = 90000, CostMult = 3.1, MaxLevel = 6, LightPct = 2.5,
		Effect = "ClickPowerMult", Value = 1.8,
		ReqId = "u_ember_mag", ReqLvl = 1,
	},
	{
		Id = "u_unlock_alba", Category = "Character", Order = 11,
		Icon = "🌅",
		Name = "Rite of Dawn", Name_it = "Rito dell'Alba",
		Tag = "Unlock Dawn Tab", Tag_it = "Sblocca Scheda Alba",
		Desc = "Unlocks the Dawn tab to manage Dawn Points and unlock New Zones.",
		Desc_it = "Sblocca la scheda Alba per gestire i Punti Alba e le Nuove Zone.",
		BaseCost = 450000, CostMult = 1, MaxLevel = 1, LightPct = 4,
		Effect = "UnlockAlba", Value = 1,
		ReqId = "u_char_mastery", ReqLvl = 1,
	},
	{
		Id = "u_apotheosis", Category = "Character", Order = 12,
		Icon = "👑",
		Name = "Keeper Ascension", Name_it = "Ascensione del Custode",
		Tag = "x2.5 Click Power", Tag_it = "x2.5 Potere Click",
		Desc = "Supreme character mastery: multiplies your click power by x2.5.",
		Desc_it = "Potenziamento supremo: moltiplica x2.5 il potere dei click.",
		BaseCost = 4.5e6, CostMult = 4.5, MaxLevel = 4, LightPct = 3.5,
		Effect = "ClickPowerMult", Value = 2.5,
		ReqId = "u_unlock_alba", ReqLvl = 1,
	},
}

-- =========================================================================
-- WEAPONS / TOOLS TO DEFEND AGAINST SHADOWS
-- =========================================================================
GameConfig.Weapons = {
	{
		Id = "wep_torch",
		Order = 1,
		Icon = "🔥",
		Name = "Sunfire Torch", Name_it = "Torcia Solare",
		Tag = "2 DMG • 20 Studs AoE", Tag_it = "2 DANNI • Area 20 Stud",
		Desc = "A sacred torch that unleashes a solar flare burst against nearby Shadows.",
		Desc_it = "Torcia sacra che sprigiona un'esplosione solare contro le Ombre vicine.",
		Cost = 150,
		Damage = 2,
		Range = 20,
		Cooldown = 0.45,
		Color = Color3.fromRGB(255, 175, 55),
	},
	{
		Id = "wep_lantern",
		Order = 2,
		Icon = "🏮",
		Name = "Radiant Lantern", Name_it = "Lanterna Radiosa",
		Tag = "5 DMG • 38 Studs Beam", Tag_it = "5 DANNI • Raggio 38 Stud",
		Desc = "Fires a focused beam of pure light that pierces distant Shadows.",
		Desc_it = "Spara un raggio concentrato di luce pura che colpisce le Ombre a distanza.",
		Cost = 3500,
		Damage = 5,
		Range = 38,
		Cooldown = 0.50,
		Color = Color3.fromRGB(75, 225, 255),
	},
	{
		Id = "wep_dawnblade",
		Order = 3,
		Icon = "🗡️",
		Name = "Dawnblade", Name_it = "Lama dell'Alba",
		Tag = "14 DMG • 30 Studs Slash", Tag_it = "14 DANNI • Fendente 30 Stud",
		Desc = "Legendary blade of light that cleaves all Shadows in a wide arc.",
		Desc_it = "Spada leggendaria di luce che spazza via tutte le Ombre in un ampio raggio.",
		Cost = 65000,
		Damage = 14,
		Range = 30,
		Cooldown = 0.40,
		Color = Color3.fromRGB(255, 235, 110),
	},
}

-- =========================================================================
-- LIGHTWEIGHT PURCHASABLE DEFENSE STRUCTURES (Walls & Turrets)
-- =========================================================================
GameConfig.Defenses = {
	{
		Id = "def_walls",
		Order = 1,
		Icon = "🧱",
		Name = "Light Walls", Name_it = "Muri di Luce",
		Tag = "+1 Barrier Wall & Burn DMG", Tag_it = "+1 Barriera Solare & Danno",
		Desc = "Builds glowing solar barriers around your Brazier (up to 4) that slow and burn Shadows.",
		Desc_it = "Costruisce barriere solari attorno al Braciere (fino a 4) che rallentano e bruciano le Ombre.",
		BaseCost = 400,
		CostMult = 3.2,
		MaxLevel = 4,
	},
	{
		Id = "def_turrets",
		Order = 2,
		Icon = "🗼",
		Name = "Solar Turrets", Name_it = "Torrette Solari",
		Tag = "+1 Auto-Turret & Laser DMG", Tag_it = "+1 Torretta Auto & Danno Laser",
		Desc = "Constructs crystal sentinel turrets (up to 4) that automatically shoot lasers at invading Shadows.",
		Desc_it = "Costruisce torrette cristalline (fino a 4) che sparano automaticamente laser alle Ombre.",
		BaseCost = 1200,
		CostMult = 3.5,
		MaxLevel = 4,
	},
}

-- Realm 1 Speed Trial Configuration
GameConfig.Regno1 = {
	Name = "Realm 1",
	TrialTitle = "Chain of Fire",
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
-- GROUND BUTTONS: BRAZIER UPGRADES
-- =========================================================================
GameConfig.Altars = {
	{
		Id = "alt1",
		Name = "Brazier Power", Name_it = "Potenza Braciere",
		BaseCost = 25, CostMult = 1.35, MaxLevel = 25,
		Pps = 3,
		Color = Color3.fromRGB(255, 165, 55), Pos = Vector3.new(-16, 0.7, 14),
	},
	{
		Id = "alt2",
		Name = "Flame Multiplier", Name_it = "Moltiplicatore Fiamma",
		BaseCost = 180, CostMult = 1.45, MaxLevel = 20,
		Pps = 12, BrazierMult = 1.12,
		Color = Color3.fromRGB(255, 215, 80), Pos = Vector3.new(16, 0.7, 14),
	},
	{
		Id = "alt3",
		Name = "Brazier Size", Name_it = "Grandezza Braciere",
		BaseCost = 850, CostMult = 1.55, MaxLevel = 15,
		Pps = 45, RadiusBonus = 1,
		Color = Color3.fromRGB(255, 115, 45), Pos = Vector3.new(-21, 0.7, -3),
	},
	{
		Id = "alt4",
		Name = "Azure Flame", Name_it = "Fiamma Azzurra",
		BaseCost = 25000, CostMult = 1, MaxLevel = 1, IsColorButton = true, ColorTier = 1,
		BenefitTag = "x2.0 Brazier & +500/s", BenefitTag_it = "x2.0 Braciere & +500/s",
		Pps = 500, BrazierMult = 2.0,
		BrazierColor = Color3.fromRGB(70, 210, 255),
		Color = Color3.fromRGB(70, 210, 255), Pos = Vector3.new(21, 0.7, -3),
	},
	{
		Id = "alt5",
		Name = "Incandescent Core", Name_it = "Nucleo Incandescente",
		BaseCost = 14000, CostMult = 1.52, MaxLevel = 15,
		Pps = 850, HeatBonus = 0.08,
		Color = Color3.fromRGB(255, 240, 120), Pos = Vector3.new(0, 0.7, -20),
	},
	{
		Id = "alt6",
		Name = "Violet Flame", Name_it = "Fiamma Viola",
		BaseCost = 750000, CostMult = 1, MaxLevel = 1, IsColorButton = true, ColorTier = 2,
		BenefitTag = "x3.0 Brazier & +18K/s", BenefitTag_it = "x3.0 Braciere & +18K/s",
		Pps = 18000, BrazierMult = 3.0,
		BrazierColor = Color3.fromRGB(205, 95, 255),
		Color = Color3.fromRGB(205, 95, 255), Pos = Vector3.new(-28, 0.7, 22),
	},
	{
		Id = "alt7",
		Name = "Brazier Crown", Name_it = "Corona del Braciere",
		BaseCost = 420000, CostMult = 1.58, MaxLevel = 15,
		Pps = 28000, RadiusBonus = 1,
		Color = Color3.fromRGB(70, 255, 180), Pos = Vector3.new(28, 0.7, 22),
	},
	{
		Id = "alt8",
		Name = "Divine Sun", Name_it = "Sole Divino",
		BaseCost = 2.5e7, CostMult = 1, MaxLevel = 1, IsColorButton = true, ColorTier = 3,
		BenefitTag = "x5.0 Brazier & +450K/s", BenefitTag_it = "x5.0 Braciere & +450K/s",
		Pps = 450000, BrazierMult = 5.0,
		BrazierColor = Color3.fromRGB(255, 250, 185),
		Color = Color3.fromRGB(255, 235, 120), Pos = Vector3.new(0, 0.7, -34),
	},
}

-- 5 Light Wisps
GameConfig.BaseWispCost = 750
GameConfig.BaseEquippedWisps = 3
GameConfig.Wisps = {
	{ Id = "w_ember", Name = "Amber Firefly", Name_it = "Lucciola Ambra", Chance = "50%", Weight = 500, ClickMult = 1.2, Color = Color3.fromRGB(255, 190, 60) },
	{ Id = "w_azure", Name = "Azure Spirit", Name_it = "Spirito Celeste", Chance = "26%", Weight = 260, ClickMult = 1.5, Color = Color3.fromRGB(70, 225, 255) },
	{ Id = "w_jade", Name = "Jade Sprite", Name_it = "Fata di Giada", Chance = "14%", Weight = 140, ClickMult = 2.0, Color = Color3.fromRGB(80, 255, 150) },
	{ Id = "w_aurora", Name = "Aurora Wisp", Name_it = "Spirito Aurora", Chance = "7%", Weight = 70, ClickMult = 3.0, Color = Color3.fromRGB(220, 110, 255) },
	{ Id = "w_phoenix", Name = "Primordial Phoenix", Name_it = "Fenice Primordiale", Chance = "3%", Weight = 30, ClickMult = 5.0, Color = Color3.fromRGB(255, 255, 255) },
}

-- =========================================================================
-- DAWN SYSTEM: Rebirth Upgrades & Unlockable New Zones
-- =========================================================================
GameConfig.AlbaPerks = {
	{
		Id = "ap_alba_gain",
		Name = "Dawn Echo", Name_it = "Eco dell'Alba",
		Desc = "+1 extra Dawn Point every time you activate the Final Dawn Button",
		Desc_it = "+1 Punto Alba extra ogni volta che premi il Bottone Finale",
		Cost = 1,
		CostMult = 2,
		MaxLevel = 10,
	},
	{
		Id = "ap_power",
		Name = "Primordial Flame", Name_it = "Fiamma Primordiale",
		Desc = "Multiplies all Light Points earned by x2.5 per level",
		Desc_it = "Tutti i Punti Luce x2.5 per livello",
		Cost = 1,
		CostMult = 2,
		MaxLevel = 6,
	},
	{
		Id = "ap_start",
		Name = "Inherited Spark", Name_it = "Scintilla Ereditata",
		Desc = "Start after Rebirth with 10,000 Light and Kindling Touch Lv. 5",
		Desc_it = "Parti dopo il Rebirth con 10.000 Punti e Mano Ardente Lv. 5",
		Cost = 1,
		CostMult = 2,
		MaxLevel = 4,
	},
	{
		Id = "ap_crit",
		Name = "Solar Eye", Name_it = "Occhio Solare",
		Desc = "Multiplies Critical Power by x2 per level",
		Desc_it = "Moltiplicatore Critici x2 per livello",
		Cost = 2,
		CostMult = 3,
		MaxLevel = 3,
	},
}

GameConfig.AlbaZones = {
	{
		Id = "az_2",
		Order = 1,
		Icon = "🌋",
		Name = "Zone 2: Crimson Sanctuary", Name_it = "Zona 2: Santuario Cremisi",
		Desc = "Unlocks Zone 2 access and grants permanent +50% Light Points.",
		Desc_it = "Sblocca l'accesso alla Zona 2 e dona +50% Punti Luce permanenti.",
		Cost = 1,
		LightMult = 1.5,
	},
	{
		Id = "az_3",
		Order = 2,
		Icon = "🌌",
		Name = "Zone 3: Astral Observatory", Name_it = "Zona 3: Osservatorio Astrale",
		Desc = "Unlocks Zone 3 access and permanently doubles (x2) Light Points.",
		Desc_it = "Sblocca l'accesso alla Zona 3 e raddoppia (x2) i Punti Luce permanenti.",
		Cost = 3,
		LightMult = 2.0,
	},
	{
		Id = "az_4",
		Order = 3,
		Icon = "☀️",
		Name = "Zone 4: Solar Forge", Name_it = "Zona 4: Forgia Solare",
		Desc = "Unlocks Zone 4 access and permanently triples (x3) Light Points.",
		Desc_it = "Sblocca l'accesso alla Zona 4 e triplica (x3) i Punti Luce permanenti.",
		Cost = 6,
		LightMult = 3.0,
	},
	{
		Id = "az_5",
		Order = 4,
		Icon = "👑",
		Name = "Zone 5: Primordial Throne", Name_it = "Zona 5: Trono Primordiale",
		Desc = "Unlocks Zone 5 access and permanently multiplies Light Points by x5.",
		Desc_it = "Sblocca l'accesso alla Zona 5 e moltiplica x5 i Punti Luce permanenti.",
		Cost = 12,
		LightMult = 5.0,
	},
}

GameConfig.Ranks = {
	{ MinLight = 0, Name = "Spark Bearer", Name_it = "Portatore di Scintilla", Color = Color3.fromRGB(255, 175, 80) },
	{ MinLight = 20, Name = "Realm 1 Keeper", Name_it = "Custode di Regno 1", Color = Color3.fromRGB(255, 215, 70) },
	{ MinLight = 45, Name = "Crystal Weaver", Name_it = "Tessitore di Cristallo", Color = Color3.fromRGB(70, 240, 210) },
	{ MinLight = 70, Name = "Twilight Herald", Name_it = "Araldo del Crepuscolo", Color = Color3.fromRGB(130, 190, 255) },
	{ MinLight = 90, Name = "Dawn Sovereign", Name_it = "Signore dell'Alba", Color = Color3.fromRGB(255, 235, 120) },
	{ MinLight = 100, Name = "Living Sun", Name_it = "Sole Vivente", Color = Color3.fromRGB(255, 255, 255) },
}

GameConfig.PromoCodes = {
	["LIGHT100"] = { Points = 250, Msg = "+250 Light Points redeemed!", Msg_it = "+250 Punti Luce riscattati!" },
	["LUCE100"] = { Points = 250, Msg = "+250 Light Points redeemed!", Msg_it = "+250 Punti Luce riscattati!" },
	["FLAME"] = { Points = 1500, Msg = "+1,500 Light Points redeemed!", Msg_it = "+1.500 Punti Luce riscattati!" },
	["FIAMMA"] = { Points = 1500, Msg = "+1,500 Light Points redeemed!", Msg_it = "+1.500 Punti Luce riscattati!" },
	["DAWN2026"] = { Points = 10000, Msg = "+10,000 Light Points redeemed!", Msg_it = "+10.000 Punti Luce riscattati!" },
	["ALBA2026"] = { Points = 10000, Msg = "+10,000 Light Points redeemed!", Msg_it = "+10.000 Punti Luce riscattati!" },
}

return GameConfig
