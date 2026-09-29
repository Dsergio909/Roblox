--!strict
--[[
	ModeloCrunchi
	Crea el modelo 3D de un Crunchi. Lo usan el servidor (Crunchis en las bases) y el
	cliente (Crunchis en la cinta).

	1. Si existe un modelo real en ReplicatedStorage > Modelos > Crunchis > <id>, lo clona.
	2. Si no, arma un PLACEHOLDER con partes simples: cuerpo verde, rabito, hoja, ojos,
	   boca y el accesorio definido en Config/Crunchis.

	Estructura del modelo:
	  - PrimaryPart "Cuerpo": la única parte anclada. Las demás están soldadas a ella, así
	    que mover el Cuerpo mueve todo (barato: un solo cambio de posición por frame).
	  - Pivote en la BASE del Crunchi: model:PivotTo(cframe) lo apoya sobre esa posición.
	  - Atributos "Crunchi" y "Mutacion".

	Rendimiento: ninguna parte colisiona, ni proyecta sombra, ni recibe toques/raycasts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalogo = require(script.Parent:WaitForChild("Catalogo"))

local ModeloCrunchi = {}

local DIAMETRO = 3 -- diámetro del cuerpo con escala 1
local VERDE = Color3.fromRGB(126, 217, 87)
local VERDE_HOJA = Color3.fromRGB(78, 159, 46)
local MARRON = Color3.fromRGB(110, 72, 40)
local BLANCO = Color3.fromRGB(250, 250, 250)
local NEGRO = Color3.fromRGB(25, 25, 25)

type Opciones = {
	forma: string,
	tamano: Vector3,
	posicion: Vector3,
	rotacion: Vector3?,
	color: Color3,
	material: string?,
	transparencia: number?,
	nombre: string?,
}

-- Configura una parte para que sea lo más barata posible.
local function prepararParte(parte: BasePart)
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	parte.CastShadow = false
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
end

local function material(nombre: string?): Enum.Material
	if nombre == nil then
		return Enum.Material.SmoothPlastic
	end
	local ok, valor = pcall(function()
		return (Enum.Material :: any)[nombre]
	end)
	return if ok and valor then valor else Enum.Material.SmoothPlastic
end

-- Crea una pieza soldada al cuerpo. Las posiciones son relativas al centro del cuerpo con
-- escala 1, y se multiplican por la escala del Crunchi.
local function agregarPieza(modelo: Model, cuerpo: BasePart, escala: number, opciones: Opciones)
	local parte = Instance.new("Part")
	parte.Name = opciones.nombre or "Pieza"
	prepararParte(parte)
	parte.Anchored = false
	parte.Massless = true
	parte.Color = opciones.color
	parte.Material = material(opciones.material)
	parte.Transparency = opciones.transparencia or 0

	local tamano = opciones.tamano * escala
	if opciones.forma == "Ball" then
		-- Las partes "Ball" de Roblox siempre son esferas perfectas. Para poder hacer
		-- elipses (cascos, gotas...) usamos un bloque con una malla esférica.
		parte.Shape = Enum.PartType.Block
		local malla = Instance.new("SpecialMesh")
		malla.MeshType = Enum.MeshType.Sphere
		malla.Parent = parte
	elseif opciones.forma == "Cylinder" then
		parte.Shape = Enum.PartType.Cylinder
	elseif opciones.forma == "Wedge" then
		parte.Shape = Enum.PartType.Wedge
	else
		parte.Shape = Enum.PartType.Block
	end
	parte.Size = tamano

	local rot = opciones.rotacion or Vector3.zero
	parte.CFrame = cuerpo.CFrame
		* CFrame.new(opciones.posicion * escala)
		* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))

	local soldadura = Instance.new("WeldConstraint")
	soldadura.Part0 = cuerpo
	soldadura.Part1 = parte
	soldadura.Parent = parte

	parte.Parent = modelo
end

local function agregarOjos(modelo: Model, cuerpo: BasePart, escala: number, estilo: string)
	local tamOjo, tamPupila, x, y, zOjo, zPupila = 0.9, 0.42, 0.55, 0.35, -1.25, -1.62
	if estilo == "grandes" then
		tamOjo, tamPupila, x, y, zOjo, zPupila = 1.25, 0.4, 0.6, 0.4, -1.15, -1.72
	end
	local colorPupila = NEGRO
	local materialPupila: string? = nil
	if estilo == "espiral" then
		colorPupila = Color3.fromRGB(170, 80, 255)
		materialPupila = "Neon"
		tamPupila = 0.5
	end
	local desvioPupila = if estilo == "bizcos" then 0.17 else 0

	for _, lado in { -1, 1 } do
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Ojo",
			forma = "Ball",
			tamano = Vector3.new(tamOjo, tamOjo, tamOjo * 0.6),
			posicion = Vector3.new(x * lado, y, zOjo),
			color = BLANCO,
		})
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Pupila",
			forma = "Ball",
			tamano = Vector3.new(tamPupila, tamPupila, tamPupila * 0.5),
			posicion = Vector3.new((x - desvioPupila) * lado, y, zPupila),
			color = colorPupila,
			material = materialPupila,
		})
		if estilo == "enojados" then
			agregarPieza(modelo, cuerpo, escala, {
				nombre = "Ceja",
				forma = "Block",
				tamano = Vector3.new(0.8, 0.15, 0.2),
				posicion = Vector3.new(x * lado, 0.92, -1.2),
				rotacion = Vector3.new(0, 0, 20 * lado),
				color = NEGRO,
			})
		end
	end
end

local function agregarBoca(modelo: Model, cuerpo: BasePart, escala: number, estilo: string)
	local y, z = -0.5, -1.38
	if estilo == "o" then
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Boca",
			forma = "Ball",
			tamano = Vector3.new(0.5, 0.55, 0.25),
			posicion = Vector3.new(0, y, z),
			color = NEGRO,
		})
	elseif estilo == "dientes" then
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Boca",
			forma = "Block",
			tamano = Vector3.new(1.6, 0.55, 0.2),
			posicion = Vector3.new(0, y, z),
			color = NEGRO,
		})
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Dientes",
			forma = "Block",
			tamano = Vector3.new(1.4, 0.2, 0.22),
			posicion = Vector3.new(0, y + 0.12, z - 0.03),
			color = BLANCO,
		})
	elseif estilo == "abierta" then
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Boca",
			forma = "Block",
			tamano = Vector3.new(1, 0.65, 0.2),
			posicion = Vector3.new(0, y, z),
			color = NEGRO,
		})
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Lengua",
			forma = "Block",
			tamano = Vector3.new(0.6, 0.2, 0.21),
			posicion = Vector3.new(0, y - 0.2, z - 0.02),
			color = Color3.fromRGB(230, 80, 90),
		})
	else
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Boca",
			forma = "Block",
			tamano = Vector3.new(1, 0.18, 0.2),
			posicion = Vector3.new(0, y, z),
			rotacion = if estilo == "torcida" then Vector3.new(0, 0, 15) else nil,
			color = NEGRO,
		})
	end
end

-- Deja un modelo (real o placeholder) listo: cuerpo anclado, resto soldado, sin colisiones.
local function prepararModeloReal(modelo: Model): BasePart?
	local cuerpo = modelo:FindFirstChild("Cuerpo", true)
	if not (cuerpo and cuerpo:IsA("BasePart")) then
		cuerpo = modelo.PrimaryPart or modelo:FindFirstChildWhichIsA("BasePart", true)
	end
	if not (cuerpo and cuerpo:IsA("BasePart")) then
		return nil
	end
	modelo.PrimaryPart = cuerpo
	for _, descendiente in modelo:GetDescendants() do
		if descendiente:IsA("BasePart") then
			prepararParte(descendiente)
			if descendiente ~= cuerpo then
				descendiente.Anchored = false
				descendiente.Massless = true
				local soldadura = Instance.new("WeldConstraint")
				soldadura.Part0 = cuerpo
				soldadura.Part1 = descendiente
				soldadura.Parent = descendiente
			end
		end
	end
	cuerpo.Anchored = true
	return cuerpo
end

local function buscarModeloReal(crunchiId: string): Model?
	local modelos = ReplicatedStorage:FindFirstChild("Modelos")
	local carpeta = modelos and modelos:FindFirstChild("Crunchis")
	local modelo = carpeta and carpeta:FindFirstChild(crunchiId)
	if modelo and modelo:IsA("Model") then
		return modelo
	end
	return nil
end

function ModeloCrunchi.Escala(crunchiId: string): number
	local def = Catalogo.datos.crunchi[crunchiId]
	if def == nil then
		return 1
	end
	local rareza = Catalogo.datos.rareza[def.rareza]
	return def.escala or (if rareza then rareza.escala else 1)
end

-- Altura total aproximada del cuerpo (para colocar etiquetas encima).
function ModeloCrunchi.Altura(crunchiId: string): number
	return DIAMETRO * ModeloCrunchi.Escala(crunchiId)
end

function ModeloCrunchi.Crear(crunchiId: string, mutacionId: string): Model
	local def = Catalogo.datos.crunchi[crunchiId]
	assert(def, `[ModeloCrunchi] No existe el Crunchi "{crunchiId}"`)
	local mutacion = Catalogo.Mutacion(mutacionId)
	local escala = ModeloCrunchi.Escala(crunchiId)

	local modelo: Model
	local cuerpo: BasePart

	local real = buscarModeloReal(crunchiId)
	local cuerpoReal: BasePart? = nil
	if real then
		modelo = real:Clone()
		cuerpoReal = prepararModeloReal(modelo)
		if cuerpoReal then
			modelo:ScaleTo(escala)
		end
	end

	if cuerpoReal then
		cuerpo = cuerpoReal
		if mutacion.color then
			cuerpo.Color = mutacion.color
			cuerpo.Material = material(mutacion.material)
		end
	else
		modelo = Instance.new("Model")
		local nuevoCuerpo = Instance.new("Part")
		nuevoCuerpo.Name = "Cuerpo"
		nuevoCuerpo.Shape = Enum.PartType.Ball
		nuevoCuerpo.Size = Vector3.one * DIAMETRO * escala
		nuevoCuerpo.Color = mutacion.color or VERDE
		nuevoCuerpo.Material = material(mutacion.material)
		nuevoCuerpo.Anchored = true
		prepararParte(nuevoCuerpo)
		nuevoCuerpo.CFrame = CFrame.new(0, DIAMETRO * escala / 2, 0)
		nuevoCuerpo.Parent = modelo
		cuerpo = nuevoCuerpo
		modelo.PrimaryPart = cuerpo

		-- Rabito y hoja
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Rabito",
			forma = "Cylinder",
			tamano = Vector3.new(0.6, 0.18, 0.18),
			posicion = Vector3.new(0, 1.65, 0),
			rotacion = Vector3.new(0, 0, 90),
			color = MARRON,
		})
		agregarPieza(modelo, cuerpo, escala, {
			nombre = "Hoja",
			forma = "Ball",
			tamano = Vector3.new(0.95, 0.14, 0.5),
			posicion = Vector3.new(0.4, 1.7, 0),
			rotacion = Vector3.new(0, 0, 25),
			color = VERDE_HOJA,
		})

		agregarOjos(modelo, cuerpo, escala, def.ojos or "normal")
		agregarBoca(modelo, cuerpo, escala, def.boca or "sonrisa")

		local piezas = def.piezas
		if piezas then
			for _, pieza in piezas do
				agregarPieza(modelo, cuerpo, escala, {
					forma = pieza.forma,
					tamano = pieza.tamano,
					posicion = pieza.posicion,
					rotacion = pieza.rotacion,
					color = pieza.color,
					material = pieza.material,
					transparencia = pieza.transparencia,
				})
			end
		end
	end

	-- Pivote en la base del cuerpo: PivotTo(cframe) apoya el Crunchi sobre ese punto.
	local radio = cuerpo.Size.Y / 2
	modelo.WorldPivot = cuerpo.CFrame * CFrame.new(0, -radio, 0)
	modelo.Name = def.nombre
	modelo:SetAttribute("Crunchi", crunchiId)
	modelo:SetAttribute("Mutacion", mutacion.id)
	-- Con StreamingEnabled: todas las partes llegan juntas al cliente (nunca medio Crunchi).
	modelo.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return modelo
end

--[[
	Etiqueta flotante sobre un Crunchi: nombre (color de rareza), rareza + mutación, ingreso
	y (opcional) precio. La usan la cinta y los pedestales.
]]
export type OpcionesEtiqueta = {
	precio: number?, -- si se pasa, se muestra una línea de precio
	ingresoPorSegundo: number, -- ya calculado por quien llama
	distanciaMaxima: number?,
	formatoDinero: (number) -> string,
}

function ModeloCrunchi.CrearEtiqueta(crunchiId: string, mutacionId: string, opciones: OpcionesEtiqueta): BillboardGui
	local def = Catalogo.datos.crunchi[crunchiId]
	local rareza = Catalogo.RarezaDe(crunchiId)
	local mutacion = Catalogo.Mutacion(mutacionId)
	local colorRareza = if rareza then rareza.color else BLANCO
	local esSecreto = rareza ~= nil and rareza.id == "secreto"

	local etiqueta = Instance.new("BillboardGui")
	etiqueta.Name = "Etiqueta"
	etiqueta.Size = UDim2.fromOffset(170, if opciones.precio then 78 else 60)
	etiqueta.StudsOffsetWorldSpace = Vector3.new(0, ModeloCrunchi.Altura(crunchiId) + 1.6, 0)
	etiqueta.MaxDistance = opciones.distanciaMaxima or 45
	etiqueta.LightInfluence = 0
	etiqueta.AlwaysOnTop = false
	etiqueta.ResetOnSpawn = false

	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lista.VerticalAlignment = Enum.VerticalAlignment.Bottom
	lista.Parent = etiqueta

	local function linea(texto: string, color: Color3, alto: number, orden: number, nombre: string): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = nombre
		label.LayoutOrder = orden
		label.Size = UDim2.new(1, 0, 0, alto)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = texto
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.2
		label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
		label.Parent = etiqueta
		return label
	end

	local textoRareza = if rareza then rareza.nombre else ""
	if mutacion.id ~= "normal" then
		textoRareza = `{mutacion.nombre} · {textoRareza}`
	end
	local lineaRareza = linea(textoRareza, if esSecreto then BLANCO else colorRareza, 16, 1, "Rareza")
	if esSecreto then
		local gradiente = Instance.new("UIGradient")
		gradiente.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
		})
		gradiente.Parent = lineaRareza
	end
	linea(if def then def.nombre else crunchiId, BLANCO, 22, 2, "Nombre")
	linea(`{opciones.formatoDinero(opciones.ingresoPorSegundo)}/s`, Color3.fromRGB(120, 255, 120), 18, 3, "Ingreso")
	if opciones.precio then
		linea(opciones.formatoDinero(opciones.precio), Color3.fromRGB(255, 230, 90), 20, 4, "Precio")
	end
	return etiqueta
end

return ModeloCrunchi
