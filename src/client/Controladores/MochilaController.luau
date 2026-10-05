--!strict
--[[
	MochilaController
	Ventana 🎒 Mochila con dos pestañas:

	  Objetos  los consumibles (Config/Consumibles): cuántos tienes, "Usar" y "Comprar"
	           (con dinero del juego). Arriba, los efectos activos con su tiempo.
	  Armas    las armas de defensa (Config/Armas): equipar las desbloqueadas y, en las
	           bloqueadas, qué falta para conseguirlas (con barrita de progreso).

	Todo lo valida el servidor (ConsumibleService, ArmaService).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigConsumibles = require(Config:WaitForChild("Consumibles"))
local ConfigArmas = require(Config:WaitForChild("Armas"))
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Desbloqueo = require(Shared:WaitForChild("Logica"):WaitForChild("Desbloqueo"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))

local MochilaController = {}

local jugador = Players.LocalPlayer
local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local textoActivos: TextLabel? = nil
local botonesPestana: { [string]: TextButton } = {}
local pestanaActual = "objetos"

local function enviar(accion: string, datos: any)
	Red.Evento("AccionMenu"):FireServer(accion, datos)
end

local function parte(nombre: string): any
	local e = EstadoCliente.Obtener(nombre)
	return if type(e) == "table" then e else nil
end

local function panel(l: ScrollingFrame, orden: number, alto: number, colorBorde: Color3?): Frame
	local marco = UI.Panel({
		Size = UDim2.new(1, -8, 0, alto),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		LayoutOrder = orden,
		Parent = l,
	})
	if colorBorde then
		UI.Borde(marco, colorBorde, 2.5)
	end
	return marco
end

local function texto(padre: Instance, contenido: string, y: number, alto: number, tamano: number, color: Color3?)
	return UI.Texto({
		texto = contenido,
		tamano = UDim2.new(1, -150, 0, alto),
		posicion = UDim2.fromOffset(10, y),
		tamanoLetra = tamano,
		alineacion = Enum.TextXAlignment.Left,
		color = color,
		padre = padre,
	})
end

local function columnaBotones(padre: Instance): Frame
	local columna = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(130, 84),
		Parent = padre,
	})
	UI.Crear("UIListLayout", {
		Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = columna,
	})
	return columna
end

----------------------------------------------------------------------------- objetos

local function textoEfectosActivos(): string
	local ahora = Reloj.Ahora()
	local partes = {}
	local jugo = jugador:GetAttribute("JugoHasta")
	if type(jugo) == "number" and jugo > ahora then
		table.insert(partes, `🧃 Jugo Turbo {Formato.Tiempo(jugo - ahora)}`)
	end
	local iman = jugador:GetAttribute("ImanHasta")
	if type(iman) == "number" and iman > ahora then
		table.insert(partes, `🧲 Imán {Formato.Tiempo(iman - ahora)}`)
	end
	return if #partes > 0 then "Activos: " .. table.concat(partes, "  ·  ") else ""
end

local function pestanaObjetos(l: ScrollingFrame)
	local e = parte("consumibles") or { tiene = {}, precios = {} }
	local rebirths = jugador:GetAttribute("Rebirths")
	local nivel = if type(rebirths) == "number" then rebirths else 0
	for i, consumible in ConfigConsumibles.LISTA do
		local tiene = e.tiene[consumible.id] or 0
		local precio = e.precios[consumible.id] or 0
		local marco = panel(l, i, 92, if tiene > 0 then Tema.COLORES.verde else nil)
		texto(marco, `{consumible.icono} {consumible.nombre} · tienes {tiene}`, 6, 24, 18)
		texto(marco, consumible.descripcion, 32, 34, 13, Tema.COLORES.textoSuave)
		texto(marco, `💰 {Formato.Dinero(precio)} c/u`, 66, 20, 14, Tema.COLORES.dinero)

		local columna = columnaBotones(marco)
		local id = consumible.id
		if tiene > 0 then
			UI.Boton({
				texto = "Usar",
				color = Tema.COLORES.verde,
				tamano = UDim2.fromOffset(130, 38),
				tamanoLetra = 17,
				alPulsar = function()
					enviar("objeto_usar", id)
				end,
				padre = columna,
			})
		end
		if nivel < consumible.requisitoRebirths then
			UI.Texto({
				texto = `🔒 Rebirth {consumible.requisitoRebirths}`,
				tamano = UDim2.fromOffset(130, 38),
				tamanoLetra = 15,
				color = Tema.COLORES.textoSuave,
				padre = columna,
			})
		else
			UI.Boton({
				texto = "Comprar",
				color = Tema.COLORES.naranja,
				tamano = UDim2.fromOffset(130, 38),
				tamanoLetra = 16,
				alPulsar = function()
					enviar("objeto_comprar", { id = id, cantidad = 1 })
				end,
				padre = columna,
			})
		end
	end
end

----------------------------------------------------------------------------- armas

local function pestanaArmas(l: ScrollingFrame)
	local e = parte("armas")
	if e == nil then
		return
	end
	UI.Texto({
		texto = "Las armas solo sirven contra ladrones, intrusos en tu base y agentes de la Redada. No se compran: se desbloquean jugando.",
		tamano = UDim2.new(1, -8, 0, 34),
		tamanoLetra = 13,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = l,
	}).LayoutOrder =
		0
	for i, arma in ConfigArmas.LISTA do
		local desbloqueada = Desbloqueo.Cumple(arma.desbloqueo, e.resumen)
		local equipada = e.equipada == arma.id
		local marco =
			panel(l, i, 96, if equipada then Tema.COLORES.dinero elseif desbloqueada then Tema.COLORES.verde else nil)
		texto(marco, `{arma.icono} {arma.nombre}`, 6, 24, 18)
		texto(marco, arma.descripcion, 30, 20, 13, Tema.COLORES.textoSuave)
		texto(
			marco,
			`Alcance {arma.alcance} · Recarga {arma.cooldown} s · Empuje {arma.empuje}`,
			50,
			18,
			13,
			Tema.COLORES.azul
		)
		local columna = columnaBotones(marco)
		if equipada then
			UI.Texto({
				texto = "✅ Equipada",
				tamano = UDim2.fromOffset(130, 38),
				tamanoLetra = 17,
				color = Tema.COLORES.dinero,
				padre = columna,
			})
		elseif desbloqueada then
			local id = arma.id
			UI.Boton({
				texto = "Equipar",
				color = Tema.COLORES.verde,
				tamano = UDim2.fromOffset(130, 40),
				tamanoLetra = 17,
				alPulsar = function()
					enviar("arma_equipar", id)
				end,
				padre = columna,
			})
		else
			texto(marco, `🔒 {Desbloqueo.Texto(arma.desbloqueo)}`, 70, 18, 13, Tema.COLORES.naranja)
			local valor = math.floor(Desbloqueo.Valor(arma.desbloqueo.tipo, e.resumen))
			UI.Texto({
				texto = `{math.min(valor, arma.desbloqueo.valor)}/{arma.desbloqueo.valor}`,
				tamano = UDim2.fromOffset(130, 20),
				tamanoLetra = 15,
				color = Tema.COLORES.textoSuave,
				padre = columna,
			})
			local fondo = UI.Panel({
				Size = UDim2.fromOffset(130, 10),
				BackgroundColor3 = Tema.COLORES.fondo,
				BackgroundTransparency = 0,
				Parent = columna,
			})
			UI.Panel({
				Size = UDim2.fromScale(Desbloqueo.Progreso(arma.desbloqueo, e.resumen), 1),
				BackgroundColor3 = Tema.COLORES.verde,
				BackgroundTransparency = 0,
				Parent = fondo,
			})
		end
	end
end

----------------------------------------------------------------------------- ventana

function MochilaController.Refrescar()
	local v = ventana
	local l = lista
	for id, boton in botonesPestana do
		boton.BackgroundColor3 = if id == pestanaActual then Tema.COLORES.naranja else Tema.COLORES.fondoClaro
	end
	if v == nil or l == nil or not v:EstaAbierta() then
		return
	end
	UI.Vaciar(l)
	if pestanaActual == "objetos" then
		pestanaObjetos(l)
	else
		pestanaArmas(l)
	end
end

-- Abre la Mochila en una pestaña ("objetos" o "armas").
function MochilaController.Abrir(pestana: string?)
	if pestana then
		pestanaActual = pestana
	end
	local v = ventana
	if v then
		v:Abrir()
		MochilaController.Refrescar()
	end
end

function MochilaController.Iniciar()
	local v = Ventana.nueva("🎒 Mochila", 600, 360, Tema.COLORES.naranja)
	ventana = v
	v.alAbrir = function()
		task.defer(MochilaController.Refrescar)
	end
	local barra = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = v.contenido,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = barra,
	})
	for _, pestana in { { id = "objetos", texto = "🧃 Objetos" }, { id = "armas", texto = "🗞️ Armas" } } do
		botonesPestana[pestana.id] = UI.Boton({
			texto = pestana.texto,
			color = Tema.COLORES.fondoClaro,
			tamano = UDim2.fromOffset(150, 38),
			tamanoLetra = 16,
			alPulsar = function()
				pestanaActual = pestana.id
				MochilaController.Refrescar()
			end,
			padre = barra,
		})
	end
	textoActivos = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, 0, 0, 18),
		posicion = UDim2.fromOffset(0, 42),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.verde,
		padre = v.contenido,
	})
	lista = UI.Lista({
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64),
		Parent = v.contenido,
	}, 6)

	HudController.AgregarBoton("🎒", Tema.COLORES.naranja, 3, function()
		v:Alternar()
	end, "izquierda")

	EstadoCliente.Cambio:Conectar(function(nombre: string)
		if nombre == "consumibles" or nombre == "armas" then
			MochilaController.Refrescar()
		end
	end)
	Reloj.Cada(1, function()
		local t = textoActivos
		if t then
			t.Text = textoEfectosActivos()
		end
	end)
end

return MochilaController
