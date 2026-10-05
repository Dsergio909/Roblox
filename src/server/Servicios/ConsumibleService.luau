--!strict
--[[
	ConsumibleService
	Objetos de un solo uso de la 🎒 Mochila (Config/Consumibles): Jugo Turbo, Imán de
	Monedas, Fertilizante Mágico, Reloj del Almacén y Bomba de Confeti.

	  - Se compran con DINERO DEL JUEGO (precio en minutos de tu ingreso) o se ganan como
	    recompensa ({ tipo = "consumible", id, cantidad }).
	  - Usar uno lo valida el servidor: si no sirve en ese momento (p. ej. Fertilizante sin
	    planta), NO se gasta.
	  - Los efectos con tiempo se guardan en datos.boosts (siguen si sales y vuelves) y se
	    publican como atributos (JugoHasta, ImanHasta) para el HUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigConsumibles = require(Shared:WaitForChild("Config"):WaitForChild("Consumibles"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RecompensaService = require(script.Parent:WaitForChild("RecompensaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local MaceteroService = require(script.Parent:WaitForChild("MaceteroService"))
local AlmacenService = require(script.Parent:WaitForChild("AlmacenService"))
local MisionService = require(script.Parent:WaitForChild("MisionService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

type Consumible = ConfigConsumibles.Consumible

local ConsumibleService = {
	-- (jugador, consumibleId)
	Usado = Senal.nueva(),
}

local porId: { [string]: Consumible } = {}
for _, consumible in ConfigConsumibles.LISTA do
	porId[consumible.id] = consumible
end

local ultimoConfeti: { [Player]: number } = {}
local jugoActivo: { [Player]: boolean } = {} -- para avisar cuando se acaba

----------------------------------------------------------------------------- consultas

function ConsumibleService.Precio(jugador: Player, consumible: Consumible): number
	return EconomiaService.DineroPorMinutos(jugador, consumible.precioMinutos, consumible.precioMinimo)
end

local function publicar(jugador: Player, datos: Tipos.Datos)
	jugador:SetAttribute("JugoHasta", datos.boosts.jugoHasta)
	jugador:SetAttribute("ImanHasta", datos.boosts.imanHasta)
end

-- Suma objetos a la Mochila (con tope). Devuelve cuántos entraron.
function ConsumibleService.Dar(jugador: Player, id: string, cantidad: number): number
	local datos = DatosService.Obtener(jugador)
	if datos == nil or porId[id] == nil then
		return 0
	end
	local actual = datos.consumibles[id] or 0
	local entran = math.clamp(math.floor(cantidad), 0, ConfigConsumibles.MAXIMO_POR_OBJETO - actual)
	if entran > 0 then
		datos.consumibles[id] = actual + entran
		DatosService.ActualizarEstado(jugador, { "consumibles" })
	end
	return entran
end

----------------------------------------------------------------------------- efectos

-- Alarga un efecto con tiempo (se acumula hasta maxDuracion desde ahora).
local function alargar(hasta: number, consumible: Consumible): number?
	local ahora = os.time()
	local desde = math.max(ahora, hasta)
	if desde - ahora >= consumible.maxDuracion then
		return nil -- ya está al máximo
	end
	return math.min(desde + consumible.duracion, ahora + consumible.maxDuracion)
end

-- Aplica el efecto. Devuelve (ok, motivo si no se pudo).
local function aplicar(jugador: Player, datos: Tipos.Datos, consumible: Consumible): (boolean, string?)
	local efecto = consumible.efecto
	if efecto == "ingreso" then
		local nuevo = alargar(datos.boosts.jugoHasta, consumible)
		if nuevo == nil then
			return false, "Ya tienes el máximo de Jugo Turbo activo"
		end
		datos.boosts.jugoHasta = nuevo
		jugoActivo[jugador] = true
		EconomiaService.AvisarCambio(jugador)
		return true, nil
	elseif efecto == "autocobro" then
		local nuevo = alargar(datos.boosts.imanHasta, consumible)
		if nuevo == nil then
			return false, "Ya tienes el máximo de Imán activo"
		end
		datos.boosts.imanHasta = nuevo
		return true, nil
	elseif efecto == "macetero" then
		if not MaceteroService.Acelerar(jugador, consumible.valor) then
			return false, "No tienes nada creciendo en tu macetero 🌱"
		end
		return true, nil
	elseif efecto == "almacen" then
		if not AlmacenService.QuitarEspera(jugador) then
			return false, "¡El Almacén ya está listo para entrar!"
		end
		return true, nil
	elseif efecto == "confeti" then
		local momento = os.clock()
		if (ultimoConfeti[jugador] or 0) + ConfigConsumibles.ESPERA_CONFETI > momento then
			return false, "Espera un momento entre bombas de confeti"
		end
		local personaje = jugador.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		if raiz == nil or not raiz:IsA("BasePart") then
			return false, nil
		end
		ultimoConfeti[jugador] = momento
		RedServidor.EnviarATodos("Efecto", "ConfetiJugador", { posicion = raiz.Position })
		return true, nil
	end
	return false, nil
end

----------------------------------------------------------------------------- acciones

local function comprar(jugador: Player, pedido: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(pedido) ~= "table" or type(pedido.id) ~= "string" then
		return
	end
	local consumible = porId[pedido.id]
	if consumible == nil then
		return
	end
	if datos.rebirths < consumible.requisitoRebirths then
		RedServidor.Notificar(jugador, `🔒 Necesitas Rebirth {consumible.requisitoRebirths}`, "error")
		return
	end
	local pedidos = if type(pedido.cantidad) == "number" then pedido.cantidad else 1
	local cantidad = math.clamp(math.floor(pedidos), 1, ConfigConsumibles.COMPRA_MAXIMA)
	if cantidad ~= cantidad then -- NaN
		return
	end
	local espacio = ConfigConsumibles.MAXIMO_POR_OBJETO - (datos.consumibles[consumible.id] or 0)
	cantidad = math.min(cantidad, espacio)
	if cantidad <= 0 then
		RedServidor.Notificar(jugador, "Ya tienes el máximo de ese objeto", "error")
		return
	end
	local total = ConsumibleService.Precio(jugador, consumible) * cantidad
	if not EconomiaService.Gastar(jugador, total, AnaliticaService.Tipo.Tienda, `objeto_{consumible.id}`) then
		RedServidor.Notificar(jugador, `Te faltan {Formato.Dinero(total - datos.dinero)}`, "sinDinero")
		return
	end
	ConsumibleService.Dar(jugador, consumible.id, cantidad)
	RedServidor.Notificar(jugador, `{consumible.icono} +{cantidad} {consumible.nombre} en tu 🎒 Mochila`, "exito")
end

local function usar(jugador: Player, id: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(id) ~= "string" then
		return
	end
	local consumible = porId[id]
	if consumible == nil or (datos.consumibles[id] or 0) < 1 then
		return
	end
	local ok, motivo = aplicar(jugador, datos, consumible)
	if not ok then
		if motivo then
			RedServidor.Notificar(jugador, motivo, "info")
		end
		return
	end
	datos.consumibles[id] -= 1
	if datos.consumibles[id] <= 0 then
		datos.consumibles[id] = nil
	end
	publicar(jugador, datos)
	RedServidor.Enviar("Efecto", jugador, "Objeto", { id = id })
	RedServidor.Notificar(jugador, `{consumible.icono} ¡Usaste {consumible.nombre}!`, "exito")
	DatosService.ActualizarEstado(jugador, { "consumibles" })
	ConsumibleService.Usado:Disparar(jugador, id)
	MisionService.Sumar(jugador, "usar_objeto", 1)
	AnaliticaService.Evento(jugador, "ObjetoUsado", 1, { id })
end

----------------------------------------------------------------------------- estado

local function estado(jugador: Player, datos: Tipos.Datos)
	local precios = {}
	for _, consumible in ConfigConsumibles.LISTA do
		precios[consumible.id] = ConsumibleService.Precio(jugador, consumible)
	end
	return { tiene = table.clone(datos.consumibles), precios = precios }
end

----------------------------------------------------------------------------- inicio

function ConsumibleService.Iniciar()
	DatosService.RegistrarEstado("consumibles", estado)

	-- Temporal: no cuenta para las recompensas "en minutos de ingreso".
	EconomiaService.RegistrarMultiplicador("JugoTurbo", function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		local jugo = porId["jugo_turbo"]
		return if datos and jugo and datos.boosts.jugoHasta > os.time() then jugo.valor else 1
	end, true)
	BaseService.RegistrarAutoCobro("Iman", function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		return datos ~= nil and datos.boosts.imanHasta > os.time()
	end)

	RecompensaService.RegistrarTipo("consumible", function(jugador: Player, recompensa)
		local id = recompensa.id or ""
		local consumible = porId[id]
		local entran = ConsumibleService.Dar(jugador, id, recompensa.cantidad or 1)
		if consumible == nil or entran <= 0 then
			return ""
		end
		return `{consumible.icono} {if entran > 1 then `{entran}× ` else ""}{consumible.nombre}`
	end)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		publicar(jugador, datos)
		jugoActivo[jugador] = datos.boosts.jugoHasta > os.time()
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		ultimoConfeti[jugador] = nil
		jugoActivo[jugador] = nil
	end)

	-- Cuando se acaba el Jugo Turbo, el ingreso vuelve a la normalidad.
	Reloj.Cada(2, function()
		local ahora = os.time()
		for jugador, activo in jugoActivo do
			local datos = DatosService.Obtener(jugador)
			if activo and (datos == nil or datos.boosts.jugoHasta <= ahora) then
				jugoActivo[jugador] = false
				EconomiaService.AvisarCambio(jugador)
				RedServidor.Notificar(jugador, "🧃 Se terminó tu Jugo Turbo", "info")
			end
		end
	end)

	Acciones.Registrar("objeto_comprar", comprar)
	Acciones.Registrar("objeto_usar", usar)

	AdminService.Registrar("objeto", function(jugador, args)
		local id = args[1] or ""
		if porId[id] == nil then
			local ids = {}
			for _, consumible in ConfigConsumibles.LISTA do
				table.insert(ids, consumible.id)
			end
			RedServidor.Notificar(jugador, `🛠️ Objetos: {table.concat(ids, ", ")}`, "info")
			return
		end
		local entran = ConsumibleService.Dar(jugador, id, tonumber(args[2]) or 5)
		RedServidor.Notificar(jugador, `🛠️ +{entran} {porId[id].nombre}`, "info")
	end)
end

return ConsumibleService
