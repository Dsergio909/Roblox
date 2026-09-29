--!strict
--[[
	NotificacionController
	Mensajes en pantalla, sin interrumpir el juego:
	  - Avisos cortos (arriba, se apilan, máximo 3, desaparecen solos).
	  - Anuncios del servidor (Crunchi raro en la cinta, robos épicos) con el color de la rareza.
	  - Alarma de robo (borde rojo parpadeante + cartel), mientras dure el robo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local SonidoController = require(script.Parent:WaitForChild("SonidoController"))

local NotificacionController = {}

local MAX_AVISOS = 3
local DURACION_AVISO = 2.8

local pantalla: ScreenGui
local contenedorAvisos: Frame
local cartelAnuncio: TextLabel
local marcoAlarma: Frame
local cartelAlarma: TextLabel
local alarmaActiva = false
local contadorAvisos = 0

----------------------------------------------------------------------------- avisos

function NotificacionController.Avisar(texto: string, tipo: string?)
	contadorAvisos += 1
	local color = Tema.COLOR_NOTIFICACION[tipo or "info"] or Tema.COLORES.azul
	local aviso = UI.Panel({
		Name = "Aviso",
		Size = UDim2.fromOffset(340, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.1,
		LayoutOrder = -contadorAvisos, -- el más nuevo arriba
		Parent = contenedorAvisos,
	})
	UI.Borde(aviso, color, 2.5)
	UI.Margen(aviso, 8)
	UI.Texto({
		texto = texto,
		tamano = UDim2.fromScale(1, 0),
		tamanoLetra = 18,
		color = Tema.COLORES.texto,
		padre = aviso,
	}).AutomaticSize =
		Enum.AutomaticSize.Y

	-- Máximo MAX_AVISOS a la vez: se quitan los más viejos.
	local avisos = {}
	for _, hijo in contenedorAvisos:GetChildren() do
		if hijo:IsA("Frame") then
			table.insert(avisos, hijo)
		end
	end
	-- Del más nuevo (LayoutOrder más negativo) al más viejo.
	table.sort(avisos, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = MAX_AVISOS + 1, #avisos do
		avisos[i]:Destroy()
	end

	if tipo == "error" or tipo == "sinDinero" then
		SonidoController.Reproducir("Error")
	end
	UI.Rebote(aviso, 0.15)
	task.delay(DURACION_AVISO, function()
		if aviso.Parent then
			local tween = TweenService:Create(aviso, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
			tween:Play()
			for _, d in aviso:GetDescendants() do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				end
			end
			task.wait(0.35)
			aviso:Destroy()
		end
	end)
end

----------------------------------------------------------------------------- anuncios

local turnoAnuncio = 0

function NotificacionController.Anunciar(texto: string, rarezaId: string?)
	local rareza = if rarezaId then Catalogo.datos.rareza[rarezaId] else nil
	local color = if rareza then rareza.color else Tema.COLORES.dinero
	if rareza and rareza.id == "secreto" then
		color = Color3.fromRGB(255, 255, 255)
	end
	turnoAnuncio += 1
	local miTurno = turnoAnuncio
	cartelAnuncio.Text = texto
	cartelAnuncio.TextColor3 = color
	cartelAnuncio.Visible = true
	cartelAnuncio.TextTransparency = 0
	UI.Rebote(cartelAnuncio, 0.25)
	if rareza and rareza.orden >= 4 then
		SonidoController.Reproducir("RarezaAlta")
	end
	task.delay(3.5, function()
		if miTurno == turnoAnuncio then
			cartelAnuncio.Visible = false
		end
	end)
end

----------------------------------------------------------------------------- alarma

function NotificacionController.Alarma(activa: boolean, nombreLadron: string?)
	alarmaActiva = activa
	marcoAlarma.Visible = activa
	cartelAlarma.Visible = activa
	if activa then
		cartelAlarma.Text = `🚨 ¡{nombreLadron or "Alguien"} TE ESTÁ ROBANDO! 🗞️ ¡Dale con el periódico!`
		task.spawn(function()
			local encendido = true
			while alarmaActiva do
				marcoAlarma.BackgroundTransparency = if encendido then 0.75 else 0.92
				encendido = not encendido
				task.wait(0.35)
			end
		end)
	end
	SonidoController.Bucle("Alarma", activa)
end

----------------------------------------------------------------------------- inicio

function NotificacionController.Iniciar()
	pantalla = UI.Pantalla("Notificaciones", 20)

	contenedorAvisos = UI.Crear("Frame", {
		Name = "Avisos",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100),
		Size = UDim2.fromOffset(340, 160),
		Parent = pantalla,
	})
	UI.Crear("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = contenedorAvisos,
	})

	cartelAnuncio = UI.Texto({
		texto = "",
		tamano = UDim2.fromOffset(520, 60),
		posicion = UDim2.fromScale(0.5, 0.32),
		ancla = Vector2.new(0.5, 0.5),
		tamanoLetra = 30,
		padre = pantalla,
	})
	cartelAnuncio.Name = "Anuncio"
	cartelAnuncio.Visible = false

	marcoAlarma = UI.Crear("Frame", {
		Name = "MarcoAlarma",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Tema.COLORES.rojo,
		BackgroundTransparency = 0.8,
		Visible = false,
		Active = false,
		Parent = pantalla,
	})
	cartelAlarma = UI.Texto({
		texto = "",
		tamano = UDim2.fromOffset(560, 50),
		posicion = UDim2.new(0.5, 0, 0, 60),
		ancla = Vector2.new(0.5, 0),
		tamanoLetra = 24,
		color = Color3.fromRGB(255, 235, 235),
		padre = pantalla,
	})
	cartelAlarma.Name = "CartelAlarma"
	cartelAlarma.Visible = false

	Red.Evento("Notificar").OnClientEvent:Connect(function(texto: any, tipo: any)
		if type(texto) == "string" then
			NotificacionController.Avisar(texto, if type(tipo) == "string" then tipo else nil)
		end
	end)
	Red.Evento("Anuncio").OnClientEvent:Connect(function(texto: any, rarezaId: any)
		if type(texto) == "string" then
			NotificacionController.Anunciar(texto, if type(rarezaId) == "string" then rarezaId else nil)
		end
	end)
	Red.Evento("Alarma").OnClientEvent:Connect(function(activa: any, ladronUserId: any)
		local nombre: string? = nil
		if type(ladronUserId) == "number" then
			local ladron = Players:GetPlayerByUserId(ladronUserId)
			nombre = if ladron then ladron.DisplayName else nil
		end
		NotificacionController.Alarma(activa == true, nombre)
	end)
end

return NotificacionController
