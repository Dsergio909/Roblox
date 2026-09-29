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
local Azar = require(script.Parent:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(script.Parent:WaitForChild("Util"):WaitForChild("Formato"))

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

local ConfigCanastas = require(Config:WaitForChild("Canastas"))
local ConfigSemillas = require(Config:WaitForChild("Semillas"))

export type Canasta = typeof(ConfigCanastas[1])
export type Semilla = typeof(ConfigSemillas[1])

local canastaPorId: { [string]: Canasta } = {}
for _, canasta in ConfigCanastas do
	canastaPorId[canasta.id] = canasta
end
local semillaPorId: { [string]: Semilla } = {}
for _, semilla in ConfigSemillas do
	semillaPorId[semilla.id] = semilla
end

local Catalogo = {
	datos = datos,
	canastas = ConfigCanastas,
	canasta = canastaPorId,
	semillas = ConfigSemillas,
	semilla = semillaPorId,
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

-- Pesos de mutación de canastas, semillas y Almacén (fijos: ver CatalogoPuro).
function Catalogo.PesosMutacionFijos(bonus: number?): { [string]: number }
	return CatalogoPuro.PesosMutacionFijos(datos, bonus)
end

-- "Mutación: Dorado 4 % · Diamante 1 % · Arcoíris 0.2 %" (para mostrar antes de abrir).
function Catalogo.TextoMutaciones(bonus: number?): string
	local probabilidades = Azar.Probabilidades(Catalogo.PesosMutacionFijos(bonus))
	local partes = {}
	for _, mutacion in datos.mutaciones do
		local p = probabilidades[mutacion.id] or 0
		if mutacion.id ~= "normal" and p > 0 then
			table.insert(partes, `{mutacion.nombre} {Formato.Porcentaje(p)}`)
		end
	end
	return "Mutación: " .. table.concat(partes, " · ")
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
