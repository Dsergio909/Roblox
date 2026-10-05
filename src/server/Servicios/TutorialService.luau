--!strict
--[[
	TutorialService
	Los primeros minutos del jugador (ver docs/GAME_DESIGN.md §3):
	  - Registra los pasos del embudo de onboarding en Analytics.
	  - Le cuenta al cliente cuánto ha avanzado (compras, cobros...) para que muestre las
	    flechas y consejos correctos. Nada de pantallas de texto: el cliente muestra una
	    flecha y 3–5 palabras.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tipos = require(Shared:WaitForChild("Tipos"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CintaService = require(script.Parent:WaitForChild("CintaService"))

local TutorialService = {}

-- A partir de cuántas compras/cobros ya no hace falta enviar actualizaciones del tutorial.
local COMPRAS_TUTORIAL = 3
local COBROS_TUTORIAL = 2

function TutorialService.Iniciar()
	DatosService.RegistrarEstado("tutorial", function(_jugador: Player, datos: Tipos.Datos)
		return {
			compras = datos.stats.comprasCinta,
			cobros = datos.stats.cobros,
			robos = datos.stats.robosExitosos,
			tiempoJugado = datos.stats.tiempoJugado,
			sesiones = datos.stats.sesiones,
		}
	end)

	CintaService.Comprado:Conectar(function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		if datos == nil then
			return
		end
		AnaliticaService.Onboarding(jugador, "PrimeraCompra")
		if #datos.crunchis >= 3 then
			AnaliticaService.Onboarding(jugador, "TresCrunchis")
		end
		if datos.stats.comprasCinta <= COMPRAS_TUTORIAL then
			DatosService.ActualizarEstado(jugador, { "tutorial" })
		end
	end)

	BaseService.Cobrado:Conectar(function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		if datos == nil then
			return
		end
		AnaliticaService.Onboarding(jugador, "PrimerCobro")
		if datos.stats.cobros <= COBROS_TUTORIAL then
			DatosService.ActualizarEstado(jugador, { "tutorial" })
		end
	end)
end

return TutorialService
