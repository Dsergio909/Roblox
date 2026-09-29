--!strict
--[[
	Config/Pase
	Pase Crunch (pase de temporada): 30 niveles con un camino GRATIS y uno PREMIUM.

	  - El camino gratis se completa jugando 4–5 días por semana durante la temporada.
	  - El premium se compra con Robux (producto PASE_PREMIUM) y da cosméticos y más premios.
	  - Ningún premio del pase es un Crunchi del Índice exclusivo de pago.

	TODO (lanzamiento): ajusta las fechas REALES de la temporada. Las fechas son reales:
	cuando termina, termina (nada de "limitado" falso). Para una temporada nueva, cambia el
	`id` (p. ej. "t2"): el progreso de todos empieza de cero y el premium se vuelve a comprar.

	Tipos de premio: dinero (minutos), canasta, semilla, cosmetico, titulo.
]]

export type Premio = { tipo: string, minutos: number?, id: string?, cantidad: number?, texto: string }
export type Nivel = { gratis: Premio, premium: Premio }

local function dinero(minutos: number): Premio
	return { tipo = "dinero", minutos = minutos, texto = `💰 {minutos} min` }
end
local function canasta(id: string, nombre: string, cantidad: number?): Premio
	local n = cantidad or 1
	return { tipo = "canasta", id = id, cantidad = n, texto = `🧺 {if n > 1 then `{n}× ` else ""}{nombre}` }
end
local function semilla(id: string, nombre: string, cantidad: number?): Premio
	local n = cantidad or 1
	return { tipo = "semilla", id = id, cantidad = n, texto = `🌱 {if n > 1 then `{n}× ` else ""}{nombre}` }
end
local function cosmetico(id: string, nombre: string): Premio
	return { tipo = "cosmetico", id = id, texto = `✨ {nombre}` }
end
local function titulo(nombre: string): Premio
	return { tipo = "titulo", id = nombre, texto = `🏷️ «{nombre}»` }
end

-- Niveles especiales; el resto sigue un patrón (ver abajo).
local ESPECIALES: { [number]: Nivel } = {
	[5] = { gratis = semilla("dorada", "Semilla Dorada"), premium = canasta("dorada", "Canasta Dorada") },
	[10] = { gratis = titulo("Crunchero de Temporada"), premium = cosmetico("aura_temporada1_premium", "Aura Nuclear") },
	[15] = { gratis = canasta("hierro", "Canasta de Hierro", 2), premium = semilla("estelar", "Semilla Estelar") },
	[20] = { gratis = cosmetico("aura_temporada1", "Aura T1"), premium = canasta("dorada", "Canasta Dorada", 2) },
	[25] = { gratis = semilla("dorada", "Semilla Dorada", 2), premium = titulo("Leyenda de la Temporada 1") },
	[30] = {
		gratis = cosmetico("estela_temporada1", "Estela T1"),
		premium = cosmetico("estela_temporada1_premium", "Estela Cohete"),
	},
}

local niveles: { Nivel } = {}
for n = 1, 30 do
	local especial = ESPECIALES[n]
	if especial then
		niveles[n] = especial
	elseif n % 3 == 0 then
		niveles[n] =
			{ gratis = canasta("madera", "Canasta de Madera"), premium = canasta("hierro", "Canasta de Hierro") }
	elseif n % 3 == 1 then
		niveles[n] = { gratis = dinero(5 + n), premium = dinero(15 + n * 2) }
	else
		niveles[n] = { gratis = semilla("comun", "Semilla Común"), premium = dinero(20 + n * 2) }
	end
end

local Pase = {
	TEMPORADA = {
		id = "t1",
		nombre = "Temporada 1: ¡Crunch en la Ciudad!",
		inicio = 1790812800, -- 2026-10-01 00:00 UTC  (TODO: fecha real de lanzamiento)
		fin = 1793923200, -- 2026-11-06 00:00 UTC  (TODO: 5 semanas después del inicio)
	},
	XP_POR_NIVEL = 500,
	-- XP por jugar: cada tantos minutos, con tope diario.
	XP_JUEGO = { CADA_MINUTOS = 10, CANTIDAD = 50, MAXIMO_DIA = 300 },
	NIVELES = niveles,
}

return table.freeze(Pase)
