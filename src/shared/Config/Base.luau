--!strict
--[[
	Config/Base
	La base de cada jugador: pedestales, bóvedas y cerrojo. Ver docs/GAME_DESIGN.md §5 y §6.
]]

local Base = {
	-- Pedestales (cada uno sostiene un Crunchi que genera dinero).
	PEDESTALES_INICIALES = 8,
	PEDESTALES_POR_REBIRTH = 1,
	PEDESTALES_MAX_GRATIS = 16,
	PEDESTALES_PASE = 4, -- Game Pass "Piso Extra" (Fase 3)
	PEDESTALES_TOTAL = 20, -- lo que cabe físicamente en la base (5 columnas × 4 filas)

	-- Bóvedas: pedestales cuyos Crunchis NO se pueden robar. Son los primeros de la base.
	-- Cada entrada: a partir de tantos rebirths, tienes tantas bóvedas.
	BOVEDAS = {
		{ rebirths = 0, cantidad = 1 },
		{ rebirths = 3, cantidad = 2 },
		{ rebirths = 6, cantidad = 3 },
	},

	-- Cerrojo: cierra la puerta de tu base con un campo de fuerza.
	CERROJO_DURACION = 60, -- segundos
	CERROJO_POR_REBIRTH = 5, -- segundos extra por cada rebirth
	CERROJO_MAXIMO = 120, -- tope de duración

	-- Cobro: radio (en studs) alrededor del botón de cobro para cobrar al pisarlo.
	COBRO_RADIO = 2.8,
	-- Cada cuánto el servidor revisa quién está pisando un botón de cobro.
	REVISION_SEGUNDOS = 0.2,
}

return table.freeze(Base)
