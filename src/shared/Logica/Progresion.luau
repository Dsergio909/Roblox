--!strict
--[[
	Logica/Progresion
	Fórmulas de progresión: rebirths, días, racha, recompensas, ganancias offline, Índice
	y selección de misiones. Módulo puro (sin Roblox), probado en tests/.
]]

local Progresion = {}

export type Requisito = { rareza: string, cantidad: number }
export type NivelRebirth = { costo: number, requisitos: { Requisito }, desbloquea: string? }
export type ConfigRebirths = {
	NIVELES: { NivelRebirth },
	FACTOR_COSTO: number,
	REQUISITO_DESPUES: Requisito,
}

----------------------------------------------------------------------------- rebirth

-- Datos del rebirth número `n` (1 = el primero).
function Progresion.NivelRebirth(n: number, config: ConfigRebirths): NivelRebirth
	local niveles = config.NIVELES
	if n <= #niveles then
		return niveles[n]
	end
	local ultimo = niveles[#niveles]
	local costo = ultimo.costo * config.FACTOR_COSTO ^ (n - #niveles)
	return { costo = costo, requisitos = { config.REQUISITO_DESPUES } }
end

export type ResultadoRequisito = { rareza: string, cantidad: number, tiene: number, cumple: boolean }

--[[
	¿Se cumplen los requisitos? `ordenes` es la lista de órdenes de rareza de los Crunchis del
	jugador (1 = común ... 7 = secreto). `ordenRareza` traduce id de rareza → orden.
	Un Crunchi de rareza MAYOR cuenta para un requisito menor, pero cada Crunchi cuenta una
	sola vez: los requisitos más exigentes se asignan primero.
]]
function Progresion.CumpleRequisitos(
	ordenes: { number },
	requisitos: { Requisito },
	ordenRareza: { [string]: number }
): (boolean, { ResultadoRequisito })
	local disponibles = table.clone(ordenes)
	table.sort(disponibles, function(a, b)
		return a > b
	end)
	local ordenados = table.clone(requisitos)
	table.sort(ordenados, function(a, b)
		return (ordenRareza[a.rareza] or 0) > (ordenRareza[b.rareza] or 0)
	end)
	local resultados: { ResultadoRequisito } = {}
	local todo = true
	for _, requisito in ordenados do
		local minimo = ordenRareza[requisito.rareza] or math.huge
		local tiene = 0
		local i = 1
		while i <= #disponibles and tiene < requisito.cantidad do
			if disponibles[i] >= minimo then
				tiene += 1
				table.remove(disponibles, i)
			else
				i += 1
			end
		end
		local cumple = tiene >= requisito.cantidad
		todo = todo and cumple
		table.insert(
			resultados,
			{ rareza = requisito.rareza, cantidad = requisito.cantidad, tiene = tiene, cumple = cumple }
		)
	end
	return todo, resultados
end

----------------------------------------------------------------------------- tiempo

-- Número de día (UTC) desde 1970. Cambia a las 00:00 UTC.
function Progresion.Dia(tiempoUnix: number): number
	return math.floor(tiempoUnix / 86400)
end

-- Número de semana; las semanas empiezan el LUNES (el 1/1/1970 fue jueves).
function Progresion.Semana(dia: number): number
	return (dia + 3) // 7
end

--[[
	Racha suave: +1 si te conectas el día siguiente; si faltaste, baja un paso por cada día
	perdido (sin bajar de 0) y luego suma el día de hoy. Nunca supera `maximo`.
	Devuelve la nueva racha.
]]
function Progresion.ActualizarRacha(racha: number, ultimoDia: number, hoy: number, maximo: number): number
	if ultimoDia == hoy then
		return racha
	end
	if ultimoDia <= 0 then
		return 1
	end
	local perdidos = math.max(0, hoy - ultimoDia - 1)
	local nueva = math.max(0, racha - perdidos) + 1
	return math.min(maximo, nueva)
end

----------------------------------------------------------------------------- recompensas

-- Dinero equivalente a N minutos de ingreso, con un mínimo.
function Progresion.DineroPorMinutos(ingresoPorSegundo: number, minutos: number, minimo: number): number
	return math.floor(math.max(minimo, ingresoPorSegundo * minutos * 60))
end

-- Ganancia al volver: porcentaje del ingreso por el tiempo fuera, con tope de horas.
function Progresion.GananciaOffline(
	ingresoPorSegundo: number,
	segundosFuera: number,
	porcentaje: number,
	horasMaximo: number
): number
	local segundos = math.clamp(segundosFuera, 0, horasMaximo * 3600)
	return math.floor(ingresoPorSegundo * porcentaje * segundos)
end

----------------------------------------------------------------------------- índice

-- Porcentaje (0–100) del Índice base: cuántos ids de `ids` aparecen en `indice`.
function Progresion.PorcentajeIndice(indice: { [string]: any }, ids: { string }): number
	if #ids == 0 then
		return 0
	end
	local tiene = 0
	for _, id in ids do
		if indice[id] ~= nil then
			tiene += 1
		end
	end
	return tiene / #ids * 100
end

----------------------------------------------------------------------------- misiones

-- Elige `cantidad` ids distintos de `pool` (sin repetir y evitando `excluir` si se puede).
function Progresion.ElegirMisiones(
	pool: { string },
	cantidad: number,
	aleatorio: () -> number,
	excluir: { string }?
): { string }
	local candidatos = {}
	for _, id in pool do
		if excluir == nil or table.find(excluir, id) == nil then
			table.insert(candidatos, id)
		end
	end
	-- Si excluir deja muy pocas, usamos el pool completo.
	if #candidatos < cantidad then
		candidatos = table.clone(pool)
	end
	local elegidas = {}
	while #elegidas < cantidad and #candidatos > 0 do
		local indice = math.min(#candidatos, math.floor(aleatorio() * #candidatos) + 1)
		table.insert(elegidas, table.remove(candidatos, indice) :: string)
	end
	return elegidas
end

return Progresion
