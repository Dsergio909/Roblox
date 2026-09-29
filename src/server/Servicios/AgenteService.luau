--!strict
--[[
	AgenteService
	Los Agentes Escáner de FrutaMax: NPCs de traje con cabeza de ESCÁNER de supermercado
	(línea láser roja). Patrullan la avenida y persiguen a quien cargue un Crunchi robado.
	Si lo alcanzan, el Crunchi vuelve a su dueño.

	Rendimiento: pocos agentes (Config/Agentes), modelos de pocas partes sin animaciones
	y UN solo ciclo de IA para todos. Se mueven con Humanoid:MoveTo (física del servidor,
	que Roblox interpola suave en los clientes).

	El modelo es un placeholder hecho con partes. Para usar un modelo real, ponlo en
	ReplicatedStorage > Modelos > AgenteEscaner (ver docs/ASSETS_PENDIENTES.md, M3).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigAgentes = require(Shared:WaitForChild("Config"):WaitForChild("Agentes"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local RoboService = require(script.Parent:WaitForChild("RoboService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Agente = {
	modelo: Model,
	humanoide: Humanoid,
	raiz: BasePart,
	estado: string, -- "patrulla" | "persecucion" | "aturdido"
	objetivo: Player?,
	desde: number,
	punto: number,
}

local AgenteService = {}

local agentes: { Agente } = {}
local carpeta: Folder

local TRAJE = Color3.fromRGB(31, 41, 55)
local GRIS = Color3.fromRGB(107, 114, 128)
local ROJO = Color3.fromRGB(255, 42, 42)

----------------------------------------------------------------------------- modelo

local function parte(
	modelo: Model,
	raiz: BasePart?,
	nombre: string,
	tamano: Vector3,
	desplazamiento: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if raiz then
		p.Massless = true
		p.CFrame = raiz.CFrame * CFrame.new(desplazamiento)
		local soldadura = Instance.new("WeldConstraint")
		soldadura.Part0 = raiz
		soldadura.Part1 = p
		soldadura.Parent = p
	end
	p.Parent = modelo
	return p
end

local function crearModeloPlaceholder(): Model
	local modelo = Instance.new("Model")
	local raiz = parte(modelo, nil, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero, TRAJE)
	raiz.Transparency = 1
	raiz.CanCollide = true
	parte(modelo, raiz, "Torso", Vector3.new(2, 2, 1), Vector3.zero, TRAJE)
	parte(modelo, raiz, "Corbata", Vector3.new(0.3, 1.3, 0.1), Vector3.new(0, 0.2, -0.55), ROJO)
	parte(modelo, raiz, "BrazoIzquierdo", Vector3.new(0.8, 2, 0.8), Vector3.new(-1.4, 0, 0), TRAJE)
	parte(modelo, raiz, "BrazoDerecho", Vector3.new(0.8, 2, 0.8), Vector3.new(1.4, 0, 0), TRAJE)
	parte(modelo, raiz, "PiernaIzquierda", Vector3.new(0.9, 2, 0.9), Vector3.new(-0.5, -2, 0), TRAJE)
	parte(modelo, raiz, "PiernaDerecha", Vector3.new(0.9, 2, 0.9), Vector3.new(0.5, -2, 0), TRAJE)
	-- Cabeza: escáner de supermercado con su ventana roja y la línea láser.
	parte(modelo, raiz, "Head", Vector3.new(1.8, 1.3, 1.4), Vector3.new(0, 1.7, 0), GRIS)
	parte(modelo, raiz, "Mango", Vector3.new(0.6, 1, 0.6), Vector3.new(0, 1.25, 0.6), GRIS)
	parte(modelo, raiz, "Ventana", Vector3.new(1.4, 0.7, 0.1), Vector3.new(0, 1.7, -0.72), ROJO, Enum.Material.Neon)
	local laser =
		parte(modelo, raiz, "Laser", Vector3.new(0.08, 0.08, 6), Vector3.new(0, 1.7, -3.7), ROJO, Enum.Material.Neon)
	laser.Transparency = 0.4
	modelo.PrimaryPart = raiz
	return modelo
end

local function crearAgente(indice: number): Agente
	local plantilla = ReplicatedStorage:FindFirstChild("Modelos")
		and (ReplicatedStorage :: any).Modelos:FindFirstChild("AgenteEscaner")
	local modelo: Model
	if plantilla and plantilla:IsA("Model") and plantilla:FindFirstChild("HumanoidRootPart") then
		modelo = plantilla:Clone()
	else
		modelo = crearModeloPlaceholder()
	end
	modelo.Name = `AgenteEscaner{indice}`

	local humanoide = modelo:FindFirstChildOfClass("Humanoid")
	if humanoide == nil then
		local nuevo = Instance.new("Humanoid")
		nuevo.RigType = Enum.HumanoidRigType.R15
		nuevo.HipHeight = 2 -- piernas de 2 studs bajo el torso
		nuevo.Parent = modelo
		humanoide = nuevo
	end
	local h = humanoide :: Humanoid
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.WalkSpeed = ConfigAgentes.VELOCIDAD_PATRULLA
	h.BreakJointsOnDeath = false
	h.MaxHealth = math.huge
	h.Health = math.huge

	local raiz = modelo:FindFirstChild("HumanoidRootPart") :: BasePart
	local puntos = ConfigAgentes.PATRULLA
	local inicio = puntos[((indice - 1) * 3) % #puntos + 1]
	modelo:PivotTo(CFrame.new(inicio + Vector3.new(0, 2, 0)))
	modelo.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	modelo.Parent = carpeta
	pcall(function()
		raiz:SetNetworkOwner(nil) -- el servidor simula a los agentes (no un jugador)
	end)

	return {
		modelo = modelo,
		humanoide = h,
		raiz = raiz,
		estado = "patrulla",
		objetivo = nil,
		desde = os.clock(),
		punto = ((indice - 1) * 3) % #puntos + 1,
	}
end

----------------------------------------------------------------------------- IA

local function raizDe(jugador: Player): BasePart?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function patrullar(agente: Agente)
	agente.estado = "patrulla"
	agente.objetivo = nil
	agente.humanoide.WalkSpeed = ConfigAgentes.VELOCIDAD_PATRULLA
end

local function buscarLadron(agente: Agente): Player?
	local mejor: Player? = nil
	local mejorDistancia = ConfigAgentes.RADIO_DETECCION
	for _, jugador in Players:GetPlayers() do
		if jugador:GetAttribute("Cargando") == true then
			local raiz = raizDe(jugador)
			if raiz then
				local distancia = (raiz.Position - agente.raiz.Position).Magnitude
				if distancia < mejorDistancia then
					mejor = jugador
					mejorDistancia = distancia
				end
			end
		end
	end
	return mejor
end

local function pensar(agente: Agente)
	if agente.modelo.Parent == nil then
		return
	end
	local ahora = os.clock()

	if agente.estado == "aturdido" then
		if ahora - agente.desde >= ConfigAgentes.DESCANSO_TRAS_ATRAPAR then
			patrullar(agente)
		end
		return
	end

	if agente.estado == "persecucion" then
		local objetivo = agente.objetivo
		local raizObjetivo = if objetivo then raizDe(objetivo) else nil
		if
			objetivo == nil
			or raizObjetivo == nil
			or objetivo:GetAttribute("Cargando") ~= true
			or ahora - agente.desde > ConfigAgentes.TIEMPO_MAXIMO_PERSECUCION
		then
			patrullar(agente)
			return
		end
		local distancia = ((raizObjetivo :: BasePart).Position - agente.raiz.Position).Magnitude
		if distancia > ConfigAgentes.DISTANCIA_ABANDONO then
			patrullar(agente)
			return
		end
		if distancia <= ConfigAgentes.RADIO_ATRAPAR then
			local jugador = objetivo :: Player
			RoboService.Fallar(jugador, "agente")
			local direccion = ((raizObjetivo :: BasePart).Position - agente.raiz.Position) * Vector3.new(1, 0, 1)
			if direccion.Magnitude > 0 then
				RedServidor.Enviar("Empujon", jugador, direccion.Unit * 40, 25)
			end
			agente.estado = "aturdido"
			agente.objetivo = nil
			agente.desde = ahora
			agente.humanoide:MoveTo(agente.raiz.Position)
			return
		end
		agente.humanoide:MoveTo((raizObjetivo :: BasePart).Position)
		return
	end

	-- Patrulla: ¿hay algún ladrón cerca?
	local ladron = buscarLadron(agente)
	if ladron then
		agente.estado = "persecucion"
		agente.objetivo = ladron
		agente.desde = ahora
		agente.humanoide.WalkSpeed = ConfigAgentes.VELOCIDAD_PERSECUCION
		RedServidor.Notificar(ladron, "🔎 ¡Un Agente Escáner te vio! ¡Corre!", "alerta")
		return
	end
	local puntos = ConfigAgentes.PATRULLA
	local destino = puntos[agente.punto]
	if (agente.raiz.Position - destino).Magnitude < 5 or ahora - agente.desde > 20 then
		agente.punto = agente.punto % #puntos + 1
		agente.desde = ahora
		destino = puntos[agente.punto]
	end
	agente.humanoide:MoveTo(destino)
end

function AgenteService.Iniciar()
	local nueva = Instance.new("Folder")
	nueva.Name = "Agentes"
	nueva.Parent = workspace
	carpeta = nueva
	for indice = 1, ConfigAgentes.CANTIDAD do
		table.insert(agentes, crearAgente(indice))
	end
	Reloj.Cada(ConfigAgentes.CICLO_IA, function()
		for _, agente in agentes do
			local ok, err = pcall(pensar :: any, agente)
			if not ok then
				warn(`[Agentes] {err}`)
			end
		end
	end)
end

return AgenteService
