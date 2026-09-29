--!strict
--[[
	ClasificacionService
	Tablas de clasificación GLOBALES del "Salón de la Fama" (Config/Clasificacion):
	Top Rebirths, Top Robos y Top Coleccionistas (Índice).

	  - Cada jugador sube su puntaje cada SUBIR_CADA segundos y al salir (solo si cambió).
	  - Los carteles se leen cada LEER_CADA segundos.
	Así se gasta muy poco del límite de DataStore de Roblox.

	Sin conexión a DataStore (Studio sin "Enable Studio Access to API Services") el juego
	funciona igual y los carteles lo dicen.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigClasificacion = require(Shared:WaitForChild("Config"):WaitForChild("Clasificacion"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))

type Cartel = { filas: { TextLabel }, estado: TextLabel }

local ClasificacionService = {}

local tiendas: { [string]: OrderedDataStore } = {}
local subidos: { [Player]: { [string]: number } } = {}
local nombres: { [number]: string } = {}
local carteles: { [string]: Cartel } = {}

----------------------------------------------------------------------------- puntajes

local function puntaje(tablaId: string, datos: Tipos.Datos): number
	if tablaId == "rebirths" then
		return datos.rebirths
	elseif tablaId == "robos" then
		return datos.stats.robosExitosos
	elseif tablaId == "indice" then
		local cantidad = 0
		for _ in datos.indice do
			cantidad += 1
		end
		return cantidad
	end
	return 0
end

local function subir(jugador: Player, datos: Tipos.Datos)
	local previos = subidos[jugador] or {}
	subidos[jugador] = previos
	for _, tabla in ConfigClasificacion.TABLAS do
		local tienda = tiendas[tabla.id]
		local valor = math.floor(puntaje(tabla.id, datos))
		if tienda and valor > 0 and previos[tabla.id] ~= valor then
			local ok = pcall(function()
				tienda:SetAsync(tostring(jugador.UserId), valor)
			end)
			if ok then
				previos[tabla.id] = valor
			end
		end
	end
end

----------------------------------------------------------------------------- carteles

local function nombreDe(userId: number): string
	local guardado = nombres[userId]
	if guardado then
		return guardado
	end
	local enServidor = Players:GetPlayerByUserId(userId)
	if enServidor then
		nombres[userId] = enServidor.Name
		return enServidor.Name
	end
	local ok, nombre = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and type(nombre) == "string" then
		nombres[userId] = nombre
		return nombre
	end
	return "???"
end

local function crearCartel(carpeta: Instance, indice: number, tabla: ConfigClasificacion.Tabla): Cartel
	local base = ConfigClasificacion.POSICION + Vector3.new(0, 0, (indice - 1) * ConfigClasificacion.SEPARACION)
	local centro = base + Vector3.new(0, 7.5, 0)
	local tablero = Instance.new("Part")
	tablero.Name = `Top_{tabla.id}`
	tablero.Anchored = true
	tablero.Size = Vector3.new(11, 12, 0.5)
	tablero.CFrame = CFrame.lookAt(centro, centro + Vector3.new(1, 0, 0)) -- mira a la avenida
	tablero.Color = Color3.fromRGB(25, 28, 40)
	tablero.Material = Enum.Material.SmoothPlastic
	tablero.CastShadow = false
	tablero.Parent = carpeta
	for _, lado in { -4, 4 } do
		local poste = Instance.new("Part")
		poste.Name = "Poste"
		poste.Anchored = true
		poste.Size = Vector3.new(0.6, 1.6, 0.6)
		poste.CFrame = tablero.CFrame * CFrame.new(lado, -6.8, 0)
		poste.Color = Color3.fromRGB(60, 64, 80)
		poste.CastShadow = false
		poste.Parent = carpeta
	end

	local superficie = Instance.new("SurfaceGui")
	superficie.Face = Enum.NormalId.Front
	superficie.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	superficie.PixelsPerStud = 25
	superficie.LightInfluence = 0
	superficie.Parent = tablero
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.Parent = superficie

	local function linea(orden: number, alto: number, color: Color3): TextLabel
		local texto = Instance.new("TextLabel")
		texto.LayoutOrder = orden
		texto.Size = UDim2.fromScale(0.94, alto)
		texto.BackgroundTransparency = 1
		texto.Font = Enum.Font.FredokaOne
		texto.TextScaled = true
		texto.TextColor3 = color
		texto.TextXAlignment = Enum.TextXAlignment.Left
		texto.Text = ""
		texto.Parent = superficie
		return texto
	end
	local titulo = linea(0, 0.12, tabla.color)
	titulo.TextXAlignment = Enum.TextXAlignment.Center
	titulo.Text = tabla.titulo
	local estado = linea(1, 0.05, Color3.fromRGB(170, 175, 195))
	estado.TextXAlignment = Enum.TextXAlignment.Center
	local filas: { TextLabel } = {}
	for puesto = 1, ConfigClasificacion.CANTIDAD do
		local color = if puesto == 1
			then Color3.fromRGB(255, 215, 80)
			elseif puesto == 2 then Color3.fromRGB(215, 220, 230)
			elseif puesto == 3 then Color3.fromRGB(230, 160, 100)
			else Color3.new(1, 1, 1)
		table.insert(filas, linea(puesto + 1, 0.8 / ConfigClasificacion.CANTIDAD, color))
	end
	return { filas = filas, estado = estado }
end

local function actualizarCartel(tabla: ConfigClasificacion.Tabla)
	local cartel = carteles[tabla.id]
	local tienda: OrderedDataStore? = tiendas[tabla.id]
	if cartel == nil then
		return
	end
	if tienda == nil then
		cartel.estado.Text = "Sin conexión con Roblox (en Studio: activa API Services)"
		return
	end
	local ok, pagina = pcall(function()
		return tienda:GetSortedAsync(false, ConfigClasificacion.CANTIDAD):GetCurrentPage()
	end)
	if not ok or type(pagina) ~= "table" then
		cartel.estado.Text = "No se pudo cargar (se reintenta solo)"
		return
	end
	for puesto, fila in cartel.filas do
		local entrada = pagina[puesto]
		if entrada then
			local userId = tonumber(entrada.key) or 0
			fila.Text = `{puesto}. {nombreDe(userId)} — {Formato.Corto(entrada.value)}`
		else
			fila.Text = `{puesto}. —`
		end
	end
	cartel.estado.Text = "Se actualiza cada pocos minutos"
end

----------------------------------------------------------------------------- inicio

function ClasificacionService.Iniciar()
	for _, tabla in ConfigClasificacion.TABLAS do
		local ok, tienda = pcall(function()
			return DataStoreService:GetOrderedDataStore(ConfigClasificacion.PREFIJO_DATASTORE .. tabla.id)
		end)
		if ok and tienda then
			tiendas[tabla.id] = tienda
		end
	end

	local carpeta = Instance.new("Model")
	carpeta.Name = "SalonDeLaFama"
	for indice, tabla in ConfigClasificacion.TABLAS do
		carteles[tabla.id] = crearCartel(carpeta, indice, tabla)
	end
	carpeta.Parent = MapaService.Carpeta or workspace

	task.spawn(function()
		while true do
			for _, tabla in ConfigClasificacion.TABLAS do
				actualizarCartel(tabla)
				task.wait(1) -- sin ráfagas de pedidos a DataStore
			end
			task.wait(ConfigClasificacion.LEER_CADA)
		end
	end)

	Reloj.Cada(ConfigClasificacion.SUBIR_CADA, function()
		for _, jugador in DatosService.JugadoresListos() do
			local datos = DatosService.Obtener(jugador)
			if datos then
				task.spawn(subir, jugador, datos)
			end
		end
	end)
	DatosService.JugadorSaliendo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		task.spawn(function()
			subir(jugador, datos)
			subidos[jugador] = nil
		end)
	end)
end

return ClasificacionService
