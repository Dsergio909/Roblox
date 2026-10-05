--!strict
--[[
	ArmaService
	Armas de defensa (Config/Armas): cuáles tiene desbloqueadas cada jugador, equipar una y
	avisar cuando se desbloquea una nueva.

	Las armas NO se compran (ni con Robux ni con dinero): se desbloquean jugando. El servidor
	valida el desbloqueo al equipar; el golpe lo maneja RoboService con los valores del arma
	que el servidor sabe que tienes equipada.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigArmas = require(Shared:WaitForChild("Config"):WaitForChild("Armas"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Desbloqueo = require(Shared:WaitForChild("Logica"):WaitForChild("Desbloqueo"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local RoboService = require(script.Parent:WaitForChild("RoboService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

type Arma = ConfigArmas.Arma

local ArmaService = {}

local armaPorId: { [string]: Arma } = {}
for _, arma in ConfigArmas.LISTA do
	armaPorId[arma.id] = arma
end
local idsIndice: { string } = {}
for _, crunchi in Catalogo.datos.crunchis do
	table.insert(idsIndice, crunchi.id)
end

-- Última "foto" del progreso de cada jugador (para avisar al cliente solo si cambió).
local firmas: { [Player]: string } = {}

function ArmaService.Resumen(datos: Tipos.Datos): Desbloqueo.Resumen
	return {
		rebirths = datos.rebirths,
		defensas = datos.stats.defensas,
		indice = Progresion.PorcentajeIndice(datos.indice, idsIndice),
		almacen = datos.almacen.veces,
		agentes = datos.stats.agentesGolpeados,
	}
end

function ArmaService.Desbloqueada(datos: Tipos.Datos, armaId: string): boolean
	local arma = armaPorId[armaId]
	return arma ~= nil and Desbloqueo.Cumple(arma.desbloqueo, ArmaService.Resumen(datos))
end

local function estado(_jugador: Player, datos: Tipos.Datos)
	return { equipada = datos.armaEquipada, resumen = ArmaService.Resumen(datos) }
end

local function equipar(jugador: Player, armaId: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(armaId) ~= "string" then
		return
	end
	local arma = armaPorId[armaId]
	if arma == nil or datos.armaEquipada == armaId then
		return
	end
	if not ArmaService.Desbloqueada(datos, armaId) then
		RedServidor.Notificar(jugador, `🔒 {Desbloqueo.Texto(arma.desbloqueo)}`, "error")
		return
	end
	datos.armaEquipada = armaId
	RoboService.ActualizarArma(jugador)
	RedServidor.Notificar(jugador, `{arma.icono} Equipaste: {arma.nombre}`, "exito")
	DatosService.ActualizarEstado(jugador, { "armas" })
	AnaliticaService.Evento(jugador, "ArmaEquipada", 1, { armaId })
end

-- Avisa (una sola vez por arma) cuando el jugador desbloquea una nueva.
local function revisarDesbloqueos(jugador: Player, silencioso: boolean)
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	local resumen = ArmaService.Resumen(datos)
	for _, arma in ConfigArmas.LISTA do
		if not datos.armasAvisadas[arma.id] and Desbloqueo.Cumple(arma.desbloqueo, resumen) then
			datos.armasAvisadas[arma.id] = true
			if not silencioso and arma.desbloqueo.tipo ~= "inicial" then
				RedServidor.Notificar(
					jugador,
					`🔓 ¡Nueva arma: {arma.icono} {arma.nombre}! Equípala en 🎒 Mochila`,
					"exito"
				)
				RedServidor.Enviar("Efecto", jugador, "Logro")
				AnaliticaService.Evento(jugador, "ArmaDesbloqueada", 1, { arma.id })
			end
		end
	end
	-- El progreso cambió: la Mochila muestra las barritas actualizadas.
	local firma =
		`{resumen.rebirths}|{resumen.defensas}|{math.floor(resumen.indice)}|{resumen.almacen}|{resumen.agentes}`
	if firmas[jugador] ~= firma then
		firmas[jugador] = firma
		DatosService.ActualizarEstado(jugador, { "armas" })
	end
end

function ArmaService.Iniciar()
	DatosService.RegistrarEstado("armas", estado)
	Acciones.Registrar("arma_equipar", equipar)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		-- Un id que ya no existe (arma quitada en una actualización) vuelve al periódico.
		if armaPorId[datos.armaEquipada] == nil then
			datos.armaEquipada = ConfigArmas.INICIAL
		end
		-- Lo que ya tenía desbloqueado al llegar no se anuncia.
		revisarDesbloqueos(jugador, true)
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		firmas[jugador] = nil
	end)
	Reloj.Cada(5, function()
		for _, jugador in DatosService.JugadoresListos() do
			revisarDesbloqueos(jugador, false)
		end
	end)

	AdminService.Registrar("arma", function(jugador, args)
		local datos = DatosService.Obtener(jugador)
		local id = args[1] or ""
		if datos == nil or armaPorId[id] == nil then
			local ids = {}
			for _, arma in ConfigArmas.LISTA do
				table.insert(ids, arma.id)
			end
			RedServidor.Notificar(jugador, `🛠️ Armas: {table.concat(ids, ", ")}`, "info")
			return
		end
		-- Admin: equipa sin requisito (solo para probar).
		datos.armaEquipada = id
		RoboService.ActualizarArma(jugador)
		DatosService.ActualizarEstado(jugador, { "armas" })
		RedServidor.Notificar(jugador, `🛠️ Arma: {armaPorId[id].nombre}`, "info")
	end)
end

return ArmaService
