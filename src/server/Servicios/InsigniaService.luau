--!strict
--[[
	InsigniaService
	Entrega las insignias (badges) de Roblox de Config/Insignias.

	Cada tanto (y al entrar) revisa los datos de cada jugador. Si cumple una condición y
	la insignia tiene ID, se la da con BadgeService y lo anota en sus datos: así nunca se
	vuelve a pedir a Roblox (las llamadas a BadgeService tienen límite).
]]

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigInsignias = require(Shared:WaitForChild("Config"):WaitForChild("Insignias"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))

local InsigniaService = {}

local REVISAR_CADA = 15 -- segundos
local enCurso: { [Player]: boolean } = {}

local idsIndice: { string } = {}
for _, crunchi in Catalogo.datos.crunchis do
	table.insert(idsIndice, crunchi.id)
end

local function valor(datos: Tipos.Datos, condicion: string): number
	if condicion == "comprasCinta" then
		return datos.stats.comprasCinta
	elseif condicion == "robosExitosos" then
		return datos.stats.robosExitosos
	elseif condicion == "defensas" then
		return datos.stats.defensas
	elseif condicion == "rebirths" then
		return datos.rebirths
	elseif condicion == "sets" then
		local cantidad = 0
		for _ in datos.setsCompletados do
			cantidad += 1
		end
		return cantidad
	elseif condicion == "indice" then
		return Progresion.PorcentajeIndice(datos.indice, idsIndice)
	elseif condicion == "almacen" then
		return datos.almacen.veces
	end
	return 0
end

local function revisar(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or enCurso[jugador] then
		return
	end
	enCurso[jugador] = true
	for _, insignia in ConfigInsignias do
		if
			insignia.id ~= 0
			and not datos.insignias[insignia.clave]
			and valor(datos, insignia.condicion) >= insignia.minimo
		then
			local ok, err = pcall(function()
				BadgeService:AwardBadge(jugador.UserId, insignia.id)
			end)
			if ok then
				datos.insignias[insignia.clave] = true
			else
				warn(`[Insignias] No se pudo dar "{insignia.clave}": {err}`)
			end
		end
	end
	enCurso[jugador] = nil
end

function InsigniaService.Iniciar()
	DatosService.JugadorListo:Conectar(function(jugador: Player)
		task.delay(5, revisar, jugador)
	end)
	Reloj.Cada(REVISAR_CADA, function()
		for _, jugador in DatosService.JugadoresListos() do
			task.spawn(revisar, jugador)
		end
	end)
end

return InsigniaService
