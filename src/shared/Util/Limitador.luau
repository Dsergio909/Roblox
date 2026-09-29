--!strict
--[[
	Util/Limitador
	Limita cuántas veces por segundo alguien puede hacer algo ("cubeta de fichas").

	Cada clave (normalmente un jugador) tiene una cubeta con `rafaga` fichas. Cada acción
	gasta una ficha, y las fichas se recargan a `porSegundo` fichas por segundo.
	Sirve para que un exploiter no pueda spamear un RemoteEvent 1000 veces por segundo.

	  local limite = Limitador.nuevo(5, 10)     -- 5 por segundo, ráfagas de hasta 10
	  if not limite:Permitir(jugador, os.clock()) then return end

	Módulo puro: el tiempo se pasa como parámetro.
]]

local Limitador = {}
Limitador.__index = Limitador

type Cubeta = { fichas: number, ultimo: number }

export type Limitador = typeof(setmetatable(
	{} :: {
		porSegundo: number,
		rafaga: number,
		cubetas: { [any]: Cubeta },
	},
	Limitador
))

function Limitador.nuevo(porSegundo: number, rafaga: number?): Limitador
	local self = setmetatable({
		porSegundo = porSegundo,
		rafaga = rafaga or math.max(1, porSegundo),
		cubetas = {},
	}, Limitador)
	return self
end

-- Devuelve true si la acción está permitida (y gasta una ficha).
function Limitador.Permitir(self: Limitador, clave: any, ahora: number): boolean
	local cubeta = self.cubetas[clave]
	if cubeta == nil then
		cubeta = { fichas = self.rafaga, ultimo = ahora }
		self.cubetas[clave] = cubeta
	end
	local transcurrido = math.max(0, ahora - cubeta.ultimo)
	cubeta.fichas = math.min(self.rafaga, cubeta.fichas + transcurrido * self.porSegundo)
	cubeta.ultimo = ahora
	if cubeta.fichas >= 1 then
		cubeta.fichas -= 1
		return true
	end
	return false
end

-- Borra la cubeta de una clave (llamar cuando el jugador sale, para no acumular memoria).
function Limitador.Olvidar(self: Limitador, clave: any)
	self.cubetas[clave] = nil
end

return Limitador
