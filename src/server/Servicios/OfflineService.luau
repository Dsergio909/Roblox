--!strict
--[[
	OfflineService
	Ganancias mientras no estás: al volver encuentras dinero acumulado ("tus Crunchis
	trabajaron mientras no estabas"). Es el gancho para volver.

	  ganancia = ingreso base × 20 % × tiempo fuera (tope de 3 horas; VIP 6 h en la Fase 3)

	Tu base NO existe mientras estás desconectado (nadie puede robarte). La ganancia se
	calcula con el ingreso que tenías al salir.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigEconomia = require(Shared:WaitForChild("Config"):WaitForChild("Economia"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local OfflineService = {
	-- (jugador, cantidad) — se cobró la ganancia offline
	Cobrado = Senal.nueva(),
}

local ausencia: { [Player]: number } = {} -- segundos de la última ausencia (para mostrarlo)
local horasExtra: { [string]: (Player) -> number } = {}

-- Otros servicios pueden subir el tope de horas (VIP en la Fase 3).
function OfflineService.RegistrarHorasExtra(nombre: string, fn: (Player) -> number)
	horasExtra[nombre] = fn
end

function OfflineService.HorasMaximo(jugador: Player): number
	local horas = ConfigEconomia.OFFLINE.HORAS_MAXIMO
	for _, fn in horasExtra do
		local ok, valor = pcall(fn, jugador)
		if ok and type(valor) == "number" then
			horas = math.max(horas, valor)
		end
	end
	return horas
end

-- Duplica la ganancia pendiente (producto "Duplicar ganancias offline", Fase 3).
function OfflineService.Duplicar(jugador: Player): boolean
	local datos = DatosService.Obtener(jugador)
	if datos == nil or datos.offline.pendiente <= 0 then
		return false
	end
	datos.offline.pendiente *= 2
	DatosService.ActualizarEstado(jugador, { "offline" })
	return true
end

local function cobrar(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or datos.offline.pendiente <= 0 then
		return
	end
	local cantidad = math.floor(datos.offline.pendiente)
	datos.offline.pendiente = 0
	EconomiaService.Agregar(jugador, cantidad, AnaliticaService.Tipo.Recompensa, "offline")
	RedServidor.Enviar("Efecto", jugador, "Logro")
	RedServidor.Notificar(jugador, `💤 Cobraste {Formato.Dinero(cantidad)} de ganancias offline`, "exito")
	DatosService.ActualizarEstado(jugador, { "offline" })
	OfflineService.Cobrado:Disparar(jugador, cantidad)
end

function OfflineService.Iniciar()
	DatosService.RegistrarEstado("offline", function(jugador: Player, datos: Tipos.Datos)
		return {
			pendiente = datos.offline.pendiente,
			segundos = ausencia[jugador] or 0,
			horasMaximo = OfflineService.HorasMaximo(jugador),
			porcentaje = ConfigEconomia.OFFLINE.PORCENTAJE,
		}
	end)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		local anterior = jugador:GetAttribute("UltimaConexionAnterior")
		if type(anterior) ~= "number" or anterior <= 0 then
			return
		end
		local segundos = os.time() - anterior
		if segundos < ConfigEconomia.OFFLINE.SEGUNDOS_MINIMOS then
			return
		end
		jugador:SetAttribute("UltimaConexionAnterior", 0) -- que no se cuente dos veces
		ausencia[jugador] = segundos
		local ganancia = Progresion.GananciaOffline(
			datos.offline.ingresoAlSalir,
			segundos,
			ConfigEconomia.OFFLINE.PORCENTAJE,
			OfflineService.HorasMaximo(jugador)
		)
		if ganancia > 0 then
			datos.offline.pendiente += ganancia
		end
	end)

	DatosService.JugadorSaliendo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		datos.offline.ingresoAlSalir = EconomiaService.IngresoBase(jugador)
		ausencia[jugador] = nil
	end)

	Acciones.Registrar("offline_cobrar", function(jugador: Player)
		cobrar(jugador)
	end)
end

return OfflineService
