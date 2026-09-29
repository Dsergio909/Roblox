--!strict
--[[
	Config/Juego
	Datos generales del juego. Lo leen tanto el servidor como el cliente.

	Todas las cifras de balance (precios, rarezas, probabilidades...) viven en los demás
	módulos de esta carpeta Config, para que se puedan cambiar sin tocar la lógica.
]]

local Juego = {
	NOMBRE = "Crunch Heist",

	-- Súbela en cada versión que publiques (y anótala en docs/CHANGELOG.md).
	VERSION = "0.3.0",

	-- Fase de desarrollo actual (ver docs/GAME_DESIGN.md, sección 13).
	FASE = 3,

	-- Nombre del DataStore donde se guardan los jugadores.
	-- ⚠️ Si lo cambias después de publicar, todos empiezan de cero.
	NOMBRE_DATASTORE = "CrunchHeist_Jugadores",

	-- true = en Studio se usan datos de mentira que se borran al cerrar (no toca tus datos reales).
	-- false = en Studio se guardan datos reales (requiere publicar y activar
	-- "Enable Studio Access to API Services").
	DATOS_DE_PRUEBA_EN_STUDIO = false,

	-- Jugadores máximos por servidor = cantidad de bases del mapa.
	-- (Recuerda configurar también el tamaño del servidor en Roblox: ver docs/CONFIGURACION_ROBLOX.md)
	MAX_JUGADORES = 8,
}

-- table.freeze impide que otro script cambie estos valores por error mientras el juego corre.
return table.freeze(Juego)
