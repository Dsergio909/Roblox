--!strict
--[[
	Logica/Mascotas
	Cuentas de las mascotas: espacios para equipar y bonus total. Módulo puro (sin Roblox),
	probado en tests/. Lo usan el servidor (que decide) y el cliente (que lo muestra).
]]

local LogicaMascotas = {}

export type ConfigEspacios = {
	ESPACIOS_BASE: number,
	ESPACIOS_POR_REBIRTH: { number },
	ESPACIOS_PASE: number,
}

-- Cuántas mascotas puede llevar equipadas a la vez.
function LogicaMascotas.Espacios(rebirths: number, tienePase: boolean, config: ConfigEspacios): number
	local espacios = config.ESPACIOS_BASE
	for _, requisito in config.ESPACIOS_POR_REBIRTH do
		if rebirths >= requisito then
			espacios += 1
		end
	end
	if tienePase then
		espacios += config.ESPACIOS_PASE
	end
	return espacios
end

-- Bonus de ingreso total de las mascotas equipadas (con tope).
function LogicaMascotas.Bonus(bonusEquipadas: { number }, maximo: number): number
	local total = 0
	for _, bonus in bonusEquipadas do
		total += bonus
	end
	return math.min(total, maximo)
end

-- Elige las `espacios` mejores (mayor bonus) de una lista de { uid, bonus }.
function LogicaMascotas.Mejores(lista: { { uid: string, bonus: number } }, espacios: number): { string }
	local ordenada = table.clone(lista)
	table.sort(ordenada, function(a, b)
		if a.bonus == b.bonus then
			return a.uid < b.uid
		end
		return a.bonus > b.bonus
	end)
	local resultado = {}
	for i = 1, math.min(espacios, #ordenada) do
		table.insert(resultado, ordenada[i].uid)
	end
	return resultado
end

return LogicaMascotas
