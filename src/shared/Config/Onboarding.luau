--!strict
--[[
	Config/Onboarding
	Pasos del embudo de los primeros minutos (se registran en AnalyticsService para ver
	en qué punto se van los jugadores). Ver docs/GAME_DESIGN.md §3.

	El orden importa: es el número de paso que ve Analytics. No reordenes los que ya
	están publicados; agrega los nuevos al final.
]]

local Onboarding = {
	PASOS = {
		"Entro", -- 1
		"PrimeraCompra", -- 2
		"PrimerCobro", -- 3
		"TresCrunchis", -- 4
		"PrimeraCanasta", -- 5
		"PrimerRoboODefensa", -- 6
		"PrimeraMision", -- 7
		"PrimerRebirth", -- 8
	},

	-- Tras cuántos segundos de la primera sesión aparece el consejo sobre robar.
	CONSEJO_ROBO_SEGUNDOS = 120,
}

return table.freeze(Onboarding)
