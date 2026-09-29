--!strict
--[[
	Util/Acciones
	Un solo RemoteEvent ("AccionMenu") para todas las acciones de menús (reclamar misión,
	abrir canasta, hacer rebirth...). Cada servicio registra las suyas:

	  Acciones.Registrar("mision_reclamar", function(jugador, datos) ... end)

	El remoto tiene límite de frecuencia y cada manejador valida sus datos.
]]

local RedServidor = require(script.Parent:WaitForChild("RedServidor"))

local Acciones = {}

type Manejador = (jugador: Player, datos: any) -> ()
local manejadores: { [string]: Manejador } = {}
local iniciado = false

function Acciones.Registrar(nombre: string, manejador: Manejador)
	manejadores[nombre] = manejador
	if not iniciado then
		iniciado = true
		RedServidor.Escuchar("AccionMenu", 8, 12, function(jugador: Player, accion: any, datos: any)
			if type(accion) ~= "string" then
				return
			end
			local fn = manejadores[accion]
			if fn then
				fn(jugador, datos)
			end
		end)
	end
end

return Acciones
