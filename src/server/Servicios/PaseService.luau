--!strict
--[[
	PaseService
	Pase Crunch (pase de temporada): 30 niveles, camino gratis y camino premium.

	  - XP: misiones (y su bonus), y jugar (50 XP cada 10 min, tope diario). Ver Config/Pase.
	  - El camino gratis se completa jugando; el premium se compra (producto PASE_PREMIUM).
	  - La temporada tiene fechas REALES: fuera de ellas no se gana XP.
	  - Cambiar TEMPORADA.id en Config/Pase empieza una temporada nueva para todos.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigPase = require(Shared:WaitForChild("Config"):WaitForChild("Pase"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RecompensaService = require(script.Parent:WaitForChild("RecompensaService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local PaseService = {}

local pendientes: { [Player]: boolean } = {}
local TEMPORADA = ConfigPase.TEMPORADA
local MAX_NIVEL = #ConfigPase.NIVELES

function PaseService.Activa(): boolean
	local ahora = os.time()
	return ahora >= TEMPORADA.inicio and ahora < TEMPORADA.fin
end

-- Si la temporada guardada no es la actual, empieza de cero.
local function asegurar(datos: Tipos.Datos)
	if datos.pase.temporada ~= TEMPORADA.id then
		datos.pase = {
			temporada = TEMPORADA.id,
			xp = 0,
			premium = false,
			gratis = {},
			premiumes = {},
			minutosJuego = 0,
			diaXp = 0,
			xpJuegoDia = 0,
		}
	end
end

local function nivelDe(xp: number): number
	return math.min(MAX_NIVEL, xp // ConfigPase.XP_POR_NIVEL)
end

function PaseService.SumarXp(jugador: Player, cantidad: number, forzar: boolean?)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or cantidad <= 0 then
		return
	end
	if not PaseService.Activa() and not forzar then
		return
	end
	asegurar(datos)
	local antes = nivelDe(datos.pase.xp)
	datos.pase.xp += cantidad
	local despues = nivelDe(datos.pase.xp)
	if despues > antes then
		RedServidor.Notificar(jugador, `⭐ ¡Nivel {despues} del Pase Crunch! Reclama tus premios`, "exito")
		RedServidor.Enviar("Efecto", jugador, "Logro")
		AnaliticaService.Progreso(jugador, `Pase_{TEMPORADA.id}`, despues)
	end
	pendientes[jugador] = true
end

function PaseService.ActivarPremium(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	asegurar(datos)
	datos.pase.premium = true
	RedServidor.Notificar(jugador, "⭐ ¡Pase Crunch Premium activado! Reclama los premios premium", "exito")
	pendientes[jugador] = true
end

function PaseService.XpPorNivel(): number
	return ConfigPase.XP_POR_NIVEL
end

local function reclamar(jugador: Player, pedido: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(pedido) ~= "table" or type(pedido.nivel) ~= "number" then
		return
	end
	asegurar(datos)
	local nivel = math.floor(pedido.nivel)
	local definicion = ConfigPase.NIVELES[nivel]
	if definicion == nil or nivel > nivelDe(datos.pase.xp) then
		return
	end
	local clave = tostring(nivel)
	local esPremium = pedido.premium == true
	local reclamados = if esPremium then datos.pase.premiumes else datos.pase.gratis
	if reclamados[clave] then
		return
	end
	if esPremium and not datos.pase.premium then
		RedServidor.Notificar(jugador, "Este premio es del Pase Premium", "error")
		return
	end
	reclamados[clave] = true
	local premio = if esPremium then definicion.premium else definicion.gratis
	local texto = RecompensaService.Dar(jugador, {
		tipo = premio.tipo,
		minutos = premio.minutos,
		id = premio.id,
		cantidad = premio.cantidad,
	}, `pase_{TEMPORADA.id}_{clave}{if esPremium then "_p" else ""}`)
	RedServidor.Notificar(jugador, `⭐ Nivel {nivel}: {texto}`, "exito")
	pendientes[jugador] = true
end

local function estado(_jugador: Player, datos: Tipos.Datos)
	asegurar(datos)
	local gratis, premiumes = {}, {}
	for clave in datos.pase.gratis do
		table.insert(gratis, tonumber(clave))
	end
	for clave in datos.pase.premiumes do
		table.insert(premiumes, tonumber(clave))
	end
	return {
		id = TEMPORADA.id,
		nombre = TEMPORADA.nombre,
		inicio = TEMPORADA.inicio,
		fin = TEMPORADA.fin,
		activa = PaseService.Activa(),
		xp = datos.pase.xp,
		xpPorNivel = ConfigPase.XP_POR_NIVEL,
		nivel = nivelDe(datos.pase.xp),
		premium = datos.pase.premium,
		gratis = gratis,
		premiumes = premiumes,
	}
end

function PaseService.Iniciar()
	DatosService.RegistrarEstado("pase", estado)
	DatosService.JugadorListo:Conectar(function(_jugador: Player, datos: Tipos.Datos)
		asegurar(datos)
	end)
	RecompensaService.XpGanada:Conectar(function(jugador: Player, cantidad: number)
		PaseService.SumarXp(jugador, cantidad)
	end)
	Acciones.Registrar("pase_reclamar", reclamar)

	-- XP por jugar: cada minuto suma tiempo; cada CADA_MINUTOS da XP (con tope diario).
	local config = ConfigPase.XP_JUEGO
	Reloj.Cada(60, function()
		if not PaseService.Activa() then
			return
		end
		local hoy = Progresion.Dia(os.time())
		for _, jugador in Players:GetPlayers() do
			local datos = DatosService.Obtener(jugador)
			if datos then
				asegurar(datos)
				local pase = datos.pase
				if pase.diaXp ~= hoy then
					pase.diaXp = hoy
					pase.xpJuegoDia = 0
				end
				pase.minutosJuego += 1
				if pase.minutosJuego % config.CADA_MINUTOS == 0 and pase.xpJuegoDia < config.MAXIMO_DIA then
					local cantidad = math.min(config.CANTIDAD, config.MAXIMO_DIA - pase.xpJuegoDia)
					pase.xpJuegoDia += cantidad
					PaseService.SumarXp(jugador, cantidad)
				end
			end
		end
	end)

	Reloj.Cada(1, function()
		for jugador in pendientes do
			pendientes[jugador] = nil
			if jugador.Parent then
				DatosService.ActualizarEstado(jugador, { "pase" })
			end
		end
	end)

	AdminService.Registrar("pasexp", function(jugador: Player, argumentos: { string })
		local cantidad = tonumber(argumentos[1]) or ConfigPase.XP_POR_NIVEL
		PaseService.SumarXp(jugador, cantidad, true)
		RedServidor.Notificar(jugador, `🛠️ +{cantidad} XP del pase`, "info")
	end)
	AdminService.Registrar("pasepremium", function(jugador: Player)
		PaseService.ActivarPremium(jugador)
	end)
end

return PaseService
