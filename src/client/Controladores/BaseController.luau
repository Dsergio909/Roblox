--!strict
--[[
	BaseController
	Todo lo visual de las bases, en el dispositivo del jugador:
	  - Contador de dinero sobre cada botón de cobro de TU base (se calcula aquí mismo a
	    partir de 3 atributos, sin tráfico de red cada segundo).
	  - Puerta con campo de fuerza cuando una base está cerrada (y choca contigo si no es tuya).
	  - Cartel de escudo/cerrojo sobre cada base.
	  - Qué acciones ves sobre cada Crunchi: "Robar" en bases ajenas, "Vender" en la tuya.
	  - Animación al llegar un Crunchi nuevo y "+$X" al cobrar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Ingreso = require(Shared:WaitForChild("Logica"):WaitForChild("Ingreso"))

local SonidoController = require(script.Parent:WaitForChild("SonidoController"))

local BaseController = {}

local jugador = Players.LocalPlayer
local carpetaBases: Folder? = nil
local inicio = os.clock()

type InfoPrompt = { tipo: string, base: Model?, pedestal: Model? }
local prompts: { [ProximityPrompt]: InfoPrompt } = {}
local carteles: { [Model]: TextLabel } = {}
local contadores: { [BasePart]: TextLabel } = {}

----------------------------------------------------------------------------- consultas

function BaseController.Carpeta(): Folder?
	return carpetaBases
end

-- Tu base (o nil si todavía no tienes).
function BaseController.MiBase(): Model?
	local indice = jugador:GetAttribute("Base")
	if carpetaBases == nil or type(indice) ~= "number" then
		return nil
	end
	local base = carpetaBases:FindFirstChild(`Base{indice}`)
	return if base and base:IsA("Model") then base else nil
end

local function valorPedestal(pedestal: Instance, momento: number): number
	local acumulado = pedestal:GetAttribute("Acumulado")
	local tasa = pedestal:GetAttribute("Tasa")
	local desde = pedestal:GetAttribute("Desde")
	if type(acumulado) ~= "number" or type(tasa) ~= "number" or type(desde) ~= "number" then
		return 0
	end
	return Ingreso.Acumulado(acumulado, tasa, desde, momento)
end

-- El botón de cobro con más dinero de tu base (para el tutorial).
function BaseController.MejorBotonCobro(): BasePart?
	local base = BaseController.MiBase()
	local carpeta = base and base:FindFirstChild("Pedestales")
	if carpeta == nil then
		return nil
	end
	local momento = Reloj.Ahora()
	local mejor: BasePart? = nil
	local mejorValor = 0
	for _, pedestal in carpeta:GetChildren() do
		local valor = valorPedestal(pedestal, momento)
		local boton = pedestal:FindFirstChild("BotonCobro")
		if valor >= 1 and valor > mejorValor and boton and boton:IsA("BasePart") then
			mejor = boton
			mejorValor = valor
		end
	end
	return mejor
end

----------------------------------------------------------------------------- acciones visibles

local function buscarAncestro(instancia: Instance, atributo: string): Model?
	local actual = instancia.Parent
	while actual and actual ~= carpetaBases do
		if actual:IsA("Model") and actual:GetAttribute(atributo) ~= nil then
			return actual
		end
		actual = actual.Parent
	end
	return nil
end

local function registrarPrompt(prompt: ProximityPrompt)
	local tipo = prompt.Name
	if tipo ~= "Robar" and tipo ~= "Vender" and tipo ~= "PromptCerrojo" then
		return
	end
	local base = buscarAncestro(prompt, "Dueno")
	local pedestal: Model? = nil
	local actual = prompt.Parent
	while actual and actual ~= base do
		if actual:IsA("Model") and actual:GetAttribute("Indice") ~= nil and actual.Name:sub(1, 1) == "P" then
			pedestal = actual
			break
		end
		actual = actual.Parent
	end
	prompts[prompt] = { tipo = tipo, base = base, pedestal = pedestal }
	prompt.Enabled = false -- se decide en la próxima actualización
end

local function baseProtegida(base: Model, momento: number): boolean
	local escudo = base:GetAttribute("EscudoHasta")
	local cerrojo = base:GetAttribute("CerrojoHasta")
	return (type(escudo) == "number" and escudo > momento) or (type(cerrojo) == "number" and cerrojo > momento)
end

local function actualizarPrompts(momento: number)
	local cargando = jugador:GetAttribute("Cargando") == true
	for prompt, info in prompts do
		if prompt.Parent == nil or info.base == nil then
			prompts[prompt] = nil
			continue
		end
		local base = info.base :: Model
		local esMia = base:GetAttribute("Dueno") == jugador.UserId
		local visible = false
		if info.tipo == "Robar" then
			local enBoveda = info.pedestal ~= nil and info.pedestal:GetAttribute("Boveda") == true
			local tieneDueno = (base:GetAttribute("Dueno") or 0) ~= 0
			visible = tieneDueno and not esMia and not cargando and not enBoveda and not baseProtegida(base, momento)
		elseif info.tipo == "Vender" or info.tipo == "PromptCerrojo" then
			visible = esMia
		end
		if prompt.Enabled ~= visible then
			prompt.Enabled = visible
		end
	end
end

----------------------------------------------------------------------------- puertas y carteles

local function cartelDe(base: Model): TextLabel?
	local existente = carteles[base]
	if existente and existente.Parent then
		return existente
	end
	local letrero = base:FindFirstChild("Letrero")
	if letrero == nil or not letrero:IsA("BasePart") then
		return nil
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EstadoBase"
	billboard.Size = UDim2.fromOffset(200, 44)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.TextScaled = true
	texto.TextStrokeTransparency = 0.2
	texto.Text = ""
	texto.Parent = billboard
	billboard.Parent = letrero
	carteles[base] = texto
	return texto
end

local function actualizarBase(base: Model, momento: number)
	local dueno = base:GetAttribute("Dueno")
	local cerrojo = base:GetAttribute("CerrojoHasta")
	local escudo = base:GetAttribute("EscudoHasta")
	local cerrada = type(cerrojo) == "number" and cerrojo > momento
	local conEscudo = type(escudo) == "number" and escudo > momento

	local puerta = base:FindFirstChild("Puerta")
	if puerta and puerta:IsA("BasePart") then
		-- Cambios locales: solo afectan a este jugador (así el dueño puede pasar).
		puerta.Transparency = if cerrada then 0.3 else 1
		puerta.CanCollide = cerrada and dueno ~= jugador.UserId
	end

	local cartel = cartelDe(base)
	if cartel then
		if conEscudo then
			cartel.Text = `🛡️ {Formato.Tiempo((escudo :: number) - momento)}`
			cartel.TextColor3 = Color3.fromRGB(120, 200, 255)
		elseif cerrada then
			cartel.Text = `🔒 {Formato.Tiempo((cerrojo :: number) - momento)}`
			cartel.TextColor3 = Color3.fromRGB(255, 110, 110)
		else
			cartel.Text = ""
		end
	end
end

----------------------------------------------------------------------------- contadores de cobro

local function contadorDe(boton: BasePart): TextLabel
	local existente = contadores[boton]
	if existente and existente.Parent then
		return existente
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Contador"
	billboard.Size = UDim2.fromOffset(110, 30)
	billboard.StudsOffset = Vector3.new(0, 1.6, 0)
	billboard.MaxDistance = 60
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = false
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(130, 255, 120)
	texto.TextStrokeTransparency = 0.1
	texto.Parent = billboard
	billboard.Parent = boton
	contadores[boton] = texto
	return texto
end

local function actualizarContadores(momento: number)
	-- Limpiar contadores de bases que ya no son tuyas
	for boton, texto in contadores do
		if boton.Parent == nil or texto.Parent == nil then
			contadores[boton] = nil
		end
	end
	local base = BaseController.MiBase()
	local carpeta = base and base:FindFirstChild("Pedestales")
	for boton, texto in contadores do
		if carpeta == nil or not boton:IsDescendantOf(carpeta) then
			local billboard = texto.Parent
			if billboard then
				billboard:Destroy()
			end
			contadores[boton] = nil
		end
	end
	if carpeta == nil then
		return
	end
	for _, pedestal in carpeta:GetChildren() do
		local boton = pedestal:FindFirstChild("BotonCobro")
		if boton and boton:IsA("BasePart") and pedestal:GetAttribute("Desbloqueado") == true then
			local valor = valorPedestal(pedestal, momento)
			if valor >= 1 then
				local texto = contadorDe(boton)
				texto.Text = Formato.Dinero(valor)
				texto.Visible = true
			elseif contadores[boton] then
				contadores[boton].Visible = false
			end
		end
	end
end

----------------------------------------------------------------------------- efectos

local function textoFlotante(parte: BasePart, texto: string, color: Color3)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(140, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.MaxDistance = 80
	billboard.LightInfluence = 0
	billboard.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = texto
	label.Parent = billboard
	billboard.Parent = parte
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, info, { StudsOffset = Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		billboard:Destroy()
	end)
end

local function alCobrar(lugar: any, cantidad: any)
	if type(lugar) ~= "number" or type(cantidad) ~= "number" then
		return
	end
	SonidoController.Reproducir(if cantidad >= 1000 then "CobroGrande" else "Cobro")
	local base = BaseController.MiBase()
	local carpeta = base and base:FindFirstChild("Pedestales")
	local pedestal = carpeta and carpeta:FindFirstChild(`P{lugar}`)
	local boton = pedestal and pedestal:FindFirstChild("BotonCobro")
	if boton and boton:IsA("BasePart") then
		textoFlotante(boton, `+{Formato.Dinero(cantidad)}`, Color3.fromRGB(255, 230, 90))
	end
end

-- Un Crunchi nuevo aparece "inflándose" en su pedestal.
local function animarLlegada(modelo: Model)
	if os.clock() - inicio < 3 then
		return -- al entrar al juego no animamos todo
	end
	task.defer(function()
		if modelo.Parent == nil or modelo.PrimaryPart == nil then
			return
		end
		local escalaFinal = modelo:GetScale()
		local valor = Instance.new("NumberValue")
		valor.Value = 0.2
		modelo:ScaleTo(escalaFinal * 0.2)
		valor.Changed:Connect(function(v)
			if modelo.Parent then
				modelo:ScaleTo(escalaFinal * math.max(0.05, v))
			end
		end)
		local tween = TweenService:Create(
			valor,
			TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Value = 1 }
		)
		tween.Completed:Connect(function()
			valor:Destroy()
		end)
		tween:Play()
	end)
end

----------------------------------------------------------------------------- inicio

local function alAgregar(descendiente: Instance)
	if descendiente:IsA("ProximityPrompt") then
		registrarPrompt(descendiente)
	elseif descendiente:IsA("Model") and descendiente:GetAttribute("Crunchi") ~= nil then
		local padre = descendiente.Parent
		if padre and padre:IsA("Model") and padre:GetAttribute("Indice") ~= nil then
			animarLlegada(descendiente)
		end
	end
end

function BaseController.Iniciar()
	task.spawn(function()
		local mapa = workspace:WaitForChild("MapaGenerado")
		local carpeta = mapa:WaitForChild("Bases") :: Folder
		carpetaBases = carpeta
		for _, descendiente in carpeta:GetDescendants() do
			if descendiente:IsA("ProximityPrompt") then
				registrarPrompt(descendiente)
			end
		end
		carpeta.DescendantAdded:Connect(alAgregar)
		carpeta.ChildRemoved:Connect(function(hijo)
			if hijo:IsA("Model") then
				carteles[hijo] = nil
			end
		end)
	end)

	Red.Evento("Cobro").OnClientEvent:Connect(alCobrar)

	Reloj.Cada(0.2, function()
		local carpeta = carpetaBases
		if carpeta == nil then
			return
		end
		local momento = Reloj.Ahora()
		actualizarContadores(momento)
		actualizarPrompts(momento)
		for _, base in carpeta:GetChildren() do
			if base:IsA("Model") then
				actualizarBase(base, momento)
			end
		end
	end)
end

return BaseController
