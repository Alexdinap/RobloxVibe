local Localization = {}

local STRINGS = {
	en = {
		LIGHT_UNIT = "Light",
		DAWN_PT_UNIT = "Dawn Pts",
		POINTS_SUFFIX = "Light Points",
		RATE_FMT = "+%s / click (%.2fs)  •  +%s / sec",
		ZONE_BADGE_FMT = "ZONES %d/5 • %s (%d%%)",
		HEAT_ALBA_FMT = "Heat x%.2f • 🌅Dawn: %d • Upg. %d/%d%s",

		TRUCE_INITIAL_FMT = "🛡️ DAWN TRUCE: %d:%02d before Shadows arrive",
		TRUCE_DAWN_FMT = "🌅 REBIRTH TRUCE: %d:%02d before Shadows return",

		MY_ZONE_BTN = "🏠 My Zone",
		CHAR_BTN_TITLE = "Character & Flame",
		CHAR_BTN_SUB = "Upgrades & Dawn",
		TUTORIAL_BTN = "📖 Tutorial",
		ROBUX_X2_BTN = "⚡ x2 Light (Robux)",
		ROBUX_X2_ACTIVE = "✅ x2 Light Active",
		MODAL_TITLE = "🔥 Keeper Sanctuary & Upgrades",
		TURRET_MODAL_TITLE = "🗼 Turret Management",
		WISPS_MODAL_TITLE = "✨ Spirit Management",
		DAILY_MODAL_TITLE = "🎁 Daily Rewards",
		HUD_TURRETS = "🗼 Turrets",
		HUD_WISPS = "✨ Spirits",
		HUD_DAILY = "🎁 Daily Rewards",
		DAILY_COMING_SOON = "The daily reward calendar is coming soon. Rewards will be announced here!",
		DAILY_DAY = "Day",
		DAILY_REWARD_SOON = "Reward coming soon",

		TUTORIAL_HEADER = "🔥 KEEPER'S GUIDE",
		TUTORIAL_STEP_FMT = "Slide %d / %d",
		TUTORIAL_PREV = "◀ Back",
		TUTORIAL_NEXT = "Next ▶",
		TUTORIAL_START = "🔥 Start Playing!",
		TUTORIAL_CLOSE_DONE = "✔ Close",
		POP_TUTORIAL_DONE = "🛡️ Tutorial complete! 3:00 Dawn Truce started!",

		TUT_1_TITLE = "1. Kindle the Central Brazier",
		TUT_1_BODY = "• Click your central Brazier (or press E / F nearby) to generate Light Points.\n• Clicking rapidly builds Flame Heat, multiplying your Light gain.\n• Touch golden Wandering Embers around your plot for instant Light bursts.",
		TUT_1_TIP = "💡 Tip: Keep clicking to build Heat! After a Dawn upgrade, you can hold the button on the Brazier Core.",

		TUT_2_TITLE = "2. Upgrade Tree & Flame Powers",
		TUT_2_BODY = "• Open 'Character & Flame' [B] to grow your incremental Upgrade Tree, starting from Kindle Flame.\n• Reaching Lv. 1 on any node reveals and unlocks its connected branches, including Flame Colors and multipliers.",
		TUT_2_TIP = "💡 Tip: Keep upgrading unlocked nodes up to MAX to unlock Dawn Rebirth!",

		TUT_3_TITLE = "3. Defend Against the Shadows",
		TUT_3_BODY = "• Once you close this tutorial, a 3:00 Dawn Truce countdown begins.\n• When the timer ends, Shadows will attack your Brazier and drain Light.\n• Step onto the Weapon pads on the left of your plot to buy Weapons, or use the Turrets button in the HUD to build defenses.",
		TUT_3_TIP = "💡 Tip: Grab the Ember Torch on your plot or build a Sunfire Turret before the 3:00 truce expires!",

		TUT_4_TITLE = "4. Light Wisps & Spirit Shrine",
		TUT_4_BODY = "• Unlock 'Spirit Awakening' in the Upgrade Tree to activate the Spirit Shrine on your plot.\n• Step onto the round Spirit pads or use the Spirits button in the HUD to summon orbiting Wisps and forge 3 into a Radiant Wisp.\n• Unlock the Realm 1 Portal for timed brazier trials with temporary multipliers.",
		TUT_4_TIP = "💡 Tip: Your strongest Wisps equip automatically around your character.",

		TUT_5_TITLE = "5. Dawn Rebirth & Monument Islands",
		TUT_5_BODY = "• Max out all nodes in the Upgrade Tree to activate the Dawn Rebirth pad behind your Brazier.\n• Rebirthing resets Light & defenses in exchange for Dawn Points.\n• Spend Dawn Points on permanent blessings and 4 Monument Islands!",
		TUT_5_TIP = "💡 Tip: Each Monument Island adds a massive permanent Light multiplier!",

		TAB_CHAR = "Character",
		TAB_DEFENSE = "Defense",
		TAB_WISPS = "Wisps",
		TAB_DAWN = "Dawn",
		TAB_CODES = "Codes",

		LOCKED_REQ = "🔒 Unlock previous upgrade first",
		BTN_MAXED = "MAXED",
		BTN_LOCKED = "LOCKED",
		BTN_EQUIPPED = "EQUIPPED",
		BTN_UNLOCKED = "UNLOCKED",

		DEF_TIP = "🛡️ Build and improve defenses to protect your Brazier from the Shadows.",
		SEC_STRUCTURES = "🗼 PLOT DEFENSES",

		WISPS_LOCKED = "🔒 Unlock 'Spirit Awakening' in the Character tab first!",
		WISPS_HEADER_FMT = "Equipped Wisps: %d / %d\nBest Wisps equip automatically!",
		SUMMON_1_FMT = "Summon x1\n(%s)",
		SUMMON_5_FMT = "Summon x5\n(%s)",
		WISP_ROW_FMT = "%s (x%.2f Click • %d%%)\nOwned: %d  |  ✨Radiant: %d",
		FORGE_READY = "✨ Forge Radiant (3→1)",
		FORGE_NEED_FMT = "Need 3 (%d/3)",

		SEC_DAWN_PERKS = "🌅 PERMANENT DAWN BLESSINGS",
		SEC_DAWN_ZONES = "🏝️ DAWN SANCTUARY ISLANDS (MONUMENTS)",
		DAWN_HEADER_FMT = "🌅 Dawn Points: %d  |  Rebirths: %d\n%s",
		DAWN_STATUS_READY = "READY! Step on Dawn Rebirth pad for +%d Dawn Pts!",
		DAWN_STATUS_PROG = "Max all tree upgrades (%d/%d) to unlock Rebirth (+%d Dawn Pts).",
		TREE_PROG_FMT = "🌳 Upgrade Tree  •  Unlocked: %d/%d  •  Maxed: %d/%d",
		TREE_HOVER_HINT = "Hover any icon to view details  •  Click to upgrade",
		TREE_TIP_CLICK = "Click icon to upgrade",
		PAD_WEP_EQUIPPED = "✅ EQUIPPED (Step to equip)",
		PAD_WEP_LOCKED_FMT = "🔒 Rebirth %d Required",
		PAD_WISP_SHRINE_TITLE = "🔮 SPIRIT SANCTUARY",
		PAD_WISP_1_TITLE = "✨ Summon Wisp x1",
		PAD_WISP_5_TITLE = "🌟 Summon Wisps x5",
		PAD_WISP_LOCKED_DESC = "Unlock Spirit Awakening",
		PAD_WISP_READY_DESC = "Orbiting Light Companions",
		POP_WEAPON_EQUIPPED = "⚔️ Equipped in hand: %s!",
		POP_WISPS_LOCKED = "🔒 Unlock 'Spirit Awakening' in the Upgrade Tree first!",

		CODE_PLACEHOLDER = "Enter promo code...",
		CODE_HINT = "Try codes: DAWN2026, FLAME",
		CODE_REDEEM = "REDEEM",
		CODE_USED = "Code already redeemed!",
		CODE_INVALID = "Invalid promo code.",

		VICTORY_TITLE = "🌅 DAWN REBIRTH COMPLETE!",
		VICTORY_BODY_FMT = "Your flame ascended into a new Dawn!\n\nEarned: +%d Dawn Points\nTotal Dawn Points: %d\n\nSpend Dawn Points on permanent blessings and Monument Islands!",
		VICTORY_OPEN_DAWN = "Open Dawn Tab",

		PLOT_OWNER_FMT = "ZONE %d • %s",
		PLOT_RANK_FMT = "Rank: %s",
		PLOT_FREE_FMT = "ZONE %d • UNCLAIMED",
		PLOT_WAIT = "Waiting for a Flame Keeper...",
		BRAZIER_OWNER_FMT = "🔥 %s's Flame",
		BRAZIER_DEFAULT_FMT = "🔥 Brazier #%d",

		ACTIVE_GROUND_PAD = "ACTIVE",
		MAX_GROUND_PAD = "MAX LEVEL",
		FINAL_BTN_COST_FMT = "Cost: %s Light • +%d Dawn Pts",

		ZONE_GATE_LOCKED_FMT = "🔒 %s • Unlock: %d Dawn Pts",
		ZONE_GATE_UNLOCKED_FMT = "✅ %s • Active (x%.2f Light)",

		POP_PASS_ACTIVE = "⚡ x2 Light GamePass Activated!",
		POP_COLOR_ALREADY = "🎨 %s active (%s)",
		POP_COLOR_UNLOCKED = "🎨 Unlocked %s! (%s)",
		POP_ALL_MAXED = "🌅 ALL MAXED! Step on the Dawn Rebirth pad!",
		POP_R1_UNLOCKED = "⛩️ Realm 1 Portal unlocked!",
		POP_NEW_UNLOCK = "✨ Unlocked: %s!",
		POP_WEAPON_BOUGHT = "⚔️ Equipped: %s!",
		POP_DEFENSE_BUILT = "🗼 Built %s (Lv.%d)!",
		POP_DAWN_PERK = "🌅 Upgraded %s!",
		POP_ZONE_UNLOCK = "🏛️ Monument Unlocked: %s!",
		POP_NEED_DAWN_PTS = "Need %d Dawn Points!",
		POP_NEED_FINAL = "Need %s Light for Dawn Rebirth!",
		POP_DAWN_DONE = "🌅 DAWN REBIRTH! +%d Dawn Points!",
		POP_NEED_LIGHT = "Need %s Light!",
		POP_WISP_1 = "✨ Summoned: %s!",
		POP_WISP_5 = "✨ Summoned x%d! Best: %s",
		POP_NEED_3_WISPS = "Need 3 identical Wisps to forge!",
		POP_FORGE_OK = "🌟 Forged Radiant %s!",
		POP_EMBER = "🔥 Wandering Ember! +%s Light",

		POP_SHADOW_KILL = "⚔️ Shadow vanquished! +%s Light",
		POP_SHADOW_RAID = "🌑 Shadows are invading your zone! Defend the Brazier!",
		POP_SHADOW_HIT = "💀 Shadows drained -%s Light from your Brazier!",

		R1_START = "⛩️ Realm 1 Trial started! Touch Brazier II!",
		R1_STEP_FMT = "🔥 Brazier %s lit (+%ds)! Next: %s",
		R1_WIN_FMT = "🌟 REALM 1 COMPLETE! Blessing x%.2f Light active!",
		R1_FAIL = "⏳ Realm 1 Trial expired! Step on Brazier I to retry.",
		R1_BANNER_ACTIVE = "⛩️ REALM 1 TRIAL • Brazier %d/%d • %ds left",
		R1_BANNER_BUFF = "⚡ REALM 1 BLESSING • x%.2f Light (%ds)",
	},

	it = {
		LIGHT_UNIT = "Luce",
		DAWN_PT_UNIT = "Punti Alba",
		POINTS_SUFFIX = "Punti Luce",
		RATE_FMT = "+%s / click (%.2fs)  •  +%s / sec",
		ZONE_BADGE_FMT = "ZONE %d/5 • %s (%d%%)",
		HEAT_ALBA_FMT = "Calore x%.2f • 🌅Alba: %d • Pot. %d/%d%s",

		TRUCE_INITIAL_FMT = "🛡️ TREGUA DELL'ALBA: %d:%02d prima delle Ombre",
		TRUCE_DAWN_FMT = "🌅 TREGUA RINASCITA: %d:%02d prima delle Ombre",

		MY_ZONE_BTN = "🏠 La Mia Zona",
		CHAR_BTN_TITLE = "Personaggio & Fiamma",
		CHAR_BTN_SUB = "Potenziamenti & Alba",
		TUTORIAL_BTN = "📖 Tutorial",
		ROBUX_X2_BTN = "⚡ x2 Luce (Robux)",
		ROBUX_X2_ACTIVE = "✅ x2 Luce Attivo",
		MODAL_TITLE = "🔥 Santuario del Custode & Potenziamenti",
		TURRET_MODAL_TITLE = "🗼 Gestione Torrette",
		WISPS_MODAL_TITLE = "✨ Gestione Spiriti",
		DAILY_MODAL_TITLE = "🎁 Ricompense Giornaliere",
		HUD_TURRETS = "🗼 Torrette",
		HUD_WISPS = "✨ Spiriti",
		HUD_DAILY = "🎁 Ricompense",
		DAILY_COMING_SOON = "Il calendario delle ricompense giornaliere arriverà presto. Le ricompense saranno annunciate qui!",
		DAILY_DAY = "Giorno",
		DAILY_REWARD_SOON = "Ricompensa in arrivo",

		TUTORIAL_HEADER = "🔥 GUIDA DEL CUSTODE",
		TUTORIAL_STEP_FMT = "Slide %d / %d",
		TUTORIAL_PREV = "◀ Indietro",
		TUTORIAL_NEXT = "Avanti ▶",
		TUTORIAL_START = "🔥 Inizia a Giocare!",
		TUTORIAL_CLOSE_DONE = "✔ Chiudi",
		POP_TUTORIAL_DONE = "🛡️ Tutorial completato! Tregua dell'Alba di 3:00 avviata!",

		TUT_1_TITLE = "1. Alimenta il Braciere Centrale",
		TUT_1_BODY = "• Clicca sul tuo Braciere centrale (o premi E / F vicino ad esso) per generare Punti Luce.\n• Cliccando velocemente aumenti il Calore della Fiamma, moltiplicando la Luce ottenuta.\n• Raccogli le Braci Vaganti dorate nel tuo plot per ottenere Luce istantanea.",
		TUT_1_TIP = "💡 Consiglio: Clicca per aumentare il Calore! Dopo un potenziamento dell'Alba, puoi tenere premuto sul Nucleo.",

		TUT_2_TITLE = "2. Albero dei Potenziamenti e Fiamma",
		TUT_2_BODY = "• Apri 'Personaggio & Fiamma' [B] per far crescere l'Albero dei Potenziamenti partendo da Alimenta Fiamma.\n• Comprando il Livello 1 di un nodo sblocchi e riveli i rami collegati, inclusi Colori Fiamma e moltiplicatori.",
		TUT_2_TIP = "💡 Consiglio: Potenzia fino al MAX tutti i nodi dell'albero per sbloccare la Rinascita!",

		TUT_3_TITLE = "3. Difendi il Braciere dalle Ombre",
		TUT_3_BODY = "• Appena chiuderai questo tutorial partirà una Tregua dell'Alba di 3:00.\n• Allo scadere del timer, le Ombre attaccheranno il tuo Braciere rubando Luce.\n• Sali sulle pedane Armi a sinistra del plot per comprarle, oppure usa il pulsante Torrette nella HUD per costruire difese.",
		TUT_3_TIP = "💡 Consiglio: Prendi la Torcia di Brace a terra o costruisci una Torretta prima che scadano i 3:00!",

		TUT_4_TITLE = "4. Spiriti di Luce e Altare Spiritico",
		TUT_4_BODY = "• Sblocca 'Risveglio Spiriti' nell'Albero per attivare l'Altare degli Spiriti nel tuo plot.\n• Sali sulle pedane rotonde Spiriti o usa il pulsante Spiriti nella HUD per evocare compagni orbitanti e forgiarli.\n• Attiva il Portale Regno 1 per affrontare sfide a tempo con bonus temporanei.",
		TUT_4_TIP = "💡 Consiglio: Gli Spiriti più forti vengono equipaggiati automaticamente attorno a te.",

		TUT_5_TITLE = "5. Rinascita dell'Alba e Isole Monumento",
		TUT_5_BODY = "• Porta al MAX tutti i nodi dell'Albero Potenziamenti per attivare la pedana Rinascita dell'Alba dietro il Braciere.\n• La Rinascita azzera Luce e difese in cambio di Punti Alba.\n• Spendi i Punti Alba in benedizioni permanenti e 4 Isole Monumento!",
		TUT_5_TIP = "💡 Consiglio: Ogni Isola Monumento aggiunge un potente moltiplicatore permanente!",

		TAB_CHAR = "Personaggio",
		TAB_DEFENSE = "Difesa",
		TAB_WISPS = "Spiriti",
		TAB_DAWN = "Alba",
		TAB_CODES = "Codici",

		LOCKED_REQ = "🔒 Sblocca prima il potenziamento precedente",
		BTN_MAXED = "MAX",
		BTN_LOCKED = "BLOCCATO",
		BTN_EQUIPPED = "EQUIPAGGIATO",
		BTN_UNLOCKED = "SBLOCCATO",

		DEF_TIP = "🛡️ Costruisci e migliora le difese per proteggere il Braciere dalle Ombre.",
		SEC_STRUCTURES = "🗼 DIFESE DEL PLOT",

		WISPS_LOCKED = "🔒 Sblocca prima 'Risveglio degli Spiriti' nella scheda Personaggio!",
		WISPS_HEADER_FMT = "Spiriti Equipaggiati: %d / %d\nI migliori si equipaggiano in automatico!",
		SUMMON_1_FMT = "Evoca x1\n(%s)",
		SUMMON_5_FMT = "Evoca x5\n(%s)",
		WISP_ROW_FMT = "%s (x%.2f Click • %d%%)\nPosseduti: %d  |  ✨Radiosi: %d",
		FORGE_READY = "✨ Forgia Radioso (3→1)",
		FORGE_NEED_FMT = "Servono 3 (%d/3)",

		SEC_DAWN_PERKS = "🌅 BENEDIZIONI PERMANENTI DELL'ALBA",
		SEC_DAWN_ZONES = "🏝️ ISOLE SANTUARIO DELL'ALBA (MONUMENTI)",
		DAWN_HEADER_FMT = "🌅 Punti Alba: %d  |  Rinascite: %d\n%s",
		DAWN_STATUS_READY = "PRONTO! Sali sulla pedana Rinascita dell'Alba per +%d Punti Alba!",
		DAWN_STATUS_PROG = "Porta al MAX tutti i potenziamenti (%d/%d) per sbloccare la Rinascita (+%d Punti Alba).",
		TREE_PROG_FMT = "🌳 Albero Potenziamenti  •  Sbloccati: %d/%d  •  MAX: %d/%d",
		TREE_HOVER_HINT = "Passa il cursore su un'icona per i dettagli  •  Clicca per potenziare",
		TREE_TIP_CLICK = "Clicca l'icona per potenziare",
		PAD_WEP_EQUIPPED = "✅ EQUIPAGGIATA (Sali per impugnare)",
		PAD_WEP_LOCKED_FMT = "🔒 Serve Rinascita %d",
		PAD_WISP_SHRINE_TITLE = "🔮 ALTARE DEGLI SPIRITI",
		PAD_WISP_1_TITLE = "✨ Evoca Spirito x1",
		PAD_WISP_5_TITLE = "🌟 Evoca Spiriti x5",
		PAD_WISP_LOCKED_DESC = "Sblocca Risveglio Spiriti",
		PAD_WISP_READY_DESC = "Compagni di Luce Orbitanti",
		POP_WEAPON_EQUIPPED = "⚔️ Impugnata: %s!",
		POP_WISPS_LOCKED = "🔒 Sblocca prima 'Risveglio Spiriti' nell'Albero Potenziamenti!",

		CODE_PLACEHOLDER = "Inserisci codice promo...",
		CODE_HINT = "Prova i codici: DAWN2026, FLAME",
		CODE_REDEEM = "RISCATTA",
		CODE_USED = "Codice già riscattato!",
		CODE_INVALID = "Codice promo non valido.",

		VICTORY_TITLE = "🌅 RINASCITA DELL'ALBA COMPLETATA!",
		VICTORY_BODY_FMT = "La tua fiamma è ascesa in una nuova Alba!\n\nGuadagnati: +%d Punti Alba\nPunti Alba Totali: %d\n\nSpendi i Punti Alba in benedizioni permanenti e Isole Monumento!",
		VICTORY_OPEN_DAWN = "Apri Scheda Alba",

		PLOT_OWNER_FMT = "ZONA %d • %s",
		PLOT_RANK_FMT = "Rango: %s",
		PLOT_FREE_FMT = "ZONA %d • LIBERA",
		PLOT_WAIT = "In attesa di un Custode...",
		BRAZIER_OWNER_FMT = "🔥 Fiamma di %s",
		BRAZIER_DEFAULT_FMT = "🔥 Braciere #%d",

		ACTIVE_GROUND_PAD = "ATTIVO",
		MAX_GROUND_PAD = "LIVELLO MAX",
		FINAL_BTN_COST_FMT = "Costo: %s Luce • +%d Punti Alba",

		ZONE_GATE_LOCKED_FMT = "🔒 %s • Sblocca: %d Punti Alba",
		ZONE_GATE_UNLOCKED_FMT = "✅ %s • Attiva (x%.2f Luce)",

		POP_PASS_ACTIVE = "⚡ GamePass x2 Luce Attivato!",
		POP_COLOR_ALREADY = "🎨 %s attiva (%s)",
		POP_COLOR_UNLOCKED = "🎨 Sbloccata %s! (%s)",
		POP_ALL_MAXED = "🌅 TUTTO AL MAX! Sali sulla pedana Rinascita dell'Alba!",
		POP_R1_UNLOCKED = "⛩️ Portale Regno 1 sbloccato!",
		POP_NEW_UNLOCK = "✨ Sbloccato: %s!",
		POP_WEAPON_BOUGHT = "⚔️ Equipaggiata: %s!",
		POP_DEFENSE_BUILT = "🗼 Costruita %s (Lv.%d)!",
		POP_DAWN_PERK = "🌅 Potenziata %s!",
		POP_ZONE_UNLOCK = "🏛️ Monumento Sbloccato: %s!",
		POP_NEED_DAWN_PTS = "Servono %d Punti Alba!",
		POP_NEED_FINAL = "Servono %s Luce per la Rinascita dell'Alba!",
		POP_DAWN_DONE = "🌅 RINASCITA DELL'ALBA! +%d Punti Alba!",
		POP_NEED_LIGHT = "Servono %s Luce!",
		POP_WISP_1 = "✨ Evocato: %s!",
		POP_WISP_5 = "✨ Evocati x%d! Migliore: %s",
		POP_NEED_3_WISPS = "Servono 3 Spiriti identici per forgiare!",
		POP_FORGE_OK = "🌟 Forgiato %s Radioso!",
		POP_EMBER = "🔥 Brace Vagante! +%s Luce",

		POP_SHADOW_KILL = "⚔️ Ombra sconfitta! +%s Luce",
		POP_SHADOW_RAID = "🌑 Le Ombre stanno invadendo la tua zona! Difendi il Braciere!",
		POP_SHADOW_HIT = "💀 Le Ombre hanno drenato -%s Luce dal Braciere!",

		R1_START = "⛩️ Prova Regno 1 avviata! Tocca il Braciere II!",
		R1_STEP_FMT = "🔥 Braciere %s acceso (+%ds)! Prossimo: %s",
		R1_WIN_FMT = "🌟 REGNO 1 COMPLETATO! Benedizione x%.2f Luce attiva!",
		R1_FAIL = "⏳ Tempo scaduto per Regno 1! Tocca il Braciere I per riprovare.",
		R1_BANNER_ACTIVE = "⛩️ PROVA REGNO 1 • Braciere %d/%d • %ds rimasti",
		R1_BANNER_BUFF = "⚡ BENEDIZIONE REGNO 1 • x%.2f Luce (%ds)",
	},
}

function Localization.T(lang, key, ...)
	local tbl = STRINGS[lang] or STRINGS.en
	local raw = tbl[key] or STRINGS.en[key] or key
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, raw, ...)
		if ok then return formatted end
	end
	return raw
end

function Localization.Pick(lang, enText, itText)
	if lang == "it" and itText and itText ~= "" then
		return itText
	end
	return enText or itText or ""
end

return Localization