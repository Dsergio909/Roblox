--!strict
--[[
	MisionesController
	Menú 📋 Misiones: diarias (3, se renuevan a las 00:00 UTC) y semanales.

	  - Barra de progreso, recompensa y botón Reclamar (verde cuando está lista).
	  - "🔄 Cambiar" para cambiar una diaria que no te gusta (1 gratis por día).
	  - El botón 📋 muestra un globito con cuántas misiones puedes reclamar.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigMisiones = require(Shared:WaitForChild("Config"):WaitForChild("Misiones"))
local ConfigConsumibles = require(Shared:WaitForChild("Config"):WaitForChild("Consumibles"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))

local MisionesController = {}

local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local boton: TextButton? = nil
local textosTiempo: { [TextLabel]: { tipo: string } } = {}

local function estado(): any
	local e = EstadoCliente.Obtener("misiones")
	return if type(e) == "table" then e else nil
end

local function enviar(accion: string, id: string)
	Red.Evento("AccionMenu"):FireServer(accion, id)
end

local function textoRecompensa(mision: any): string
	local partes = { `💰 {Formato.Dinero(mision.dinero or 0)}`, `⭐ {mision.xp or 0} XP` }
	if (mision.semillas or 0) > 0 then
		table.insert(partes, `🌱 {mision.semillas}`)
	end
	local objeto = mision.objeto
	if type(objeto) == "table" and type(objeto.id) == "string" then
		local icono = "🎒"
		for _, consumible in ConfigConsumibles.LISTA do
			if consumible.id == objeto.id then
				icono = consumible.icono
			end
		end
		table.insert(partes, `{icono} ×{objeto.cantidad or 1}`)
	end
	return table.concat(partes, "  ")
end

local function tarjeta(padre: Instance, mision: any, orden: number, esDiaria: boolean, cambios: number)
	local marco = UI.Panel({
		Size = UDim2.new(1, -8, 0, 74),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		LayoutOrder = orden,
		Parent = padre,
	})
	local completa = mision.progreso >= mision.meta
	UI.Texto({
		texto = mision.texto,
		tamano = UDim2.new(1, -150, 0, 24),
		posicion = UDim2.fromOffset(10, 6),
		tamanoLetra = 17,
		alineacion = Enum.TextXAlignment.Left,
		padre = marco,
	})
	UI.Texto({
		texto = textoRecompensa(mision),
		tamano = UDim2.new(1, -150, 0, 18),
		posicion = UDim2.fromOffset(10, 30),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.dinero,
		padre = marco,
	})
	local _, fijar = UI.Barra(marco, UDim2.new(1, -170, 0, 10), Tema.COLORES.verde, UDim2.fromOffset(10, 54))
	fijar(mision.progreso / math.max(1, mision.meta))
	UI.Texto({
		texto = `{mision.progreso}/{mision.meta}`,
		tamano = UDim2.fromOffset(60, 16),
		posicion = UDim2.new(1, -160, 0, 50),
		tamanoLetra = 13,
		padre = marco,
	})

	if mision.reclamada then
		UI.Texto({
			texto = "✅",
			tamano = UDim2.fromOffset(130, 60),
			posicion = UDim2.new(1, -10, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 30,
			padre = marco,
		})
	elseif completa then
		UI.Boton({
			texto = "¡Reclamar!",
			color = Tema.COLORES.verde,
			tamano = UDim2.fromOffset(130, 50),
			posicion = UDim2.new(1, -8, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 18,
			alPulsar = function()
				enviar("mision_reclamar", mision.id)
			end,
			padre = marco,
		})
	elseif esDiaria and cambios > 0 then
		UI.Boton({
			texto = "🔄 Cambiar",
			color = Tema.COLORES.fondo,
			tamano = UDim2.fromOffset(130, 44),
			posicion = UDim2.new(1, -8, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 16,
			alPulsar = function()
				enviar("mision_cambiar", mision.id)
			end,
			padre = marco,
		})
	end
end

local function contarListas(e: any): number
	local cantidad = 0
	for _, grupo in { e.diarias or {}, e.semanales or {} } do
		for _, mision in grupo do
			if not mision.reclamada and mision.progreso >= mision.meta then
				cantidad += 1
			end
		end
	end
	return cantidad
end

local function encabezado(padre: Instance, texto: string, orden: number, tipo: string?): TextLabel
	local label = UI.Texto({
		texto = texto,
		tamano = UDim2.new(1, -8, 0, 26),
		tamanoLetra = 19,
		alineacion = Enum.TextXAlignment.Left,
		padre = padre,
	})
	label.LayoutOrder = orden
	if tipo then
		textosTiempo[label] = { tipo = tipo }
	end
	return label
end

local function actualizarTiempos()
	local e = estado()
	if e == nil then
		return
	end
	local ahora = Reloj.Ahora()
	for label, info in textosTiempo do
		if label.Parent == nil then
			textosTiempo[label] = nil
		elseif info.tipo == "diarias" then
			label.Text = `☀️ Diarias · nuevas en {Formato.Duracion(e.finDia - ahora)}`
		else
			label.Text = `📅 Semanales · terminan en {Formato.Duracion(e.finSemana - ahora)}`
		end
	end
end

local function refrescar()
	local e = estado()
	if boton then
		HudController.Globito(boton, if e then contarListas(e) else 0)
	end
	local v = ventana
	local l = lista
	if v == nil or l == nil or not v:EstaAbierta() or e == nil then
		return
	end
	UI.Vaciar(l)
	textosTiempo = {}
	encabezado(l, "", 1, "diarias")
	for i, mision in e.diarias do
		tarjeta(l, mision, 1 + i, true, e.cambios or 0)
	end
	local bonus = ConfigMisiones.BONUS_DIARIO
	local canasta = Catalogo.canasta[bonus.canasta]
	local textoBonus = UI.Texto({
		texto = `{if e.bonusDiario then "✅" else "🏅"} Completa las 3 diarias: 🧺 {if canasta
			then canasta.nombre
			else ""} + ⭐ {bonus.xp} XP   ·   Cambios hoy: {e.cambios or 0}`,
		tamano = UDim2.new(1, -8, 0, 22),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = l,
	})
	textoBonus.LayoutOrder = 10
	encabezado(l, "", 20, "semanales")
	for i, mision in e.semanales do
		tarjeta(l, mision, 20 + i, false, 0)
	end
	actualizarTiempos()
end

function MisionesController.Abrir()
	if ventana then
		ventana:Abrir()
	end
end

function MisionesController.Iniciar()
	local v = Ventana.nueva("📋 Misiones", 540, 340, Tema.COLORES.verde)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end
	lista = UI.Lista({ Size = UDim2.fromScale(1, 1), Parent = v.contenido }, 6)

	boton = HudController.AgregarBoton("📋", Tema.COLORES.verde, 3, function()
		v:Alternar()
	end)

	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "misiones" then
			refrescar()
		end
	end)
	Reloj.Cada(1, function()
		if v:EstaAbierta() then
			actualizarTiempos()
		end
	end)
end

return MisionesController
