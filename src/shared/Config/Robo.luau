--!strict
--[[
	Config/Robo
	Reglas de robo y TODAS las protecciones. Ver docs/GAME_DESIGN.md §5.

	⚠️ Ninguna de estas protecciones se puede comprar con Robux. Son iguales para todos.
]]

local Robo = {
	-- Robar
	TIEMPO_ROBAR = 1.5, -- segundos manteniendo pulsado para agarrar un Crunchi
	DISTANCIA_MAXIMA = 12, -- studs: distancia máxima al Crunchi al empezar el robo
	VELOCIDAD_CARGANDO = 0.8, -- el ladrón camina al 80 % de su velocidad
	TIEMPO_MAXIMO_CARGA = 60, -- si no llega a su base en este tiempo, el Crunchi vuelve a su dueño

	-- Protecciones
	ESCUDO_ENTRADA = 180, -- segundos de escudo al entrar al servidor
	NOVATO_SEGUNDOS = 15 * 60, -- tiempo total de juego durante el que tu base es inrobable
	LIMITE_ROBOS = 2, -- robos máximos a una misma base...
	VENTANA_ROBOS = 10 * 60, -- ...dentro de esta ventana de tiempo
	ESCUDO_ALIVIO = 5 * 60, -- escudo automático al alcanzar el límite
	COOLDOWN_PAR = 5 * 60, -- un mismo ladrón no puede robarle a la misma víctima en este tiempo
	DIFERENCIA_REBIRTHS = 2, -- no puedes robar a alguien con esta cantidad (o más) de rebirths menos
	REVANCHA = 45, -- tras robar, tu cerrojo queda inutilizable estos segundos

	-- Si robas mientras tienes escudo de entrada o de novato, lo pierdes (si no, sería injusto).
	ROBAR_QUITA_ESCUDO = true,

	-- Antitrampas: quien carga un Crunchi no puede alejarse del punto del robo más rápido de lo
	-- que camina (con margen). Detecta teletransportes y "speed hacks" sin falsos positivos
	-- por lag: se compara la distancia TOTAL recorrida, no el salto entre dos muestras.
	ANTITRAMPA_SEGUNDOS = 2, -- tolerancia extra de tiempo
	ANTITRAMPA_MARGEN = 1.35, -- velocidad máxima = velocidad cargando × margen

	-- Periódico enrollado (defensa)
	PERIODICO_ALCANCE = 8, -- studs
	PERIODICO_COOLDOWN = 0.8, -- segundos entre golpes
	PERIODICO_EMPUJE = 55, -- fuerza horizontal del empujón
	PERIODICO_EMPUJE_ARRIBA = 28, -- fuerza vertical del empujón
}

return table.freeze(Robo)
