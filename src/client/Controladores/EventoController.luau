--!strict
--[[
	EventoController
	Muestra los eventos del servidor (EventoService): un cartel con la cuenta regresiva
	REAL, un anuncio al empezar, música de evento y un tono de color suave.

	Lluvia de Manzanas: manzanas gigantes caen cerca del jugador. Son SOLO visuales y solo
	existen en este dispositivo, se reciclan (nunca se crean ni destruyen durante la lluvia)
	y con el Modo ahorro caen menos.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigEventos = require(Shared:WaitForChild("Config"):WaitForChild("Eventos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local SonidoController = require(script.Parent:WaitForChild("SonidoController"))
local EfectosController = require(script.Parent:WaitForChild("EfectosController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

type Evento = ConfigEventos.Evento
type Manzana = { parte: BasePart, velocidad: number, activa: boolean }

local EventoController = {}

local actual: Evento? = nil
local banner: Frame
local textoNombre: TextLabel
local textoTiempo: TextLabel
local borde: UIStroke
local correccion: ColorCorrectionEffect

local manzanas: { Manzana } = {}
local carpetaLluvia: Folder
local acumulado = 0
local RADIO_LLUVIA = 70
local ALTURA_LLUVIA = 70

local function buscar(id: string): Evento?
	for _, evento in ConfigEventos.ROTACION do
		if evento.id == id then
			return evento
		end
	end
	for _, evento in ConfigEventos.TEMPORADA do
		if evento.id == id then
			return evento
		end
	end
	return nil
end

----------------------------------------------------------------------------- lluvia

local function crearManzana(): Manzana
	local parte = Instance.new("Part")
	parte.Name = "Manzana"
	parte.Shape = Enum.PartType.Ball
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanQuery = false
	parte.CanTouch = false
	parte.CastShadow = false
	parte.Material = Enum.Material.SmoothPlastic
	parte.Parent = nil
	return { parte = parte, velocidad = 0, activa = false }
end

local function soltarManzana(centro: Vector3)
	for _, manzana in manzanas do
		if not manzana.activa then
			local angulo = math.random() * math.pi * 2
			local distancia = math.random() * RADIO_LLUVIA
			local posicion = centro
				+ Vector3.new(math.cos(angulo) * distancia, ALTURA_LLUVIA, math.sin(angulo) * distancia)
			local tamano = 2.5 + math.random() * 2.5
			manzana.parte.Size = Vector3.one * tamano
			manzana.parte.Color = if math.random() < 0.15
				then Color3.fromRGB(255, 200, 40) -- de vez en cuando, una dorada
				else Color3.fromRGB(225, 40, 50)
			manzana.parte.CFrame = CFrame.new(posicion)
			manzana.parte.Parent = carpetaLluvia
			manzana.velocidad = 35 + math.random() * 20
			manzana.activa = true
			return
		end
	end
end

local function lluvia(dt: number)
	local evento = actual
	local lloviendo = evento ~= nil and evento.tipo == "lluvia" and EfectosController.calidad > 0
	if lloviendo then
		local camara = workspace.CurrentCamera
		if camara then
			acumulado += dt * ConfigEventos.LLUVIA.MANZANAS_POR_SEGUNDO * EfectosController.calidad
			while acumulado >= 1 do
				acumulado -= 1
				soltarManzana(camara.Focus.Position)
			end
		end
	end
	for _, manzana in manzanas do
		if manzana.activa then
			local posicion = manzana.parte.Position - Vector3.new(0, manzana.velocidad * dt, 0)
			if posicion.Y < -2 or not lloviendo then
				manzana.activa = false
				manzana.parte.Parent = nil
			else
				manzana.parte.CFrame = CFrame.new(posicion)
			end
		end
	end
end

----------------------------------------------------------------------------- cartel

local function actualizarTiempo()
	if actual == nil then
		return
	end
	local hasta = workspace:GetAttribute("EventoHasta")
	local restante = if type(hasta) == "number" then math.max(0, hasta - Reloj.Ahora()) else 0
	textoTiempo.Text = `termina en {Formato.Tiempo(restante)}`
end

local function alCambiar()
	local id = workspace:GetAttribute("EventoId")
	local evento = if type(id) == "string" then buscar(id) else nil
	if evento == actual then
		return
	end
	actual = evento
	if evento then
		banner.Visible = true
		textoNombre.Text = `{evento.icono} {evento.nombre}`
		textoNombre.TextColor3 = evento.color
		borde.Color = evento.color
		UI.Rebote(banner, 0.2)
		actualizarTiempo()
		NotificacionController.Anunciar(`{evento.icono} ¡{evento.nombre}! {evento.descripcion}`, "legendario")
		SonidoController.Reproducir("Evento")
		SonidoController.Pista("MusicaEvento")
		correccion.TintColor = Color3.new(1, 1, 1):Lerp(evento.color, 0.12)
		correccion.Enabled = true
	else
		banner.Visible = false
		SonidoController.Pista("MusicaPrincipal")
		correccion.Enabled = false
	end
end

function EventoController.Iniciar()
	banner = UI.Panel({
		Name = "Evento",
		Position = UDim2.fromOffset(8, 46),
		Size = UDim2.fromOffset(250, 46),
		Visible = false,
		Parent = HudController.Pantalla(),
	})
	UI.Escalar(banner)
	borde = UI.Borde(banner, Tema.COLORES.dinero, 2.5)
	textoNombre = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -12, 0, 24),
		posicion = UDim2.fromOffset(6, 2),
		tamanoLetra = 18,
		alineacion = Enum.TextXAlignment.Left,
		padre = banner,
	})
	textoTiempo = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -12, 0, 18),
		posicion = UDim2.fromOffset(6, 25),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = banner,
	})

	correccion = Instance.new("ColorCorrectionEffect")
	correccion.Name = "TonoEvento"
	correccion.Enabled = false
	correccion.Parent = Lighting

	carpetaLluvia = Instance.new("Folder")
	carpetaLluvia.Name = "LluviaLocal"
	carpetaLluvia.Parent = workspace
	for _ = 1, ConfigEventos.LLUVIA.MAX_MANZANAS do
		table.insert(manzanas, crearManzana())
	end

	workspace:GetAttributeChangedSignal("EventoId"):Connect(alCambiar)
	alCambiar()
	Reloj.Cada(0.5, actualizarTiempo)
	RunService.Heartbeat:Connect(lluvia)
end

return EventoController
