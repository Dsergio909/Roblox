--!strict
--[[
	AnaliticaService
	Envoltorio de AnalyticsService de Roblox. Los datos se ven en el Creator Dashboard
	(Analytics) y sirven para ajustar el juego con datos reales:

	  - Onboarding: en qué paso de los primeros minutos se van los jugadores.
	  - Economía: de dónde sale y en qué se gasta el dinero (detectar inflación).
	  - Eventos: robos, compras, ofertas vistas/cerradas/compradas...

	En Studio no se envía nada a Roblox (solo se imprime si DEPURAR = true).
]]

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigOnboarding = require(Config:WaitForChild("Onboarding"))
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))

local AnaliticaService = {}

local EN_STUDIO = RunService:IsStudio()
local DEPURAR = false -- true = imprimir en Output cada evento (útil al probar en Studio)

-- Tipos de transacción recomendados por Roblox (Enum.AnalyticsEconomyTransactionType).
AnaliticaService.Tipo = {
	Juego = Enum.AnalyticsEconomyTransactionType.Gameplay.Name, -- cobros, ventas, robos
	Tienda = Enum.AnalyticsEconomyTransactionType.Shop.Name, -- comprar en la cinta, canastas
	Robux = Enum.AnalyticsEconomyTransactionType.IAP.Name, -- compras con Robux
	Recompensa = Enum.AnalyticsEconomyTransactionType.TimedReward.Name, -- diarias, offline, misiones
	Inicio = Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
	Contextual = Enum.AnalyticsEconomyTransactionType.ContextualPurchase.Name,
}

local function llamar(descripcion: string, fn: () -> ())
	if DEPURAR then
		print(`[Analitica] {descripcion}`)
	end
	if EN_STUDIO then
		return
	end
	local ok, err = pcall(fn :: any)
	if not ok then
		warn(`[Analitica] Falló "{descripcion}": {err}`)
	end
end

-- Paso del embudo de los primeros minutos. Se registra una sola vez por jugador.
function AnaliticaService.Onboarding(jugador: Player, paso: string)
	local indice = table.find(ConfigOnboarding.PASOS, paso)
	if indice == nil then
		warn(`[Analitica] Paso de onboarding desconocido: {paso}`)
		return
	end
	local datos = DatosService.Obtener(jugador)
	if datos == nil or datos.onboarding[paso] then
		return
	end
	datos.onboarding[paso] = true
	llamar(`Onboarding {indice} {paso} ({jugador.Name})`, function()
		AnalyticsService:LogOnboardingFunnelStepEvent(jugador, indice, paso)
	end)
end

----------------------------------------------------------------------------- economía

type Agrupado = { cantidad: number, saldo: number }
-- Eventos frecuentes (cobros) acumulados por jugador → clave → total
local agrupados: { [Player]: { [string]: Agrupado } } = {}

local function enviarEconomia(
	jugador: Player,
	fuente: boolean,
	cantidad: number,
	saldo: number,
	tipo: string,
	sku: string
)
	local flujo = if fuente then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
	llamar(`Economía {flujo.Name} {cantidad} {tipo}/{sku} ({jugador.Name})`, function()
		AnalyticsService:LogEconomyEvent(jugador, flujo, "Dinero", cantidad, saldo, tipo, sku)
	end)
end

--[[
	Registra una entrada (fuente = true) o salida (fuente = false) de dinero.
	  tipo: uno de AnaliticaService.Tipo
	  sku:  detalle (p. ej. "cobro", "venta", id del Crunchi comprado)
	  agrupar: true para eventos muy frecuentes (se suman y se envían cada minuto)
]]
function AnaliticaService.Economia(
	jugador: Player,
	fuente: boolean,
	cantidad: number,
	saldo: number,
	tipo: string,
	sku: string,
	agrupar: boolean?
)
	if cantidad <= 0 then
		return
	end
	if not agrupar then
		enviarEconomia(jugador, fuente, cantidad, saldo, tipo, sku)
		return
	end
	local porJugador = agrupados[jugador]
	if porJugador == nil then
		porJugador = {}
		agrupados[jugador] = porJugador
	end
	local clave = `{if fuente then "+" else "-"}|{tipo}|{sku}`
	local actual = porJugador[clave]
	if actual == nil then
		porJugador[clave] = { cantidad = cantidad, saldo = saldo }
	else
		actual.cantidad += cantidad
		actual.saldo = saldo
	end
end

local function vaciarAgrupados(jugador: Player)
	local porJugador = agrupados[jugador]
	if porJugador == nil then
		return
	end
	agrupados[jugador] = nil
	for clave, valor in porJugador do
		local partes = string.split(clave, "|")
		enviarEconomia(jugador, partes[1] == "+", math.floor(valor.cantidad), valor.saldo, partes[2], partes[3])
	end
end

----------------------------------------------------------------------------- eventos

-- Evento personalizado con hasta 3 campos de texto extra.
function AnaliticaService.Evento(jugador: Player, nombre: string, valor: number?, campos: { string }?)
	local camposRoblox: { [string]: string }? = nil
	if campos then
		local c: { [string]: string } = {}
		local claves = {
			Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
			Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
			Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
		}
		for i = 1, math.min(3, #campos) do
			c[claves[i]] = campos[i]
		end
		camposRoblox = c
	end
	llamar(`Evento {nombre} = {valor or 1} ({jugador.Name})`, function()
		AnalyticsService:LogCustomEvent(jugador, nombre, valor or 1, camposRoblox)
	end)
end

-- Progresión (rebirths, sets...).
function AnaliticaService.Progreso(jugador: Player, camino: string, nivel: number, nombreNivel: string?)
	llamar(`Progreso {camino} {nivel} ({jugador.Name})`, function()
		AnalyticsService:LogProgressionCompleteEvent(jugador, camino, nivel, nombreNivel or "")
	end)
end

function AnaliticaService.Iniciar()
	Reloj.Cada(ConfigEconomia.ANALITICA_AGRUPAR_SEGUNDOS, function()
		for jugador in agrupados do
			vaciarAgrupados(jugador)
		end
	end)
	Players.PlayerRemoving:Connect(vaciarAgrupados)
	DatosService.JugadorListo:Conectar(function(jugador: Player)
		AnaliticaService.Onboarding(jugador, "Entro")
	end)
end

return AnaliticaService
