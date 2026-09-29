--!strict
--[[
	DatosService
	Carga y guarda los datos de cada jugador con ProfileStore.

	Qué garantiza:
	  - Bloqueo de sesión: los datos de un jugador solo se modifican en UN servidor a la vez
	    (evita duplicar Crunchis entrando a dos servidores).
	  - Autoguardado periódico, guardado al salir y al cerrar el servidor (ProfileStore lo
	    hace solo, incluido BindToClose).
	  - Versión del esquema + migraciones para cambiar la forma de los datos sin romper
	    los datos viejos.

	Señales para los demás servicios:
	  DatosService.JugadorListo(jugador, datos)       datos cargados, el jugador puede jugar
	  DatosService.JugadorSaliendo(jugador, datos)    antes del último guardado (no esperar aquí)

	En Studio sin "Enable Studio Access to API Services" el juego funciona igual, pero no
	guarda nada (ProfileStore lo avisa en Output).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local ConfigJuego = require(Config:WaitForChild("Juego"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local ServerScriptService = game:GetService("ServerScriptService")
local ProfileStore =
	require(ServerScriptService:WaitForChild("Server"):WaitForChild("Paquetes"):WaitForChild("ProfileStore")) :: any
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Datos = Tipos.Datos

-- Sube este número si cambias la forma de datos que ya existen, y agrega una migración.
local VERSION_DATOS = 1

-- Datos de un jugador nuevo. ProfileStore:Reconcile() agrega a los jugadores existentes
-- cualquier campo NUEVO que pongas aquí (no hace falta migración para agregar campos).
local PLANTILLA: Datos = {
	version = VERSION_DATOS,
	dinero = ConfigEconomia.DINERO_INICIAL,
	crunchis = {},
	contadorUid = 0,
	rebirths = 0,
	indice = {},
	stats = {
		tiempoJugado = 0,
		sesiones = 0,
		comprasCinta = 0,
		cobros = 0,
		robosExitosos = 0,
		robosSufridos = 0,
		defensas = 0,
		gananciaTotal = 0,
	},
	onboarding = {},
	primeraConexion = 0,
	ultimaConexion = 0,
	recibos = {},
	ajustes = {
		musica = true,
		efectos = true,
		ahorro = false,
	},

	-- Fase 2
	mejorAmigo = "",
	setsCompletados = {},
	hitosIndice = {},
	titulos = {},
	tituloEquipado = "",
	misiones = {
		dia = 0,
		diarias = {},
		semana = 0,
		semanales = {},
		cambiosUsados = 0,
		bonusDiario = false,
	},
	login = {
		diasTotales = 0,
		ultimoDia = 0,
		racha = 0,
		pendiente = false,
	},
	tickets = {},
	-- ⚠️ Las tablas de la plantilla deben estar VACÍAS si el jugador puede vaciarlas: Reconcile
	-- vuelve a rellenar las claves que falten (regalaría semillas en cada sesión). Los
	-- regalos iniciales se dan una sola vez en darRegalosIniciales().
	semillas = {},
	macetero = {
		semilla = "",
		listaEn = 0,
	},
	offline = {
		ingresoAlSalir = 0,
		pendiente = 0,
	},

	-- Fase 3
	compras = {
		primeraCompraDinero = false,
		packInicial = false,
		vecesOfertaPack = 0,
		pruebaX2 = false,
		robuxGastados = 0,
	},
	boosts = { x2Hasta = 0 },
	pase = {
		temporada = "",
		xp = 0,
		premium = false,
		gratis = {},
		premiumes = {},
		minutosJuego = 0,
		diaXp = 0,
		xpJuegoDia = 0,
	},
	cosmeticos = {},
	equipados = { aura = "", estela = "" },

	-- Fase 4
	almacen = { proximo = 0, veces = 0 },
	insignias = {},
}

-- Migraciones: MIGRACIONES[n] convierte datos de la versión n a la n + 1.
local MIGRACIONES: { [number]: (datos: any) -> () } = {
	-- [1] = function(datos) datos.campoNuevo = datos.campoViejo; datos.campoViejo = nil end,
}

type Perfil = {
	Data: Datos,
	IsActive: (self: Perfil) -> boolean,
	Reconcile: (self: Perfil) -> (),
	EndSession: (self: Perfil) -> (),
	AddUserId: (self: Perfil, userId: number) -> (),
	Save: (self: Perfil) -> (),
	OnSessionEnd: RBXScriptSignal,
	OnLastSave: RBXScriptSignal,
	OnAfterSave: RBXScriptSignal,
	LastSavedData: Datos,
}

local DatosService = {
	JugadorListo = Senal.nueva(),
	JugadorSaliendo = Senal.nueva(),
	-- (jugador, crunchiId, mutacionId, esNuevo) — el jugador consiguió un Crunchi (comprado,
	-- robado, de canasta, del macetero...). esNuevo = primera vez que tiene ese tipo.
	CrunchiObtenido = Senal.nueva(),
}

local tienda = ProfileStore.New(ConfigJuego.NOMBRE_DATASTORE, PLANTILLA)
if RunService:IsStudio() and ConfigJuego.DATOS_DE_PRUEBA_EN_STUDIO then
	-- Datos de mentira que se borran al cerrar el servidor.
	tienda = tienda.Mock
end

local perfiles: { [Player]: Perfil } = {}
local saliendo: { [Player]: boolean } = {}
local proveedoresEstado: { [string]: (Player, Datos) -> any } = {}

----------------------------------------------------------------------------- utilidades

local function copiaProfunda<T>(valor: T): T
	if type(valor) ~= "table" then
		return valor
	end
	local copia = {}
	for clave, v in valor :: any do
		copia[clave] = copiaProfunda(v)
	end
	return copia :: any
end

local function migrar(datos: Datos)
	local version = datos.version or 1
	while version < VERSION_DATOS do
		local migracion = MIGRACIONES[version]
		if migracion then
			migracion(datos)
		end
		version += 1
	end
	datos.version = VERSION_DATOS
end

-- Lo que recibe una cuenta nueva (una sola vez).
local function darRegalosIniciales(jugador: Player, datos: Datos)
	local ahora = os.time()
	datos.primeraConexion = ahora
	table.insert(datos.crunchis, {
		uid = `{jugador.UserId}-{datos.contadorUid + 1}`,
		id = ConfigEconomia.CRUNCHI_INICIAL,
		mut = "normal",
		lugar = 1,
	})
	datos.contadorUid += 1
	datos.indice[ConfigEconomia.CRUNCHI_INICIAL] = ahora
	datos.indice[`{ConfigEconomia.CRUNCHI_INICIAL}:normal`] = ahora
	datos.semillas["comun"] = 1 -- una semilla para descubrir el macetero
end

----------------------------------------------------------------------------- API

function DatosService.Obtener(jugador: Player): Datos?
	local perfil = perfiles[jugador]
	if perfil and perfil:IsActive() then
		return perfil.Data
	end
	return nil
end

-- Espera a que los datos estén cargados (máximo `limite` segundos).
function DatosService.Esperar(jugador: Player, limite: number?): Datos?
	local inicio = os.clock()
	local maximo = limite or 20
	while jugador.Parent == Players and os.clock() - inicio < maximo do
		local datos = DatosService.Obtener(jugador)
		if datos then
			return datos
		end
		task.wait(0.1)
	end
	return DatosService.Obtener(jugador)
end

function DatosService.Perfil(jugador: Player): Perfil?
	return perfiles[jugador]
end

function DatosService.JugadoresListos(): { Player }
	local lista = {}
	for jugador in perfiles do
		if not saliendo[jugador] then
			table.insert(lista, jugador)
		end
	end
	return lista
end

-- Identificador único para un Crunchi nuevo: "<UserId>-<contador>" (único en todo el juego).
function DatosService.NuevoUid(jugador: Player): string
	local datos = DatosService.Obtener(jugador)
	assert(datos, "NuevoUid sin datos")
	datos.contadorUid += 1
	return `{jugador.UserId}-{datos.contadorUid}`
end

-- Registra en el Índice que el jugador consiguió este Crunchi (y esta mutación) y avisa
-- a los demás servicios (misiones, sets...). Devuelve true si es el primero de ese tipo.
function DatosService.RegistrarIndice(jugador: Player, crunchiId: string, mutacionId: string): boolean
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return false
	end
	local ahora = os.time()
	local nuevo = datos.indice[crunchiId] == nil
	if nuevo then
		datos.indice[crunchiId] = ahora
	end
	local clave = `{crunchiId}:{mutacionId}`
	if datos.indice[clave] == nil then
		datos.indice[clave] = ahora
	end
	DatosService.CrunchiObtenido:Disparar(jugador, crunchiId, mutacionId, nuevo)
	return nuevo
end

--[[
	Estado privado: información que solo ve el dueño (misiones, índice, tutorial...).
	Cada servicio registra una función que arma su parte del estado.
]]
function DatosService.RegistrarEstado(nombre: string, proveedor: (Player, Datos) -> any)
	proveedoresEstado[nombre] = proveedor
end

function DatosService.ConstruirEstado(jugador: Player): Tipos.EstadoPrivado?
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return nil
	end
	local estado: Tipos.EstadoPrivado = {}
	for nombre, proveedor in proveedoresEstado do
		local ok, valor = pcall(proveedor, jugador, datos)
		if ok then
			estado[nombre] = valor
		else
			warn(`[Datos] Error armando estado "{nombre}": {valor}`)
		end
	end
	return estado
end

-- Envía al cliente solo las partes del estado que cambiaron (p. ej. {"tutorial", "indice"}).
function DatosService.ActualizarEstado(jugador: Player, partes: { string })
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	local cambios: Tipos.EstadoPrivado = {}
	for _, nombre in partes do
		local proveedor = proveedoresEstado[nombre]
		if proveedor then
			local ok, valor = pcall(proveedor, jugador, datos)
			if ok then
				cambios[nombre] = valor
			end
		end
	end
	RedServidor.Enviar("EstadoPrivado", jugador, cambios)
end

-- Guarda ahora mismo (solo para momentos críticos, como compras con Robux).
function DatosService.GuardarYa(jugador: Player)
	local perfil = perfiles[jugador]
	if perfil and perfil:IsActive() then
		perfil:Save()
	end
end

-- Reinicia los datos del jugador (comando de admin). Conserva TODO lo pagado con Robux
-- (recibos, compras, pase, cosméticos) para no perder ni volver a entregar compras.
function DatosService.Reiniciar(jugador: Player)
	local perfil = perfiles[jugador]
	if perfil == nil or not perfil:IsActive() then
		return
	end
	DatosService.JugadorSaliendo:Disparar(jugador, perfil.Data)
	local recibos = perfil.Data.recibos
	local compras = perfil.Data.compras
	local pase = perfil.Data.pase
	local cosmeticos = perfil.Data.cosmeticos
	local nuevos = copiaProfunda(PLANTILLA)
	for clave in perfil.Data :: any do
		(perfil.Data :: any)[clave] = nil
	end
	for clave, valor in nuevos :: any do
		(perfil.Data :: any)[clave] = valor
	end
	perfil.Data.recibos = recibos
	perfil.Data.compras = compras
	perfil.Data.pase = pase
	perfil.Data.cosmeticos = cosmeticos
	perfil.Data.ultimaConexion = os.time()
	darRegalosIniciales(jugador, perfil.Data)
	DatosService.JugadorListo:Disparar(jugador, perfil.Data)
	RedServidor.Enviar("EstadoPrivado", jugador, DatosService.ConstruirEstado(jugador))
end

----------------------------------------------------------------------------- ciclo de vida

local function alEntrar(jugador: Player)
	local parametros = {
		Cancel = function()
			return jugador.Parent ~= Players
		end,
	}
	local perfil: Perfil? = tienda:StartSessionAsync(`Jugador_{jugador.UserId}`, parametros)
	if perfil == nil then
		jugador:Kick("No pudimos cargar tus datos. Vuelve a entrar en un momento.")
		return
	end

	perfil:AddUserId(jugador.UserId) -- cumplimiento de GDPR (derecho al borrado)
	perfil:Reconcile() -- agrega campos nuevos de la PLANTILLA
	migrar(perfil.Data)

	perfil.OnSessionEnd:Connect(function()
		perfiles[jugador] = nil
		saliendo[jugador] = nil
		jugador:Kick("Tus datos se abrieron en otro servidor. Vuelve a entrar.")
	end)

	if jugador.Parent ~= Players then
		perfil:EndSession() -- se fue mientras cargaba
		return
	end

	local datos = perfil.Data
	local ahora = os.time()

	-- Jugador nuevo: su primer Crunchi y una semilla.
	if datos.primeraConexion == 0 then
		darRegalosIniciales(jugador, datos)
	end

	datos.stats.sesiones += 1
	jugador:SetAttribute("UltimaConexionAnterior", datos.ultimaConexion)
	datos.ultimaConexion = ahora
	perfiles[jugador] = perfil

	DatosService.JugadorListo:Disparar(jugador, datos)
end

local function alSalir(jugador: Player)
	local perfil = perfiles[jugador]
	if perfil == nil then
		return
	end
	saliendo[jugador] = true
	if perfil:IsActive() then
		perfil.Data.ultimaConexion = os.time()
		-- Los servicios guardan lo pendiente (dinero sin cobrar, robos en curso...).
		-- Senal ejecuta los oyentes al instante, antes de seguir con EndSession.
		DatosService.JugadorSaliendo:Disparar(jugador, perfil.Data)
	end
	perfil:EndSession()
	perfiles[jugador] = nil
	saliendo[jugador] = nil
end

function DatosService.Iniciar()
	for _, jugador in Players:GetPlayers() do
		task.spawn(alEntrar, jugador)
	end
	Players.PlayerAdded:Connect(alEntrar)
	Players.PlayerRemoving:Connect(alSalir)

	-- Tiempo total de juego (para la protección de novato y estadísticas).
	Reloj.Cada(1, function(dt)
		for jugador, perfil in perfiles do
			if perfil:IsActive() and not saliendo[jugador] then
				perfil.Data.stats.tiempoJugado += dt
			end
		end
	end)

	-- El cliente pide su estado privado completo al arrancar.
	RedServidor.Responder("PedirEstado", 2, 4, function(jugador: Player)
		DatosService.Esperar(jugador, 20)
		return DatosService.ConstruirEstado(jugador)
	end)

	if ProfileStore.OnError then
		ProfileStore.OnError:Connect(function(mensaje: string, tiendaNombre: string, clave: string)
			warn(`[Datos] Error de DataStore en {tiendaNombre}/{clave}: {mensaje}`)
		end)
	end
end

return DatosService
