--!strict
--[[
	EconomiaService
	ÚNICO lugar del juego que suma o resta dinero. Así:
	  - todo movimiento queda registrado en Analytics,
	  - el dinero nunca queda negativo,
	  - la UI y la tabla de jugadores se actualizan solas.

	También calcula el MULTIPLICADOR de ingreso de cada jugador. Otros servicios aportan
	sus bonus sin que Economia los conozca:

	  EconomiaService.RegistrarBonus("Rebirths", function(jugador) return 0.5 * rebirths end)
	  EconomiaService.RegistrarMultiplicador("PaseX2", function(jugador) return 2 end)
	  EconomiaService.AvisarCambio(jugador)   -- cuando cambia algo que afecta al multiplicador
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))
local Ingreso = require(Shared:WaitForChild("Logica"):WaitForChild("Ingreso"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))

local EconomiaService = {
	-- (jugador) — cambió algo que afecta el multiplicador de ingreso
	MultiplicadorCambio = Senal.nueva(),
	-- (jugador, cantidad, tipo, sku) — el jugador ganó dinero
	DineroGanado = Senal.nueva(),
}

type Proveedor = (Player) -> number
local bonusAditivos: { [string]: Proveedor } = {}
local multiplicadores: { [string]: Proveedor } = {}

local enGrupo: { [Player]: boolean } = {}

----------------------------------------------------------------------------- dinero

local function actualizarVisibles(jugador: Player, dinero: number)
	jugador:SetAttribute("Dinero", dinero)
	local stats = jugador:FindFirstChild("leaderstats")
	local valor = stats and stats:FindFirstChild("Dinero")
	if valor and valor:IsA("StringValue") then
		valor.Value = Formato.Dinero(dinero)
	end
end

function EconomiaService.Dinero(jugador: Player): number
	local datos = DatosService.Obtener(jugador)
	return if datos then datos.dinero else 0
end

--[[
	Suma dinero.
	  tipo: AnaliticaService.Tipo.* (Juego, Tienda, Robux, Recompensa...)
	  sku: detalle para Analytics ("cobro", "venta", "admin"...)
	  agrupar: true para eventos muy frecuentes (cobros)
]]
function EconomiaService.Agregar(
	jugador: Player,
	cantidad: number,
	tipo: string,
	sku: string,
	agrupar: boolean?
): boolean
	local datos = DatosService.Obtener(jugador)
	if datos == nil or cantidad ~= cantidad or cantidad <= 0 or cantidad == math.huge then
		return false
	end
	cantidad = math.floor(cantidad)
	datos.dinero += cantidad
	datos.stats.gananciaTotal += cantidad
	actualizarVisibles(jugador, datos.dinero)
	AnaliticaService.Economia(jugador, true, cantidad, datos.dinero, tipo, sku, agrupar)
	EconomiaService.DineroGanado:Disparar(jugador, cantidad, tipo, sku)
	return true
end

-- Resta dinero si alcanza. Devuelve false (y no cambia nada) si no alcanza.
function EconomiaService.Gastar(jugador: Player, cantidad: number, tipo: string, sku: string): boolean
	local datos = DatosService.Obtener(jugador)
	if datos == nil or cantidad ~= cantidad or cantidad < 0 then
		return false
	end
	cantidad = math.floor(cantidad)
	if datos.dinero < cantidad then
		return false
	end
	datos.dinero -= cantidad
	actualizarVisibles(jugador, datos.dinero)
	AnaliticaService.Economia(jugador, false, cantidad, datos.dinero, tipo, sku)
	return true
end

-- Pone el dinero en un valor exacto (rebirth). No cuenta como ganancia ni gasto en Analytics.
function EconomiaService.Fijar(jugador: Player, cantidad: number)
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	datos.dinero = math.max(0, math.floor(cantidad))
	actualizarVisibles(jugador, datos.dinero)
end

----------------------------------------------------------------------------- multiplicador

function EconomiaService.RegistrarBonus(nombre: string, proveedor: Proveedor)
	bonusAditivos[nombre] = proveedor
end

function EconomiaService.RegistrarMultiplicador(nombre: string, proveedor: Proveedor)
	multiplicadores[nombre] = proveedor
end

local function recolectar(proveedores: { [string]: Proveedor }, jugador: Player): { number }
	local valores = {}
	for nombre, proveedor in proveedores do
		local ok, valor = pcall(proveedor, jugador)
		if ok and type(valor) == "number" and valor == valor then
			table.insert(valores, valor)
		elseif not ok then
			warn(`[Economia] Error en el bonus "{nombre}": {valor}`)
		end
	end
	return valores
end

-- Multiplicador total de ingreso del jugador (1 = sin bonus).
function EconomiaService.Multiplicador(jugador: Player): number
	return Ingreso.MultiplicadorTotal(recolectar(bonusAditivos, jugador), recolectar(multiplicadores, jugador))
end

-- Detalle de bonus (para mostrarlo en la UI): nombre → valor.
function EconomiaService.DetalleBonus(jugador: Player): { [string]: number }
	local detalle: { [string]: number } = {}
	for nombre, proveedor in bonusAditivos do
		local ok, valor = pcall(proveedor, jugador)
		if ok and type(valor) == "number" and valor ~= 0 then
			detalle[nombre] = valor
		end
	end
	for nombre, proveedor in multiplicadores do
		local ok, valor = pcall(proveedor, jugador)
		if ok and type(valor) == "number" and valor ~= 1 then
			detalle[nombre] = valor
		end
	end
	return detalle
end

function EconomiaService.AvisarCambio(jugador: Player)
	EconomiaService.MultiplicadorCambio:Disparar(jugador)
end

----------------------------------------------------------------------------- ciclo de vida

local function crearLeaderstats(jugador: Player, datos: any)
	local existentes = jugador:FindFirstChild("leaderstats")
	if existentes then
		existentes:Destroy()
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "leaderstats"
	local dinero = Instance.new("StringValue")
	dinero.Name = "Dinero"
	dinero.Value = Formato.Dinero(datos.dinero)
	dinero.Parent = carpeta
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = datos.rebirths
	rebirths.Parent = carpeta
	carpeta.Parent = jugador
end

function EconomiaService.ActualizarRebirths(jugador: Player, rebirths: number)
	jugador:SetAttribute("Rebirths", rebirths)
	local stats = jugador:FindFirstChild("leaderstats")
	local valor = stats and stats:FindFirstChild("Rebirths")
	if valor and valor:IsA("IntValue") then
		valor.Value = rebirths
	end
end

function EconomiaService.Iniciar()
	-- Bonus por rebirths.
	EconomiaService.RegistrarBonus("Rebirths", function(jugador)
		local datos = DatosService.Obtener(jugador)
		return if datos then datos.rebirths * ConfigEconomia.BONUS.POR_REBIRTH else 0
	end)
	-- Bonus Premium (además, cada minuto de un usuario Premium genera Premium Payouts).
	EconomiaService.RegistrarBonus("Premium", function(jugador)
		return if jugador.MembershipType == Enum.MembershipType.Premium then ConfigEconomia.BONUS.PREMIUM else 0
	end)
	-- Bonus por estar en el grupo del juego.
	EconomiaService.RegistrarBonus("Grupo", function(jugador)
		return if enGrupo[jugador] then ConfigEconomia.BONUS.GRUPO else 0
	end)

	Players.PlayerMembershipChanged:Connect(function(jugador)
		EconomiaService.AvisarCambio(jugador)
	end)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos)
		crearLeaderstats(jugador, datos)
		actualizarVisibles(jugador, datos.dinero)
		EconomiaService.ActualizarRebirths(jugador, datos.rebirths)
		if ConfigEconomia.ID_GRUPO ~= 0 then
			local ok, esMiembro = pcall(function()
				return jugador:IsInGroupAsync(ConfigEconomia.ID_GRUPO)
			end)
			if ok and esMiembro then
				enGrupo[jugador] = true
				EconomiaService.AvisarCambio(jugador)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(jugador)
		enGrupo[jugador] = nil
	end)
end

return EconomiaService
