--!strict
--[[
	RebirthController
	Menú 🔁 Rebirth: qué cuesta, qué necesitas (✓/✗), qué ganas y qué pierdes.
	Pide confirmación doble antes de hacerlo. El botón del HUD avisa ("!") cuando ya
	puedes hacer rebirth.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local ConfigBase = require(Config:WaitForChild("Base"))
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

local RebirthController = {}

local jugador = Players.LocalPlayer
local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local boton: TextButton? = nil
local confirmando = false
local eligiendoAmigo = false

local function estado(): any
	local e = EstadoCliente.Obtener("rebirth")
	return if type(e) == "table" then e else nil
end

local function dinero(): number
	local d = jugador:GetAttribute("Dinero")
	return if type(d) == "number" then d else 0
end

local function puede(e: any): boolean
	return e.cumpleRequisitos == true and dinero() >= e.costo
end

local function crunchiPorUid(uid: string): any
	local datos = EstadoCliente.Obtener("crunchis")
	if type(datos) ~= "table" then
		return nil
	end
	for _, crunchi in datos.lista do
		if crunchi.uid == uid then
			return crunchi
		end
	end
	return nil
end

local function linea(padre: Instance, texto: string, ok: boolean?, orden: number)
	local color = if ok == nil then Tema.COLORES.texto elseif ok then Tema.COLORES.verde else Tema.COLORES.rojo
	local prefijo = if ok == nil then "" elseif ok then "✓ " else "✗ "
	UI.Texto({
		texto = prefijo .. texto,
		tamano = UDim2.new(1, -8, 0, 22),
		tamanoLetra = 17,
		alineacion = Enum.TextXAlignment.Left,
		color = color,
		padre = padre,
	}).LayoutOrder =
		orden
end

local function refrescarEleccionAmigo(l: ScrollingFrame)
	local datos = EstadoCliente.Obtener("crunchis")
	linea(l, "Elige tu Mejor Amigo (lo conservas tras el rebirth):", nil, 1)
	local rejilla = Tarjetas.Rejilla(l, 2)
	if type(datos) ~= "table" then
		return
	end
	local ordenados: { any } = table.clone(datos.lista)
	table.sort(ordenados, function(a, b)
		local _, pa = Catalogo.Valor(a.id, a.mut)
		local _, pb = Catalogo.Valor(b.id, b.mut)
		return pa > pb
	end)
	for i, crunchi in ordenados do
		local _, precio = Catalogo.Valor(crunchi.id, crunchi.mut)
		Tarjetas.Crunchi(crunchi.id, crunchi.mut, {
			orden = i,
			pie = if crunchi.uid == datos.mejorAmigo then "⭐ Elegido" else Formato.Dinero(precio),
			alPulsar = function()
				Red.Evento("AccionCrunchi"):FireServer("mejoramigo", crunchi.uid)
				eligiendoAmigo = false
			end,
			padre = rejilla,
		})
	end
end

local function refrescar()
	local e = estado()
	if boton then
		local listo = e ~= nil and puede(e)
		HudController.Globito(boton, if listo then 1 else 0)
		local globo = boton:FindFirstChild("Globito") :: TextLabel?
		if globo then
			globo.Text = "!"
		end
	end
	local v = ventana
	local l = lista
	if v == nil or l == nil or not v:EstaAbierta() or e == nil then
		return
	end
	UI.Vaciar(l)
	if eligiendoAmigo then
		refrescarEleccionAmigo(l)
		return
	end

	local multActual = 1 + e.actual * ConfigEconomia.BONUS.POR_REBIRTH
	local multNuevo = 1 + e.siguiente * ConfigEconomia.BONUS.POR_REBIRTH
	linea(l, `Rebirth {e.actual} → {e.siguiente}`, nil, 1)
	linea(l, "Ganas:", nil, 2)
	linea(l, `  💹 Ingreso x{multActual} → x{multNuevo} para siempre`, true, 3)
	local pedestales = math.min(
		ConfigBase.PEDESTALES_MAX_GRATIS,
		ConfigBase.PEDESTALES_INICIALES + e.siguiente * ConfigBase.PEDESTALES_POR_REBIRTH
	)
	linea(l, `  🏛️ {pedestales} pedestales · más tiempo de cerrojo`, true, 4)
	if e.desbloquea ~= "" then
		linea(l, `  🔓 {e.desbloquea}`, true, 5)
	end
	linea(l, "Necesitas:", nil, 6)
	linea(l, `  💰 {Formato.Dinero(e.costo)} (tienes {Formato.Dinero(dinero())})`, dinero() >= e.costo, 7)
	for i, requisito in e.requisitos do
		local rareza = Catalogo.datos.rareza[requisito.rareza]
		local nombre = if rareza then rareza.nombre else requisito.rareza
		linea(
			l,
			`  🍏 {requisito.cantidad} Crunchi {nombre} o mejor (tienes {requisito.tiene})`,
			requisito.cumple,
			7 + i
		)
	end
	linea(l, "Pierdes tu dinero y tus Crunchis, MENOS tu Mejor Amigo.", false, 20)
	linea(l, "Conservas: Índice, sets, títulos, misiones, semillas y canastas.", true, 21)

	-- Mejor Amigo
	local fila = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 122),
		LayoutOrder = 22,
		Parent = l,
	})
	local amigo = crunchiPorUid(e.mejorAmigo)
	if amigo then
		Tarjetas.Crunchi(amigo.id, amigo.mut, { pie = "⭐ Mejor Amigo", padre = fila })
	end
	UI.Boton({
		texto = "Cambiar Mejor Amigo",
		color = Tema.COLORES.fondoClaro,
		tamano = UDim2.fromOffset(200, 46),
		posicion = UDim2.fromOffset(110, 36),
		tamanoLetra = 16,
		alPulsar = function()
			eligiendoAmigo = true
			refrescar()
		end,
		padre = fila,
	})

	local listo = puede(e)
	local botonRebirth = UI.Boton({
		texto = if confirmando then "¿Seguro? Toca otra vez para confirmar" else "🔁 HACER REBIRTH",
		color = if listo
			then (if confirmando then Tema.COLORES.rojo else Tema.COLORES.morado)
			else Tema.COLORES.fondoClaro,
		tamano = UDim2.new(1, -8, 0, 54),
		tamanoLetra = 20,
		alPulsar = function()
			if not puede(e) then
				return
			end
			if confirmando then
				confirmando = false
				Red.Evento("AccionMenu"):FireServer("rebirth")
				if ventana then
					ventana:Cerrar()
				end
			else
				confirmando = true
				refrescar()
				task.delay(4, function()
					if confirmando then
						confirmando = false
						refrescar()
					end
				end)
			end
		end,
		padre = l,
	})
	botonRebirth.LayoutOrder = 30
end

function RebirthController.Iniciar()
	local v = Ventana.nueva("🔁 Rebirth", 540, 350, Tema.COLORES.morado)
	ventana = v
	v.alAbrir = function()
		confirmando = false
		eligiendoAmigo = false
		task.defer(refrescar)
	end
	lista = UI.Lista({ Size = UDim2.fromScale(1, 1), Parent = v.contenido }, 4)

	boton = HudController.AgregarBoton("🔁", Color3.fromRGB(120, 90, 220), 4, function()
		v:Alternar()
	end, "izquierda")

	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "rebirth" or parte == "crunchis" then
			refrescar()
		end
	end)
	jugador:GetAttributeChangedSignal("Dinero"):Connect(function()
		-- Solo lo necesario: el globito del botón (la ventana se refresca al abrirla).
		local e = estado()
		if boton and e then
			HudController.Globito(boton, if puede(e) then 1 else 0)
			local globo = boton:FindFirstChild("Globito") :: TextLabel?
			if globo then
				globo.Text = "!"
			end
		end
	end)
end

return RebirthController
