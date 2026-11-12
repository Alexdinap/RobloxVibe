--!nonstrict
--[[
	GameEngine - tutta l'economia del gioco vive qui, sul server.

	Il client e' puramente estetico: manda solo richieste ("voglio comprare X")
	che vengono ricalcolate e validate qui. Nessun numero che arriva dal client
	viene mai usato per aumentare Watt, Plasma o Materia Oscura.

	Contenuti:
	  - creazione automatica dei RemoteEvent / RemoteFunction
	  - DataStore con pcall (funziona anche in locale senza API attive)
	  - guadagno offline calcolato con os.time()
	  - loop principale a 0.1s: Watt, Plasma, Auto-Buyer, leaderstats
	  - acquisto continuo mentre si resta sopra un pulsante (0.15s)
	  - validazione nodi del muro e Collasso Quantistico (prestige)
	  - Sfere di Sovraccarico: boost x2 per 30s
	  - classifica globale su OrderedDataStore (Top 10)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BigNum = require(Shared:WaitForChild("BigNum"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

--------------------------------------------------------------------------------
-- REMOTES (creati se non esistono)
--------------------------------------------------------------------------------

local REMOTES_FOLDER = "QuantumCoreRemotes"

local function cartellaRemotes()
	local esistente = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER)
	if esistente then
		return esistente
	end
	local cartella = Instance.new("Folder")
	cartella.Name = REMOTES_FOLDER
	cartella.Parent = ReplicatedStorage
	return cartella
end

local function creaRemote(nome, classe)
	local cartella = cartellaRemotes()
	local esistente = cartella:FindFirstChild(nome)
	if esistente and esistente:IsA(classe) then
		return esistente
	end
	if esistente then
		esistente:Destroy()
	end
	local nuovo = Instance.new(classe)
	nuovo.Name = nome
	nuovo.Parent = cartella
	return nuovo
end

local Remotes = {
	State = creaRemote("State", "RemoteEvent"),
	Feedback = creaRemote("Feedback", "RemoteEvent"),
	Offline = creaRemote("Offline", "RemoteEvent"),
	GetProfile = creaRemote("GetProfile", "RemoteFunction"),
	Purchase = creaRemote("Purchase", "RemoteFunction"),
	BuyNode = creaRemote("BuyNode", "RemoteFunction"),
	Prestige = creaRemote("Prestige", "RemoteFunction"),
}

--------------------------------------------------------------------------------
-- DATASTORE (sempre protetto da pcall: in locale puo' non essere disponibile)
--------------------------------------------------------------------------------

local function creaDataStore(nome, ordinato)
	local ok, risultato = pcall(function()
		if ordinato then
			return DataStoreService:GetOrderedDataStore(nome)
		end
		return DataStoreService:GetDataStore(nome)
	end)
	if ok then
		return risultato
	end
	warn("[Quantum Core] DataStore '" .. nome .. "' non disponibile: si gioca in memoria. " .. tostring(risultato))
	return nil
end

local storeProfili = creaDataStore(GameConfig.Meta.DataStoreName, false)
local storeClassifica = creaDataStore(GameConfig.Meta.LeaderboardStoreName, true)

--------------------------------------------------------------------------------
-- TABELLE DI LOOKUP
--------------------------------------------------------------------------------

local PULSANTI_PER_ID = {}
for _, pulsante in GameConfig.Buttons do
	PULSANTI_PER_ID[pulsante.id] = pulsante
end

local NODI_PER_ID = {}
for _, nodo in GameConfig.Nodes do
	NODI_PER_ID[nodo.id] = nodo
end

local NODO_PRESTIGIO = NODI_PER_ID[GameConfig.Prestige.NodeId]

--------------------------------------------------------------------------------
-- PROFILI
--------------------------------------------------------------------------------

local profili = {} -- [userId] = profilo
local ultimiAcquisti = {} -- [userId] = os.clock dell'ultimo acquisto

local rng = Random.new()

local function numeroSicuro(valore)
	if type(valore) ~= "number" or valore ~= valore then
		return 0
	end
	if valore < 0 then
		return 0
	end
	return BigNum.clamp(valore)
end

local function nuovoProfilo()
	return {
		watt = GameConfig.Economy.StartingWatt,
		plasma = 0,
		materiaOscura = 0,
		statisticheWatt = 0, -- Watt totali guadagnati: base della classifica
		buttons = {},
		nodes = {},
		lastSeen = os.time(),
		boostUntil = 0,
		prestigi = 0,
	}
end

-- Accetta dal DataStore solo cio' che conosciamo: niente ID inventati.
local function sanificaProfilo(dati)
	local profilo = nuovoProfilo()
	if type(dati) ~= "table" then
		return profilo
	end

	profilo.watt = numeroSicuro(dati.watt)
	profilo.plasma = numeroSicuro(dati.plasma)
	profilo.materiaOscura = math.floor(numeroSicuro(dati.materiaOscura))
	profilo.statisticheWatt = numeroSicuro(dati.statisticheWatt)
	profilo.boostUntil = numeroSicuro(dati.boostUntil)
	profilo.prestigi = math.floor(numeroSicuro(dati.prestigi))

	local lastSeen = math.floor(numeroSicuro(dati.lastSeen))
	profilo.lastSeen = lastSeen > 0 and lastSeen or os.time()

	if type(dati.buttons) == "table" then
		for id, livello in pairs(dati.buttons) do
			if PULSANTI_PER_ID[id] and type(livello) == "number" then
				profilo.buttons[id] = math.clamp(math.floor(livello), 0, GameConfig.Economy.MaxLevels)
			end
		end
	end

	if type(dati.nodes) == "table" then
		for id, sbloccato in pairs(dati.nodes) do
			if NODI_PER_ID[id] and sbloccato == true then
				profilo.nodes[id] = true
			end
		end
	end

	return profilo
end

--------------------------------------------------------------------------------
-- CALCOLI ECONOMICI
--------------------------------------------------------------------------------

-- Ricalcola da zero produzione e moltiplicatori: nessun valore "accumulato" fidato.
local function calcolaStatistiche(profilo)
	local produzioneBase = 0
	local moltiplicatorePulsanti = 1

	for _, pulsante in GameConfig.Buttons do
		local livello = profilo.buttons[pulsante.id] or 0
		if livello > 0 then
			if pulsante.effectType == "WattPerSecond" then
				produzioneBase += pulsante.value * livello
			elseif pulsante.effectType == "WattMultiplier" then
				moltiplicatorePulsanti *= pulsante.value ^ livello
			end
		end
	end

	local potenzaGeneratori = 1
	local moltiplicatoreGlobale = 1
	local riduzioneCosto = 1
	local frequenzaBonus = 1
	local plasmaAdditivo = 0
	local moltiplicatorePlasma = 1
	local autoBuy = 0

	for _, nodo in GameConfig.Nodes do
		if profilo.nodes[nodo.id] then
			for _, effetto in nodo.effects do
				local tipo = effetto.kind
				local valore = effetto.value
				if tipo == "GeneratorPower" then
					potenzaGeneratori *= valore
				elseif tipo == "CostReduction" then
					riduzioneCosto *= valore
				elseif tipo == "GlobalWatt" then
					moltiplicatoreGlobale *= valore
				elseif tipo == "BonusFrequency" then
					frequenzaBonus *= valore
				elseif tipo == "PlasmaRate" then
					plasmaAdditivo += valore
				elseif tipo == "PlasmaMultiplier" then
					moltiplicatorePlasma *= valore
				elseif tipo == "AutoBuyLevels" then
					autoBuy = math.max(autoBuy, valore)
				end
			end
		end
	end

	local moltiplicatorePrestigio = math.min(
		GameConfig.Prestige.MultiplierPerDarkMatter ^ profilo.materiaOscura,
		GameConfig.Prestige.MaxMultiplier
	)

	local wattPerSecondo = produzioneBase
		* moltiplicatorePulsanti
		* potenzaGeneratori
		* moltiplicatoreGlobale
		* moltiplicatorePrestigio

	return {
		wattPerSecondo = BigNum.clamp(wattPerSecondo),
		plasmaPerSecondo = plasmaAdditivo * moltiplicatorePlasma,
		riduzioneCosto = riduzioneCosto,
		frequenzaBonus = frequenzaBonus,
		autoBuy = autoBuy,
		moltiplicatorePrestigio = moltiplicatorePrestigio,
	}
end

local function costoPulsante(profilo, pulsante, riduzioneCosto)
	local livello = profilo.buttons[pulsante.id] or 0
	return BigNum.clamp(pulsante.baseCost * (pulsante.costMultiplier ^ livello) * riduzioneCosto)
end

local function guadagnoPrestigio(watt)
	if watt < GameConfig.Prestige.RequiredWatt then
		return 0
	end
	return math.max(1, math.floor((watt / GameConfig.Prestige.RequiredWatt) ^ GameConfig.Prestige.GainExponent))
end

local function prestigioPronto(profilo)
	if not NODO_PRESTIGIO then
		return false
	end
	for _, requisito in NODO_PRESTIGIO.requires do
		if not profilo.nodes[requisito] then
			return false
		end
	end
	return profilo.watt >= GameConfig.Prestige.RequiredWatt
end

--------------------------------------------------------------------------------
-- STATO INVIATO AL CLIENT
--------------------------------------------------------------------------------

local function creaPayload(player, profilo)
	local stats = calcolaStatistiche(profilo)

	local costi = {}
	for _, pulsante in GameConfig.Buttons do
		costi[pulsante.id] = costoPulsante(profilo, pulsante, stats.riduzioneCosto)
	end

	local pulsanti = {}
	for id, livello in pairs(profilo.buttons) do
		pulsanti[id] = livello
	end

	local nodi = {}
	for id in pairs(profilo.nodes) do
		nodi[id] = true
	end

	return {
		watt = profilo.watt,
		wattPerSecondo = stats.wattPerSecondo,
		plasma = profilo.plasma,
		plasmaPerSecondo = stats.plasmaPerSecondo,
		materiaOscura = profilo.materiaOscura,
		boostUntil = profilo.boostUntil,
		serverTime = os.time(),
		buttons = pulsanti,
		nodes = nodi,
		costs = costi,
		autoBuy = stats.autoBuy,
		bonus = profilo._bonusSpot,
		prestige = {
			reward = guadagnoPrestigio(profilo.watt),
			ready = prestigioPronto(profilo),
			required = GameConfig.Prestige.RequiredWatt,
		},
		offline = profilo._reportOffline,
	}
end

local function inviaStato(player, profilo)
	local payload = creaPayload(player, profilo)

	-- Il report offline viaggia una volta sola.
	if profilo._reportOffline then
		Remotes.Offline:FireClient(player, profilo._reportOffline)
		profilo._reportOffline = nil
		payload.offline = nil
	end

	Remotes.State:FireClient(player, payload)
end

--------------------------------------------------------------------------------
-- LEADERSTATS
--------------------------------------------------------------------------------

local function creaLeaderstats(player)
	local cartella = Instance.new("Folder")
	cartella.Name = "leaderstats"

	local watt = Instance.new("IntValue")
	watt.Name = "Watt"
	watt.Value = 0
	watt.Parent = cartella

	local materia = Instance.new("IntValue")
	materia.Name = "MateriaOscura"
	materia.Value = 0
	materia.Parent = cartella

	cartella.Parent = player
	return watt, materia
end

--------------------------------------------------------------------------------
-- CARICAMENTO / SALVATAGGIO
--------------------------------------------------------------------------------

local KEY_PREFIX = "player_"

local function caricaProfilo(player)
	local profilo

	if storeProfili then
		local ok, dati = pcall(function()
			return storeProfili:GetAsync(KEY_PREFIX .. player.UserId)
		end)
		if ok then
			profilo = sanificaProfilo(dati)
		else
			warn("[Quantum Core] Caricamento fallito per " .. player.Name .. ": " .. tostring(dati))
			profilo = nuovoProfilo()
		end
	else
		profilo = nuovoProfilo()
	end

	-- Guadagno offline: tempo trascorso * produzione * efficienza offline.
	local trascorso = math.clamp(os.time() - profilo.lastSeen, 0, GameConfig.Economy.OfflineMaxSeconds)
	if trascorso >= 60 then
		local stats = calcolaStatistiche(profilo)
		local guadagno = stats.wattPerSecondo * trascorso * GameConfig.Economy.OfflineEfficiency
		if guadagno > 0 then
			profilo.watt += guadagno
			profilo.statisticheWatt += guadagno
			profilo._reportOffline = {
				secondi = trascorso,
				watt = guadagno,
			}
		end
	end

	profilo.lastSeen = os.time()
	profilo._autoBuyTimer = 0
	profilo._prossimoBonus = os.clock() + GameConfig.Economy.BonusInterval
	profilo._bonusSpot = nil
	profilo._bonusBorn = 0

	return profilo
end

local function salvaProfilo(player, profilo)
	if not profilo then
		return
	end
	profilo.lastSeen = os.time()

	if not storeProfili then
		return
	end

	local dati = {
		watt = profilo.watt,
		plasma = profilo.plasma,
		materiaOscura = profilo.materiaOscura,
		statisticheWatt = profilo.statisticheWatt,
		buttons = profilo.buttons,
		nodes = profilo.nodes,
		lastSeen = profilo.lastSeen,
		boostUntil = profilo.boostUntil,
		prestigi = profilo.prestigi,
	}

	local ok, errore = pcall(function()
		storeProfili:SetAsync(KEY_PREFIX .. player.UserId, dati)
	end)
	if not ok then
		warn("[Quantum Core] Salvataggio fallito per " .. player.Name .. ": " .. tostring(errore))
	end

	if storeClassifica then
		pcall(function()
			storeClassifica:SetAsync(player.UserId, math.floor(profilo.statisticheWatt))
		end)
	end
end

--------------------------------------------------------------------------------
-- CLASSIFICA GLOBALE (SurfaceGui sul muro laterale)
--------------------------------------------------------------------------------

local cacheNomi = {}

local function nomeDaUserId(userId)
	local cached = cacheNomi[userId]
	if cached then
		return cached
	end
	local ok, nome = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nome = (ok and nome) or ("Player" .. tostring(userId))
	cacheNomi[userId] = nome
	return nome
end

local function sfondoClassifica()
	local mappa = Workspace:FindFirstChild("QuantumCoreMap")
	local pannello = mappa and mappa:FindFirstChild("LeaderboardBoard")
	local gui = pannello and pannello:FindFirstChild("LeaderboardGui")
	return gui and gui:FindFirstChild("Sfondo")
end

local function scriviRighe(sfondo, voci)
	for indice = 1, GameConfig.Meta.MaxLeaderboardEntries do
		local etichetta = sfondo:FindFirstChild("Row" .. indice)
		if etichetta then
			local voce = voci[indice]
			if voce then
				etichetta.Text = string.format("%d. %s - %s", indice, voce.nome, BigNum.format(voce.valore))
			else
				etichetta.Text = string.format("%d. ---", indice)
			end
		end
	end
end

-- Fallback usato quando OrderedDataStore non e' disponibile (es. Studio locale).
local function classificaDaMemoria(sfondo)
	local voci = {}
	for _, player in Players:GetPlayers() do
		local profilo = profili[player.UserId]
		if profilo then
			table.insert(voci, { nome = player.DisplayName, valore = profilo.statisticheWatt })
		end
	end
	table.sort(voci, function(a, b)
		return a.valore > b.valore
	end)
	scriviRighe(sfondo, voci)
end

local function aggiornaClassifica()
	local sfondo = sfondoClassifica()
	if not sfondo then
		return
	end

	if not storeClassifica then
		classificaDaMemoria(sfondo)
		return
	end

	local ok, pagine = pcall(function()
		return storeClassifica:GetSortedAsync(false, GameConfig.Meta.MaxLeaderboardEntries)
	end)
	if not ok or not pagine then
		classificaDaMemoria(sfondo)
		return
	end

	local okPagina, pagina = pcall(function()
		return pagine:GetCurrentPage()
	end)
	if not okPagina or not pagina then
		classificaDaMemoria(sfondo)
		return
	end

	local voci = {}
	for _, elemento in pagina do
		table.insert(voci, {
			nome = nomeDaUserId(elemento.key),
			valore = elemento.value,
		})
	end
	scriviRighe(sfondo, voci)
end

--------------------------------------------------------------------------------
-- AZIONI DI GIOCO (tutte validate lato server)
--------------------------------------------------------------------------------

-- Cerca il pulsante su cui il giocatore e' davvero in piedi (posizione del server).
local function padSottoGiocatore(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local posizione = root.Position
	if math.abs(posizione.Y - GameConfig.Map.PlatformTopY) > 10 then
		return nil
	end

	for _, pulsante in GameConfig.Buttons do
		local pad = pulsante.pos
		local dx = posizione.X - pad.X
		local dz = posizione.Z - pad.Z
		if math.sqrt(dx * dx + dz * dz) <= GameConfig.Map.ButtonDetectRadius then
			return pulsante
		end
	end

	return nil
end

local function acquistaPulsante(player, profilo, pulsante, stats)
	stats = stats or calcolaStatistiche(profilo)

	local livello = profilo.buttons[pulsante.id] or 0
	if livello >= GameConfig.Economy.MaxLevels then
		return false, "Livello massimo raggiunto"
	end

	local costo = costoPulsante(profilo, pulsante, stats.riduzioneCosto)
	if profilo.watt < costo then
		return false, "Watt insufficienti"
	end

	profilo.watt -= costo
	profilo.buttons[pulsante.id] = livello + 1

	Remotes.Feedback:FireClient(player, {
		kind = "Purchase",
		buttonId = pulsante.id,
		level = livello + 1,
	})

	return true
end

local function acquistaNodo(player, profilo, nodoId)
	local nodo = NODI_PER_ID[nodoId]
	if not nodo then
		return false, "Nodo inesistente"
	end

	-- Il nodo finale non si "compra": esegue il prestige.
	if nodo.isPrestige then
		return false, "Usa il pulsante Collasso Quantistico"
	end

	if profilo.nodes[nodo.id] then
		return false, "Nodo gia' sbloccato"
	end

	for _, requisito in nodo.requires do
		if not profilo.nodes[requisito] then
			return false, "Prerequisiti mancanti"
		end
	end

	local saldo = nodo.currency == "Plasma" and profilo.plasma or profilo.watt
	if saldo < nodo.cost then
		return false, "Risorse insufficienti"
	end

	if nodo.currency == "Plasma" then
		profilo.plasma -= nodo.cost
	else
		profilo.watt -= nodo.cost
	end

	profilo.nodes[nodo.id] = true
	Remotes.Feedback:FireClient(player, { kind = "Node", nodeId = nodo.id })

	return true, "Sbloccato: " .. nodo.nome
end

local function eseguiPrestigio(player, profilo)
	if not prestigioPronto(profilo) then
		return false, "Servono 1e15 Watt e il nodo Singolarita'"
	end

	local guadagno = guadagnoPrestigio(profilo.watt)
	if guadagno <= 0 then
		return false, "Watt insufficienti"
	end

	profilo.materiaOscura += guadagno
	profilo.prestigi += 1
	profilo.watt = 0
	profilo.plasma = 0
	profilo.boostUntil = 0
	profilo._bonusSpot = nil
	profilo._prossimoBonus = os.clock() + GameConfig.Economy.BonusInterval

	Remotes.Feedback:FireClient(player, { kind = "Prestige", darkMatter = guadagno })

	return true, string.format("Collasso completato: +%d Materia Oscura", guadagno)
end

--------------------------------------------------------------------------------
-- SFERE DI SOVRACCARICO (per giocatore, cosi' la frequenza dei nodi ha senso)
--------------------------------------------------------------------------------

local function aggiornaSferaBonus(player, profilo, stats, adesso)
	local intervallo = GameConfig.Economy.BonusInterval / math.max(stats.frequenzaBonus, 0.05)
	profilo._prossimoBonus = profilo._prossimoBonus or (adesso + GameConfig.Economy.BonusInterval)

	if profilo._bonusSpot then
		-- Scaduta: sparisce e si riprogramma.
		if adesso - profilo._bonusBorn > GameConfig.Economy.BonusLifetime then
			profilo._bonusSpot = nil
			profilo._prossimoBonus = adesso + intervallo
			return
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - profilo._bonusSpot).Magnitude <= GameConfig.Economy.BonusCollectRadius then
			profilo._bonusSpot = nil
			profilo._prossimoBonus = adesso + intervallo
			profilo.boostUntil = os.time() + GameConfig.Economy.BonusDuration
			Remotes.Feedback:FireClient(player, { kind = "Bonus" })
		end
	elseif adesso >= profilo._prossimoBonus then
		local minimo = GameConfig.Map.BonusAreaMin
		local massimo = GameConfig.Map.BonusAreaMax
		profilo._bonusSpot = Vector3.new(
			rng:NextNumber(minimo.X, massimo.X),
			GameConfig.Map.PlatformTopY + GameConfig.Map.BonusHeight,
			rng:NextNumber(minimo.Z, massimo.Z)
		)
		profilo._bonusBorn = adesso
		Remotes.Feedback:FireClient(player, { kind = "BonusSpawn" })
	end
end

--------------------------------------------------------------------------------
-- AGGIORNAMENTO DI UN GIOCATORE (chiamato ogni 0.1s)
--------------------------------------------------------------------------------

local function aggiornaGiocatore(player, profilo, dt, adesso)
	local stats = calcolaStatistiche(profilo)
	local boostAttivo = profilo.boostUntil > os.time()
	local moltiplicatoreBoost = boostAttivo and GameConfig.Economy.BonusMultiplier or 1

	local guadagno = stats.wattPerSecondo * moltiplicatoreBoost * dt
	profilo.watt += guadagno
	profilo.statisticheWatt += guadagno
	profilo.plasma += stats.plasmaPerSecondo * dt

	-- leaderstats (IntValue: limitiamo per evitare overflow)
	if profilo._leaderstatsWatt then
		profilo._leaderstatsWatt.Value = math.clamp(math.floor(profilo.watt), 0, 9e18)
	end
	if profilo._leaderstatsMateria then
		profilo._leaderstatsMateria.Value = math.clamp(profilo.materiaOscura, 0, 9e18)
	end

	-- Auto-Buyer: comprano livelli gratis, senza consumare Watt.
	if stats.autoBuy > 0 then
		profilo._autoBuyTimer = (profilo._autoBuyTimer or 0) + dt
		if profilo._autoBuyTimer >= GameConfig.Economy.AutoBuyInterval then
			profilo._autoBuyTimer -= GameConfig.Economy.AutoBuyInterval
			for indice = 1, math.min(stats.autoBuy, #GameConfig.Buttons) do
				local pulsante = GameConfig.Buttons[indice]
				local livello = profilo.buttons[pulsante.id] or 0
				if livello < GameConfig.Economy.MaxLevels then
					profilo.buttons[pulsante.id] = livello + 1
				end
			end
			Remotes.Feedback:FireClient(player, { kind = "AutoBuy" })
		end
	end

	-- Acquisto continuo: basta restare fermi sul pad.
	local pulsante = padSottoGiocatore(player)
	if pulsante then
		local ultimo = ultimiAcquisti[player.UserId] or 0
		if adesso - ultimo >= GameConfig.Economy.PurchaseCooldown then
			ultimiAcquisti[player.UserId] = adesso
			acquistaPulsante(player, profilo, pulsante, stats)
		end
	end

	aggiornaSferaBonus(player, profilo, stats, adesso)
end

--------------------------------------------------------------------------------
-- LOOP PRINCIPALE
--------------------------------------------------------------------------------

task.spawn(function()
	local ultimoTick = os.clock()
	local accumulatoreSync = 0
	local accumulatoreSalvataggio = 0
	local accumulatoreClassifica = GameConfig.Economy.LeaderboardInterval

	while true do
		local adesso = os.clock()
		local dt = math.clamp(adesso - ultimoTick, 0, 1) -- tetto anti-freeze
		ultimoTick = adesso

		for _, player in Players:GetPlayers() do
			local profilo = profili[player.UserId]
			if profilo then
				aggiornaGiocatore(player, profilo, dt, adesso)
			end
		end

		accumulatoreSync += dt
		if accumulatoreSync >= GameConfig.Economy.SyncInterval then
			accumulatoreSync = 0
			for _, player in Players:GetPlayers() do
				local profilo = profili[player.UserId]
				if profilo then
					inviaStato(player, profilo)
				end
			end
		end

		accumulatoreSalvataggio += dt
		if accumulatoreSalvataggio >= GameConfig.Economy.SaveInterval then
			accumulatoreSalvataggio = 0
			for _, player in Players:GetPlayers() do
				local profilo = profili[player.UserId]
				if profilo then
					salvaProfilo(player, profilo)
				end
			end
		end

		accumulatoreClassifica += dt
		if accumulatoreClassifica >= GameConfig.Economy.LeaderboardInterval then
			accumulatoreClassifica = 0
			aggiornaClassifica()
		end

		task.wait(GameConfig.Economy.TickInterval)
	end
end)

--------------------------------------------------------------------------------
-- EVENTI GIOCATORE
--------------------------------------------------------------------------------

local function onPlayerAdded(player)
	local profilo = caricaProfilo(player)
	profili[player.UserId] = profilo
	profilo._leaderstatsWatt, profilo._leaderstatsMateria = creaLeaderstats(player)

	-- Stato iniziale (il client lo richiede anche con GetProfile come backup).
	task.defer(function()
		if player.Parent then
			inviaStato(player, profilo)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profilo = profili[player.UserId]
	if profilo then
		salvaProfilo(player, profilo)
	end
	profili[player.UserId] = nil
	ultimiAcquisti[player.UserId] = nil
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

--------------------------------------------------------------------------------
-- HANDLER DELLE REMOTEFUNCTION
--------------------------------------------------------------------------------

Remotes.GetProfile.OnServerInvoke = function(player)
	local profilo = profili[player.UserId]
	if not profilo then
		return nil
	end
	local payload = creaPayload(player, profilo)
	-- Il report offline viaggia una volta sola (qui o sul RemoteEvent Offline).
	profilo._reportOffline = nil
	return payload
end

Remotes.Purchase.OnServerInvoke = function(player, buttonId)
	local profilo = profili[player.UserId]
	if not profilo then
		return false, "Profilo non caricato"
	end
	if type(buttonId) ~= "string" then
		return false, "Richiesta non valida"
	end

	local pulsante = PULSANTI_PER_ID[buttonId]
	if not pulsante then
		return false, "Pulsante inesistente"
	end

	-- Anti-exploit: deve essere fisicamente sopra il pad, e non troppo veloce.
	if padSottoGiocatore(player) ~= pulsante then
		return false, "Devi stare sopra il pulsante"
	end

	local adesso = os.clock()
	local ultimo = ultimiAcquisti[player.UserId] or 0
	if adesso - ultimo < GameConfig.Economy.PurchaseCooldown * 0.9 then
		return false, "Troppo veloce"
	end
	ultimiAcquisti[player.UserId] = adesso

	return acquistaPulsante(player, profilo, pulsante)
end

Remotes.BuyNode.OnServerInvoke = function(player, nodeId)
	local profilo = profili[player.UserId]
	if not profilo then
		return false, "Profilo non caricato"
	end
	if type(nodeId) ~= "string" then
		return false, "Richiesta non valida"
	end

	local nodo = NODI_PER_ID[nodeId]
	if nodo and nodo.isPrestige then
		return eseguiPrestigio(player, profilo)
	end

	local ok, messaggio = acquistaNodo(player, profilo, nodeId)
	inviaStato(player, profilo)
	return ok, messaggio
end

Remotes.Prestige.OnServerInvoke = function(player)
	local profilo = profili[player.UserId]
	if not profilo then
		return false, "Profilo non caricato"
	end
	local ok, messaggio = eseguiPrestigio(player, profilo)
	inviaStato(player, profilo)
	return ok, messaggio
end

--------------------------------------------------------------------------------
-- SALVATAGGIO ALLA CHIUSURA DEL SERVER
--------------------------------------------------------------------------------

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		local profilo = profili[player.UserId]
		if profilo then
			salvaProfilo(player, profilo)
		end
	end
	task.wait(2)
end)

aggiornaClassifica()
print("[Quantum Core] GameEngine avviato. Nodi: " .. #GameConfig.Nodes .. ", pulsanti: " .. #GameConfig.Buttons)
