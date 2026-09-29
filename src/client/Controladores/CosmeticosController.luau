--!strict
--[[
	CosmeticosController
	Dibuja en ESTE dispositivo las auras y estelas de los jugadores cercanos, y maneja lo
	visual del VIP:

	  - Auras (partículas) y estelas (Trail) según los atributos "Aura"/"Estela" de cada
	    jugador. Solo para jugadores a menos de DISTANCIA studs, con tope de emisores, y se
	    apagan con el Modo ahorro (EfectosController.calidad = 0).
	  - Etiqueta [VIP] en el chat.
	  - Puerta de la Terraza VIP sólida para quien no es VIP.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigCosmeticos = require(Shared:WaitForChild("Config"):WaitForChild("Cosmeticos"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local EfectosController = require(script.Parent:WaitForChild("EfectosController"))

type Cosmetico = ConfigCosmeticos.Cosmetico

local CosmeticosController = {}

local jugadorLocal = Players.LocalPlayer
local DISTANCIA = 90
local MAX_JUGADORES_CON_EFECTOS = 8

local porId: { [string]: Cosmetico } = {}
for _, cosmetico in ConfigCosmeticos do
	porId[cosmetico.id] = cosmetico
end

type Dibujado = { aura: string, estela: string, objetos: { Instance } }
local dibujados: { [Player]: Dibujado } = {}

local function esVip(jugador: Player): boolean
	local pases = jugador:GetAttribute("Pases")
	return type(pases) == "string" and string.find("," .. pases .. ",", ",VIP,", 1, true) ~= nil
end

local function colores(cosmetico: Cosmetico): ColorSequence
	if cosmetico.arcoiris then
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 50)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(90, 255, 110)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 180, 255)),
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 90, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
		})
	end
	return ColorSequence.new(cosmetico.color, cosmetico.color2 or cosmetico.color)
end

local function quitar(jugador: Player)
	local dibujado = dibujados[jugador]
	if dibujado then
		for _, objeto in dibujado.objetos do
			objeto:Destroy()
		end
		dibujados[jugador] = nil
	end
end

local function dibujar(jugador: Player, raiz: BasePart, auraId: string, estelaId: string)
	quitar(jugador)
	local objetos: { Instance } = {}
	local aura = porId[auraId]
	if aura then
		local ancla = Instance.new("Attachment")
		ancla.Name = "AuraCosmetico"
		ancla.Parent = raiz
		local emisor = Instance.new("ParticleEmitter")
		emisor.Color = colores(aura)
		emisor.LightEmission = 0.6
		emisor.Rate = math.max(2, 14 * EfectosController.calidad)
		emisor.Lifetime = NumberRange.new(0.8, 1.3)
		emisor.Speed = NumberRange.new(1, 3)
		emisor.SpreadAngle = Vector2.new(180, 180)
		emisor.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		emisor.Transparency = NumberSequence.new(0.2, 1)
		emisor.Acceleration = Vector3.new(0, 2, 0)
		emisor.Parent = ancla
		table.insert(objetos, ancla)
	end
	local estela = porId[estelaId]
	if estela then
		local arriba = Instance.new("Attachment")
		arriba.Name = "EstelaArriba"
		arriba.Position = Vector3.new(0, 0.8, 0)
		arriba.Parent = raiz
		local abajo = Instance.new("Attachment")
		abajo.Name = "EstelaAbajo"
		abajo.Position = Vector3.new(0, -0.9, 0)
		abajo.Parent = raiz
		local trail = Instance.new("Trail")
		trail.Attachment0 = arriba
		trail.Attachment1 = abajo
		trail.Color = colores(estela)
		trail.Lifetime = 0.6
		trail.LightEmission = 0.5
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = raiz
		table.insert(objetos, arriba)
		table.insert(objetos, abajo)
		table.insert(objetos, trail)
	end
	dibujados[jugador] = { aura = auraId, estela = estelaId, objetos = objetos }
end

local function actualizar()
	local miRaiz = jugadorLocal.Character and jugadorLocal.Character:FindFirstChild("HumanoidRootPart")
	local miPosicion = if miRaiz and miRaiz:IsA("BasePart") then miRaiz.Position else nil
	local activos = 0
	for _, jugador in Players:GetPlayers() do
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		local aura = jugador:GetAttribute("Aura")
		local estela = jugador:GetAttribute("Estela")
		local auraId = if type(aura) == "string" then aura else ""
		local estelaId = if type(estela) == "string" then estela else ""
		local cerca = raiz ~= nil
			and raiz:IsA("BasePart")
			and (jugador == jugadorLocal or (miPosicion ~= nil and (raiz.Position - miPosicion).Magnitude < DISTANCIA))
		local permitido = EfectosController.calidad > 0 and activos < MAX_JUGADORES_CON_EFECTOS
		if cerca and permitido and (auraId ~= "" or estelaId ~= "") then
			activos += 1
			local dibujado = dibujados[jugador]
			local r = raiz :: BasePart
			local primero = if dibujado then dibujado.objetos[1] else nil
			local roto = primero ~= nil and not r:IsAncestorOf(primero)
			if dibujado == nil or dibujado.aura ~= auraId or dibujado.estela ~= estelaId or roto then
				dibujar(jugador, r, auraId, estelaId)
			end
		else
			quitar(jugador)
		end
	end
end

local function actualizarTerraza()
	local mapa = workspace:FindFirstChild("MapaGenerado")
	local terraza = mapa and mapa:FindFirstChild("TerrazaVIP")
	local puerta = terraza and terraza:FindFirstChild("PuertaVIP")
	if puerta and puerta:IsA("BasePart") then
		puerta.CanCollide = not esVip(jugadorLocal)
	end
end

function CosmeticosController.Iniciar()
	Reloj.Cada(1, function()
		actualizar()
		actualizarTerraza()
	end)
	Players.PlayerRemoving:Connect(quitar)

	-- [VIP] en el chat (TextChatService).
	TextChatService.OnIncomingMessage = function(mensaje: TextChatMessage)
		local propiedades = Instance.new("TextChatMessageProperties")
		local fuente = mensaje.TextSource
		if fuente then
			local autor = Players:GetPlayerByUserId(fuente.UserId)
			if autor and esVip(autor) then
				propiedades.PrefixText = `<font color="#FFC828">[VIP]</font> {mensaje.PrefixText}`
			end
		end
		return propiedades
	end
end

return CosmeticosController
