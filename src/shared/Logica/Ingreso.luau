--!strict
--[[
	Logica/Ingreso
	Fórmulas de dinero. Módulo puro (sin Roblox), probado en tests/.

	Ingreso de un pedestal por segundo:
	  ingreso base × multiplicador de mutación × multiplicador total

	Multiplicador total:
	  (1 + suma de bonus aditivos) × producto de multiplicadores
	  Los bonus aditivos (rebirths, sets, amigos, grupo, Premium...) se SUMAN para que
	  no se disparen. Los multiplicadores (pase x2, boost x2) se multiplican.
]]

local Ingreso = {}

function Ingreso.MultiplicadorTotal(aditivos: { number }, multiplicadores: { number }): number
	local suma = 1
	for _, bonus in aditivos do
		suma += bonus
	end
	local producto = 1
	for _, mult in multiplicadores do
		producto *= mult
	end
	return math.max(0, suma * producto)
end

function Ingreso.PorSegundo(ingresoBase: number, multMutacion: number, multTotal: number): number
	return ingresoBase * multMutacion * multTotal
end

function Ingreso.Precio(precioBase: number, multMutacion: number): number
	return math.floor(precioBase * multMutacion)
end

function Ingreso.PrecioVenta(precioBase: number, multMutacion: number, porcentaje: number): number
	return math.floor(precioBase * multMutacion * porcentaje)
end

-- Bonus por amigos en el mismo servidor, con tope.
function Ingreso.BonusAmigos(cantidadAmigos: number, porAmigo: number, maximo: number): number
	return math.min(maximo, math.max(0, cantidadAmigos) * porAmigo)
end

-- Dinero acumulado en un pedestal: lo que tenía + tasa × tiempo transcurrido.
function Ingreso.Acumulado(acumulado: number, tasa: number, desde: number, ahora: number): number
	return acumulado + tasa * math.max(0, ahora - desde)
end

return Ingreso
