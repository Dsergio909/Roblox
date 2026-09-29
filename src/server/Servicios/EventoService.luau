--!strict
--[[
	EventoService
	Eventos automáticos del servidor (Config/Eventos): Lluvia de Manzanas, Redada FrutaMax,
	Hora Dorada, Noche Nuclear... Rotan solos: cada INTERVALO_MINUTOS empieza el siguiente.

	Qué hace cada evento (todo sale de su configuración):
	  mutaciones   multiplica las probabilidades de mutación en las cintas
	  rarezas      multiplica las probabilidades de rareza en las cintas
	  multIngreso  multiplicador de ingreso para todos mientras dura
	  tipo         "redada" → AgenteService manda agentes a etiquetar Crunchis
	               "lluvia" → los clientes dibujan manzanas cayendo (solo visual)

	El cliente se entera por dos atributos de Workspace: "EventoId" y "EventoHasta" (hora
	del servidor). Con eso muestra el cartel y la cuenta regresiva: sin remotos extra.

	Los eventos de TEMPORADA solo entran en la rotación entre sus fechas reales de inicio y
	fin: si dice "limitado", lo es de verdad (nada de escasez falsa).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigEventos = require(Shared:WaitForChild("Config"):WaitForChild("Eventos"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local CintaService = require(script.Parent:WaitForChild("CintaService"))
local AgenteService = require(script.Parent:WaitForChild("AgenteService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Evento = ConfigEventos.Evento

local EventoService = {
	Iniciado = Senal.nueva(), -- (evento: Evento)
	Terminado = Senal.nueva(), -- (evento: Evento)
}

local actual: Evento? = nil
local hasta = 0
local proximo = 0
local turno = 0

-- Eventos que pueden salir AHORA: la rotación fija + los de temporada vigentes.
local function candidatos(momento: number): { Evento }
	local lista: { Evento } = table.clone(ConfigEventos.ROTACION)
	for _, evento in ConfigEventos.TEMPORADA do
		local inicio = evento.inicio or 0
		local fin = evento.fin or 0
		if momento >= inicio and momento < fin then
			table.insert(lista, evento)
		end
	end
	return lista
end

local function buscar(id: string): Evento?
	for _, evento in ConfigEventos.ROTACION do
		if evento.id == id then
			return evento
		end
	end
	for _, evento in ConfigEventos.TEMPORADA do
		if evento.id == id then
			return evento
		end
	end
	return nil
end

function EventoService.Actual(): Evento?
	return actual
end

-- Cuando cambia el multiplicador de ingreso de todos (empieza o termina una Hora Dorada).
local function avisarATodos()
	for _, jugador in Players:GetPlayers() do
		EconomiaService.AvisarCambio(jugador)
	end
end

local function terminar()
	local evento = actual
	if evento == nil then
		return
	end
	actual = nil
	hasta = 0
	workspace:SetAttribute("EventoId", nil)
	workspace:SetAttribute("EventoHasta", nil)
	if evento.tipo == "redada" then
		AgenteService.TerminarRedada()
	end
	if evento.multIngreso then
		avisarATodos()
	end
	proximo = Reloj.Ahora() + ConfigEventos.INTERVALO_MINUTOS * 60
	EventoService.Terminado:Disparar(evento)
end

local function empezar(evento: Evento)
	terminar()
	local momento = Reloj.Ahora()
	actual = evento
	hasta = momento + evento.duracion * 60
	workspace:SetAttribute("EventoHasta", hasta)
	workspace:SetAttribute("EventoId", evento.id) -- al final: el cliente reacciona a este
	if evento.tipo == "redada" then
		AgenteService.IniciarRedada()
	end
	if evento.multIngreso then
		avisarATodos()
	end
	EventoService.Iniciado:Disparar(evento)
end

local function siguiente(momento: number): Evento?
	local lista = candidatos(momento)
	if #lista == 0 then
		return nil
	end
	turno = turno % #lista + 1
	return lista[turno]
end

local function revisar()
	local momento = Reloj.Ahora()
	if actual then
		if momento >= hasta then
			terminar()
		end
	elseif momento >= proximo then
		local evento = siguiente(momento)
		if evento then
			empezar(evento)
		else
			proximo = momento + ConfigEventos.INTERVALO_MINUTOS * 60
		end
	end
end

function EventoService.Iniciar()
	proximo = Reloj.Ahora() + ConfigEventos.PRIMERO_A_LOS_MINUTOS * 60

	CintaService.RegistrarModificadorMutacion("Evento", function()
		local evento = actual
		return if evento then evento.mutaciones else nil
	end)
	CintaService.RegistrarModificadorRareza("Evento", function()
		local evento = actual
		return if evento then evento.rarezas else nil
	end)
	-- Temporal: no cuenta para las recompensas "en minutos de ingreso" (ver EconomiaService).
	EconomiaService.RegistrarMultiplicador("Evento", function()
		local evento = actual
		return if evento and evento.multIngreso then evento.multIngreso else 1
	end, true)

	AdminService.Registrar("evento", function(jugador, args)
		local id = args[1]
		if id == nil or id == "fin" then
			terminar()
			RedServidor.Notificar(jugador, "🛠️ Evento terminado", "info")
			return
		end
		local evento = buscar(id)
		if evento == nil then
			local ids = {}
			for _, e in ConfigEventos.ROTACION do
				table.insert(ids, e.id)
			end
			for _, e in ConfigEventos.TEMPORADA do
				table.insert(ids, e.id)
			end
			RedServidor.Notificar(jugador, `🛠️ Eventos: {table.concat(ids, ", ")}, fin`, "info")
			return
		end
		empezar(evento)
	end)

	Reloj.Cada(1, revisar)
end

return EventoService
