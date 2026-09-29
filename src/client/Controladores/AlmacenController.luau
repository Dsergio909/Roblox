--!strict
--[[
	AlmacenController
	Lo que el jugador ve del Almacén FrutaMax (AlmacenService):

	  - Los LÁSERES: se crean y mueven solo en este dispositivo, con la misma fórmula y el
	    mismo reloj que usa el servidor para saber si los tocaste (Logica/Laseres). Solo se
	    mueven si la cámara está cerca del edificio.
	  - La cuenta regresiva mientras estás adentro.
	  - El texto de la puerta: "🔒 Rebirth 1" o cuánto falta para la próxima caja.
	  - Un aviso cuando se desbloquea (al llegar a Rebirth 1).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigAlmacen = require(Shared:WaitForChild("Config"):WaitForChild("Almacen"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Laseres = require(Shared:WaitForChild("Logica"):WaitForChild("Laseres"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local AlmacenController = {}

local jugador = Players.LocalPlayer
local ENTRADA = ConfigAlmacen.ENTRADA
local MARCO = CFrame.lookAt(ENTRADA, ENTRADA - Vector3.new(1, 0, 0)) -- igual que en el servidor
local ALTO_LASER = ConfigAlmacen.ALTO - 1
local CENTRO = (MARCO * CFrame.new(0, 0, -ConfigAlmacen.LARGO_PASILLO / 2)).Position
local DISTANCIA_VISIBLE = 140

local rayos: { BasePart } = {}
local panel: Frame
local texto: TextLabel

local function crearLaseres()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "LaseresLocales"
	for _ = 1, #ConfigAlmacen.LASERES do
		local rayo = Instance.new("Part")
		rayo.Name = "Laser"
		rayo.Anchored = true
		rayo.CanCollide = false
		rayo.CanQuery = false
		rayo.CanTouch = false
		rayo.CastShadow = false
		rayo.Material = Enum.Material.Neon
		rayo.Color = Color3.fromRGB(255, 30, 30)
		rayo.Transparency = 0.35
		rayo.Size = Vector3.new(ConfigAlmacen.ANCHO_LASER, ALTO_LASER, Laseres.GROSOR)
		rayo.Parent = carpeta
		table.insert(rayos, rayo)
	end
	carpeta.Parent = workspace
end

local function moverLaseres()
	local camara = workspace.CurrentCamera
	if camara == nil or (camara.CFrame.Position - CENTRO).Magnitude > DISTANCIA_VISIBLE then
		return
	end
	local t = Reloj.Ahora()
	for indice, laser in ConfigAlmacen.LASERES do
		local lado = Laseres.Lado(laser, t)
		rayos[indice].CFrame = MARCO * CFrame.new(lado, ALTO_LASER / 2, -laser.z)
	end
end

local function textoPuerta(): string
	local rebirths = jugador:GetAttribute("Rebirths")
	if type(rebirths) ~= "number" or rebirths < ConfigAlmacen.REQUISITO_REBIRTHS then
		return `🔒 Rebirth {ConfigAlmacen.REQUISITO_REBIRTHS}`
	end
	local estado = EstadoCliente.Obtener("almacen")
	local proximo = if type(estado) == "table" and type(estado.proximo) == "number" then estado.proximo else 0
	local falta = proximo - Reloj.Ahora()
	if falta > 0 then
		return `⏳ {Formato.Tiempo(falta)}`
	end
	return "Entrar"
end

local function actualizar()
	-- Cuenta regresiva adentro
	local hasta = jugador:GetAttribute("AlmacenHasta")
	if type(hasta) == "number" then
		panel.Visible = true
		texto.Text = `🏭 ¡Esquiva los láseres y abre la caja! {math.ceil(math.max(0, hasta - Reloj.Ahora()))} s`
	else
		panel.Visible = false
	end
	-- Texto de la puerta (solo cambia en este dispositivo; el servidor valida igual)
	local mapa = workspace:FindFirstChild("MapaGenerado")
	local almacen = mapa and mapa:FindFirstChild("AlmacenFrutaMax")
	local puerta = almacen and almacen:FindFirstChild("Puerta")
	local prompt = puerta and puerta:FindFirstChild("Entrar")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = textoPuerta()
	end
end

function AlmacenController.Iniciar()
	crearLaseres()
	RunService.RenderStepped:Connect(moverLaseres)

	panel = UI.Panel({
		Name = "Almacen",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -92),
		Size = UDim2.fromOffset(400, 44),
		Visible = false,
		Parent = HudController.Pantalla(),
	})
	UI.Escalar(panel, 400)
	UI.Borde(panel, Tema.COLORES.rojo, 3)
	texto = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -12, 1, 0),
		posicion = UDim2.fromOffset(6, 0),
		tamanoLetra = 18,
		padre = panel,
	})
	Reloj.Cada(0.25, actualizar)

	-- Aviso cuando se desbloquea
	local anterior = jugador:GetAttribute("Rebirths")
	jugador:GetAttributeChangedSignal("Rebirths"):Connect(function()
		local ahora = jugador:GetAttribute("Rebirths")
		if
			type(ahora) == "number"
			and type(anterior) == "number"
			and anterior < ConfigAlmacen.REQUISITO_REBIRTHS
			and ahora >= ConfigAlmacen.REQUISITO_REBIRTHS
		then
			NotificacionController.Avisar(
				"🏭 ¡Se abrió el Almacén FrutaMax! Al oeste de la avenida: esquiva los láseres y saca un Crunchi",
				"exito"
			)
		end
		anterior = ahora
	end)
end

return AlmacenController
