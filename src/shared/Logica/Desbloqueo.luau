--!strict
--[[
	Logica/Desbloqueo
	Requisitos de desbloqueo por jugar (armas y lo que venga). Módulo puro (sin Roblox),
	probado en tests/. El servidor decide; el cliente usa lo mismo para mostrar el progreso.

	  Resumen: los números del jugador que pueden desbloquear algo.
	  Requisito: { tipo, valor } (ver Config/Armas).
]]

export type Resumen = {
	rebirths: number,
	defensas: number,
	indice: number, -- porcentaje 0 a 100
	almacen: number,
	agentes: number,
}

export type Requisito = { tipo: string, valor: number }

local Desbloqueo = {}

Desbloqueo.TIPOS = { "inicial", "rebirths", "defensas", "indice", "almacen", "agentes" }

-- Cuánto lleva el jugador en ese tipo de requisito.
function Desbloqueo.Valor(tipo: string, resumen: Resumen): number
	if tipo == "rebirths" then
		return resumen.rebirths
	elseif tipo == "defensas" then
		return resumen.defensas
	elseif tipo == "indice" then
		return resumen.indice
	elseif tipo == "almacen" then
		return resumen.almacen
	elseif tipo == "agentes" then
		return resumen.agentes
	end
	return 0
end

function Desbloqueo.Cumple(requisito: Requisito, resumen: Resumen): boolean
	if requisito.tipo == "inicial" then
		return true
	end
	return Desbloqueo.Valor(requisito.tipo, resumen) >= requisito.valor
end

-- Texto para la UI: "Llega a Rebirth 3", "Detén 3 ladrones"...
function Desbloqueo.Texto(requisito: Requisito): string
	local v = requisito.valor
	if requisito.tipo == "inicial" then
		return "Lo tienen todos"
	elseif requisito.tipo == "rebirths" then
		return `Llega a Rebirth {v}`
	elseif requisito.tipo == "defensas" then
		return `Detén a {v} ladrones con un golpe`
	elseif requisito.tipo == "indice" then
		return `Completa el {v} % del Índice`
	elseif requisito.tipo == "almacen" then
		return `Saca {v} cajas del Almacén FrutaMax`
	elseif requisito.tipo == "agentes" then
		return `Golpea a {v} agentes de la Redada`
	end
	return "?"
end

-- Progreso de 0 a 1 (para una barrita).
function Desbloqueo.Progreso(requisito: Requisito, resumen: Resumen): number
	if requisito.tipo == "inicial" or requisito.valor <= 0 then
		return 1
	end
	return math.clamp(Desbloqueo.Valor(requisito.tipo, resumen) / requisito.valor, 0, 1)
end

return Desbloqueo
