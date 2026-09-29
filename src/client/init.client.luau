--!strict
--[[
	Punto de entrada del CLIENTE (se ejecuta en el dispositivo de cada jugador).

	Rojo convierte esta carpeta (src/client) en un LocalScript llamado "Client" dentro de
	StarterPlayer > StarterPlayerScripts. Carga los "controladores" (UI, efectos, sonidos)
	en un orden conocido; cada uno expone Iniciar().

	Recordatorio: el cliente NUNCA decide dinero, compras ni robos. Solo muestra cosas y
	le PIDE acciones al servidor, que valida todo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Juego = require(Shared:WaitForChild("Config"):WaitForChild("Juego"))

local Interfaz = script:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
UI.Iniciar()

local Controladores = script:WaitForChild("Controladores")

local ORDEN = {
	"EstadoCliente",
	"SonidoController",
	"NotificacionController",
	"BaseController",
	"HudController",
	"CintaController",
	"EfectosController",
	"RoboController",
	"TutorialController",
	"CanastasController",
	"MisionesController",
	"IndiceController",
	"RebirthController",
	"BienvenidaController",
	"DepositoController",
	"MaceteroController",
	"TiendaController",
	"PaseController",
	"CosmeticosController",
	"OfertaController",
	"AdminController",
}

for _, nombre in ORDEN do
	local modulo = Controladores:WaitForChild(nombre, 10)
	if modulo == nil or not modulo:IsA("ModuleScript") then
		warn(`[{Juego.NOMBRE}] No se encontró el controlador {nombre}`)
		continue
	end
	local controlador = (require :: any)(modulo)
	local ok, err = pcall(controlador.Iniciar)
	if not ok then
		warn(`[{Juego.NOMBRE}] Error iniciando {nombre}: {err}`)
	end
end

print(`[{Juego.NOMBRE}] Cliente v{Juego.VERSION} listo.`)
