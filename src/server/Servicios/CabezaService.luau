--!strict
--[[
	CabezaService
	La etiqueta sobre la cabeza de cada jugador: nombre, título equipado y rebirths.
	Es ESTATUS visible para todos (prueba social): títulos de sets, VIP, Premium...

	Otros servicios agregan etiquetas (p. ej. "[VIP]" en la Fase 3):
	  CabezaService.RegistrarEtiqueta("VIP", function(jugador) return "[VIP]", Color3... end)
]]

local Players = game:GetService("Players")

local CabezaService = {}

type Etiqueta = (Player) -> (string?, Color3?)
local etiquetas: { [string]: { orden: number, fn: Etiqueta } } = {}

function CabezaService.RegistrarEtiqueta(nombre: string, orden: number, fn: Etiqueta)
	etiquetas[nombre] = { orden = orden, fn = fn }
end

local function textoEtiquetas(jugador: Player): string
	local lista = {}
	for _, etiqueta in etiquetas do
		table.insert(lista, etiqueta)
	end
	table.sort(lista, function(a, b)
		return a.orden < b.orden
	end)
	local partes = {}
	for _, etiqueta in lista do
		local ok, texto, color = pcall(etiqueta.fn, jugador)
		if ok and type(texto) == "string" and texto ~= "" then
			if typeof(color) == "Color3" then
				local c = color :: Color3
				local hex = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
				table.insert(partes, `<font color="{hex}">{texto}</font>`)
			else
				table.insert(partes, texto)
			end
		end
	end
	return table.concat(partes, " ")
end

local function linea(padre: Instance, nombre: string, orden: number, alto: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = nombre
	label.LayoutOrder = orden
	label.Size = UDim2.new(1, 0, 0, alto)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.RichText = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.25
	label.Text = ""
	label.Parent = padre
	return label
end

function CabezaService.Actualizar(jugador: Player)
	local personaje = jugador.Character
	local cabeza = personaje and personaje:FindFirstChild("Head")
	if cabeza == nil then
		return
	end
	local cartel = cabeza:FindFirstChild("Cartel")
	if cartel == nil then
		local nuevo = Instance.new("BillboardGui")
		nuevo.Name = "Cartel"
		nuevo.Size = UDim2.fromOffset(220, 58)
		nuevo.StudsOffset = Vector3.new(0, 2.6, 0)
		nuevo.MaxDistance = 70
		nuevo.LightInfluence = 0
		nuevo.ResetOnSpawn = false
		local lista = Instance.new("UIListLayout")
		lista.SortOrder = Enum.SortOrder.LayoutOrder
		lista.VerticalAlignment = Enum.VerticalAlignment.Bottom
		lista.Parent = nuevo
		linea(nuevo, "Titulo", 1, 18, Color3.fromRGB(255, 215, 90))
		linea(nuevo, "Nombre", 2, 24, Color3.fromRGB(255, 255, 255))
		nuevo.Parent = cabeza
		cartel = nuevo
	end
	local c = cartel :: BillboardGui
	local titulo = jugador:GetAttribute("Titulo")
	local rebirths = jugador:GetAttribute("Rebirths")
	local extra = textoEtiquetas(jugador)
	local nombre = jugador.DisplayName
	if type(rebirths) == "number" and rebirths > 0 then
		nombre = `{nombre} <font color="#8FE3FF">🔁{rebirths}</font>`
	end
	if extra ~= "" then
		nombre = `{extra} {nombre}`
	end
	local lineaTitulo = c:FindFirstChild("Titulo") :: TextLabel
	local lineaNombre = c:FindFirstChild("Nombre") :: TextLabel
	lineaNombre.Text = nombre
	lineaTitulo.Text = if type(titulo) == "string" and titulo ~= "" then `« {titulo} »` else ""
end

function CabezaService.Iniciar()
	local function alEntrar(jugador: Player)
		jugador.CharacterAdded:Connect(function(personaje)
			local humanoide = personaje:WaitForChild("Humanoid", 5)
			if humanoide and humanoide:IsA("Humanoid") then
				-- Ocultamos el nombre por defecto de Roblox (usamos el nuestro).
				humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			personaje:WaitForChild("Head", 5)
			CabezaService.Actualizar(jugador)
		end)
		for _, atributo in { "Titulo", "Rebirths", "EtiquetasCambiaron" } do
			jugador:GetAttributeChangedSignal(atributo):Connect(function()
				CabezaService.Actualizar(jugador)
			end)
		end
	end
	for _, jugador in Players:GetPlayers() do
		alEntrar(jugador)
	end
	Players.PlayerAdded:Connect(alEntrar)
end

return CabezaService
