--!strict
--[[
	Util/RedServidor
	Escucha los remotos del cliente con dos protecciones automáticas:

	  1. Límite de frecuencia por jugador (un exploiter no puede spamear).
	  2. pcall: si el manejador falla, se registra el error y el servidor sigue funcionando.

	Cada manejador DEBE validar sus argumentos (tipos, distancias, dueño...), porque
	cualquier cosa que llega del cliente puede venir manipulada.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))
local Limitador = require(Shared:WaitForChild("Util"):WaitForChild("Limitador"))

local RedServidor = {}

local limitadores: { Limitador.Limitador } = {}

Players.PlayerRemoving:Connect(function(jugador)
	for _, limitador in limitadores do
		limitador:Olvidar(jugador)
	end
end)

-- Escucha un RemoteEvent del cliente. `porSegundo` y `rafaga` limitan la frecuencia.
function RedServidor.Escuchar(nombre: string, porSegundo: number, rafaga: number, manejador: (Player, ...any) -> ())
	local limitador = Limitador.nuevo(porSegundo, rafaga)
	table.insert(limitadores, limitador)
	Red.Evento(nombre).OnServerEvent:Connect(function(jugador: Player, ...: any)
		if not limitador:Permitir(jugador, os.clock()) then
			return
		end
		local ok, err = pcall(manejador :: any, jugador, ...)
		if not ok then
			warn(`[Red] Error procesando "{nombre}" de {jugador.Name}: {err}`)
		end
	end)
end

-- Responde un RemoteFunction del cliente (el cliente espera la respuesta).
function RedServidor.Responder(nombre: string, porSegundo: number, rafaga: number, manejador: (Player, ...any) -> any)
	local limitador = Limitador.nuevo(porSegundo, rafaga)
	table.insert(limitadores, limitador)
	Red.Funcion(nombre).OnServerInvoke = function(jugador: Player, ...: any): any
		if not limitador:Permitir(jugador, os.clock()) then
			return nil
		end
		local ok, resultado = pcall(manejador, jugador, ...)
		if not ok then
			warn(`[Red] Error respondiendo "{nombre}" a {jugador.Name}: {resultado}`)
			return nil
		end
		return resultado
	end
end

function RedServidor.Enviar(nombre: string, jugador: Player, ...: any)
	Red.Evento(nombre):FireClient(jugador, ...)
end

function RedServidor.EnviarATodos(nombre: string, ...: any)
	Red.Evento(nombre):FireAllClients(...)
end

-- Atajo para mostrar un mensaje flotante a un jugador. Tipos: "info", "exito", "error", "alerta".
function RedServidor.Notificar(jugador: Player, texto: string, tipo: string?)
	Red.Evento("Notificar"):FireClient(jugador, texto, tipo or "info")
end

return RedServidor
