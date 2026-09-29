--!strict
--[[
	EfectosController
	Efectos visuales y de sonido que el servidor pide ("Efecto") o que pasan en el cliente.

	Rendimiento: las partículas SOLO existen en el cliente, tienen un tope por efecto y un
	tope global, y el "Modo ahorro" (Ajustes, Fase 4) las reduce o apaga.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))

local SonidoController = require(script.Parent:WaitForChild("SonidoController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local EfectosController = {
	-- 1 = normal, 0.3 = modo ahorro, 0 = sin partículas (lo cambia el menú de Ajustes)
	calidad = 1,
}

local jugador = Players.LocalPlayer
local MAX_EMISORES = 6
local emisoresActivos = 0

-- Explosión de confeti en una posición (sin assets: usa la textura por defecto).
function EfectosController.Confeti(posicion: Vector3, color: Color3?, cantidad: number?)
	local total = math.floor((cantidad or 30) * EfectosController.calidad)
	if total <= 0 or emisoresActivos >= MAX_EMISORES then
		return
	end
	emisoresActivos += 1
	local ancla = Instance.new("Part")
	ancla.Anchored = true
	ancla.CanCollide = false
	ancla.CanQuery = false
	ancla.CanTouch = false
	ancla.Transparency = 1
	ancla.Size = Vector3.one * 0.2
	ancla.CFrame = CFrame.new(posicion)
	local emisor = Instance.new("ParticleEmitter")
	emisor.Enabled = false
	emisor.Lifetime = NumberRange.new(0.6, 1.1)
	emisor.Speed = NumberRange.new(14, 24)
	emisor.SpreadAngle = Vector2.new(60, 60)
	emisor.Acceleration = Vector3.new(0, -35, 0)
	emisor.Rotation = NumberRange.new(0, 360)
	emisor.RotSpeed = NumberRange.new(-200, 200)
	emisor.Size = NumberSequence.new(0.35)
	emisor.LightEmission = 0.3
	local base = color or Color3.fromRGB(255, 220, 80)
	emisor.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, base),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 255, 140)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 200)),
	})
	emisor.Parent = ancla
	ancla.Parent = workspace
	emisor:Emit(total)
	task.delay(1.5, function()
		ancla:Destroy()
		emisoresActivos -= 1
	end)
end

local function posicionJugador(): Vector3?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz.Position
	end
	return nil
end

local function alEfecto(nombre: any, datos: any)
	if type(nombre) ~= "string" then
		return
	end
	if nombre == "Compra" then
		SonidoController.Reproducir("Compra")
		local posicion = posicionJugador()
		local rareza = if type(datos) == "table" and type(datos.crunchi) == "string"
			then Catalogo.RarezaDe(datos.crunchi)
			else nil
		if posicion then
			EfectosController.Confeti(posicion + Vector3.new(0, 2, 0), if rareza then rareza.color else nil)
		end
		if type(datos) == "table" and datos.nuevo == true and type(datos.crunchi) == "string" then
			local def = Catalogo.datos.crunchi[datos.crunchi]
			if def then
				NotificacionController.Avisar(`📖 ¡Nuevo en tu Índice: {def.nombre}!`, "exito")
			end
		end
	elseif nombre == "Robo" then
		SonidoController.Reproducir("Robo")
		local posicion = posicionJugador()
		if posicion then
			EfectosController.Confeti(posicion + Vector3.new(0, 2, 0), Color3.fromRGB(255, 80, 80), 40)
		end
	elseif nombre == "Logro" then
		SonidoController.Reproducir("Logro")
		local posicion = posicionJugador()
		if posicion then
			EfectosController.Confeti(posicion + Vector3.new(0, 3, 0), Color3.fromRGB(255, 220, 80), 25)
		end
	elseif nombre == "Rebirth" then
		SonidoController.Reproducir("Rebirth")
		local nivel = if type(datos) == "table" and type(datos.nivel) == "number" then datos.nivel else 0
		NotificacionController.Anunciar(`🔁 ¡REBIRTH {nivel}!`, "mitico")
		local posicion = posicionJugador()
		if posicion then
			for i = 1, 3 do
				task.delay(i * 0.25, function()
					EfectosController.Confeti(posicion + Vector3.new(0, 3, 0), Color3.fromRGB(180, 120, 255), 40)
				end)
			end
		end
	elseif nombre == "Golpe" then
		SonidoController.Reproducir("Golpe")
	elseif nombre == "Cerrojo" then
		SonidoController.Reproducir("Cerrojo")
	end
end

function EfectosController.Iniciar()
	Red.Evento("Efecto").OnClientEvent:Connect(alEfecto)
end

return EfectosController
