--!strict
--[[
	Config/Juego
	Datos generales del juego. Lo leen tanto el servidor como el cliente.

	Todas las cifras de balance (precios, rarezas, probabilidades...) vivirán en
	módulos de esta carpeta Config, para que se puedan cambiar sin tocar la lógica.
]]

local Juego = {
	NOMBRE = "Crunch Heist",

	-- Súbela en cada versión que publiques (y anótala en docs/CHANGELOG.md).
	VERSION = "0.0.1",

	-- Fase de desarrollo actual (ver docs/GAME_DESIGN.md, sección 13).
	FASE = 0,
}

-- table.freeze impide que otro script cambie estos valores por error mientras el juego corre.
return table.freeze(Juego)
