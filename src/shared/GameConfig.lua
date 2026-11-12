local GameConfig = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd"
}

function GameConfig.Format(n)
	if n == nil or n ~= n then return "0" end
	if n == math.huge then return "Infinito" end
	if n < 0 then return "-" .. GameConfig.Format(-n) end
	if n < 1000 then
		if n < 10 and n % 1 ~= 0 then
			return string.format("%.1f", n)
		end
		return tostring(math.floor(n))
	end
	local tier = math.floor(math.log10(n) / 3)
	if tier < #SUFFIXES then
		return string.format("%.2f%s", n / (10 ^ (tier * 3)), SUFFIXES[tier + 1])
	else
		local exp = math.floor(math.log10(n))
		return string.format("%.2fe%d", n / (10 ^ exp), exp)
	end
end

-- Potenziamenti Principali (Acquistabili con Punti Luce)
GameConfig.Upgrades = {
	-- Potenziamenti Click & Fiamma
	{ Id = "u_click_add", Category = "Flame", Icon = "🔥", Name = "Soffio Ardente", Desc = "+1 Punto base per click", BaseCost = 10, CostMult = 1.45, MaxLevel = 30, LightPct = 0.5, Effect = "ClickAdd", Value = 1 },
	{ Id = "u_click_mult", Category = "Flame", Icon = "⚡", Name = "Fiamma Concentrata", Desc = "x1.60 Punti per ogni click", BaseCost = 45, CostMult = 2.35, MaxLevel = 15, LightPct = 1, Effect = "ClickMult", Value = 1.60 },
	{ Id = "u_radius", Category = "Flame", Icon = "☀️", Name = "Espansione della Luce", Desc = "+3% Luce nel mondo & Click x1.35", BaseCost = 75, CostMult = 2.20, MaxLevel = 8, LightPct = 3, Effect = "ClickMult", Value = 1.35 },
	{ Id = "u_crit", Category = "Flame", Icon = "💥", Name = "Scintilla Critica", Desc = "+6% chance Critico (x12 Punti)", BaseCost = 120, CostMult = 2.10, MaxLevel = 10, LightPct = 0.5, Effect = "CritChance", Value = 0.06 },
	{ Id = "u_autoclick", Category = "Flame", Icon = "⏱️", Name = "Battito della Fiamma", Desc = "+1 Click automatico al secondo", BaseCost = 200, CostMult = 2.40, MaxLevel = 10, LightPct = 0.5, Effect = "AutoClick", Value = 1 },
	{ Id = "u_heat", Category = "Flame", Icon = "🌡️", Name = "Braci Persistenti", Desc = "Bonus Calore massimo +x0.6", BaseCost = 350, CostMult = 2.60, MaxLevel = 6, LightPct = 1, Effect = "HeatMax", Value = 0.6 },
	{ Id = "u_ember_mag", Category = "Flame", Icon = "🧲", Name = "Attrazione Luminosa", Desc = "Attira le sfere vaganti nel buio", BaseCost = 1500, CostMult = 1, MaxLevel = 1, LightPct = 2, Effect = "Magnet", Value = 1 },
	{ Id = "u_wisp_slot", Category = "Flame", Icon = "✨", Name = "Legame Spiritico", Desc = "+1 Spirito di Luce attivo", BaseCost = 8000, CostMult = 4.0, MaxLevel = 2, LightPct = 2, Effect = "ExtraWisp", Value = 1 },

	-- Risveglio dei 5 Regni Oscuri
	{ Id = "u_braziers", Category = "World", Icon = "🔥", Name = "Sentiero dei Bracieri", Desc = "Accende 12 bracieri + Click x2.0", BaseCost = 250, CostMult = 1, MaxLevel = 1, LightPct = 12, Zone = "Braziers", Effect = "ClickMult", Value = 2.0 },
	{ Id = "u_crystals", Category = "World", Icon = "💎", Name = "Foresta di Cristallo", Desc = "Illumina i cristalli a Est + Click x2.5", BaseCost = 2500, CostMult = 1, MaxLevel = 1, LightPct = 15, Zone = "Crystals", Effect = "ClickMult", Value = 2.5 },
	{ Id = "u_lanterns", Category = "World", Icon = "🏮", Name = "Giardino delle Lanterne", Desc = "Lanterne volanti a Sud-Ovest + Click x3.0", BaseCost = 25000, CostMult = 1, MaxLevel = 1, LightPct = 15, Zone = "Lanterns", Effect = "ClickMult", Value = 3.0 },
	{ Id = "u_waterfall", Category = "World", Icon = "🌊", Name = "Cascata Eterea", Desc = "Accende la cascata a Ovest + Click x4.0", BaseCost = 250000, CostMult = 1, MaxLevel = 1, LightPct = 18, Zone = "Waterfall", Effect = "ClickMult", Value = 4.0 },
	{ Id = "u_temple", Category = "World", Icon = "🏛️", Name = "Tempio dell'Alba", Desc = "Risveglia il Sole a Nord + Click x6.0", BaseCost = 3e6, CostMult = 1, MaxLevel = 1, LightPct = 22, Zone = "Temple", Effect = "ClickMult", Value = 6.0 },
}

-- 8 Altari a Terra attorno alla Fiamma
GameConfig.Altars = {
	{ Id = "alt1", Name = "Pietra Focaia", Desc = "+1/s & +0.5 Click", BaseCost = 25, CostMult = 1.18, Pps = 1, ClickBonus = 0.5, Color = Color3.fromRGB(255, 165, 55), Pos = Vector3.new(-16, 1.4, 14) },
	{ Id = "alt2", Name = "Lanterna Antica", Desc = "+6/s & +2 Click", BaseCost = 140, CostMult = 1.20, Pps = 6, ClickBonus = 2, Color = Color3.fromRGB(255, 215, 80), Pos = Vector3.new(16, 1.4, 14) },
	{ Id = "alt3", Name = "Braciere Runico", Desc = "+30/s & +8 Click", BaseCost = 750, CostMult = 1.22, Pps = 30, ClickBonus = 8, Color = Color3.fromRGB(255, 105, 45), Pos = Vector3.new(-21, 1.4, -3) },
	{ Id = "alt4", Name = "Faro del Crepuscolo", Desc = "+150/s & +35 Click", BaseCost = 4000, CostMult = 1.24, Pps = 150, ClickBonus = 35, Color = Color3.fromRGB(95, 220, 255), Pos = Vector3.new(21, 1.4, -3) },
	{ Id = "alt5", Name = "Specchio Solare", Desc = "+800/s & +160 Click", BaseCost = 22000, CostMult = 1.26, Pps = 800, ClickBonus = 160, Color = Color3.fromRGB(255, 240, 120), Pos = Vector3.new(0, 1.4, -20) },
	{ Id = "alt6", Name = "Fucina Stellare", Desc = "+4.5K/s & +850 Click", BaseCost = 130000, CostMult = 1.28, Pps = 4500, ClickBonus = 850, Color = Color3.fromRGB(195, 120, 255), Pos = Vector3.new(-28, 1.4, 22) },
	{ Id = "alt7", Name = "Obelisco dell'Alba", Desc = "+25K/s & +4.5K Click", BaseCost = 850000, CostMult = 1.30, Pps = 25000, ClickBonus = 4500, Color = Color3.fromRGB(70, 255, 180), Pos = Vector3.new(28, 1.4, 22) },
	{ Id = "alt8", Name = "Cuore del Sole", Desc = "+150K/s & +25K Click", BaseCost = 6e6, CostMult = 1.32, Pps = 150000, ClickBonus = 25000, Color = Color3.fromRGB(255, 225, 95), Pos = Vector3.new(0, 1.4, -34) },
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
GameConfig.PrestigeCost = 1e8
GameConfig.StarPerks = {
	{ Id = "sp_power", Name = "Fiamma Primordiale", Desc = "Tutti i Punti x5 per livello", Cost = 1, CostMult = 2, MaxLevel = 5 },
	{ Id = "sp_start", Name = "Scintilla Ereditata", Desc = "Parti con 5.000 Punti e Soffio Liv. 5", Cost = 1, CostMult = 2, MaxLevel = 3 },
	{ Id = "sp_crit", Name = "Occhio Solare", Desc = "Moltiplicatore Critici x2", Cost = 2, CostMult = 3, MaxLevel = 3 },
	{ Id = "sp_ward", Name = "Barriera di Luce", Desc = "Respinge automaticamente le Ombre", Cost = 2, CostMult = 1, MaxLevel = 1 },
}

GameConfig.Ranks = {
	{ MinLight = 0, Name = "Portatore di Scintilla", Color = Color3.fromRGB(255, 175, 80) },
	{ MinLight = 20, Name = "Custode dei Bracieri", Color = Color3.fromRGB(255, 215, 70) },
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
