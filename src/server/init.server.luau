--!strict
--[[
	Punto de entrada del SERVIDOR.

	Rojo convierte esta carpeta (src/server) en un Script llamado "Server" dentro de
	ServerScriptService. Los demás archivos son ModuleScripts hijos de este Script.

	Decisión de arquitectura: un solo Script de arranque que inicia los servicios en un
	orden conocido. Cada servicio expone Iniciar(); el orden importa porque unos escuchan
	señales de otros (p. ej. BaseService escucha a DatosService.JugadorListo).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Juego = require(Shared:WaitForChild("Config"):WaitForChild("Juego"))
local Red = require(Shared:WaitForChild("Red"))

-- 1. Crear todos los RemoteEvents antes de que ningún servicio los use.
Red.Iniciar()

local Servicios = script:WaitForChild("Servicios")

-- 2. Orden de inicio. Los que generan el mundo van primero; DatosService va al final
--    porque al iniciarse empieza a cargar jugadores y dispara JugadorListo: para entonces
--    todos los demás ya deben estar escuchando.
local ORDEN = {
	"MapaService",
	"AnaliticaService",
	"EconomiaService",
	"BaseService",
	"CintaService",
	"RoboService",
	"RecompensaService",
	"IndiceService",
	"CabezaService",
	"CanastaService",
	"MaceteroService",
	"MisionService",
	"LoginService",
	"OfflineService",
	"RebirthService",
	"SocialService",
	"AgenteService",
	"TutorialService",
	"AdminService",
	"DatosService",
}

for _, nombre in ORDEN do
	local modulo = Servicios:FindFirstChild(nombre)
	if modulo == nil or not modulo:IsA("ModuleScript") then
		warn(`[{Juego.NOMBRE}] No se encontró el servicio {nombre}`)
		continue
	end
	local servicio = (require :: any)(modulo)
	local ok, err = pcall(servicio.Iniciar)
	if not ok then
		warn(`[{Juego.NOMBRE}] Error iniciando {nombre}: {err}`)
	end
end

print(`[{Juego.NOMBRE}] Servidor v{Juego.VERSION} iniciado (Fase {Juego.FASE}).`)
