--!strict
--[[
	Red
	Lista central de todos los RemoteEvents y RemoteFunctions del juego.

	Tenerlos en un solo lugar evita errores de tipeo ("ComprarCinta" vs "CompraCinta") y
	deja claro qué puede pedir el cliente al servidor.

	  Servidor:  Red.Iniciar() una vez al arrancar (crea los remotos).
	  Ambos:     Red.Evento("ComprarCinta") / Red.Funcion("PedirCinta")

	⚠️ Todo lo que llega del cliente puede venir de un exploiter: el servidor SIEMPRE valida
	(ver server/Util/RedServidor).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NOMBRE_CARPETA = "Remotos"

local EVENTOS = {
	-- Cliente → Servidor
	"ComprarCinta", -- (itemId: number)
	"AccionAdmin", -- (comando: string, argumento: string?)
	"AccionCrunchi", -- (accion: string, uid: string, extra: any?)  (Fase 2)
	"AccionMenu", -- (accion: string, datos: any?)  acciones de menús (misiones, índice, ajustes...)

	-- Servidor → Cliente
	"CintaNuevo", -- (item: ItemCinta)
	"CintaRemovido", -- (itemId: number, compradorUserId: number?)
	"Notificar", -- (texto: string, tipo: string?)
	"Anuncio", -- (texto: string, rarezaId: string?)
	"Alarma", -- (activa: boolean, ladronUserId: number?)
	"Empujon", -- (direccion: Vector3, fuerzaArriba: number)
	"Cobro", -- (lugar: number, cantidad: number)
	"EstadoPrivado", -- (cambios: {[string]: any})
	"Efecto", -- (nombre: string, datos: any?)
}

local FUNCIONES = {
	"PedirCinta", -- () → {ItemCinta}
	"PedirEstado", -- () → EstadoPrivado
}

local Red = {}

local carpeta: Folder? = nil

local function esValido(lista: { string }, nombre: string): boolean
	return table.find(lista, nombre) ~= nil
end

-- Solo el servidor: crea la carpeta y todos los remotos.
function Red.Iniciar()
	assert(RunService:IsServer(), "Red.Iniciar solo se llama en el servidor")
	local existente = ReplicatedStorage:FindFirstChild(NOMBRE_CARPETA)
	local nueva = if existente and existente:IsA("Folder") then existente else Instance.new("Folder")
	nueva.Name = NOMBRE_CARPETA
	for _, nombre in EVENTOS do
		if nueva:FindFirstChild(nombre) == nil then
			local remoto = Instance.new("RemoteEvent")
			remoto.Name = nombre
			remoto.Parent = nueva
		end
	end
	for _, nombre in FUNCIONES do
		if nueva:FindFirstChild(nombre) == nil then
			local remoto = Instance.new("RemoteFunction")
			remoto.Name = nombre
			remoto.Parent = nueva
		end
	end
	nueva.Parent = ReplicatedStorage
	carpeta = nueva
end

local function obtenerCarpeta(): Folder
	if carpeta then
		return carpeta
	end
	local encontrada = ReplicatedStorage:WaitForChild(NOMBRE_CARPETA) :: Folder
	carpeta = encontrada
	return encontrada
end

function Red.Evento(nombre: string): RemoteEvent
	assert(esValido(EVENTOS, nombre), `[Red] El evento "{nombre}" no está en la lista EVENTOS`)
	return obtenerCarpeta():WaitForChild(nombre) :: RemoteEvent
end

function Red.Funcion(nombre: string): RemoteFunction
	assert(esValido(FUNCIONES, nombre), `[Red] La función "{nombre}" no está en la lista FUNCIONES`)
	return obtenerCarpeta():WaitForChild(nombre) :: RemoteFunction
end

return Red
