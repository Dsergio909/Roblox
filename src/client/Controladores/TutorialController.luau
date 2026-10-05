--!strict
--[[
	TutorialController
	El "tutorial" de los primeros 60 segundos, SIN pantallas de texto:
	una flecha luminosa (rayo) que apunta a lo que hay que hacer + un globo de 3–5 palabras.

	  1. Sin compras:  rayo al Crunchi de la cinta más cercano que puedes pagar.
	  2. Sin cobros:   rayo al botón verde con más dinero de tu base.
	  3. A los 2 min de tu primera sesión: consejo sobre robar y el escudo.

	El avance lo manda el servidor (estado privado "tutorial").
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigOnboarding = require(Shared:WaitForChild("Config"):WaitForChild("Onboarding"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local CintaController = require(script.Parent:WaitForChild("CintaController"))
local BaseController = require(script.Parent:WaitForChild("BaseController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local TutorialController = {}

local jugador = Players.LocalPlayer
local inicioSesion = os.clock()
local consejoRoboMostrado = false

local globo: Frame
local textoGlobo: TextLabel
local rayo: Beam? = nil
local anclaOrigen: Attachment? = nil
local anclaDestino: Attachment? = nil
local destinoActual: BasePart? = nil

local function raiz(): BasePart?
	local personaje = jugador.Character
	local r = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function quitarRayo()
	if rayo then
		rayo:Destroy()
	end
	if anclaOrigen then
		anclaOrigen:Destroy()
	end
	if anclaDestino then
		anclaDestino:Destroy()
	end
	rayo, anclaOrigen, anclaDestino, destinoActual = nil, nil, nil, nil
end

local function apuntar(destino: BasePart?)
	local origen = raiz()
	if destino == nil or origen == nil then
		quitarRayo()
		return
	end
	if destino == destinoActual and rayo and anclaOrigen and anclaOrigen.Parent == origen then
		return
	end
	quitarRayo()
	local a0 = Instance.new("Attachment")
	a0.Name = "TutorialOrigen"
	a0.Parent = origen
	local a1 = Instance.new("Attachment")
	a1.Name = "TutorialDestino"
	a1.Position = Vector3.new(0, 1, 0)
	a1.Parent = destino
	local nuevo = Instance.new("Beam")
	nuevo.Attachment0 = a0
	nuevo.Attachment1 = a1
	nuevo.Color = ColorSequence.new(Tema.COLORES.dinero)
	nuevo.Width0 = 0.7
	nuevo.Width1 = 0.3
	nuevo.FaceCamera = true
	nuevo.LightEmission = 1
	nuevo.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 0),
	})
	nuevo.Parent = origen
	rayo, anclaOrigen, anclaDestino, destinoActual = nuevo, a0, a1, destino
end

local function mostrarGlobo(texto: string?)
	if texto then
		if textoGlobo.Text ~= texto then
			textoGlobo.Text = texto
			UI.Rebote(globo, 0.15)
		end
		globo.Visible = true
	else
		globo.Visible = false
	end
end

local function actualizar()
	local tutorial = EstadoCliente.Obtener("tutorial")
	if type(tutorial) ~= "table" then
		return
	end
	local posicion = raiz()
	if (tutorial.compras or 0) == 0 then
		mostrarGlobo("¡Compra un Crunchi en la cinta! 🛒")
		apuntar(if posicion then CintaController.MasCercanoAsequible(posicion.Position) else nil)
	elseif (tutorial.cobros or 0) == 0 then
		local boton = BaseController.MejorBotonCobro()
		mostrarGlobo(
			if boton then "¡Pisa el botón verde para cobrar! 💰" else "¡Espera a que tu Crunchi gane dinero!"
		)
		apuntar(boton)
	else
		mostrarGlobo(nil)
		quitarRayo()
		-- Consejo sobre robar, una vez, en la primera sesión.
		if
			not consejoRoboMostrado
			and (tutorial.sesiones or 0) <= 1
			and os.clock() - inicioSesion > ConfigOnboarding.CONSEJO_ROBO_SEGUNDOS
		then
			consejoRoboMostrado = true
			NotificacionController.Avisar(
				"👀 ¡Puedes ROBAR Crunchis de otras bases! Tu base tiene escudo 🛡️",
				"alerta"
			)
			NotificacionController.Avisar(
				"🗞️ Si te roban, ¡persigue al ladrón y dale con el periódico!",
				"info"
			)
		end
	end
end

function TutorialController.Iniciar()
	local pantalla = UI.Pantalla("Tutorial", 10)
	local marco = UI.Crear("Frame", {
		Name = "MarcoGlobo",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -160),
		Size = UDim2.fromOffset(360, 48),
		Parent = pantalla,
	})
	UI.Escalar(marco, 360)
	globo = UI.Panel({
		Name = "Globo",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = marco,
	})
	UI.Borde(globo, Tema.COLORES.dinero, 3)
	textoGlobo = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -12, 1, 0),
		posicion = UDim2.fromOffset(6, 0),
		tamanoLetra = 22,
		color = Tema.COLORES.dinero,
		padre = globo,
	})
	jugador.CharacterAdded:Connect(quitarRayo)
	Reloj.Cada(0.5, actualizar)
end

return TutorialController
