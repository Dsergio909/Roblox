--!strict
--[[
	RecompensaService
	Entrega recompensas de cualquier tipo con una sola función (misiones, calendario,
	hitos del Índice, pase de temporada...):

	  { tipo = "dinero", minutos = 5 }                → 5 minutos de tu ingreso base
	  { tipo = "canasta", id = "madera", cantidad = 1 } → tickets de canasta gratis
	  { tipo = "semilla", id = "comun", cantidad = 2 }  → semillas para el macetero
	  { tipo = "xp", cantidad = 100 }                   → experiencia del Pase (Fase 3)

	Devuelve un texto corto para mostrar ("💰 $1.2K", "🧺 Canasta de Madera"...).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))

export type Recompensa = {
	tipo: string,
	minutos: number?,
	minimo: number?,
	id: string?,
	cantidad: number?,
}

local RecompensaService = {
	-- (jugador, cantidad) — lo escucha el Pase de Temporada (Fase 3)
	XpGanada = Senal.nueva(),
}

local DINERO_MINIMO_POR_DEFECTO = 100

function RecompensaService.Dar(jugador: Player, recompensa: Recompensa, sku: string): string
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return ""
	end
	local cantidad = recompensa.cantidad or 1
	if recompensa.tipo == "dinero" then
		local dinero = EconomiaService.DineroPorMinutos(
			jugador,
			recompensa.minutos or 1,
			recompensa.minimo or DINERO_MINIMO_POR_DEFECTO
		)
		EconomiaService.Agregar(jugador, dinero, AnaliticaService.Tipo.Recompensa, sku)
		return `💰 {Formato.Dinero(dinero)}`
	elseif recompensa.tipo == "canasta" then
		local id = recompensa.id or ""
		local canasta = Catalogo.canasta[id]
		if canasta == nil then
			return ""
		end
		datos.tickets[id] = (datos.tickets[id] or 0) + cantidad
		DatosService.ActualizarEstado(jugador, { "canastas" })
		return `🧺 {if cantidad > 1 then `{cantidad}× ` else ""}{canasta.nombre}`
	elseif recompensa.tipo == "semilla" then
		local id = recompensa.id or ""
		local semilla = Catalogo.semilla[id]
		if semilla == nil then
			return ""
		end
		datos.semillas[id] = (datos.semillas[id] or 0) + cantidad
		DatosService.ActualizarEstado(jugador, { "macetero" })
		return `🌱 {if cantidad > 1 then `{cantidad}× ` else ""}{semilla.nombre}`
	elseif recompensa.tipo == "cosmetico" then
		local id = recompensa.id or ""
		datos.cosmeticos[id] = true
		DatosService.ActualizarEstado(jugador, { "cosmeticos" })
		return `✨ ¡Cosmético nuevo!`
	elseif recompensa.tipo == "titulo" then
		local titulo = recompensa.id or ""
		datos.titulos[titulo] = true
		DatosService.ActualizarEstado(jugador, { "indice" })
		return `🏷️ Título «{titulo}»`
	elseif recompensa.tipo == "xp" then
		RecompensaService.XpGanada:Disparar(jugador, cantidad)
		return `⭐ {cantidad} XP`
	end
	return ""
end

-- Entrega varias y devuelve los textos unidos: "💰 $5K · 🧺 Canasta de Madera".
function RecompensaService.DarVarias(jugador: Player, recompensas: { Recompensa }, sku: string): string
	local textos = {}
	for _, recompensa in recompensas do
		local texto = RecompensaService.Dar(jugador, recompensa, sku)
		if texto ~= "" then
			table.insert(textos, texto)
		end
	end
	return table.concat(textos, " · ")
end

function RecompensaService.Iniciar() end

return RecompensaService
