--!strict
--[[
	RoboController
	Lo que ve y siente el jugador durante un robo:
	  - Si te están robando: un rayo rojo te señala al ladrón para que lo persigas.
	  - Si te dan un periodicazo: sales volando (empujón cartoon, sin daño).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))

local RoboController = {}

local jugador = Players.LocalPlayer
local rayo: Beam? = nil
local anclaPropia: Attachment? = nil
local anclaLadron: Attachment? = nil

local function raizDe(personaje: Model?): BasePart?
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function quitarRayo()
	if rayo then
		rayo:Destroy()
		rayo = nil
	end
	if anclaPropia then
		anclaPropia:Destroy()
		anclaPropia = nil
	end
	if anclaLadron then
		anclaLadron:Destroy()
		anclaLadron = nil
	end
end

local function apuntarAlLadron(ladron: Player)
	quitarRayo()
	local miRaiz = raizDe(jugador.Character)
	local suRaiz = raizDe(ladron.Character)
	if miRaiz == nil or suRaiz == nil then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "RayoAlarma"
	a0.Parent = miRaiz
	local a1 = Instance.new("Attachment")
	a1.Name = "RayoAlarma"
	a1.Position = Vector3.new(0, 2, 0)
	a1.Parent = suRaiz
	local nuevo = Instance.new("Beam")
	nuevo.Attachment0 = a0
	nuevo.Attachment1 = a1
	nuevo.Color = ColorSequence.new(Color3.fromRGB(255, 60, 60))
	nuevo.Width0 = 0.5
	nuevo.Width1 = 0.5
	nuevo.FaceCamera = true
	nuevo.LightEmission = 1
	nuevo.Transparency = NumberSequence.new(0.2)
	nuevo.Parent = miRaiz
	rayo, anclaPropia, anclaLadron = nuevo, a0, a1
end

local function alEmpujon(direccion: any, arriba: any)
	if typeof(direccion) ~= "Vector3" or type(arriba) ~= "number" then
		return
	end
	local personaje = jugador.Character
	local raiz = raizDe(personaje)
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if raiz == nil or humanoide == nil then
		return
	end
	-- Límite por seguridad (el servidor manda el valor, pero no está de más).
	local horizontal = if direccion.Magnitude > 120 then direccion.Unit * 120 else direccion
	humanoide:ChangeState(Enum.HumanoidStateType.FallingDown)
	raiz.AssemblyLinearVelocity = horizontal + Vector3.new(0, math.min(arriba, 60), 0)
end

function RoboController.Iniciar()
	Red.Evento("Alarma").OnClientEvent:Connect(function(activa: any, ladronUserId: any)
		if activa == true and type(ladronUserId) == "number" then
			local ladron = Players:GetPlayerByUserId(ladronUserId)
			if ladron then
				apuntarAlLadron(ladron)
			end
		else
			quitarRayo()
		end
	end)
	Red.Evento("Empujon").OnClientEvent:Connect(alEmpujon)
	jugador.CharacterAdded:Connect(quitarRayo)
end

return RoboController
