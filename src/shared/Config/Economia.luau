--!strict
--[[
	Config/Economia
	Números generales de la economía. Ver docs/GAME_DESIGN.md §7.

	Fórmula del ingreso por segundo de cada pedestal:
	  ingreso base del Crunchi × multiplicador de mutación
	  × (1 + suma de BONUS aditivos)        ← rebirths, sets, racha, amigos, grupo, Premium
	  × multiplicadores (pase x2, boost x2)
]]

local Economia = {
	-- Con qué empieza un jugador nuevo.
	DINERO_INICIAL = 50,
	CRUNCHI_INICIAL = "crunchito_bobo",

	-- Vender un Crunchi devuelve este porcentaje de su precio (0.5 = 50 %).
	VENTA_PORCENTAJE = 0.5,

	-- Bonus aditivos (se suman entre sí; 0.1 = +10 %).
	BONUS = {
		POR_REBIRTH = 0.5,
		POR_AMIGO = 0.1,
		AMIGOS_MAXIMO = 0.3,
		GRUPO = 0.05,
		PREMIUM = 0.1,
	},

	-- Ganancias offline: al volver cobras este porcentaje de tu ingreso por el tiempo fuera.
	OFFLINE = {
		PORCENTAJE = 0.2,
		HORAS_MAXIMO = 3,
		HORAS_MAXIMO_VIP = 6, -- Game Pass VIP (Fase 3)
		SEGUNDOS_MINIMOS = 60, -- menos que esto no cuenta
	},

	-- ID del grupo de Roblox del juego (para el bonus de grupo).
	-- TODO (configuración de Roblox): crea el grupo y pon aquí su ID. 0 = desactivado.
	ID_GRUPO = 0,

	-- Los cobros de pedestal son muy frecuentes: se agrupan y se envían a Analytics
	-- cada tantos segundos para no saturar el servicio.
	ANALITICA_AGRUPAR_SEGUNDOS = 60,
}

return table.freeze(Economia)
