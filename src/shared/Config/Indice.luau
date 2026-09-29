--!strict
--[[
	Config/Indice
	Hitos del Índice (porcentaje de Crunchis distintos que tuviste alguna vez).
	Los premios de sets están en Config/Sets.

	El Índice de mutaciones (Dorado, Diamante...) es aparte: es la meta a largo plazo.
]]

export type Hito = { porcentaje: number, titulo: string, minutos: number, canasta: string? }

local Indice = {
	HITOS = {
		{ porcentaje = 25, titulo = "Coleccionista", minutos = 10, canasta = "hierro" },
		{ porcentaje = 50, titulo = "Gran Coleccionista", minutos = 20, canasta = "dorada" },
		{ porcentaje = 75, titulo = "Experto Crunchi", minutos = 30, canasta = "dorada" },
		{ porcentaje = 100, titulo = "Maestro Crunch", minutos = 60, canasta = "epica" },
	} :: { Hito },

	-- Mutaciones que tienen su propia pestaña en el Índice.
	MUTACIONES_INDICE = { "dorado", "diamante", "arcoiris", "radiactivo" },
}

return table.freeze(Indice)
