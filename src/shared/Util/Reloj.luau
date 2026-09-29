--!strict
--[[
	Util/Reloj
	Tiempo compartido entre servidor y clientes, y ciclos periódicos baratos.

	  Reloj.Ahora()                     → tiempo del servidor (segundos), igual en servidor y clientes
	  Reloj.Cada(0.2, function(dt) end) → ejecuta la función cada 0.2 s (un solo Heartbeat)

	Decisión: en vez de muchos `while true do task.wait(0.2) end` sueltos, cada sistema usa
	un único Reloj.Cada. Es más barato y fácil de controlar.
]]

local RunService = game:GetService("RunService")

local Reloj = {}

function Reloj.Ahora(): number
	return workspace:GetServerTimeNow()
end

-- Llama a `fn(dtAcumulado)` aproximadamente cada `intervalo` segundos.
-- Devuelve la conexión (llama :Disconnect() para detenerlo).
function Reloj.Cada(intervalo: number, fn: (number) -> ()): RBXScriptConnection
	local acumulado = 0
	return RunService.Heartbeat:Connect(function(dt)
		acumulado += dt
		if acumulado >= intervalo then
			local transcurrido = acumulado
			acumulado = 0
			fn(transcurrido)
		end
	end)
end

return Reloj
