--!strict
--[[
	HudController
	La interfaz fija de la pantalla (pensada primero para celular):

	  Arriba al centro:   💰 dinero (el número "cuenta" hacia arriba al ganar) y +$/s
	  Arriba a la izq.:   estado de tu base (🛡️ escudo / 🔒 cerrada / ⚠️ sin protección)
	  Abajo al centro:    si cargas un Crunchi robado: "¡Llévalo a tu base!" + barra de tiempo

	Lee atributos públicos del jugador (Dinero, IngresoSeg, Cargando...) y de su base.
	Otros controladores pueden agregar botones con HudController.AgregarBoton (Fases 2–4).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local ConfigRobo = require(Shared:WaitForChild("Config"):WaitForChild("Robo"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local BaseController = require(script.Parent:WaitForChild("BaseController"))

local HudController = {
	-- Lo asigna la tienda: abrir la pestaña de pases desde el aviso discreto "x2 para siempre".
	AlPedirX2 = nil :: (() -> ())?,
}

local jugador = Players.LocalPlayer

local pantalla: ScreenGui
local textoDinero: TextLabel
local textoIngreso: TextLabel
local pildoraDinero: Frame
local superiorHud: Frame? = nil
local textoBoost: TextLabel
local botonX2: TextButton? = nil
local textoEstadoBase: TextLabel
local panelCarga: Frame
local textoCarga: TextLabel
local barraCarga: Frame
local columnaBotones: Frame
local columnaIzquierda: Frame

local dineroMostrado = 0
local dineroObjetivo = 0

----------------------------------------------------------------------------- botones laterales

-- Agrega un botón a una columna lateral (Tienda, Índice, Misiones...). `lado` puede ser
-- "derecha" (por defecto) o "izquierda". Devuelve el botón (para ponerle un globito).
function HudController.AgregarBoton(
	texto: string,
	color: Color3,
	orden: number,
	alPulsar: () -> (),
	lado: string?
): TextButton
	local boton = UI.Boton({
		texto = texto,
		color = color,
		tamano = UDim2.fromOffset(50, 50),
		tamanoLetra = 24,
		alPulsar = alPulsar,
		padre = if lado == "izquierda" then columnaIzquierda else columnaBotones,
	})
	boton.LayoutOrder = orden
	return boton
end

-- Globito rojo con número (p. ej. misiones completadas por reclamar). 0 = ocultar.
function HudController.Globito(boton: GuiObject, cantidad: number)
	local globo = boton:FindFirstChild("Globito") :: TextLabel?
	if globo == nil then
		local nuevo = UI.Texto({
			texto = "",
			tamano = UDim2.fromOffset(22, 22),
			posicion = UDim2.new(1, -8, 0, -6),
			tamanoLetra = 14,
			padre = boton,
		})
		nuevo.Name = "Globito"
		nuevo.BackgroundTransparency = 0
		nuevo.BackgroundColor3 = Tema.COLORES.rojo
		UI.Esquinas(nuevo, UDim.new(1, 0))
		globo = nuevo
	end
	local g = globo :: TextLabel
	g.Visible = cantidad > 0
	g.Text = if cantidad > 9 then "9+" else tostring(cantidad)
end

-- Bloque de arriba al centro (dinero, ingreso, boosts). Lo que se ponga adentro escala junto.
function HudController.Superior(): Frame
	return superiorHud :: Frame
end

function HudController.Pantalla(): ScreenGui
	return pantalla
end

----------------------------------------------------------------------------- actualización

local function actualizarDinero()
	local dinero = jugador:GetAttribute("Dinero")
	local nuevo = if type(dinero) == "number" then dinero else 0
	if nuevo > dineroObjetivo and dineroObjetivo > 0 then
		UI.Rebote(pildoraDinero, 0.08)
	end
	dineroObjetivo = nuevo
	if nuevo < dineroMostrado then
		dineroMostrado = nuevo -- al gastar, baja al instante
	end
end

local function actualizarIngreso()
	local ingreso = jugador:GetAttribute("IngresoSeg")
	local valor = if type(ingreso) == "number" then ingreso else 0
	textoIngreso.Text = `+{Formato.Dinero(valor)}/s`
end

local function actualizarEstados()
	local momento = Reloj.Ahora()

	-- Estado de tu base
	local base = BaseController.MiBase()
	if base then
		local escudo = base:GetAttribute("EscudoHasta")
		local cerrojo = base:GetAttribute("CerrojoHasta")
		local revancha = base:GetAttribute("RevanchaHasta")
		if type(escudo) == "number" and escudo > momento then
			local tipo = base:GetAttribute("EscudoTipo")
			local nombre = if tipo == "novato" then "Escudo de novato" else "Escudo"
			textoEstadoBase.Text = `🛡️ {nombre} {Formato.Tiempo(escudo - momento)}`
			textoEstadoBase.TextColor3 = Color3.fromRGB(140, 210, 255)
		elseif type(cerrojo) == "number" and cerrojo > momento then
			textoEstadoBase.Text = `🔒 Cerrada {Formato.Tiempo(cerrojo - momento)}`
			textoEstadoBase.TextColor3 = Color3.fromRGB(255, 140, 140)
		elseif type(revancha) == "number" and revancha > momento then
			textoEstadoBase.Text = `⚠️ Cerrojo en {Formato.Tiempo(revancha - momento)}`
			textoEstadoBase.TextColor3 = Tema.COLORES.naranja
		else
			textoEstadoBase.Text = "⚠️ Base abierta: ¡usa el cerrojo!"
			textoEstadoBase.TextColor3 = Tema.COLORES.dinero
		end
	else
		textoEstadoBase.Text = "Buscando tu base…"
		textoEstadoBase.TextColor3 = Tema.COLORES.textoSuave
	end

	-- Boosts
	local partes = {}
	local boostHasta = jugador:GetAttribute("BoostX2Hasta")
	local ahoraUnix = Reloj.Ahora() -- reloj del servidor (el del celular puede estar mal)
	local conBoost = type(boostHasta) == "number" and boostHasta > ahoraUnix
	if conBoost then
		table.insert(partes, `⚡ x2 {Formato.Tiempo((boostHasta :: number) - ahoraUnix)}`)
	end
	local suerteHasta = workspace:GetAttribute("SuerteHasta")
	if type(suerteHasta) == "number" and suerteHasta > ahoraUnix then
		table.insert(partes, `🍀 Suerte x2 {Formato.Tiempo(suerteHasta - ahoraUnix)}`)
	end
	-- Objetos de la Mochila con tiempo
	local jugoHasta = jugador:GetAttribute("JugoHasta")
	if type(jugoHasta) == "number" and jugoHasta > ahoraUnix then
		table.insert(partes, `🧃 {Formato.Tiempo(jugoHasta - ahoraUnix)}`)
	end
	local imanHasta = jugador:GetAttribute("ImanHasta")
	if type(imanHasta) == "number" and imanHasta > ahoraUnix then
		table.insert(partes, `🧲 {Formato.Tiempo(imanHasta - ahoraUnix)}`)
	end
	textoBoost.Text = table.concat(partes, "  ")
	-- Tras la prueba gratis: un botón pequeño "x2 para siempre" (nunca un pop-up).
	local pases = jugador:GetAttribute("Pases")
	local tieneX2 = type(pases) == "string" and string.find(pases, "X2_DINERO", 1, true) ~= nil
	local probo = type(boostHasta) == "number" and boostHasta > 0
	if botonX2 then
		botonX2.Visible = probo and not conBoost and not tieneX2
	end

	-- Cargando un Crunchi robado
	local cargando = jugador:GetAttribute("Cargando") == true
	panelCarga.Visible = cargando
	if cargando then
		local hasta = jugador:GetAttribute("CargandoHasta")
		local crunchiId = jugador:GetAttribute("CargandoCrunchi")
		local restante = if type(hasta) == "number" then math.max(0, hasta - momento) else 0
		local def = if type(crunchiId) == "string" then Catalogo.datos.crunchi[crunchiId] else nil
		textoCarga.Text = `🏃 ¡Lleva a {if def then def.nombre else "tu Crunchi"} a tu base! {math.ceil(restante)} s`
		barraCarga.Size = UDim2.fromScale(math.clamp(restante / ConfigRobo.TIEMPO_MAXIMO_CARGA, 0, 1), 1)
	end
end

-- El número de dinero "cuenta" hacia el valor real (se siente como una recompensa).
local function animarDinero(dt: number)
	if dineroMostrado ~= dineroObjetivo then
		local diferencia = dineroObjetivo - dineroMostrado
		local paso = diferencia * math.min(1, dt * 8)
		if math.abs(diferencia) < 1 then
			dineroMostrado = dineroObjetivo
		else
			dineroMostrado += paso
		end
		textoDinero.Text = Formato.Dinero(dineroMostrado)
	end
end

----------------------------------------------------------------------------- construcción

local function construir()
	pantalla = UI.Pantalla("HUD", 5)

	-- Dinero (arriba al centro). El contenedor se escala desde arriba al centro.
	local superior = UI.Crear("Frame", {
		Name = "Superior",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(210, 106),
		Parent = pantalla,
	})
	UI.Escalar(superior)
	superiorHud = superior
	pildoraDinero = UI.Panel({
		Name = "Dinero",
		Size = UDim2.fromOffset(210, 50),
		Parent = superior,
	})
	UI.Borde(pildoraDinero, Tema.COLORES.dinero, 2.5)
	textoDinero = UI.Texto({
		texto = "$0",
		tamano = UDim2.new(1, -16, 1, 0),
		posicion = UDim2.fromOffset(8, 0),
		tamanoLetra = 32,
		color = Tema.COLORES.dinero,
		padre = pildoraDinero,
	})
	textoIngreso = UI.Texto({
		texto = "+$0/s",
		tamano = UDim2.fromOffset(210, 22),
		posicion = UDim2.fromOffset(0, 56),
		tamanoLetra = 18,
		color = Tema.COLORES.verde,
		padre = superior,
	})
	-- Boosts activos (⚡ x2 propio, 🍀 suerte del servidor)
	textoBoost = UI.Texto({
		texto = "",
		tamano = UDim2.fromOffset(210, 20),
		posicion = UDim2.fromOffset(0, 80),
		tamanoLetra = 15,
		color = Tema.COLORES.dinero,
		padre = superior,
	})

	-- Estado de la base (arriba a la izquierda)
	local pildoraBase = UI.Panel({
		Name = "EstadoBase",
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.fromOffset(250, 34),
		Parent = pantalla,
	})
	UI.Escalar(pildoraBase)
	textoEstadoBase = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -12, 1, 0),
		posicion = UDim2.fromOffset(6, 0),
		tamanoLetra = 16,
		padre = pildoraBase,
	})

	-- Cargando un Crunchi robado (abajo al centro, encima de la barra de herramientas)
	panelCarga = UI.Panel({
		Name = "Carga",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -92),
		Size = UDim2.fromOffset(380, 56),
		Visible = false,
		Parent = pantalla,
	})
	UI.Escalar(panelCarga, 380)
	UI.Borde(panelCarga, Tema.COLORES.rojo, 3)
	textoCarga = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -12, 0, 30),
		posicion = UDim2.fromOffset(6, 4),
		tamanoLetra = 19,
		padre = panelCarga,
	})
	local fondoBarra = UI.Panel({
		Position = UDim2.new(0, 10, 1, -16),
		Size = UDim2.new(1, -20, 0, 10),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		BackgroundTransparency = 0,
		Parent = panelCarga,
	})
	barraCarga = UI.Panel({
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Tema.COLORES.rojo,
		BackgroundTransparency = 0,
		Parent = fondoBarra,
	})

	-- Columna de botones (derecha, centrada verticalmente: cómoda para el pulgar)
	local function columna(nombre: string, ancla: Vector2, posicion: UDim2): Frame
		local marco = UI.Crear("Frame", {
			Name = nombre,
			BackgroundTransparency = 1,
			AnchorPoint = ancla,
			Position = posicion,
			Size = UDim2.fromOffset(58, 340),
			Parent = pantalla,
		}) :: Frame
		UI.Crear("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			Parent = marco,
		})
		UI.Escalar(marco, nil, 340)
		return marco
	end
	columnaBotones = columna("Botones", Vector2.new(1, 0.5), UDim2.new(1, -6, 0.5, 0))
	columnaIzquierda = columna("BotonesIzquierda", Vector2.new(0, 0.5), UDim2.new(0, 6, 0.5, 0))

	-- "x2 para siempre": aparece solo cuando terminó un boost y no tienes el pase.
	local x2 = UI.Boton({
		texto = "⚡ x2 para siempre",
		color = Tema.COLORES.fondoClaro,
		tamano = UDim2.fromOffset(170, 34),
		posicion = UDim2.new(0.5, 0, 0, 112),
		ancla = Vector2.new(0.5, 0),
		tamanoLetra = 14,
		alPulsar = function()
			local fn = HudController.AlPedirX2
			if fn then
				fn()
			end
		end,
		padre = superior,
	})
	x2.Visible = false
	botonX2 = x2
end

-- Auto-Cobro: un solo "+$X" junto al dinero (en lugar de uno por pedestal).
local function mostrarCobroTotal(cantidad: number)
	local texto = UI.Texto({
		texto = `+{Formato.Dinero(cantidad)}`,
		tamano = UDim2.fromOffset(120, 24),
		posicion = UDim2.new(1, 4, 0, 12),
		tamanoLetra = 20,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.dinero,
		padre = pildoraDinero,
	})
	local info = TweenInfo.new(0.9)
	TweenService:Create(texto, info, { Position = UDim2.new(1, 4, 0, -14), TextTransparency = 1 }):Play()
	task.delay(1, function()
		texto:Destroy()
	end)
end

function HudController.Iniciar()
	construir()
	Red.Evento("Cobro").OnClientEvent:Connect(function(lugar: any, cantidad: any)
		if lugar == 0 and type(cantidad) == "number" then
			mostrarCobroTotal(cantidad)
		end
	end)
	jugador:GetAttributeChangedSignal("Dinero"):Connect(actualizarDinero)
	jugador:GetAttributeChangedSignal("IngresoSeg"):Connect(actualizarIngreso)
	actualizarDinero()
	dineroMostrado = dineroObjetivo
	textoDinero.Text = Formato.Dinero(dineroMostrado)
	actualizarIngreso()
	RunService.RenderStepped:Connect(animarDinero)
	Reloj.Cada(0.25, actualizarEstados)
end

return HudController
