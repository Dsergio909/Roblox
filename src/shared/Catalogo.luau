--!strict
--[[
	Catalogo
	Punto de acceso único a toda la configuración de Crunchis, rarezas, mutaciones, sets
	y cintas, ya indexada y validada.

	  local Catalogo = require(Shared.Catalogo)
	  local def = Catalogo.datos.crunchi["crunchito_bobo"]
	  local ingreso, precio = Catalogo.Valor("crunchito_bobo", "dorado")

	Si la configuración tiene un error (p. ej. un Crunchi con una rareza que no existe),
	el juego lo muestra en Output al arrancar.
]]

local Config = script.Parent:WaitForChild("Config")
local CatalogoPuro = require(script.Parent:WaitForChild("Logica"):WaitForChild("CatalogoPuro"))

local datos, errores = CatalogoPuro.Construir(
	require(Config:WaitForChild("Rarezas")),
	require(Config:WaitForChild("Mutaciones")),
	require(Config:WaitForChild("Sets")),
	require(Config:WaitForChild("Crunchis")),
	require(Config:WaitForChild("Cintas"))
)

if #errores > 0 then
	error("[Catalogo] La configuración tiene errores:\n  - " .. table.concat(errores, "\n  - "))
end

export type Catalogo = CatalogoPuro.Catalogo
export type Crunchi = CatalogoPuro.Crunchi
export type Rareza = CatalogoPuro.Rareza
export type Mutacion = CatalogoPuro.Mutacion
export type Cinta = CatalogoPuro.Cinta

local Catalogo = {
	datos = datos,
}

function Catalogo.Valor(crunchiId: string, mutacionId: string): (number, number)
	return CatalogoPuro.Valor(datos, crunchiId, mutacionId)
end

function Catalogo.OrdenDe(crunchiId: string): number
	return CatalogoPuro.OrdenDe(datos, crunchiId)
end

function Catalogo.RarezaDe(crunchiId: string): Rareza?
	local def = datos.crunchi[crunchiId]
	return if def then datos.rareza[def.rareza] else nil
end

function Catalogo.Mutacion(mutacionId: string): Mutacion
	return datos.mutacion[mutacionId] or datos.mutacion["normal"]
end

-- Nombre completo con mutación: "Crunchito Bobo" o "Crunchito Bobo (Dorado)".
function Catalogo.NombreCompleto(crunchiId: string, mutacionId: string): string
	local def = datos.crunchi[crunchiId]
	local nombre = if def then def.nombre else crunchiId
	if mutacionId ~= "normal" then
		return `{nombre} ({Catalogo.Mutacion(mutacionId).nombre})`
	end
	return nombre
end

return Catalogo
