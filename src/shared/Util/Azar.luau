--!strict
--[[
	Util/Azar
	Selección aleatoria con pesos (probabilidades relativas).

	El servidor usa Azar.Ponderado para decidir rarezas y mutaciones, y la UI usa
	Azar.Probabilidades con LOS MISMOS pesos para mostrar los porcentajes. Así lo que
	se muestra al jugador y lo que realmente pasa nunca pueden ser distintos.

	Módulo puro: recibe la función aleatoria como parámetro (fácil de probar).
]]

local Azar = {}

export type Pesos = { [string]: number }
export type FuenteAleatoria = () -> number -- devuelve un número en [0, 1)

-- Lista de claves con peso positivo, en orden alfabético (para que el resultado sea
-- reproducible con la misma semilla).
local function clavesOrdenadas(pesos: Pesos): { string }
	local claves = {}
	for clave, peso in pesos do
		if peso > 0 then
			table.insert(claves, clave)
		end
	end
	table.sort(claves)
	return claves
end

function Azar.Total(pesos: Pesos): number
	local total = 0
	for _, peso in pesos do
		if peso > 0 then
			total += peso
		end
	end
	return total
end

-- Elige una clave según su peso. Devuelve nil si no hay pesos positivos.
function Azar.Ponderado(pesos: Pesos, aleatorio: FuenteAleatoria): string?
	local claves = clavesOrdenadas(pesos)
	local total = Azar.Total(pesos)
	if total <= 0 then
		return nil
	end
	local objetivo = aleatorio() * total
	local acumulado = 0
	for _, clave in claves do
		acumulado += pesos[clave]
		if objetivo < acumulado then
			return clave
		end
	end
	return claves[#claves] -- por redondeo, en el borde exacto
end

-- Convierte pesos en probabilidades (0 a 1) que suman 1.
function Azar.Probabilidades(pesos: Pesos): { [string]: number }
	local total = Azar.Total(pesos)
	local resultado: { [string]: number } = {}
	if total <= 0 then
		return resultado
	end
	for clave, peso in pesos do
		if peso > 0 then
			resultado[clave] = peso / total
		end
	end
	return resultado
end

-- Multiplica el peso de ciertas claves (p. ej. "Suerte del servidor" duplica las rarezas altas).
function Azar.Multiplicar(pesos: Pesos, factores: { [string]: number }): Pesos
	local resultado: Pesos = {}
	for clave, peso in pesos do
		resultado[clave] = peso * (factores[clave] or 1)
	end
	return resultado
end

-- Elige un elemento de una lista, con la misma probabilidad para todos.
function Azar.Elegir<T>(lista: { T }, aleatorio: FuenteAleatoria): T?
	if #lista == 0 then
		return nil
	end
	local indice = math.floor(aleatorio() * #lista) + 1
	return lista[math.min(indice, #lista)]
end

return Azar
