--!strict
--[[
	Config/Agentes
	Los Agentes Escáner de FrutaMax: patrullan la avenida y persiguen a quien cargue un
	Crunchi robado. Si lo atrapan, el Crunchi vuelve a su dueño.

	Rendimiento: pocos NPCs y un solo ciclo de IA para todos.
]]

local Agentes = {
	CANTIDAD = 3,
	VELOCIDAD_PATRULLA = 9,
	-- Un ladrón camina a 16 × 0.8 = 12.8: el agente es apenas más rápido, así que un buen
	-- ladrón que se aleja a tiempo puede escapar.
	VELOCIDAD_PERSECUCION = 13.5,
	RADIO_DETECCION = 30, -- studs
	RADIO_ATRAPAR = 4,
	DISTANCIA_ABANDONO = 55, -- si el ladrón se aleja tanto, el agente se rinde
	TIEMPO_MAXIMO_PERSECUCION = 10, -- segundos
	DESCANSO_TRAS_ATRAPAR = 4, -- segundos que el agente se queda "aturdido" tras atrapar a alguien
	CICLO_IA = 0.25, -- segundos entre decisiones

	-- Puntos de patrulla (en la avenida). El agente va de uno a otro.
	PATRULLA = {
		Vector3.new(-120, 3, 18),
		Vector3.new(-40, 3, 18),
		Vector3.new(40, 3, 18),
		Vector3.new(120, 3, 18),
		Vector3.new(120, 3, -18),
		Vector3.new(40, 3, -18),
		Vector3.new(-40, 3, -18),
		Vector3.new(-120, 3, -18),
	},
}

return table.freeze(Agentes)
