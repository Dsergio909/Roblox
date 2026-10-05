--!strict
--[[
	PaseController
	Menú ⭐ Pase Crunch: niveles de la temporada con su premio GRATIS y su premio PREMIUM.
	Muestra el nivel, la barra de XP, cuándo termina la temporada (fecha real) y los botones
	para comprar el Premium o saltar un nivel (sin pop-ups: solo si el jugador los toca).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigPase = require(Config:WaitForChild("Pase"))
local ConfigProductos = require(Config:WaitForChild("Productos"))
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local PaseController = {}

local jugador = Players.LocalPlayer
local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local encabezado: TextLabel? = nil
local fijarBarra: ((number) -> ())? = nil
local boton: TextButton? = nil

local function estado(): any
	local e = EstadoCliente.Obtener("pase")
	return if type(e) == "table" then e else nil
end

local function conjunto(listaNiveles: { number }?): { [number]: boolean }
	local resultado = {}
	local niveles: { number } = listaNiveles or {}
	for _, n in niveles do
		resultado[n] = true
	end
	return resultado
end

local function comprar(clave: string)
	local producto = ConfigProductos.PRODUCTOS[clave]
	if producto.id == 0 then
		NotificacionController.Avisar(
			"Este producto aún no está configurado (falta su ID en Config/Productos).",
			"error"
		)
		return
	end
	MarketplaceService:PromptProductPurchase(jugador, producto.id)
end

local function reclamables(e: any): number
	local gratis = conjunto(e.gratis)
	local premiumes = conjunto(e.premiumes)
	local cantidad = 0
	for n = 1, e.nivel do
		if not gratis[n] then
			cantidad += 1
		end
		if e.premium and not premiumes[n] then
			cantidad += 1
		end
	end
	return cantidad
end

local function celdaPremio(padre: Instance, premio: any, estadoPremio: string, nivel: number, esPremium: boolean)
	local marco = UI.Panel({
		BackgroundColor3 = if esPremium then Color3.fromRGB(70, 50, 20) else Tema.COLORES.fondoClaro,
		Size = UDim2.new(0.5, -40, 1, 0),
		Parent = padre,
	})
	UI.Texto({
		texto = premio.texto,
		tamano = UDim2.new(1, -110, 1, 0),
		posicion = UDim2.fromOffset(8, 0),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		padre = marco,
	})
	if estadoPremio == "reclamar" then
		UI.Boton({
			texto = "Reclamar",
			color = Tema.COLORES.verde,
			tamano = UDim2.fromOffset(100, 38),
			posicion = UDim2.new(1, -4, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 14,
			alPulsar = function()
				Red.Evento("AccionMenu"):FireServer("pase_reclamar", { nivel = nivel, premium = esPremium })
			end,
			padre = marco,
		})
	else
		local texto = if estadoPremio == "hecho" then "✅" elseif estadoPremio == "bloqueado" then "🔒" else "⏳"
		UI.Texto({
			texto = texto,
			tamano = UDim2.fromOffset(100, 38),
			posicion = UDim2.new(1, -4, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 22,
			padre = marco,
		})
	end
end

local function refrescar()
	local e = estado()
	if boton and e then
		HudController.Globito(boton, reclamables(e))
	end
	local v = ventana
	local l = lista
	if v == nil or l == nil or not v:EstaAbierta() or e == nil then
		return
	end
	UI.Vaciar(l)
	local xpNivel = e.xp - e.nivel * e.xpPorNivel
	local restante = e.fin - Reloj.Ahora()
	if encabezado then
		encabezado.Text = `{e.nombre} · Nivel {e.nivel}/{#ConfigPase.NIVELES} · `
			.. (if e.activa then `termina en {Formato.Duracion(restante)}` else "temporada terminada")
			.. (if e.premium then " · ⭐ PREMIUM" else "")
	end
	if fijarBarra then
		fijarBarra(if e.nivel >= #ConfigPase.NIVELES then 1 else xpNivel / e.xpPorNivel)
	end

	-- Botones de compra (solo si no tiene premium / si quiere saltar un nivel)
	local filaCompras = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 46),
		LayoutOrder = 0,
		Parent = l,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		Parent = filaCompras,
	})
	if not e.premium then
		UI.Boton({
			texto = `⭐ Premium · R$ {ConfigProductos.PRODUCTOS.PASE_PREMIUM.precio}`,
			color = Tema.COLORES.dinero,
			tamano = UDim2.fromOffset(230, 44),
			tamanoLetra = 16,
			alPulsar = function()
				comprar("PASE_PREMIUM")
			end,
			padre = filaCompras,
		})
	end
	if e.activa and e.nivel < #ConfigPase.NIVELES then
		UI.Boton({
			texto = `⏩ +1 nivel · R$ {ConfigProductos.PRODUCTOS.PASE_NIVEL.precio}`,
			color = Tema.COLORES.fondoClaro,
			tamano = UDim2.fromOffset(200, 44),
			tamanoLetra = 15,
			alPulsar = function()
				comprar("PASE_NIVEL")
			end,
			padre = filaCompras,
		})
	end

	local gratis = conjunto(e.gratis)
	local premiumes = conjunto(e.premiumes)
	for n, nivel in ConfigPase.NIVELES do
		local fila = UI.Crear("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -8, 0, 44),
			LayoutOrder = n,
			Parent = l,
		})
		UI.Crear("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			Parent = fila,
		})
		local alcanzado = n <= e.nivel
		UI.Texto({
			texto = tostring(n),
			tamano = UDim2.fromOffset(60, 44),
			tamanoLetra = 20,
			color = if alcanzado then Tema.COLORES.dinero else Tema.COLORES.textoSuave,
			padre = fila,
		})
		local estadoGratis = if gratis[n] then "hecho" elseif alcanzado then "reclamar" else "pendiente"
		local estadoPremium = if premiumes[n]
			then "hecho"
			elseif not e.premium then "bloqueado"
			elseif alcanzado then "reclamar"
			else "pendiente"
		celdaPremio(fila, nivel.gratis, estadoGratis, n, false)
		celdaPremio(fila, nivel.premium, estadoPremium, n, true)
	end
end

function PaseController.Iniciar()
	local v = Ventana.nueva("⭐ Pase Crunch", 600, 350, Tema.COLORES.dinero)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end
	encabezado = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, 0, 0, 20),
		tamanoLetra = 15,
		alineacion = Enum.TextXAlignment.Left,
		padre = v.contenido,
	})
	local _, fijar = UI.Barra(v.contenido, UDim2.new(1, 0, 0, 10), Tema.COLORES.dinero, UDim2.fromOffset(0, 24))
	fijarBarra = fijar
	UI.Texto({
		texto = "Nivel · Gratis · Premium",
		tamano = UDim2.new(1, 0, 0, 16),
		posicion = UDim2.fromOffset(0, 38),
		tamanoLetra = 13,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = v.contenido,
	})
	lista = UI.Lista({
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 1, -58),
		Parent = v.contenido,
	}, 4)

	boton = HudController.AgregarBoton("⭐", Tema.COLORES.dinero, 5, function()
		v:Alternar()
	end)
	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "pase" then
			refrescar()
		end
	end)
end

return PaseController
