--!strict
--[[
	CosmeticoService
	Auras y estelas (Config/Cosmeticos): estatus visible, sin ventaja de juego.

	  - Se consiguen con dinero del juego, con un Game Pass o como premio.
	  - El jugador equipa una de cada tipo. El servidor solo guarda la elección y la publica
	    como atributo ("Aura", "Estela"); CADA CLIENTE dibuja los efectos (así el servidor no
	    replica partículas y el "Modo ahorro" puede apagarlos en celulares lentos).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigCosmeticos = require(Shared:WaitForChild("Config"):WaitForChild("Cosmeticos"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local CompraService = require(script.Parent:WaitForChild("CompraService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

type Cosmetico = ConfigCosmeticos.Cosmetico

local CosmeticoService = {}

local porId: { [string]: Cosmetico } = {}
for _, cosmetico in ConfigCosmeticos do
	porId[cosmetico.id] = cosmetico
end

function CosmeticoService.Tiene(jugador: Player, id: string): boolean
	local cosmetico = porId[id]
	local datos = DatosService.Obtener(jugador)
	if cosmetico == nil or datos == nil then
		return false
	end
	if string.sub(cosmetico.fuente, 1, 5) == "pase:" then
		return CompraService.TienePase(jugador, string.sub(cosmetico.fuente, 6))
	end
	return datos.cosmeticos[id] == true
end

local function publicar(jugador: Player, datos: Tipos.Datos)
	jugador:SetAttribute("Aura", datos.equipados.aura)
	jugador:SetAttribute("Estela", datos.equipados.estela)
end

local function comprar(jugador: Player, id: any)
	local datos = DatosService.Obtener(jugador)
	local cosmetico = if type(id) == "string" then porId[id] else nil
	if datos == nil or cosmetico == nil or cosmetico.fuente ~= "dinero" then
		return
	end
	if datos.cosmeticos[cosmetico.id] then
		return
	end
	local precio = cosmetico.precioDinero or 0
	if not EconomiaService.Gastar(jugador, precio, AnaliticaService.Tipo.Tienda, `cosmetico_{cosmetico.id}`) then
		RedServidor.Notificar(jugador, `Te faltan {Formato.Dinero(precio - datos.dinero)}`, "sinDinero")
		return
	end
	datos.cosmeticos[cosmetico.id] = true
	datos.equipados[cosmetico.tipo :: any] = cosmetico.id
	publicar(jugador, datos)
	RedServidor.Notificar(jugador, `✨ ¡Tienes {cosmetico.nombre}!`, "exito")
	RedServidor.Enviar("Efecto", jugador, "Logro")
	DatosService.ActualizarEstado(jugador, { "cosmeticos" })
end

local function equipar(jugador: Player, pedido: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(pedido) ~= "table" then
		return
	end
	local tipo = pedido.tipo
	if tipo ~= "aura" and tipo ~= "estela" then
		return
	end
	local id = if type(pedido.id) == "string" then pedido.id else ""
	if id ~= "" then
		local cosmetico = porId[id]
		if cosmetico == nil or cosmetico.tipo ~= tipo or not CosmeticoService.Tiene(jugador, id) then
			return
		end
	end
	datos.equipados[tipo :: any] = id
	publicar(jugador, datos)
	DatosService.ActualizarEstado(jugador, { "cosmeticos" })
end

function CosmeticoService.Iniciar()
	DatosService.RegistrarEstado("cosmeticos", function(jugador: Player, datos: Tipos.Datos)
		local tiene = {}
		for _, cosmetico in ConfigCosmeticos do
			if CosmeticoService.Tiene(jugador, cosmetico.id) then
				table.insert(tiene, cosmetico.id)
			end
		end
		return { tiene = tiene, aura = datos.equipados.aura, estela = datos.equipados.estela }
	end)
	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		publicar(jugador, datos)
	end)
	-- Al comprar un pase con cosmético, se equipa solo.
	CompraService.PaseObtenido:Conectar(function(jugador: Player, clave: string)
		local datos = DatosService.Obtener(jugador)
		if datos == nil then
			return
		end
		for _, cosmetico in ConfigCosmeticos do
			if cosmetico.fuente == `pase:{clave}` then
				datos.equipados[cosmetico.tipo :: any] = cosmetico.id
			end
		end
		publicar(jugador, datos)
		DatosService.ActualizarEstado(jugador, { "cosmeticos" })
	end)
	Acciones.Registrar("cosmetico_comprar", comprar)
	Acciones.Registrar("cosmetico_equipar", equipar)
end

return CosmeticoService
