--!strict
--[[
	Util/Formato
	Convierte números y tiempos en texto bonito para la UI.

	  Formato.Corto(1234567)      → "1.23M"
	  Formato.Dinero(1500)        → "$1.5K"
	  Formato.Completo(1234567)   → "1,234,567"
	  Formato.Tiempo(125)         → "2:05"
	  Formato.Porcentaje(0.0005)  → "0.05 %"

	Módulo puro: no usa nada de Roblox, así que se puede probar fuera de Studio (tests/).
]]

local Formato = {}

-- K = mil, M = millón, B = billón (mil millones, escala corta en inglés, la que usa Roblox), etc.
local SUFIJOS = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- Quita ceros sobrantes: "1.50" → "1.5", "2.00" → "2".
local function quitarCeros(texto: string): string
	if string.find(texto, ".", 1, true) == nil then
		return texto
	end
	texto = string.gsub(texto, "0+$", "")
	texto = string.gsub(texto, "%.$", "")
	return texto
end

-- Redondea HACIA ABAJO a cierta cantidad de decimales (así nunca mostramos más dinero del que hay).
local function truncar(valor: number, decimales: number): number
	local factor = 10 ^ decimales
	-- El pequeño margen evita errores de coma flotante (p. ej. 1.15 * 100 = 114.999...).
	return math.floor(valor * factor + 1e-9) / factor
end

function Formato.Corto(numero: number): string
	if numero ~= numero then
		return "0" -- NaN
	end
	if numero < 0 then
		return "-" .. Formato.Corto(-numero)
	end
	if numero == math.huge then
		return "∞"
	end
	if numero < 1000 then
		return tostring(math.floor(numero))
	end

	local indice = math.floor(math.log10(numero) / 3)
	if indice >= #SUFIJOS then
		return string.format("%.2e", numero)
	end

	local valor = numero / 10 ^ (indice * 3)
	-- Por errores de coma flotante, valor podría ser 999.9999 o 1000: lo corregimos.
	if valor >= 1000 and indice + 1 < #SUFIJOS then
		indice += 1
		valor /= 1000
	end

	local decimales = if valor >= 100 then 0 elseif valor >= 10 then 1 else 2
	local texto = string.format("%." .. decimales .. "f", truncar(valor, decimales))
	return quitarCeros(texto) .. SUFIJOS[indice + 1]
end

function Formato.Dinero(numero: number): string
	if numero < 0 then
		return "-$" .. Formato.Corto(-numero)
	end
	return "$" .. Formato.Corto(numero)
end

function Formato.Completo(numero: number): string
	local entero = math.floor(math.abs(numero))
	local texto = tostring(entero)
	local conComas = string.reverse((string.gsub(string.reverse(texto), "(%d%d%d)", "%1,")))
	conComas = string.gsub(conComas, "^,", "")
	if numero < 0 then
		return "-" .. conComas
	end
	return conComas
end

function Formato.Tiempo(segundos: number): string
	local total = math.max(0, math.floor(segundos))
	local horas = total // 3600
	local minutos = (total % 3600) // 60
	local segs = total % 60
	if horas > 0 then
		return string.format("%d:%02d:%02d", horas, minutos, segs)
	end
	return string.format("%d:%02d", minutos, segs)
end

-- Probabilidad (0 a 1) a texto. Muestra más decimales para probabilidades pequeñas,
-- para que "0.05 %" no aparezca como "0 %".
function Formato.Porcentaje(probabilidad: number): string
	local p = probabilidad * 100
	local texto
	if p >= 10 then
		texto = string.format("%.1f", p)
	elseif p >= 1 then
		texto = string.format("%.2f", p)
	elseif p >= 0.01 then
		texto = string.format("%.3f", p)
	else
		texto = string.format("%.4f", p)
	end
	return quitarCeros(texto) .. " %"
end

return Formato
