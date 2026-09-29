--!strict
--[[
	BienvenidaController
	Ventana 🎁 Recompensas: calendario diario (7 días), racha y ganancias offline.

	Se abre SOLA una vez por sesión si hay algo que cobrar, pero NUNCA en la primera
	sesión de un jugador nuevo (sus primeros 60 segundos son para jugar, no para leer).
	En ese caso solo aparece un globito en el botón 🎁.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigLogin = require(Shared:WaitForChild("Config"):WaitForChild("Login"))
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))

local BienvenidaController = {}

local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local boton: TextButton? = nil
local abiertaEstaSesion = false

local ICONOS: { [string]: string } = { dinero = "💰", canasta = "🧺", semilla = "🌱" }

local function login(): any
	local e = EstadoCliente.Obtener("login")
	return if type(e) == "table" then e else nil
end

local function offline(): any
	local e = EstadoCliente.Obtener("offline")
	return if type(e) == "table" then e else nil
end

local function pendientes(): number
	local cantidad = 0
	local l = login()
	if l and l.pendiente then
		cantidad += 1
	end
	local o = offline()
	if o and (o.pendiente or 0) > 0 then
		cantidad += 1
	end
	return cantidad
end

local function refrescar()
	if boton then
		HudController.Globito(boton, pendientes())
	end
	local v = ventana
	local l = lista
	if v == nil or l == nil or not v:EstaAbierta() then
		return
	end
	UI.Vaciar(l)
	local datosLogin = login()
	local datosOffline = offline()

	-- Ganancias offline
	if datosOffline and (datosOffline.pendiente or 0) > 0 then
		local marco = UI.Panel({
			Size = UDim2.new(1, -8, 0, 78),
			BackgroundColor3 = Tema.COLORES.fondoClaro,
			LayoutOrder = 1,
			Parent = l,
		})
		UI.Borde(marco, Tema.COLORES.dinero, 2)
		local tiempo = if (datosOffline.segundos or 0) > 0 then ` ({Formato.Duracion(datosOffline.segundos)})` else ""
		UI.Texto({
			texto = `💤 Mientras no estabas{tiempo}, tus Crunchis ganaron:`,
			tamano = UDim2.new(1, -160, 0, 26),
			posicion = UDim2.fromOffset(10, 6),
			tamanoLetra = 16,
			alineacion = Enum.TextXAlignment.Left,
			padre = marco,
		})
		UI.Texto({
			texto = Formato.Dinero(datosOffline.pendiente),
			tamano = UDim2.new(1, -160, 0, 36),
			posicion = UDim2.fromOffset(10, 34),
			tamanoLetra = 30,
			alineacion = Enum.TextXAlignment.Left,
			color = Tema.COLORES.dinero,
			padre = marco,
		})
		UI.Boton({
			texto = "¡Cobrar!",
			color = Tema.COLORES.verde,
			tamano = UDim2.fromOffset(140, 52),
			posicion = UDim2.new(1, -10, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			alPulsar = function()
				Red.Evento("AccionMenu"):FireServer("offline_cobrar")
			end,
			padre = marco,
		})
	end

	if datosLogin == nil then
		return
	end

	-- Racha
	UI.Texto({
		texto = `🔥 Racha: {datosLogin.racha} día(s) seguidos → +{math.floor((datosLogin.bonus or 0) * 100)} % de ingreso (máx. +{math.floor(
			datosLogin.rachaMaxima * ConfigLogin.RACHA_BONUS_POR_DIA * 100
		)} %). Si faltas un día, solo baja un paso.`,
		tamano = UDim2.new(1, -8, 0, 40),
		tamanoLetra = 15,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.naranja,
		padre = l,
	}).LayoutOrder =
		2

	-- Calendario de 7 días
	local fila = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 96),
		LayoutOrder = 3,
		Parent = l,
	})
	UI.Crear("UIGridLayout", {
		CellSize = UDim2.new(1 / 7, -6, 1, 0),
		CellPadding = UDim2.fromOffset(6, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = fila,
	})
	for dia, recompensa in ConfigLogin.CALENDARIO do
		local reclamado = dia < datosLogin.dia or (dia == datosLogin.dia and not datosLogin.pendiente)
		local esHoy = dia == datosLogin.dia and datosLogin.pendiente
		local celda = UI.Panel({
			BackgroundColor3 = if esHoy then Color3.fromRGB(70, 60, 20) else Tema.COLORES.fondoClaro,
			LayoutOrder = dia,
			Parent = fila,
		})
		UI.Borde(celda, if esHoy then Tema.COLORES.dinero else Tema.COLORES.fondo, if esHoy then 3 else 1)
		UI.Texto({
			texto = `Día {dia}`,
			tamano = UDim2.new(1, 0, 0, 18),
			posicion = UDim2.fromOffset(0, 4),
			tamanoLetra = 13,
			padre = celda,
		})
		UI.Texto({
			texto = if reclamado then "✅" else (ICONOS[recompensa.tipo] or "🎁"),
			tamano = UDim2.new(1, 0, 0, 34),
			posicion = UDim2.fromOffset(0, 22),
			tamanoLetra = 28,
			padre = celda,
		})
		UI.Texto({
			texto = recompensa.texto,
			tamano = UDim2.new(1, -4, 0, 30),
			posicion = UDim2.fromOffset(2, 60),
			tamanoLetra = 11,
			color = Tema.COLORES.textoSuave,
			padre = celda,
		})
	end

	if datosLogin.pendiente then
		UI.Boton({
			texto = `🎁 Reclamar día {datosLogin.dia}`,
			color = Tema.COLORES.verde,
			tamano = UDim2.new(1, -8, 0, 52),
			tamanoLetra = 20,
			alPulsar = function()
				Red.Evento("AccionMenu"):FireServer("login_reclamar")
			end,
			padre = l,
		}).LayoutOrder =
			4
	else
		UI.Texto({
			texto = "Vuelve mañana para la siguiente recompensa. El calendario nunca se reinicia.",
			tamano = UDim2.new(1, -8, 0, 30),
			tamanoLetra = 15,
			color = Tema.COLORES.textoSuave,
			padre = l,
		}).LayoutOrder =
			4
	end
end

-- Abre la ventana automáticamente una vez por sesión (no en la primera sesión).
local function quizasAbrir()
	if abiertaEstaSesion or not EstadoCliente.Listo then
		return
	end
	local tutorial = EstadoCliente.Obtener("tutorial")
	local sesiones = if type(tutorial) == "table" then tutorial.sesiones or 0 else 0
	if sesiones <= 1 or pendientes() == 0 then
		return
	end
	abiertaEstaSesion = true
	task.delay(2, function()
		if ventana and not Ventana.HayAbierta() then
			ventana:Abrir()
		end
	end)
end

function BienvenidaController.Iniciar()
	local v = Ventana.nueva("🎁 Recompensas", 560, 340, Tema.COLORES.dinero)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end
	lista = UI.Lista({ Size = UDim2.fromScale(1, 1), Parent = v.contenido }, 8)

	boton = HudController.AgregarBoton("🎁", Color3.fromRGB(230, 170, 30), 1, function()
		v:Alternar()
	end, "izquierda")

	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "login" or parte == "offline" or parte == "_listo" then
			refrescar()
			quizasAbrir()
		end
	end)
end

return BienvenidaController
