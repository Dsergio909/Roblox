--!strict
--[[
	Punto de entrada del SERVIDOR.

	Rojo convierte esta carpeta (src/server) en un Script llamado "Server" dentro de
	ServerScriptService. Los demás archivos de la carpeta serán ModuleScripts hijos
	de este Script.

	Decisión de arquitectura: un solo Script de arranque que carga los servicios en
	un orden conocido (datos → economía → cinta → robos...). Así evitamos que decenas
	de scripts sueltos arranquen en orden aleatorio. Los servicios llegan en la Fase 1.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Juego = require(ReplicatedStorage.Shared.Config.Juego)

print(`[{Juego.NOMBRE}] Servidor v{Juego.VERSION} iniciado (Fase {Juego.FASE}). Rojo sincroniza correctamente.`)
