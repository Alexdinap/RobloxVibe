--!nonstrict
--[[
	ClientEffects - tutto cio' che il giocatore vede e sente.

	Il client NON calcola economia: riceve lo stato dal server ogni 0.2s e lo
	disegna. Le uniche cose "locali" sono estetiche:
	  - HUD (Watt, Watt/s, Plasma, Materia Oscura, timer boost, popup offline)
	  - Upgrade Tree sul muro: SurfaceGui per-giocatore agganciata al muro
	    (ogni giocatore ha i suoi sblocchi, quindi non puo' essere lato server)
	  - BillboardGui sopra i 6 pulsanti con livello e costo formattato
	  - evoluzione del Quantum Core (dimensione, colore, rotazione, anelli)
	  - sfere di sovraccarico e aura di Materia Oscura
	  - juice: suono con pitch crescente, tween sui pad, testi "+Watt"
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BigNum = require(Shared:WaitForChild("BigNum"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local THEME = GameConfig.Theme
local TESTI = GameConfig.Testi
local MAP = GameConfig.Map

--------------------------------------------------------------------------------
-- REMOTES
--------------------------------------------------------------------------------

local cartellaRemotes = ReplicatedStorage:WaitForChild("QuantumCoreRemotes")
local StateRemote = cartellaRemotes:WaitForChild("State")
local FeedbackRemote = cartellaRemotes:WaitForChild("Feedback")
local OfflineRemote = cartellaRemotes:WaitForChild("Offline")
local GetProfileRemote = cartellaRemotes:WaitForChild("GetProfile")
local BuyNodeRemote = cartellaRemotes:WaitForChild("BuyNode")
local PrestigeRemote = cartellaRemotes:WaitForChild("Prestige")

--------------------------------------------------------------------------------
-- STATO LOCALE
--------------------------------------------------------------------------------

local stato = {
	watt = 0,
	wattPerSecondo = 0,
	plasma = 0,
	plasmaPerSecondo = 0,
	materiaOscura = 0,
	boostUntil = 0,
	serverTime = os.time(),
	buttons = {},
	nodes = {},
	costs = {},
	autoBuy = 0,
	bonus = nil,
	prestige = { reward = 0, ready = false, required = GameConfig.Prestige.RequiredWatt },
}

local nodiPerId = {}
for _, nodo in GameConfig.Nodes do
	nodiPerId[nodo.id] = nodo
end

--------------------------------------------------------------------------------
-- HELPER UI
--------------------------------------------------------------------------------

local function angoli(istanza, raggio)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, raggio)
	corner.Parent = istanza
	return corner
end

local function bordo(istanza, colore, spessore, trasparenza)
	local stroke = Instance.new("UIStroke")
	stroke.Color = colore or THEME.Bordo
	stroke.Thickness = spessore or 1.5
	stroke.Transparency = trasparenza or 0.35
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = istanza
	return stroke
end

local function pannello(genitore, nome, dimensione, posizione, ancoraggio)
	local frame = Instance.new("Frame")
	frame.Name = nome
	frame.Size = dimensione
	frame.Position = posizione
	frame.AnchorPoint = ancoraggio or Vector2.new(0, 0)
	frame.BackgroundColor3 = THEME.Pannello
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = genitore
	angoli(frame, 12)
	bordo(frame, THEME.Bordo, 1.5, 0.4)
	return frame
end

local function etichetta(genitore, nome, testo, dimensione, posizione, testoSize, colore, grassetto)
	local label = Instance.new("TextLabel")
	label.Name = nome
	label.Size = dimensione
	label.Position = posizione
	label.BackgroundTransparency = 1
	label.Font = grassetto and Enum.Font.GothamBold or Enum.Font.GothamMedium
	label.Text = testo
	label.TextColor3 = colore or THEME.Testo
	label.TextSize = testoSize or 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = genitore
	return label
end

--------------------------------------------------------------------------------
-- HUD
--------------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "QuantumCoreHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local pannelloRisorse = pannello(gui, "Risorse", UDim2.fromOffset(340, 166), UDim2.fromOffset(16, 16))

etichetta(pannelloRisorse, "TitoloWatt", TESTI.HudWatt, UDim2.fromOffset(150, 16), UDim2.fromOffset(14, 10), 12, THEME["Testo attenuato"], true)
local valoreWatt = etichetta(pannelloRisorse, "ValoreWatt", "0", UDim2.fromOffset(300, 40), UDim2.fromOffset(14, 26), 34, THEME.Accento, true)
local rateWatt = etichetta(pannelloRisorse, "RateWatt", "0/s", UDim2.fromOffset(300, 18), UDim2.fromOffset(14, 68), 14, THEME["Testo attenuato"])

local divisore = Instance.new("Frame")
divisore.Size = UDim2.new(1, -28, 0, 1)
divisore.Position = UDim2.fromOffset(14, 92)
divisore.BackgroundColor3 = THEME.Bordo
divisore.BackgroundTransparency = 0.5
divisore.BorderSizePixel = 0
divisore.Parent = pannelloRisorse

etichetta(pannelloRisorse, "TitoloPlasma", TESTI.HudPlasma, UDim2.fromOffset(90, 20), UDim2.fromOffset(14, 102), 12, THEME["Testo attenuato"], true)
local valorePlasma = etichetta(pannelloRisorse, "ValorePlasma", "0", UDim2.fromOffset(200, 24), UDim2.fromOffset(112, 100), 20, THEME.AccentoSecondario, true)
valorePlasma.TextXAlignment = Enum.TextXAlignment.Right

etichetta(pannelloRisorse, "TitoloMateria", TESTI.HudMateriaOscura, UDim2.fromOffset(160, 20), UDim2.fromOffset(14, 130), 12, THEME["Testo attenuato"], true)
local valoreMateria = etichetta(pannelloRisorse, "ValoreMateria", "0", UDim2.fromOffset(140, 24), UDim2.fromOffset(172, 128), 20, THEME.MateriaOscura, true)
valoreMateria.TextXAlignment = Enum.TextXAlignment.Right

-- Pill del boost attivo.
local pillolaBoost = pannello(gui, "Boost", UDim2.fromOffset(270, 46), UDim2.new(0.5, 0, 0, 16), Vector2.new(0.5, 0))
pillolaBoost.BackgroundColor3 = Color3.fromRGB(40, 30, 8)
bordo(pillolaBoost, THEME.Oro, 2, 0.2)
local testoBoost = etichetta(pillolaBoost, "Testo", TESTI.HudBoost .. "  -  0:00", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 17, THEME.Oro, true)
testoBoost.TextXAlignment = Enum.TextXAlignment.Center
pillolaBoost.Visible = false

-- Suggerimento in basso.
local suggerimento = etichetta(gui, "Suggerimento", TESTI.Suggerimento, UDim2.fromOffset(760, 26), UDim2.new(0.5, 0, 1, -30), 15, THEME["Testo attenuato"])
suggerimento.AnchorPoint = Vector2.new(0.5, 1)
suggerimento.TextXAlignment = Enum.TextXAlignment.Center

-- Toast per i messaggi delle azioni.
local toast = pannello(gui, "Toast", UDim2.fromOffset(470, 44), UDim2.new(0.5, 0, 0, 70), Vector2.new(0.5, 0))
local testoToast = etichetta(toast, "Testo", "", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), 16, THEME.Testo, true)
testoToast.TextXAlignment = Enum.TextXAlignment.Center
toast.Visible = false

local funzioneToastToken = 0

local function mostraToast(messaggio, colore)
	if not messaggio or messaggio == "" then
		return
	end
	funzioneToastToken += 1
	local token = funzioneToastToken
	testoToast.Text = messaggio
	testoToast.TextColor3 = colore or THEME.Testo
	toast.Visible = true
	toast.BackgroundTransparency = 0.12

	task.delay(2.4, function()
		if token == funzioneToastToken then
			TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			task.delay(0.4, function()
				if token == funzioneToastToken then
					toast.Visible = false
				end
			end)
		end
	end)
end

--------------------------------------------------------------------------------
-- POPUP OFFLINE
--------------------------------------------------------------------------------

local popupOffline = Instance.new("Frame")
popupOffline.Name = "PopupOffline"
popupOffline.Size = UDim2.fromScale(1, 1)
popupOffline.BackgroundColor3 = Color3.new(0, 0, 0)
popupOffline.BackgroundTransparency = 0.45
popupOffline.BorderSizePixel = 0
popupOffline.Visible = false
popupOffline.Parent = gui

local cartaOffline = pannello(popupOffline, "Carta", UDim2.fromOffset(560, 300), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
cartaOffline.BackgroundColor3 = THEME.PannelloChiaro

etichetta(cartaOffline, "Titolo", TESTI.OfflineTitolo, UDim2.new(1, -40, 0, 30), UDim2.fromOffset(20, 22), 22, THEME.Accento, true).TextXAlignment = Enum.TextXAlignment.Center
etichetta(cartaOffline, "Testo", TESTI.OfflineTesto, UDim2.new(1, -60, 0, 40), UDim2.fromOffset(30, 66), 15, THEME["Testo attenuato"]).TextXAlignment = Enum.TextXAlignment.Center

local valoreOffline = etichetta(cartaOffline, "Valore", "+0", UDim2.new(1, -40, 0, 44), UDim2.fromOffset(20, 116), 36, THEME.Accento, true)
valoreOffline.TextXAlignment = Enum.TextXAlignment.Center

local dettaglioOffline = etichetta(cartaOffline, "Dettaglio", "", UDim2.new(1, -40, 0, 24), UDim2.fromOffset(20, 168), 14, THEME["Testo attenuato"])
dettaglioOffline.TextXAlignment = Enum.TextXAlignment.Center

local bottoneOffline = Instance.new("TextButton")
bottoneOffline.Name = "Riscuoti"
bottoneOffline.Size = UDim2.fromOffset(220, 46)
bottoneOffline.Position = UDim2.new(0.5, 0, 1, -70)
bottoneOffline.AnchorPoint = Vector2.new(0.5, 0)
bottoneOffline.BackgroundColor3 = THEME.Accento
bottoneOffline.BorderSizePixel = 0
bottoneOffline.Font = Enum.Font.GothamBold
bottoneOffline.Text = TESTI.OfflineBottone
bottoneOffline.TextColor3 = Color3.fromRGB(6, 10, 18)
bottoneOffline.TextSize = 17
bottoneOffline.Parent = cartaOffline
angoli(bottoneOffline, 10)

bottoneOffline.Activated:Connect(function()
	popupOffline.Visible = false
end)

local function mostraPopupOffline(report)
	if not report or not report.watt or report.watt <= 0 then
		return
	end
	valoreOffline.Text = "+" .. BigNum.format(report.watt) .. " Watt"
	dettaglioOffline.Text = "Assenza: " .. BigNum.formatTime(report.secondi or 0) .. "  -  efficienza offline 25%"
	popupOffline.Visible = true
end

--------------------------------------------------------------------------------
-- SUONI E JUICE
--------------------------------------------------------------------------------

local suonoAcquisto = Instance.new("Sound")
suonoAcquisto.Name = "Acquisto"
-- Suono integrato nel client Roblox: nessun asset esterno caricato dal gioco.
suonoAcquisto.SoundId = "rbxasset://sounds/electronicpingshort.wav"
suonoAcquisto.Volume = 0.55
suonoAcquisto.Parent = SoundService

local comboAcquisti = 0
local ultimoAcquisto = 0

local function suonoConPitch(pitch)
	-- pcall: se l'asset audio non fosse disponibile il gioco resta silenzioso
	-- invece di generare un errore.
	pcall(function()
		suonoAcquisto.PlaybackSpeed = pitch
		suonoAcquisto.TimePosition = 0
		suonoAcquisto:Play()
	end)
end

-- Testo che sale dal pad quando si compra (+Watt).
local function testoFluttuante(testo, posizione, colore)
	local ancoraggio = Instance.new("Part")
	ancoraggio.Name = "TestoFluttuante"
	ancoraggio.Anchored = true
	ancoraggio.CanCollide = false
	ancoraggio.CanTouch = false
	ancoraggio.CanQuery = false
	ancoraggio.Transparency = 1
	ancoraggio.Size = Vector3.new(1, 1, 1)
	ancoraggio.CFrame = CFrame.new(posizione)
	ancoraggio.Parent = Workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(170, 46)
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(0, 0, 0)
	bb.Parent = ancoraggio

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = testo
	label.TextColor3 = colore or THEME.Accento
	label.TextSize = 26
	label.TextStrokeTransparency = 0.35
	label.Parent = bb

	TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 7, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.9), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(1, function()
		ancoraggio:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- MAPPA: riferimenti
--------------------------------------------------------------------------------

local mappa = Workspace:WaitForChild("QuantumCoreMap")
local pannelloAlbero = mappa:WaitForChild("UpgradeTreePanel")
local cartellaPulsanti = mappa:WaitForChild("Buttons")
local modelloNucleo = mappa:WaitForChild("QuantumCore")

--------------------------------------------------------------------------------
-- UPGRADE TREE SUL MURO (SurfaceGui per-giocatore)
--------------------------------------------------------------------------------

local LARGHEZZA_PX = MAP.WallSize.X * MAP.WallPixelsPerStud
local ALTEZZA_PX = MAP.WallSize.Y * MAP.WallPixelsPerStud

local guiMuro = Instance.new("SurfaceGui")
guiMuro.Name = "UpgradeTreeLive"
guiMuro.Face = Enum.NormalId.Front
guiMuro.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
guiMuro.PixelsPerStud = MAP.WallPixelsPerStud
guiMuro.LightInfluence = 0
guiMuro.AlwaysOnTop = false
guiMuro.Adornee = pannelloAlbero
guiMuro.Parent = playerGui

-- Livello delle linee di collegamento (sotto ai nodi).
local livelloLinee = Instance.new("Frame")
livelloLinee.Name = "Linee"
livelloLinee.Size = UDim2.fromScale(1, 1)
livelloLinee.BackgroundTransparency = 1
livelloLinee.ZIndex = 1
livelloLinee.Parent = guiMuro

local linee = {}

local function creaLinea(da, a, colore, nodoFiglioId)
	local x1, y1 = da.X * LARGHEZZA_PX, da.Y * ALTEZZA_PX
	local x2, y2 = a.X * LARGHEZZA_PX, a.Y * ALTEZZA_PX
	local dx, dy = x2 - x1, y2 - y1
	local distanza = math.sqrt(dx * dx + dy * dy)

	local linea = Instance.new("Frame")
	linea.Name = "Linea"
	linea.AnchorPoint = Vector2.new(0, 0.5)
	linea.Position = UDim2.fromOffset(x1, y1)
	linea.Size = UDim2.fromOffset(distanza, 5)
	linea.Rotation = math.deg(math.atan2(dy, dx))
	linea.BackgroundColor3 = colore or THEME.Bordo
	linea.BackgroundTransparency = 0.7
	linea.BorderSizePixel = 0
	linea.ZIndex = 1
	linea.Parent = livelloLinee

	table.insert(linee, { frame = linea, da = da, a = a, nodoFiglioId = nodoFiglioId })
	return linea
end

local nodiUi = {}

for _, nodo in GameConfig.Nodes do
	-- Linee verso i prerequisiti.
	for _, requisito in nodo.requires do
		local padre = nodiPerId[requisito]
		if padre then
			creaLinea(padre.position, nodo.position, nodo.isPrestige and THEME.MateriaOscura or THEME.Bordo, nodo.id)
		end
	end

	local larghezza = nodo.isPrestige and 330 or 290
	local altezza = nodo.isPrestige and 148 or 124
	local coloreTitolo = nodo.isPrestige and THEME.MateriaOscura or THEME.Accento

	local bottone = Instance.new("TextButton")
	bottone.Name = nodo.id
	bottone.Size = UDim2.fromOffset(larghezza, altezza)
	bottone.Position = UDim2.fromScale(nodo.position.X, nodo.position.Y)
	bottone.AnchorPoint = Vector2.new(0.5, 0.5)
	bottone.BackgroundColor3 = THEME.Pannello
	bottone.BackgroundTransparency = 0.05
	bottone.BorderSizePixel = 0
	bottone.AutoButtonColor = false
	bottone.Text = ""
	bottone.ZIndex = 2
	bottone.Parent = guiMuro
	angoli(bottone, 16)

	local stroke = bordo(bottone, THEME.Bordo, 2.5, 0.35)

	local titolo = etichetta(bottone, "Titolo", nodo.nome, UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 12), 20, coloreTitolo, true)
	titolo.ZIndex = 3
	titolo.TextTruncate = Enum.TextTruncate.AtEnd

	local descrizione = etichetta(bottone, "Descrizione", nodo.descrizione, UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, 40), 14, THEME["Testo attenuato"])
	descrizione.ZIndex = 3
	descrizione.TextWrapped = true
	descrizione.TextYAlignment = Enum.TextYAlignment.Top

	local costo = etichetta(bottone, "Costo", "", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, altezza - 36), 17, THEME.Oro, true)
	costo.ZIndex = 3
	costo.TextTruncate = Enum.TextTruncate.AtEnd

	local etichettaStato = etichetta(bottone, "Stato", TESTI.NodoBloccato, UDim2.fromOffset(110, 22), UDim2.new(1, -122, 0, 10), 13, THEME["Testo attenuato"], true)
	etichettaStato.TextXAlignment = Enum.TextXAlignment.Right
	etichettaStato.ZIndex = 3

	nodiUi[nodo.id] = {
		nodo = nodo,
		bottone = bottone,
		stroke = stroke,
		titolo = titolo,
		descrizione = descrizione,
		costo = costo,
		etichettaStato = etichettaStato,
	}

	-- Hover: bordo piu' luminoso.
	bottone.MouseEnter:Connect(function()
		stroke.Transparency = 0
	end)
	bottone.MouseLeave:Connect(function()
		stroke.Transparency = 0.35
	end)

	-- Click: chiede al server. Il server decide tutto.
	bottone.Activated:Connect(function()
		TweenService:Create(bottone, TweenInfo.new(0.08), { BackgroundTransparency = 0.45 }):Play()
		task.delay(0.09, function()
			TweenService:Create(bottone, TweenInfo.new(0.18), { BackgroundTransparency = 0.05 }):Play()
		end)

		local chiamataOk, esito, messaggio = pcall(function()
			if nodo.isPrestige then
				return PrestigeRemote:InvokeServer()
			end
			return BuyNodeRemote:InvokeServer(nodo.id)
		end)

		if not chiamataOk then
			mostraToast("Connessione con il server persa", THEME.Pericolo)
			return
		end

		if esito then
			mostraToast(messaggio or "Fatto!", THEME.Successo)
			suonoConPitch(1.25)
		else
			mostraToast(messaggio or "Azione non riuscita", THEME.Pericolo)
			suonoConPitch(0.7)
		end
	end)
end

-- Aggiorna colori/testi dei nodi in base allo stato del giocatore.
local function aggiornaAlbero()
	for id, voce in pairs(nodiUi) do
		local nodo = voce.nodo
		local sbloccato = stato.nodes[id] == true
		local prerequisitiOk = true
		for _, requisito in nodo.requires do
			if stato.nodes[requisito] ~= true then
				prerequisitiOk = false
				break
			end
		end

		local saldo = nodo.currency == "Plasma" and stato.plasma or stato.watt
		local acquistabile = prerequisitiOk and not sbloccato and saldo >= nodo.cost

		if nodo.isPrestige then
			local pronto = stato.prestige and stato.prestige.ready
			voce.titolo.TextColor3 = THEME.MateriaOscura
			voce.stroke.Color = pronto and THEME.MateriaOscura or THEME.Bordo
			voce.stroke.Transparency = pronto and 0 or 0.45
			voce.bottone.BackgroundColor3 = pronto and Color3.fromRGB(28, 14, 44) or THEME.Pannello
			voce.etichettaStato.Text = pronto and "PRONTO" or "ENDGAME"
			voce.etichettaStato.TextColor3 = pronto and THEME.Successo or THEME["Testo attenuato"]
			if pronto then
				local ricompensa = stato.prestige and stato.prestige.reward or 0
				voce.costo.Text = "+" .. BigNum.format(ricompensa) .. " Materia Oscura"
				voce.costo.TextColor3 = THEME.MateriaOscura
			else
				voce.costo.Text = TESTI.PrestigeBloccato .. " (" .. BigNum.format(saldo) .. " W)"
				voce.costo.TextColor3 = THEME["Testo attenuato"]
			end
		elseif sbloccato then
			voce.bottone.BackgroundColor3 = Color3.fromRGB(12, 32, 26)
			voce.stroke.Color = THEME.Successo
			voce.stroke.Transparency = 0.2
			voce.titolo.TextColor3 = THEME.Successo
			voce.etichettaStato.Text = TESTI.NodoAttivo
			voce.etichettaStato.TextColor3 = THEME.Successo
			voce.costo.Text = "Gia' attivo"
			voce.costo.TextColor3 = THEME["Testo attenuato"]
		elseif acquistabile then
			voce.bottone.BackgroundColor3 = Color3.fromRGB(18, 30, 44)
			voce.stroke.Color = THEME.Accento
			voce.stroke.Transparency = 0.05
			voce.titolo.TextColor3 = THEME.Accento
			voce.etichettaStato.Text = TESTI.NodoAcquistabile
			voce.etichettaStato.TextColor3 = THEME.Accento
			voce.costo.Text = "Costo: " .. BigNum.format(nodo.cost) .. (nodo.currency == "Plasma" and " Plasma" or " Watt")
			voce.costo.TextColor3 = THEME.Oro
		elseif prerequisitiOk then
			voce.bottone.BackgroundColor3 = THEME.Pannello
			voce.stroke.Color = THEME.Bordo
			voce.stroke.Transparency = 0.35
			voce.titolo.TextColor3 = THEME.Testo
			voce.etichettaStato.Text = "DA SBLOCCARE"
			voce.etichettaStato.TextColor3 = THEME["Testo attenuato"]
			voce.costo.Text = BigNum.format(nodo.cost) .. (nodo.currency == "Plasma" and " Plasma" or " Watt")
			voce.costo.TextColor3 = THEME["Testo attenuato"]
		else
			voce.bottone.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
			voce.stroke.Color = THEME.Bordo
			voce.stroke.Transparency = 0.6
			voce.titolo.TextColor3 = THEME["Testo attenuato"]
			voce.etichettaStato.Text = TESTI.NodoBloccato
			voce.etichettaStato.TextColor3 = THEME["Testo attenuato"]
			voce.costo.Text = BigNum.format(nodo.cost) .. (nodo.currency == "Plasma" and " Plasma" or " Watt")
			voce.costo.TextColor3 = Color3.fromRGB(80, 90, 112)
		end
	end

	-- Linee: accese se il nodo figlio e' sbloccato.
	for _, linea in linee do
		linea.frame.BackgroundTransparency = stato.nodes[linea.nodoFiglioId] == true and 0.2 or 0.78
	end
end

--------------------------------------------------------------------------------
-- BILLBOARD SUI 6 PULSANTI
--------------------------------------------------------------------------------

local billboardPulsanti = {}

for _, pulsante in GameConfig.Buttons do
	local pad = cartellaPulsanti:FindFirstChild("Pad_" .. pulsante.id)
	if pad then
		local ancora = pad:FindFirstChild("Nucleo") or pad:FindFirstChildWhichIsA("BasePart")
		if ancora then
			local bb = Instance.new("BillboardGui")
			bb.Name = "Info_" .. pulsante.id
			bb.Adornee = ancora
			bb.Size = UDim2.fromOffset(250, 108)
			bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
			bb.AlwaysOnTop = false
			bb.MaxDistance = 180
			bb.Parent = playerGui

			local cartella = Instance.new("Frame")
			cartella.Size = UDim2.fromScale(1, 1)
			cartella.BackgroundColor3 = THEME.Pannello
			cartella.BackgroundTransparency = 0.15
			cartella.BorderSizePixel = 0
			cartella.Parent = bb
			angoli(cartella, 10)
			bordo(cartella, pulsante.coloreNeon, 2, 0.25)

			local nome = etichetta(cartella, "Nome", pulsante.nome, UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 6), 15, pulsante.coloreNeon, true)
			nome.TextXAlignment = Enum.TextXAlignment.Center

			local livello = etichetta(cartella, "Livello", "Lv. 0", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 28), 14, THEME.Testo, true)
			livello.TextXAlignment = Enum.TextXAlignment.Center

			local costo = etichetta(cartella, "Costo", "", UDim2.new(1, -16, 0, 22), UDim2.fromOffset(8, 50), 14, THEME.Oro)
			costo.TextXAlignment = Enum.TextXAlignment.Center

			local descrizione = etichetta(cartella, "Descrizione", pulsante.descrizione, UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 76), 12, THEME["Testo attenuato"])
			descrizione.TextXAlignment = Enum.TextXAlignment.Center
			descrizione.TextTruncate = Enum.TextTruncate.AtEnd

			billboardPulsanti[pulsante.id] = {
				pulsante = pulsante,
				livello = livello,
				costo = costo,
				cartella = cartella,
			}
		end
	end
end

local function aggiornaPulsanti()
	for id, voce in pairs(billboardPulsanti) do
		local livello = stato.buttons[id] or 0
		local costo = stato.costs[id] or voce.pulsante.baseCost

		voce.livello.Text = "Lv. " .. tostring(livello)
		if livello > 0 then
			voce.costo.Text = "Prossimo: " .. BigNum.format(costo)
		else
			voce.costo.Text = "Costo: " .. BigNum.format(costo)
		end

		local accessibile = stato.watt >= costo
		voce.costo.TextColor3 = accessibile and THEME.Successo or THEME.Oro
	end
end

--------------------------------------------------------------------------------
-- NUCLEO: EVOLUZIONE LOCALE (5 stadi)
--------------------------------------------------------------------------------

local sferaNucleo = modelloNucleo:WaitForChild("CoreSphere")
local guscioNucleo = modelloNucleo:FindFirstChild("CoreShell")

local anelli = {}
for indice = 1, 4 do
	local modello = modelloNucleo:FindFirstChild("Ring" .. indice)
	if modello then
		local parti = {}
		for _, discendente in modello:GetDescendants() do
			if discendente:IsA("BasePart") then
				table.insert(parti, discendente)
			end
		end
		table.insert(anelli, {
			modello = modello,
			base = modello:GetPivot(),
			parti = parti,
			visibile = nil,
		})
	end
end

local stadioCorrente = GameConfig.CoreStages[1]
local raggioAttuale = stadioCorrente.raggio
local coloreAttuale = stadioCorrente.colore

local function stadioPerWatt(watt)
	local scelto = GameConfig.CoreStages[1]
	for _, stadio in GameConfig.CoreStages do
		if watt >= stadio.soglia then
			scelto = stadio
		end
	end
	return scelto
end

local function impostaVisibilitaAnello(anello, visibile)
	if anello.visibile == visibile then
		return
	end
	anello.visibile = visibile
	for _, parte in anello.parti do
		if parte.Name ~= "Perno" then
			parte.Transparency = visibile and 0 or 1
		end
	end
end

--------------------------------------------------------------------------------
-- SFERA DI SOVRACCARICO (locale: ognuno vede la propria)
--------------------------------------------------------------------------------

local sferaBonus = Instance.new("Part")
sferaBonus.Name = "SferaSovraccarico"
sferaBonus.Shape = Enum.PartType.Ball
sferaBonus.Size = Vector3.new(5, 5, 5)
sferaBonus.Anchored = true
sferaBonus.CanCollide = false
sferaBonus.CanTouch = false
sferaBonus.CanQuery = false
sferaBonus.Material = Enum.Material.Neon
sferaBonus.Color = THEME.Oro
sferaBonus.Transparency = 1
sferaBonus.CFrame = CFrame.new(0, -1000, 0)
sferaBonus.Parent = Workspace

local luceBonus = Instance.new("PointLight")
luceBonus.Color = THEME.Oro
luceBonus.Brightness = 3
luceBonus.Range = 26
luceBonus.Shadows = false
luceBonus.Parent = sferaBonus

--------------------------------------------------------------------------------
-- AURA DI MATERIA OSCURA
--------------------------------------------------------------------------------

local aura = {}
for indice = 1, 8 do
	local sferaAura = Instance.new("Part")
	sferaAura.Name = "AuraDarkMatter"
	sferaAura.Shape = Enum.PartType.Ball
	sferaAura.Size = Vector3.new(1.1, 1.1, 1.1)
	sferaAura.Anchored = true
	sferaAura.CanCollide = false
	sferaAura.CanTouch = false
	sferaAura.CanQuery = false
	sferaAura.Material = Enum.Material.Neon
	sferaAura.Color = THEME.MateriaOscura
	sferaAura.Transparency = 1
	sferaAura.CFrame = CFrame.new(0, -1000, 0)
	sferaAura.Parent = Workspace
	table.insert(aura, sferaAura)
end

--------------------------------------------------------------------------------
-- APPLICAZIONE DELLO STATO
--------------------------------------------------------------------------------

local function applicaStato(payload)
	if type(payload) ~= "table" then
		return
	end

	stato.watt = payload.watt or 0
	stato.wattPerSecondo = payload.wattPerSecondo or 0
	stato.plasma = payload.plasma or 0
	stato.plasmaPerSecondo = payload.plasmaPerSecondo or 0
	stato.materiaOscura = payload.materiaOscura or 0
	stato.boostUntil = payload.boostUntil or 0
	stato.serverTime = payload.serverTime or os.time()
	stato.buttons = payload.buttons or {}
	stato.nodes = payload.nodes or {}
	stato.costs = payload.costs or {}
	stato.autoBuy = payload.autoBuy or 0
	stato.bonus = payload.bonus
	stato.prestige = payload.prestige or stato.prestige

	valoreWatt.Text = BigNum.format(stato.watt)
	rateWatt.Text = BigNum.formatRate(stato.wattPerSecondo)
	valorePlasma.Text = BigNum.format(stato.plasma)
	valoreMateria.Text = BigNum.format(stato.materiaOscura)

	aggiornaAlbero()
	aggiornaPulsanti()

	if payload.offline then
		mostraPopupOffline(payload.offline)
	end
end

--------------------------------------------------------------------------------
-- LOOP VISIVO (client)
--------------------------------------------------------------------------------

local ultimoAggiornamentoBoost = 0

RunService.RenderStepped:Connect(function(dt)
	local tempo = os.clock()

	-- Evoluzione del nucleo.
	local stadioTarget = stadioPerWatt(stato.watt)
	local fattore = math.min(dt * 3, 1)
	raggioAttuale += (stadioTarget.raggio - raggioAttuale) * fattore
	coloreAttuale = coloreAttuale:Lerp(stadioTarget.colore, fattore)

	local diametro = raggioAttuale * 2
	sferaNucleo.Size = Vector3.new(diametro, diametro, diametro)
	sferaNucleo.Color = coloreAttuale
	sferaNucleo.CFrame = CFrame.new(sferaNucleo.Position) * CFrame.Angles(tempo * stadioTarget.velocitaRotazione, tempo * stadioTarget.velocitaRotazione * 0.6, 0)

	if guscioNucleo and guscioNucleo:IsA("BasePart") then
		local diametroGuscio = diametro * 1.35
		guscioNucleo.Size = Vector3.new(diametroGuscio, diametroGuscio, diametroGuscio)
		guscioNucleo.Color = coloreAttuale
	end

	local luce = sferaNucleo:FindFirstChildOfClass("PointLight")
	if luce then
		luce.Color = coloreAttuale
	end

	for indice, anello in anelli do
		local visibile = indice <= stadioTarget.anelli
		impostaVisibilitaAnello(anello, visibile)
		if visibile then
			local direzione = (indice % 2 == 0) and -1 or 1
			local velocita = stadioTarget.velocitaRotazione * (0.45 + indice * 0.22) * direzione
			anello.modello:PivotTo(anello.base * CFrame.Angles(0, tempo * velocita, 0))
		end
	end

	-- Sfera di sovraccarico.
	if stato.bonus then
		local posizione = stato.bonus
		local oscillazione = math.sin(tempo * 3) * 0.5
		sferaBonus.CFrame = CFrame.new(posizione + Vector3.new(0, oscillazione, 0)) * CFrame.Angles(0, tempo * 2, 0)
		sferaBonus.Transparency = 0.05
		luceBonus.Enabled = true
	else
		sferaBonus.Transparency = 1
		luceBonus.Enabled = false
	end

	-- Aura di Materia Oscura attorno all'avatar.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local attivi = math.clamp(3 + math.floor(stato.materiaOscura), 0, #aura)
	if stato.materiaOscura > 0 and root then
		for indice, sfera in aura do
			if indice <= attivi then
				local angolo = tempo * (0.9 + indice * 0.15) + (indice / #aura) * math.pi * 2
				local raggioOrbita = 4.5
				local posizione = root.Position
					+ Vector3.new(math.cos(angolo) * raggioOrbita, math.sin(tempo * 2 + indice) * 0.8 + 1, math.sin(angolo) * raggioOrbita)
				sfera.CFrame = CFrame.new(posizione) * CFrame.Angles(0, tempo * 3, 0)
				sfera.Transparency = 0.05
			else
				sfera.Transparency = 1
			end
		end
	else
		for _, sfera in aura do
			sfera.Transparency = 1
		end
	end

	-- Timer del boost (aggiornato 5 volte al secondo).
	if tempo - ultimoAggiornamentoBoost > 0.2 then
		ultimoAggiornamentoBoost = tempo
		local rimanente = stato.boostUntil - os.time()
		if rimanente > 0 then
			pillolaBoost.Visible = true
			testoBoost.Text = TESTI.HudBoost .. "  -  " .. BigNum.formatTime(rimanente)
		else
			pillolaBoost.Visible = false
		end
	end
end)

--------------------------------------------------------------------------------
-- FEEDBACK DAL SERVER
--------------------------------------------------------------------------------

FeedbackRemote.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end

	if info.kind == "Purchase" then
		local pulsante = nil
		for _, candidato in GameConfig.Buttons do
			if candidato.id == info.buttonId then
				pulsante = candidato
				break
			end
		end

		-- Pitch crescente quando si compra velocemente.
		if os.clock() - ultimoAcquisto < 0.7 then
			comboAcquisti = math.min(comboAcquisti + 1, 18)
		else
			comboAcquisti = 0
		end
		ultimoAcquisto = os.clock()
		suonoConPitch(0.85 + comboAcquisti * 0.055)

		if pulsante then
			local pad = cartellaPulsanti:FindFirstChild("Pad_" .. pulsante.id)
			local nucleo = pad and pad:FindFirstChild("Nucleo")
			if nucleo and nucleo:IsA("BasePart") then
				local coloreOriginale = pulsante.coloreNeon
				nucleo.Color = Color3.new(1, 1, 1)
				TweenService:Create(nucleo, TweenInfo.new(0.22), { Color = coloreOriginale }):Play()
			end
			testoFluttuante("+1 Lv", pulsante.pos + Vector3.new(0, 5, 0), pulsante.coloreNeon)
		end
	elseif info.kind == "Bonus" then
		suonoConPitch(1.8)
		mostraToast("SOVRACCARICO ATTIVO: x2 Watt per 30s", THEME.Oro)
	elseif info.kind == "BonusSpawn" then
		suonoConPitch(1.35)
	elseif info.kind == "Prestige" then
		suonoConPitch(2)
		mostraToast("COLLASSO QUANTISTICO: +" .. tostring(info.darkMatter or 0) .. " Materia Oscura", THEME.MateriaOscura)
	elseif info.kind == "Node" then
		suonoConPitch(1.5)
	end
end)

StateRemote.OnClientEvent:Connect(applicaStato)

OfflineRemote.OnClientEvent:Connect(mostraPopupOffline)

--------------------------------------------------------------------------------
-- STATO INIZIALE
--------------------------------------------------------------------------------

task.spawn(function()
	local ok, payload = pcall(function()
		return GetProfileRemote:InvokeServer()
	end)
	if ok and payload then
		applicaStato(payload)
		if payload.offline then
			mostraPopupOffline(payload.offline)
		end
	end
end)

print("[Quantum Core] ClientEffects pronto.")
