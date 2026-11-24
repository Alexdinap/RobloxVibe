local Localization = {}

Localization.DefaultLang = "en"

local STRINGS = {
	en = {
		POINTS_SUFFIX = "Light Points",
		RATE_FMT = "+%s / click  •  +%s / sec",
		ZONE_BADGE_FMT = "ZONES %d/5 • %s (%d%%)",
		HEAT_ALBA_FMT = "Heat x%.2f • 🌅Dawn: %d • Upg. %d/%d%s",
		MY_ZONE_BTN = "🏠 MY ZONE",
		CHAR_BTN_TITLE = "SANCTUARY",
		CHAR_BTN_SUB = "Upgrades & Defense [B]",
		ROBUX_X2_BTN = "⚡ x2 LIGHT (ROBUX)",
		ROBUX_X2_ACTIVE = "✅ x2 LIGHT ACTIVE",
		MODAL_TITLE = "🧙 KEEPER'S SANCTUARY",

		TAB_CHAR = "🔥 Character",
		TAB_DEFENSE = "🛡️ Defense",
		TAB_WISPS = "✨ Wisps",
		TAB_DAWN = "🌅 Dawn",
		TAB_CODES = "🎁 Codes",

		LOCKED_REQ = "🔒 Requires previous upgrade",
		BTN_LOCKED = "LOCKED",
		BTN_MAXED = "MAXED",
		BTN_OWNED = "✅ OWNED",
		BTN_EQUIPPED = "✅ EQUIPPED",
		BTN_UNLOCKED = "✅ UNLOCKED",
		LIGHT_UNIT = "Light",
		DAWN_PT_UNIT = "Dawn Pt",
		MAX_GROUND_PAD = "✅ MAXED",
		ACTIVE_GROUND_PAD = "✅ ACTIVE",

		SEC_WEAPONS = "⚔️ SPIRIT WEAPONS (Equipped to Hotbar)",
		SEC_STRUCTURES = "🏰 BASE DEFENSES (Auto-built around Brazier)",
		DEF_TIP = "Shadows raid your Brazier and drain Light! Equip weapons or build Light Walls & Solar Turrets to repel them.",

		WISPS_LOCKED = "🔒 Unlock 'Spirit Summoning' in the Character tab first!",
		WISPS_HEADER_FMT = "✨ Active Wisps: %d / %d  (Strongest wisps auto-equip)",
		SUMMON_1_FMT = "Summon x1 (%s)",
		SUMMON_5_FMT = "Summon x5 (%s)",
		WISP_ROW_FMT = "● %s (x%.1f | %s) — Norm: %d | Rad: %d",
		FORGE_READY = "🌟 FORGE (3→1)",
		FORGE_NEED_FMT = "Need 3 (%d/3)",

		DAWN_STATUS_READY = "✅ Final Dawn Button is active on your island! Step on it for +%d Dawn Points.",
		DAWN_STATUS_PROG = "Max all upgrades (%d/%d) and press the Final Dawn Button for +%d Dawn Points.",
		DAWN_HEADER_FMT = "🌅 AVAILABLE DAWN POINTS: %d   •   Rebirths: %d\n%s",
		SEC_DAWN_PERKS = "✨ DAWN UPGRADES (PERMANENT)",
		SEC_DAWN_ZONES = "🗺️ UNLOCK NEW ZONES WITH DAWN POINTS",

		CODE_PLACEHOLDER = "Enter code (e.g. LIGHT100)",
		CODE_HINT = "Active codes: LIGHT100, FLAME, DAWN2026",
		CODE_REDEEM = "REDEEM",
		CODE_USED = "Code already redeemed!",
		CODE_INVALID = "Invalid promo code!",
		CODE_ERR = "Error redeeming code",

		VICTORY_TITLE = "🌅 SUPREME DAWN ACHIEVED!",
		VICTORY_BODY_FMT = "You activated the Final Dawn Button and earned +%d Dawn Points!\nTotal Dawn Points: %d\n\nSpend them in the Dawn tab to boost Rebirths or unlock New Zones.",
		VICTORY_OPEN_DAWN = "OPEN DAWN TAB",

		PLOT_FREE_FMT = "ZONE %d — OPEN",
		PLOT_WAIT = "Awaiting a Flame Keeper",
		PLOT_OWNER_FMT = "ZONE %d — %s",
		PLOT_RANK_FMT = "Rank: %s",
		BRAZIER_DEFAULT_FMT = "Zone %d Brazier",
		BRAZIER_OWNER_FMT = "%s's Brazier",
		FINAL_BTN_COST_FMT = "Cost: %s Light (+%d Dawn Pt)",

		R1_BANNER_ACTIVE = "CHAIN OF FIRE: Brazier %d/%d  •  %.1fs",
		R1_BANNER_BUFF = "REALM 1 BLESSING: x%.2f  •  %ds",
		R1_START = "🔥 CHAIN OF FIRE STARTED! Touch Brazier II!",
		R1_STEP_FMT = "🔥 Brazier %s lit! (+%.1fs) Next: %s",
		R1_WIN_FMT = "🏆 REALM 1 COMPLETED! Permanent x1.35 + x%.2f Blessing (30s)!",
		R1_FAIL = "⏳ Time expired! Step on Brazier I to retry.",

		POP_PASS_ACTIVE = "⚡ PERMANENT x2 LIGHT ACTIVATED!",
		POP_COLOR_ALREADY = "🎨 %s is already unlocked! (%s)",
		POP_COLOR_UNLOCKED = "🎨 COLOR UNLOCKED: %s (%s)!",
		POP_ALL_MAXED = "🌅 ALL UPGRADES MAXED! The Final Dawn Button has appeared!",
		POP_DAWN_DONE = "🌅 DAWN REBIRTH COMPLETE! +%d Dawn Points earned!",
		POP_NEED_FINAL = "🌅 You need %s Light Points for the Final Dawn Button!",
		POP_R1_UNLOCKED = "🏃 REALM 1 UNLOCKED! Run to Brazier I on your island!",
		POP_NEW_UNLOCK = "🆕 UNLOCKED: %s!",
		POP_DAWN_PERK = "🌅 Dawn Upgrade purchased: %s!",
		POP_ZONE_UNLOCK = "🗺️ NEW ZONE UNLOCKED: %s!",
		POP_WEAPON_BOUGHT = "⚔️ Weapon unlocked & equipped: %s!",
		POP_DEFENSE_BUILT = "🛡️ Defense upgraded: %s [Lv.%d]!",
		POP_NEED_LIGHT = "You need %s Light Points!",
		POP_WISP_1 = "✨ Summoned: %s!",
		POP_WISP_5 = "✨ Summoned %d Wisps! Best: %s",
		POP_NEED_3_WISPS = "You need 3 identical Wisps to forge!",
		POP_FORGE_OK = "🌟 FORGE SUCCESS! Radiant %s (x2.5)!",
		POP_EMBER = "✨ Wandering Orb: +%s Light!",
		POP_SHADOW_KILL = "🛡️ Shadow banished: +%s Light!",
		POP_SHADOW_HIT = "⚠️ A Shadow struck your Brazier! -%s Light!",
		POP_SHADOW_RAID = "🌑 Shadows are attacking your Brazier!",
	},

	it = {
		POINTS_SUFFIX = "Punti Luce",
		RATE_FMT = "+%s / click  •  +%s / sec",
		ZONE_BADGE_FMT = "ZONE %d/5 • %s (%d%%)",
		HEAT_ALBA_FMT = "Calore x%.2f • 🌅Alba: %d • Potenz. %d/%d%s",
		MY_ZONE_BTN = "🏠 LA MIA ZONA",
		CHAR_BTN_TITLE = "SANTUARIO",
		CHAR_BTN_SUB = "Potenziamenti & Difesa [B]",
		ROBUX_X2_BTN = "⚡ LUCE x2 (ROBUX)",
		ROBUX_X2_ACTIVE = "✅ LUCE x2 ATTIVA",
		MODAL_TITLE = "🧙 SANTUARIO DEL CUSTODE",

		TAB_CHAR = "🔥 Personaggio",
		TAB_DEFENSE = "🛡️ Difesa",
		TAB_WISPS = "✨ Spiriti",
		TAB_DAWN = "🌅 Alba",
		TAB_CODES = "🎁 Codici",

		LOCKED_REQ = "🔒 Richiede potenziamento precedente",
		BTN_LOCKED = "BLOCCATO",
		BTN_MAXED = "MASSIMO",
		BTN_OWNED = "✅ POSSEDUTO",
		BTN_EQUIPPED = "✅ EQUIPAGGIATO",
		BTN_UNLOCKED = "✅ SBLOCCATA",
		LIGHT_UNIT = "Luce",
		DAWN_PT_UNIT = "P. Alba",
		MAX_GROUND_PAD = "✅ MASSIMO",
		ACTIVE_GROUND_PAD = "✅ ATTIVO",

		SEC_WEAPONS = "⚔️ ARMI SPIRITICHE (Aggiunte all'inventario)",
		SEC_STRUCTURES = "🏰 DIFESE BASE (Costruite attorno al Braciere)",
		DEF_TIP = "Le Ombre attaccano il Braciere e rubano Luce! Compra armi o costruisci Muri di Luce e Torrette Solari.",

		WISPS_LOCKED = "🔒 Sblocca 'Evocazione Spiriti' nella scheda Personaggio!",
		WISPS_HEADER_FMT = "✨ Spiriti Attivi: %d / %d  (I migliori si equipaggiano in automatico)",
		SUMMON_1_FMT = "Evoca x1 (%s)",
		SUMMON_5_FMT = "Evoca x5 (%s)",
		WISP_ROW_FMT = "● %s (x%.1f | %s) — Norm: %d | Rad: %d",
		FORGE_READY = "🌟 FORGIA (3→1)",
		FORGE_NEED_FMT = "Servono 3 (%d/3)",

		DAWN_STATUS_READY = "✅ Bottone Finale attivo sull'isola! Premilo per ottenere +%d Punti Alba.",
		DAWN_STATUS_PROG = "Completa i potenziamenti (%d/%d) e premi il Bottone Finale per +%d Punti Alba.",
		DAWN_HEADER_FMT = "🌅 PUNTI ALBA DISPONIBILI: %d   •   Rebirth effettuati: %d\n%s",
		SEC_DAWN_PERKS = "✨ POTENZIAMENTI ALBA (PERMANENTI)",
		SEC_DAWN_ZONES = "🗺️ SBLOCCA NUOVE ZONE CON I PUNTI ALBA",

		CODE_PLACEHOLDER = "Codice (es. LIGHT100)",
		CODE_HINT = "Codici attivi: LIGHT100, FLAME, DAWN2026",
		CODE_REDEEM = "RISCATTA",
		CODE_USED = "Codice già usato!",
		CODE_INVALID = "Codice non valido!",
		CODE_ERR = "Errore riscatto codice",

		VICTORY_TITLE = "🌅 ALBA SUPREMA COMPIUTA!",
		VICTORY_BODY_FMT = "Hai attivato il Bottone Finale e ottenuto +%d Punti Alba!\nTotale Punti Alba: %d\n\nUsali nella scheda Alba per potenziare il Rebirth o sbloccare Nuove Zone.",
		VICTORY_OPEN_DAWN = "APRI SCHEDA ALBA",

		PLOT_FREE_FMT = "ZONA %d — LIBERA",
		PLOT_WAIT = "In attesa di un Custode",
		PLOT_OWNER_FMT = "ZONA %d — %s",
		PLOT_RANK_FMT = "Rango: %s",
		BRAZIER_DEFAULT_FMT = "Braciere Zona %d",
		BRAZIER_OWNER_FMT = "Braciere di %s",
		FINAL_BTN_COST_FMT = "Costo: %s Luce (+%d P. Alba)",

		R1_BANNER_ACTIVE = "CATENA DEL FUOCO: Braciere %d/%d  •  %.1fs",
		R1_BANNER_BUFF = "BENEDIZIONE REGNO 1: x%.2f  •  %ds",
		R1_START = "🔥 CATENA DEL FUOCO AVVIATA! Tocca il Braciere II!",
		R1_STEP_FMT = "🔥 Braciere %s acceso! (+%.1fs) Prossimo: %s",
		R1_WIN_FMT = "🏆 REGNO 1 COMPLETATO! x1.35 Permanente + Benedizione x%.2f (30s)!",
		R1_FAIL = "⏳ Tempo scaduto! Torna al Braciere I per riprovare.",

		POP_PASS_ACTIVE = "⚡ LUCE x2 PERMANENTE ATTIVATA!",
		POP_COLOR_ALREADY = "🎨 %s già sbloccata! (%s)",
		POP_COLOR_UNLOCKED = "🎨 COLORE SBLOCCATO: %s (%s)!",
		POP_ALL_MAXED = "🌅 POTENZIAMENTI COMPLETATI! È comparso il Bottone dell'Alba Finale!",
		POP_DAWN_DONE = "🌅 ALBA COMPIUTA! +%d Punti Alba ottenuti!",
		POP_NEED_FINAL = "🌅 Servono %s Punti Luce per il Bottone Finale!",
		POP_R1_UNLOCKED = "🏃 REGNO 1 SBLOCCATO! Corri al Braciere I della tua Zona!",
		POP_NEW_UNLOCK = "🆕 SBLOCCATO: %s!",
		POP_DAWN_PERK = "🌅 Potenziamento Alba acquistato: %s!",
		POP_ZONE_UNLOCK = "🗺️ NUOVA ZONA SBLOCCATA: %s!",
		POP_WEAPON_BOUGHT = "⚔️ Arma sbloccata ed equipaggiata: %s!",
		POP_DEFENSE_BUILT = "🛡️ Difesa potenziata: %s [Lv.%d]!",
		POP_NEED_LIGHT = "Servono %s Punti Luce!",
		POP_WISP_1 = "✨ Evocato: %s!",
		POP_WISP_5 = "✨ Evocati %d Spiriti! Migliore: %s",
		POP_NEED_3_WISPS = "Servono 3 Spiriti identici!",
		POP_FORGE_OK = "🌟 FORGIA RIUSCITA! %s RADIOSO (x2.5)!",
		POP_EMBER = "✨ Sfera: +%s Luce!",
		POP_SHADOW_KILL = "🛡️ Ombra dissipata: +%s Luce!",
		POP_SHADOW_HIT = "⚠️ Un'Ombra ha colpito il Braciere! -%s Luce!",
		POP_SHADOW_RAID = "🌑 Le Ombre stanno attaccando il tuo Braciere!",
	}
}

function Localization.T(lang, key, ...)
	local dict = STRINGS[lang] or STRINGS[Localization.DefaultLang]
	local raw = dict[key] or STRINGS.en[key] or key
	if select("#", ...) > 0 then
		return string.format(raw, ...)
	end
	return raw
end

function Localization.Pick(lang, enText, itText)
	if lang == "it" then
		return itText or enText
	end
	return enText or itText
end

return Localization
