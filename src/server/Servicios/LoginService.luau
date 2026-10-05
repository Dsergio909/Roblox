--!strict
--[[
	LoginService
	Recompensa diaria por conectarse y racha SUAVE (ver Config/Login):

	  - Calendario de 7 recompensas por DÍAS DE CONEXIÓN: nunca se reinicia. Si faltas,
	    sigues donde quedaste.
	  - Racha: +2 % de ingreso por día seguido (máximo +10 %). Faltar un día resta UN paso,
	    no la borra entera. Nada de "pierdes todo si no pagas".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigLogin = require(Shared:WaitForChild("Config"):WaitForChild("Login"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RecompensaService = require(script.Parent:WaitForChild("RecompensaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local LoginService = {}

-- Índice (1–7) de la recompensa del calendario que toca.
local function diaCalendario(datos: Tipos.Datos): number
	return ((math.max(1, datos.login.diasTotales) - 1) % #ConfigLogin.CALENDARIO) + 1
end

-- Procesa el día actual. Devuelve true si es un día nuevo para este jugador.
local function procesarDia(jugador: Player, datos: Tipos.Datos): boolean
	local login = datos.login
	local hoy = Progresion.Dia(os.time())
	if login.ultimoDia == hoy then
		return false
	end
	login.racha = Progresion.ActualizarRacha(login.racha, login.ultimoDia, hoy, ConfigLogin.RACHA_MAXIMA)
	login.ultimoDia = hoy
	login.diasTotales += 1
	login.pendiente = true
	EconomiaService.AvisarCambio(jugador)
	AnaliticaService.Evento(jugador, "DiaConectado", login.diasTotales, { tostring(login.racha) })
	return true
end

local function reclamar(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or not datos.login.pendiente then
		return
	end
	datos.login.pendiente = false
	local dia = diaCalendario(datos)
	local recompensa = ConfigLogin.CALENDARIO[dia]
	local texto = RecompensaService.Dar(jugador, {
		tipo = recompensa.tipo,
		minutos = recompensa.minutos,
		minimo = ConfigLogin.DINERO_MINIMO,
		id = recompensa.id,
		cantidad = recompensa.cantidad,
	}, `login_dia{dia}`)
	RedServidor.Notificar(jugador, `🎁 Día {dia}: {texto}`, "exito")
	RedServidor.Enviar("Efecto", jugador, "Logro")
	DatosService.ActualizarEstado(jugador, { "login" })
end

function LoginService.Iniciar()
	EconomiaService.RegistrarBonus("Racha", function(jugador)
		local datos = DatosService.Obtener(jugador)
		return if datos then datos.login.racha * ConfigLogin.RACHA_BONUS_POR_DIA else 0
	end)

	DatosService.RegistrarEstado("login", function(_jugador: Player, datos: Tipos.Datos)
		return {
			dia = diaCalendario(datos),
			pendiente = datos.login.pendiente,
			racha = datos.login.racha,
			rachaMaxima = ConfigLogin.RACHA_MAXIMA,
			bonus = datos.login.racha * ConfigLogin.RACHA_BONUS_POR_DIA,
			diasTotales = datos.login.diasTotales,
		}
	end)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		procesarDia(jugador, datos)
	end)

	Acciones.Registrar("login_reclamar", function(jugador: Player)
		reclamar(jugador)
	end)

	-- Si alguien está jugando cuando cambia el día, recibe la recompensa nueva al momento.
	Reloj.Cada(60, function()
		for _, jugador in Players:GetPlayers() do
			local datos = DatosService.Obtener(jugador)
			if datos and procesarDia(jugador, datos) then
				RedServidor.Notificar(jugador, "🎁 ¡Nuevo día! Tienes una recompensa diaria", "exito")
				DatosService.ActualizarEstado(jugador, { "login" })
			end
		end
	end)
end

return LoginService
