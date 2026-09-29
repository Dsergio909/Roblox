--!strict
--[[
	DepositoController
	Menú 📦 Mis Crunchis (base + depósito) y el panel de OPCIONES de un Crunchi.

	Acciones (las valida el servidor):
	  💰 Vender (50 % del precio; pide confirmación si es Épico o mejor)
	  📦 Guardar en el depósito (no produce, pero no se puede robar)
	  ⬆️ Colocar en un pedestal libre
	  🔒 Mover a la bóveda (no se puede robar y sigue produciendo)
	  ⭐ Mejor Amigo (lo conservas al hacer rebirth)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigEconomia = require(Shared:WaitForChild("Config"):WaitForChild("Economia"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local Tarjetas = require(Interfaz:WaitForChild("Tarjetas"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local BaseController = require(script.Parent:WaitForChild("BaseController"))

local DepositoController = {}

local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local ventanaOpciones: Ventana.Ventana? = nil
local uidSeleccionado: string? = nil
local confirmarVenta: string? = nil

local function estado(): any
	local e = EstadoCliente.Obtener("crunchis")
	return if type(e) == "table" then e else nil
end

local function accion(nombre: string, uid: string)
	Red.Evento("AccionCrunchi"):FireServer(nombre, uid)
end

local function buscar(uid: string): any
	local e = estado()
	if e == nil then
		return nil
	end
	for _, crunchi in e.lista do
		if crunchi.uid == uid then
			return crunchi
		end
	end
	return nil
end

local function precioVenta(crunchi: any): number
	local _, precio = Catalogo.Valor(crunchi.id, crunchi.mut)
	return math.floor(precio * ConfigEconomia.VENTA_PORCENTAJE)
end

----------------------------------------------------------------------------- opciones

local function refrescarOpciones()
	local v = ventanaOpciones
	local uid = uidSeleccionado
	if v == nil or uid == nil or not v:EstaAbierta() then
		return
	end
	UI.Vaciar(v.contenido)
	local crunchi = buscar(uid)
	local e = estado()
	if crunchi == nil or e == nil then
		v:Cerrar()
		return
	end
	local ingreso = Catalogo.Valor(crunchi.id, crunchi.mut)
	Tarjetas.Crunchi(crunchi.id, crunchi.mut, {
		pie = if crunchi.uid == e.mejorAmigo then "⭐ Mejor Amigo" else nil,
		padre = v.contenido,
	})
	local lugar = if crunchi.lugar == 0
		then "📦 En el depósito"
		elseif crunchi.lugar <= (e.bovedas or 0) then `🔒 En la bóveda (pedestal {crunchi.lugar})`
		else `Pedestal {crunchi.lugar}`
	UI.Texto({
		texto = `{lugar}\n{Formato.Dinero(ingreso)}/s (sin bonus)\nValor de venta: {Formato.Dinero(
			precioVenta(crunchi)
		)}`,
		tamano = UDim2.new(1, -110, 0, 80),
		posicion = UDim2.fromOffset(106, 0),
		tamanoLetra = 16,
		alineacion = Enum.TextXAlignment.Left,
		padre = v.contenido,
	})

	local botones = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 126),
		Size = UDim2.new(1, 0, 1, -126),
		Parent = v.contenido,
	})
	UI.Crear("UIGridLayout", {
		CellSize = UDim2.fromOffset(176, 44),
		CellPadding = UDim2.fromOffset(6, 6),
		Parent = botones,
	})
	local rareza = Catalogo.RarezaDe(crunchi.id)
	local esValioso = rareza ~= nil and rareza.orden >= 4
	UI.Boton({
		texto = if confirmarVenta == uid
			then "¿Seguro? Toca otra vez"
			else `💰 Vender {Formato.Dinero(precioVenta(crunchi))}`,
		color = Tema.COLORES.rojo,
		tamanoLetra = 15,
		alPulsar = function()
			if esValioso and confirmarVenta ~= uid then
				confirmarVenta = uid
				refrescarOpciones()
				return
			end
			confirmarVenta = nil
			accion("vender", uid)
			v:Cerrar()
		end,
		padre = botones,
	})
	if crunchi.lugar == 0 then
		UI.Boton({
			texto = "⬆️ Colocar en la base",
			color = Tema.COLORES.verde,
			tamanoLetra = 15,
			alPulsar = function()
				accion("colocar", uid)
			end,
			padre = botones,
		})
	else
		UI.Boton({
			texto = "📦 Guardar en depósito",
			color = Tema.COLORES.azul,
			tamanoLetra = 15,
			alPulsar = function()
				accion("depositar", uid)
			end,
			padre = botones,
		})
	end
	if crunchi.lugar > (e.bovedas or 0) or crunchi.lugar == 0 then
		UI.Boton({
			texto = "🔒 A la bóveda",
			color = Color3.fromRGB(200, 150, 40),
			tamanoLetra = 15,
			alPulsar = function()
				accion("boveda", uid)
			end,
			padre = botones,
		})
	end
	if crunchi.uid ~= e.mejorAmigo then
		UI.Boton({
			texto = "⭐ Mejor Amigo",
			color = Tema.COLORES.morado,
			tamanoLetra = 15,
			alPulsar = function()
				accion("mejoramigo", uid)
			end,
			padre = botones,
		})
	end
end

function DepositoController.AbrirOpciones(uid: string)
	uidSeleccionado = uid
	confirmarVenta = nil
	if ventanaOpciones then
		ventanaOpciones:Abrir()
		refrescarOpciones()
	end
end

----------------------------------------------------------------------------- lista

local function refrescar()
	refrescarOpciones()
	local v = ventana
	local l = lista
	local e = estado()
	if v == nil or l == nil or not v:EstaAbierta() or e == nil then
		return
	end
	UI.Vaciar(l)
	local enBase, enDeposito = {}, {}
	for _, crunchi in e.lista do
		if crunchi.lugar == 0 then
			table.insert(enDeposito, crunchi)
		else
			table.insert(enBase, crunchi)
		end
	end
	local function porValor(a: any, b: any): boolean
		local _, pa = Catalogo.Valor(a.id, a.mut)
		local _, pb = Catalogo.Valor(b.id, b.mut)
		return pa > pb
	end
	table.sort(enBase, porValor)
	table.sort(enDeposito, porValor)

	local function seccion(titulo: string, crunchis: { any }, orden: number)
		UI.Texto({
			texto = titulo,
			tamano = UDim2.new(1, -8, 0, 24),
			tamanoLetra = 18,
			alineacion = Enum.TextXAlignment.Left,
			padre = l,
		}).LayoutOrder =
			orden
		local rejilla = Tarjetas.Rejilla(l, orden + 1)
		for i, crunchi in crunchis do
			local pie = if crunchi.uid == e.mejorAmigo
				then "⭐"
				elseif crunchi.lugar > 0 and crunchi.lugar <= (e.bovedas or 0) then "🔒 bóveda"
				else nil
			Tarjetas.Crunchi(crunchi.id, crunchi.mut, {
				orden = i,
				pie = pie,
				alPulsar = function()
					DepositoController.AbrirOpciones(crunchi.uid)
				end,
				padre = rejilla,
			})
		end
	end
	seccion(`🏠 En tu base ({#enBase}/{e.pedestales or 0})`, enBase, 1)
	seccion(`📦 Depósito ({#enDeposito}/{e.deposito or 0}) · no producen, no se pueden robar`, enDeposito, 3)
end

function DepositoController.Iniciar()
	local v = Ventana.nueva("📦 Mis Crunchis", 580, 350, Tema.COLORES.azul)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end
	lista = UI.Lista({ Size = UDim2.fromScale(1, 1), Parent = v.contenido }, 6)

	local opciones = Ventana.nueva("Opciones", 380, 290, Tema.COLORES.azul)
	ventanaOpciones = opciones

	HudController.AgregarBoton("📦", Tema.COLORES.azul, 2, function()
		v:Alternar()
	end, "izquierda")

	BaseController.OpcionesPedidas:Conectar(function(uid: string)
		DepositoController.AbrirOpciones(uid)
	end)
	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "crunchis" then
			refrescar()
		end
	end)
end

return DepositoController
