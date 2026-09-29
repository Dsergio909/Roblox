--!strict
--[[
	CanastasController
	Menú 🧺 Canastas + animación de revelación.

	⚠️ Las PROBABILIDADES de cada canasta se muestran SIEMPRE antes del botón de abrir.
	Se calculan de Config/Canastas, los mismos pesos que usa el servidor para sortear.

	La revelación (nombres que giran y se detienen en el premio) también se usa al
	cosechar el macetero.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local Tarjetas = require(Interfaz:WaitForChild("Tarjetas"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local SonidoController = require(script.Parent:WaitForChild("SonidoController"))
local EfectosController = require(script.Parent:WaitForChild("EfectosController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local CanastasController = {}

local jugador = Players.LocalPlayer
local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local boton: TextButton? = nil
local revelacion: Frame? = nil

local function estado(): any
	local e = EstadoCliente.Obtener("canastas")
	return if type(e) == "table" then e else { tickets = {}, maximoPorVez = 1 }
end

local function abrir(id: string, ticket: boolean, cantidad: number)
	Red.Evento("AccionMenu"):FireServer("canasta_abrir", { id = id, ticket = ticket, cantidad = cantidad })
end

-- Texto con las probabilidades por rareza, de mayor a menor rareza, con sus colores.
local function textoProbabilidades(pesos: { [string]: number }): string
	local probabilidades = Azar.Probabilidades(pesos)
	local partes = {}
	for i = #Catalogo.datos.rarezas, 1, -1 do
		local rareza = Catalogo.datos.rarezas[i]
		local p = probabilidades[rareza.id]
		if p then
			local c = if rareza.id == "secreto" then Color3.fromRGB(255, 255, 255) else rareza.color
			local hex = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
			table.insert(partes, `<font color="{hex}">{rareza.nombre} {Formato.Porcentaje(p)}</font>`)
		end
	end
	return table.concat(partes, "  ·  ")
end

local function tarjetaCanasta(padre: Instance, canasta: any, orden: number, e: any)
	local tickets = e.tickets[canasta.id] or 0
	if canasta.soloTicket and tickets <= 0 then
		return
	end
	local marco = UI.Panel({
		Size = UDim2.new(1, -8, 0, 104),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		LayoutOrder = orden,
		Parent = padre,
	})
	UI.Borde(marco, canasta.color, 2.5)
	UI.Texto({
		texto = `🧺 {canasta.nombre}{if tickets > 0 then `   ·   🎟️ tienes {tickets}` else ""}`,
		tamano = UDim2.new(1, -20, 0, 24),
		posicion = UDim2.fromOffset(10, 4),
		tamanoLetra = 19,
		alineacion = Enum.TextXAlignment.Left,
		color = canasta.color:Lerp(Color3.new(1, 1, 1), 0.3),
		padre = marco,
	})
	local probabilidades = UI.Texto({
		texto = textoProbabilidades(canasta.pesos),
		tamano = UDim2.new(1, -20, 0, 32),
		posicion = UDim2.fromOffset(10, 28),
		tamanoLetra = 13,
		alineacion = Enum.TextXAlignment.Left,
		padre = marco,
	})
	probabilidades.RichText = true

	local botones = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 1, -44),
		Size = UDim2.new(1, -20, 0, 40),
		Parent = marco,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 6),
		Parent = botones,
	})
	local rebirths = jugador:GetAttribute("Rebirths")
	local nivel = if type(rebirths) == "number" then rebirths else 0
	if tickets > 0 then
		UI.Boton({
			texto = "Abrir gratis 🎟️",
			color = Tema.COLORES.verde,
			tamano = UDim2.fromOffset(150, 40),
			tamanoLetra = 16,
			alPulsar = function()
				abrir(canasta.id, true, 1)
			end,
			padre = botones,
		})
	end
	if not canasta.soloTicket then
		if nivel < canasta.requisitoRebirths then
			UI.Texto({
				texto = `🔒 Rebirth {canasta.requisitoRebirths}`,
				tamano = UDim2.fromOffset(150, 40),
				tamanoLetra = 16,
				color = Tema.COLORES.textoSuave,
				padre = botones,
			})
		else
			local maximo = e.maximoPorVez or 1
			if maximo > 1 then
				UI.Boton({
					texto = `Abrir x{maximo} {Formato.Dinero(canasta.precio * maximo)}`,
					color = Tema.COLORES.azul,
					tamano = UDim2.fromOffset(170, 40),
					tamanoLetra = 15,
					alPulsar = function()
						abrir(canasta.id, false, maximo)
					end,
					padre = botones,
				})
			end
			UI.Boton({
				texto = `Abrir {Formato.Dinero(canasta.precio)}`,
				color = Tema.COLORES.naranja,
				tamano = UDim2.fromOffset(150, 40),
				tamanoLetra = 16,
				alPulsar = function()
					abrir(canasta.id, false, 1)
				end,
				padre = botones,
			})
		end
	end
end

local function totalTickets(e: any): number
	local total = 0
	for _, cantidad in e.tickets do
		total += cantidad
	end
	return total
end

local function refrescar()
	local e = estado()
	if boton then
		HudController.Globito(boton, totalTickets(e))
	end
	local v = ventana
	local l = lista
	if v == nil or l == nil or not v:EstaAbierta() then
		return
	end
	UI.Vaciar(l)
	local nota = UI.Texto({
		texto = "Se pagan con dinero del juego. Las probabilidades de cada canasta se muestran siempre.",
		tamano = UDim2.new(1, -8, 0, 20),
		tamanoLetra = 13,
		color = Tema.COLORES.textoSuave,
		padre = l,
	})
	nota.LayoutOrder = 0
	for i, canasta in Catalogo.canastas do
		tarjetaCanasta(l, canasta, i, e)
	end
end

----------------------------------------------------------------------------- revelación

local function mostrarRevelacion(titulo: string, resultados: { any })
	local marco = revelacion
	if marco == nil then
		return
	end
	marco.Visible = true
	UI.Vaciar(marco:FindFirstChild("Premios") :: Instance)
	local tituloLabel = marco:FindFirstChild("Titulo") :: TextLabel
	tituloLabel.Text = titulo
	local premios = marco:FindFirstChild("Premios") :: Frame

	-- Suspenso: nombres al azar girando durante ~1.2 s
	local girador = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, 0, 0, 40),
		tamanoLetra = 30,
		padre = premios,
	})
	local crunchis = Catalogo.datos.crunchis
	for i = 1, 14 do
		local azar = crunchis[math.random(1, #crunchis)]
		girador.Text = azar.nombre
		local rareza = Catalogo.RarezaDe(azar.id)
		girador.TextColor3 = if rareza then rareza.color else Tema.COLORES.texto
		SonidoController.Reproducir("Clic")
		task.wait(0.04 + i * 0.006)
	end
	girador:Destroy()

	local mejorOrden = 0
	for i, resultado in resultados do
		Tarjetas.Crunchi(resultado.crunchi, resultado.mut, {
			orden = i,
			pie = if resultado.nuevo then "📖 ¡NUEVO!" else nil,
			padre = premios,
		})
		mejorOrden = math.max(mejorOrden, Catalogo.OrdenDe(resultado.crunchi))
	end
	local primera = resultados[1]
	local rareza = if primera then Catalogo.RarezaDe(primera.crunchi) else nil
	tituloLabel.Text = if #resultados == 1 and primera
		then `¡{Catalogo.NombreCompleto(primera.crunchi, primera.mut)}!`
		else `¡{#resultados} Crunchis!`
	tituloLabel.TextColor3 = if rareza and rareza.id ~= "secreto" then rareza.color else Tema.COLORES.dinero
	UI.Rebote(premios, 0.3)
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		EfectosController.Confeti(
			raiz.Position + Vector3.new(0, 3, 0),
			if rareza then rareza.color else nil,
			30 + mejorOrden * 8
		)
	end
	if mejorOrden >= 4 then
		SonidoController.Reproducir("RarezaAlta")
	else
		SonidoController.Reproducir("Compra")
	end
	for _, resultado in resultados do
		if resultado.lugar == 0 then
			NotificacionController.Avisar("Tu base está llena: lo guardamos en el depósito 📦", "info")
			break
		end
	end
end

local function construirRevelacion()
	local pantalla = UI.Pantalla("Revelacion", 40)
	local marco = UI.Panel({
		Name = "Revelacion",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 240),
		BackgroundTransparency = 0.05,
		Visible = false,
		Active = true,
		Parent = pantalla,
	})
	UI.Escalar(marco, 420, 240)
	UI.Borde(marco, Tema.COLORES.dinero, 3)
	local titulo = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -20, 0, 40),
		posicion = UDim2.fromOffset(10, 8),
		tamanoLetra = 26,
		padre = marco,
	})
	titulo.Name = "Titulo"
	local premios = UI.Crear("Frame", {
		Name = "Premios",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 52),
		Size = UDim2.new(1, -20, 0, 122),
		Parent = marco,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = premios,
	})
	UI.Boton({
		texto = "¡Genial!",
		color = Tema.COLORES.verde,
		tamano = UDim2.fromOffset(160, 48),
		posicion = UDim2.new(0.5, 0, 1, -10),
		ancla = Vector2.new(0.5, 1),
		alPulsar = function()
			marco.Visible = false
		end,
		padre = marco,
	})
	revelacion = marco
end

function CanastasController.Abrir()
	if ventana then
		ventana:Abrir()
	end
end

function CanastasController.Iniciar()
	local v = Ventana.nueva("🧺 Canastas", 580, 350, Tema.COLORES.naranja)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end
	lista = UI.Lista({ Size = UDim2.fromScale(1, 1), Parent = v.contenido }, 8)
	construirRevelacion()

	boton = HudController.AgregarBoton("🧺", Tema.COLORES.naranja, 1, function()
		v:Alternar()
	end)

	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "canastas" then
			refrescar()
		end
	end)
	jugador:GetAttributeChangedSignal("Rebirths"):Connect(refrescar)

	Red.Evento("Efecto").OnClientEvent:Connect(function(nombre: any, datos: any)
		if nombre ~= "Canasta" or type(datos) ~= "table" or type(datos.resultados) ~= "table" then
			return
		end
		local canasta = Catalogo.canasta[datos.canasta]
		local titulo = if canasta then `Abriendo {canasta.nombre}…` else "🌱 Cosechando…"
		task.spawn(mostrarRevelacion, titulo, datos.resultados)
	end)

	-- Pequeña animación del botón para llamar la atención si hay tickets.
	task.spawn(function()
		while true do
			task.wait(4)
			local b = boton
			if b and totalTickets(estado()) > 0 then
				local escala = b:FindFirstChildOfClass("UIScale")
				if escala then
					TweenService:Create(escala, TweenInfo.new(0.2), { Scale = 1.12 }):Play()
					task.wait(0.2)
					TweenService:Create(escala, TweenInfo.new(0.2), { Scale = 1 }):Play()
				end
			end
		end
	end)
end

return CanastasController
