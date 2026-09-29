--!strict
--[[
	AjustesService
	Guarda los ajustes del jugador (⚙️): música, efectos y Modo ahorro. Se guardan con sus
	datos, así valen en cualquier dispositivo y servidor. El cliente los aplica.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tipos = require(Shared:WaitForChild("Tipos"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local AjustesService = {}

local CLAVES = { "musica", "efectos", "ahorro" }

function AjustesService.Iniciar()
	DatosService.RegistrarEstado("ajustes", function(_, datos: Tipos.Datos)
		return table.clone(datos.ajustes)
	end)

	-- ("ajustes", { clave = "musica", valor = false })
	Acciones.Registrar("ajustes", function(jugador: Player, pedido: any)
		if type(pedido) ~= "table" or type(pedido.valor) ~= "boolean" then
			return
		end
		local clave = pedido.clave
		if type(clave) ~= "string" or table.find(CLAVES, clave) == nil then
			return
		end
		local datos = DatosService.Obtener(jugador)
		if datos == nil then
			return
		end
		(datos.ajustes :: any)[clave] = pedido.valor
		DatosService.ActualizarEstado(jugador, { "ajustes" })
	end)
end

return AjustesService
