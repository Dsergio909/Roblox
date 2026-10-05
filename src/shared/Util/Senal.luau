--!strict
--[[
	Util/Senal
	Una "señal" (evento) simple para comunicar módulos entre sí sin que dependan unos de otros.

	  local AlCargar = Senal.nueva()
	  local conexion = AlCargar:Conectar(function(jugador) ... end)
	  AlCargar:Disparar(jugador)
	  conexion:Desconectar()

	Cada función conectada corre en su propio hilo (task.spawn): si una falla, las demás
	siguen funcionando. Corren de inmediato (antes de que Disparar termine) salvo que esperen.
]]

local Senal = {}
Senal.__index = Senal

export type Conexion = { Desconectar: (self: Conexion) -> () }

export type Senal = typeof(setmetatable({} :: { oyentes: { (...any) -> () } }, Senal))

function Senal.nueva(): Senal
	return setmetatable({ oyentes = {} }, Senal)
end

function Senal.Conectar(self: Senal, fn: (...any) -> ()): Conexion
	table.insert(self.oyentes, fn)
	local conexion = {}
	function conexion.Desconectar(_: Conexion)
		local indice = table.find(self.oyentes, fn)
		if indice then
			table.remove(self.oyentes, indice)
		end
	end
	return conexion :: Conexion
end

function Senal.Disparar(self: Senal, ...: any)
	-- Copia de la lista por si alguien se desconecta mientras disparamos.
	for _, fn in table.clone(self.oyentes) do
		task.spawn(fn, ...)
	end
end

return Senal
