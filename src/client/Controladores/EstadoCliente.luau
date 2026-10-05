--!strict
--[[
	EstadoCliente
	Guarda el estado PRIVADO que el servidor comparte solo con este jugador (tutorial,
	misiones, índice...). Los demás controladores leen de aquí y escuchan los cambios.

	  EstadoCliente.Obtener("tutorial")
	  EstadoCliente.Cambio:Conectar(function(parte, valor) ... end)

	Lo público (dinero, rebirths, base...) viene en atributos del jugador, no aquí.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local EstadoCliente = {
	Cambio = Senal.nueva(), -- (parte: string, valor: any)
	Listo = false,
}

local estado: { [string]: any } = {}

function EstadoCliente.Obtener(parte: string): any
	return estado[parte]
end

local function aplicar(cambios: any)
	if type(cambios) ~= "table" then
		return
	end
	for parte, valor in cambios do
		estado[parte] = valor
		EstadoCliente.Cambio:Disparar(parte, valor)
	end
end

function EstadoCliente.Iniciar()
	Red.Evento("EstadoPrivado").OnClientEvent:Connect(aplicar)
	task.spawn(function()
		local ok, inicial = pcall(function()
			return Red.Funcion("PedirEstado"):InvokeServer()
		end)
		if ok then
			aplicar(inicial)
		end
		EstadoCliente.Listo = true
		EstadoCliente.Cambio:Disparar("_listo", true)
	end)
end

return EstadoCliente
