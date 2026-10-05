--!strict
--[[
	SocialService
	Bonus por jugar con amigos: +10 % de ingreso por cada amigo en el mismo servidor
	(máximo +30 %). Invitar amigos = más jugadores = mejor para el algoritmo de Roblox.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigEconomia = require(Shared:WaitForChild("Config"):WaitForChild("Economia"))
local Ingreso = require(Shared:WaitForChild("Logica"):WaitForChild("Ingreso"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))

local SocialService = {}

-- Caché de amistades: "idMenor:idMayor" → true/false (IsFriendsWithAsync consulta la web).
local amistades: { [string]: boolean } = {}
local amigosEnServidor: { [Player]: number } = {}

local function clave(a: number, b: number): string
	return if a < b then `{a}:{b}` else `{b}:{a}`
end

local function sonAmigos(a: Player, b: Player): boolean
	local k = clave(a.UserId, b.UserId)
	local conocido = amistades[k]
	if conocido ~= nil then
		return conocido
	end
	local ok, resultado = pcall(function()
		return a:IsFriendsWithAsync(b.UserId)
	end)
	local valor = ok and resultado == true
	amistades[k] = valor
	return valor
end

local function recalcular()
	local jugadores = Players:GetPlayers()
	for _, jugador in jugadores do
		local cantidad = 0
		for _, otro in jugadores do
			if otro ~= jugador and sonAmigos(jugador, otro) then
				cantidad += 1
			end
		end
		if amigosEnServidor[jugador] ~= cantidad then
			amigosEnServidor[jugador] = cantidad
			jugador:SetAttribute("AmigosEnServidor", cantidad)
			EconomiaService.AvisarCambio(jugador)
		end
	end
end

function SocialService.Iniciar()
	EconomiaService.RegistrarBonus("Amigos", function(jugador)
		return Ingreso.BonusAmigos(
			amigosEnServidor[jugador] or 0,
			ConfigEconomia.BONUS.POR_AMIGO,
			ConfigEconomia.BONUS.AMIGOS_MAXIMO
		)
	end)
	DatosService.JugadorListo:Conectar(function()
		recalcular()
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		amigosEnServidor[jugador] = nil
		task.defer(recalcular)
	end)
end

return SocialService
