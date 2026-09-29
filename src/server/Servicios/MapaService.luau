--!strict
--[[
	MapaService
	Genera el mapa PLACEHOLDER con partes de colores: suelo, avenida, cintas y 8 bases.
	Así puedes probar el juego sin haber modelado nada todavía.

	Todo se crea dentro de Workspace > MapaGenerado. Las medidas están en Config/Mapa.
	Cuando tengas modelos reales, se podrán reemplazar las partes visuales sin cambiar
	la lógica (ver docs/ASSETS_PENDIENTES.md).

	Cada base (en coordenadas locales de la base, -Z es el frente):
	  - Piso, paredes semitransparentes y una puerta al frente (hacia la avenida).
	  - 20 pedestales en una cuadrícula de 5×4, cada uno con su botón de cobro delante.
	  - Botón del cerrojo junto a la puerta y un letrero con el nombre del dueño.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigMapa = require(Config:WaitForChild("Mapa"))
local ConfigBase = require(Config:WaitForChild("Base"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))

export type PedestalMapa = {
	indice: number,
	modelo: Model,
	pedestal: BasePart,
	boton: BasePart,
	ancla: CFrame, -- dónde se apoya el Crunchi (arriba del pedestal, mirando al frente)
}

export type BaseMapa = {
	indice: number,
	modelo: Model,
	cframe: CFrame,
	pedestales: { PedestalMapa },
	puerta: BasePart,
	cerrojo: BasePart,
	promptCerrojo: ProximityPrompt,
	letrero: TextLabel,
	macetero: BasePart,
	aparicion: CFrame, -- donde aparece el dueño
	salida: CFrame, -- afuera de la puerta (para sacar intrusos cuando está cerrada)
}

export type CintaMapa = {
	id: string,
	inicio: Vector3,
	fin: Vector3,
	direccion: Vector3,
	largo: number,
	altura: number, -- altura de la superficie de la cinta
}

local MapaService = {
	Bases = {} :: { BaseMapa },
	Cintas = {} :: { [string]: CintaMapa },
	Carpeta = nil :: Folder?,
}

local MEDIDAS = ConfigMapa.BASE

type PropsParte = {
	nombre: string,
	tamano: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparencia: number?,
	colisiona: boolean?,
	forma: Enum.PartType?,
	sombra: boolean?,
	padre: Instance,
}

local function crearParte(props: PropsParte): Part
	local parte = Instance.new("Part")
	parte.Name = props.nombre
	parte.Anchored = true
	parte.Size = props.tamano
	parte.CFrame = props.cframe
	parte.Color = props.color
	parte.Material = props.material or Enum.Material.SmoothPlastic
	parte.Transparency = props.transparencia or 0
	parte.CanCollide = if props.colisiona == nil then true else props.colisiona
	parte.CanTouch = false
	parte.CastShadow = if props.sombra == nil then false else props.sombra
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	if props.forma then
		parte.Shape = props.forma
	end
	parte.Parent = props.padre
	return parte
end

local function oscurecer(color: Color3, factor: number): Color3
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

----------------------------------------------------------------------------- bases

local function construirPedestal(
	carpeta: Folder,
	cfBase: CFrame,
	indice: number,
	x: number,
	z: number,
	esBoveda: boolean
): PedestalMapa
	local modelo = Instance.new("Model")
	modelo.Name = `P{indice}`

	local alto = MEDIDAS.ALTO_PEDESTAL
	local diametro = MEDIDAS.DIAMETRO_PEDESTAL
	local pedestal = crearParte({
		nombre = "Pedestal",
		tamano = Vector3.new(alto, diametro, diametro),
		cframe = cfBase * CFrame.new(x, alto / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
		color = if esBoveda then Color3.fromRGB(235, 190, 70) else Color3.fromRGB(225, 225, 232),
		forma = Enum.PartType.Cylinder,
		padre = modelo,
	})

	local boton = crearParte({
		nombre = "BotonCobro",
		tamano = Vector3.new(2.6, 0.3, 1.8),
		cframe = cfBase * CFrame.new(x, 0.15, z - MEDIDAS.DISTANCIA_BOTON_COBRO),
		color = Color3.fromRGB(80, 220, 90),
		colisiona = false,
		padre = modelo,
	})

	modelo.PrimaryPart = pedestal
	modelo:SetAttribute("Indice", indice)
	modelo.Parent = carpeta

	return {
		indice = indice,
		modelo = modelo,
		pedestal = pedestal,
		boton = boton,
		ancla = cfBase * CFrame.new(x, alto, z),
	}
end

local function construirBase(carpetaBases: Folder, indice: number, centro: Vector3): BaseMapa
	-- La base mira hacia la avenida (Z = 0): su frente (-Z local) apunta a la avenida.
	local cf = CFrame.lookAt(centro, Vector3.new(centro.X, centro.Y, 0))
	local color = ConfigMapa.COLORES_BASE[indice] or Color3.fromRGB(230, 230, 230)
	local colorPared = oscurecer(color, 0.8)

	local modelo = Instance.new("Model")
	modelo.Name = `Base{indice}`
	modelo:SetAttribute("Indice", indice)
	modelo:SetAttribute("Dueno", 0)
	modelo:SetAttribute("DuenoNombre", "")
	modelo:SetAttribute("CerrojoHasta", 0)
	modelo:SetAttribute("EscudoHasta", 0)
	modelo:SetAttribute("EscudoTipo", "")
	modelo:SetAttribute("RevanchaHasta", 0)

	local ancho, fondo, altoPared = MEDIDAS.ANCHO, MEDIDAS.FONDO, MEDIDAS.ALTO_PARED

	local piso = crearParte({
		nombre = "Piso",
		tamano = Vector3.new(ancho, 1, fondo),
		cframe = cf * CFrame.new(0, -0.5, 0),
		color = color,
		padre = modelo,
	})
	modelo.PrimaryPart = piso

	local paredes = Instance.new("Folder")
	paredes.Name = "Paredes"
	paredes.Parent = modelo
	local function pared(nombre: string, tamano: Vector3, posicion: Vector3)
		crearParte({
			nombre = nombre,
			tamano = tamano,
			cframe = cf * CFrame.new(posicion),
			color = colorPared,
			transparencia = 0.35,
			padre = paredes,
		})
	end
	local mitadAncho, mitadFondo = ancho / 2, fondo / 2
	local puertaAncho = MEDIDAS.ANCHO_PUERTA
	local tramo = (ancho - puertaAncho) / 2
	pared("Fondo", Vector3.new(ancho, altoPared, 1), Vector3.new(0, altoPared / 2, mitadFondo - 0.5))
	pared("Izquierda", Vector3.new(1, altoPared, fondo), Vector3.new(-mitadAncho + 0.5, altoPared / 2, 0))
	pared("Derecha", Vector3.new(1, altoPared, fondo), Vector3.new(mitadAncho - 0.5, altoPared / 2, 0))
	pared(
		"FrenteIzquierda",
		Vector3.new(tramo, altoPared, 1),
		Vector3.new(-mitadAncho + tramo / 2, altoPared / 2, -mitadFondo + 0.5)
	)
	pared(
		"FrenteDerecha",
		Vector3.new(tramo, altoPared, 1),
		Vector3.new(mitadAncho - tramo / 2, altoPared / 2, -mitadFondo + 0.5)
	)

	-- Puerta: invisible y sin colisión por defecto. El cliente la muestra (campo de fuerza)
	-- y activa su colisión para los que no son dueños cuando el cerrojo está activo.
	local puerta = crearParte({
		nombre = "Puerta",
		tamano = Vector3.new(puertaAncho, altoPared, 0.6),
		cframe = cf * CFrame.new(0, altoPared / 2, -mitadFondo + 0.5),
		color = Color3.fromRGB(255, 70, 70),
		material = Enum.Material.ForceField,
		transparencia = 1,
		colisiona = false,
		padre = modelo,
	})

	-- Botón del cerrojo
	local posCerrojo = MEDIDAS.POSICION_CERROJO
	local cerrojo = crearParte({
		nombre = "BotonCerrojo",
		tamano = Vector3.new(1.8, 2.6, 1.8),
		cframe = cf * CFrame.new(posCerrojo.X, 1.3, posCerrojo.Z),
		color = Color3.fromRGB(230, 60, 60),
		padre = modelo,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptCerrojo"
	prompt.ActionText = "Cerrar base"
	prompt.ObjectText = "Cerrojo"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = cerrojo

	-- Macetero (en la esquina opuesta al cerrojo): se planta una semilla que crece en
	-- tiempo real. La planta la dibuja el cliente según los atributos del macetero.
	local posMacetero = MEDIDAS.POSICION_MACETERO
	local macetero = crearParte({
		nombre = "Macetero",
		tamano = Vector3.new(1.4, 3, 3),
		cframe = cf * CFrame.new(posMacetero.X, 0.7, posMacetero.Z) * CFrame.Angles(0, 0, math.rad(90)),
		color = Color3.fromRGB(170, 95, 55),
		forma = Enum.PartType.Cylinder,
		padre = modelo,
	})
	macetero:SetAttribute("Semilla", "")
	macetero:SetAttribute("ListaEn", 0)
	local promptMacetero = Instance.new("ProximityPrompt")
	promptMacetero.Name = "PromptMacetero"
	promptMacetero.ActionText = "Macetero"
	promptMacetero.ObjectText = "🌱"
	promptMacetero.HoldDuration = 0
	promptMacetero.MaxActivationDistance = 9
	promptMacetero.RequiresLineOfSight = false
	promptMacetero.Parent = macetero

	-- Letrero con el nombre del dueño, sobre la puerta
	local cartel = crearParte({
		nombre = "Letrero",
		tamano = Vector3.new(16, 3, 0.4),
		cframe = cf * CFrame.new(0, altoPared + 1.6, -mitadFondo + 0.5),
		color = Color3.fromRGB(40, 40, 48),
		padre = modelo,
	})
	local superficie = Instance.new("SurfaceGui")
	superficie.Face = Enum.NormalId.Front
	superficie.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	superficie.PixelsPerStud = 30
	superficie.LightInfluence = 0
	superficie.Parent = cartel
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(255, 255, 255)
	texto.Text = "Base libre"
	texto.Parent = superficie

	-- Pedestales (fila 1 = fondo, columnas de izquierda a derecha)
	local carpetaPedestales = Instance.new("Folder")
	carpetaPedestales.Name = "Pedestales"
	carpetaPedestales.Parent = modelo
	local pedestales: { PedestalMapa } = {}
	local indicePedestal = 0
	for _, z in MEDIDAS.FILAS do
		for _, x in MEDIDAS.COLUMNAS do
			indicePedestal += 1
			if indicePedestal > ConfigBase.PEDESTALES_TOTAL then
				break
			end
			local esBoveda = indicePedestal <= 1
			table.insert(pedestales, construirPedestal(carpetaPedestales, cf, indicePedestal, x, z, esBoveda))
		end
	end

	-- Con StreamingEnabled: el dueño siempre tiene su base cargada; los demás la reciben
	-- completa (nunca media base).
	modelo.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	modelo.Parent = carpetaBases

	local aparicionPos = cf * MEDIDAS.POSICION_APARICION
	return {
		indice = indice,
		modelo = modelo,
		cframe = cf,
		pedestales = pedestales,
		puerta = puerta,
		cerrojo = cerrojo,
		promptCerrojo = prompt,
		letrero = texto,
		macetero = macetero,
		aparicion = CFrame.lookAt(aparicionPos, aparicionPos + cf.LookVector * -1),
		salida = cf * CFrame.new(0, 3, -mitadFondo - 5),
	}
end

----------------------------------------------------------------------------- cintas

local function construirCinta(carpeta: Folder, id: string)
	local datos = ConfigMapa.CINTAS[id]
	local definicion = Catalogo.datos.cinta[id]
	if datos == nil or definicion == nil then
		return
	end
	local inicio, fin = datos.inicio, datos.fin
	local vector = fin - inicio
	local largo = vector.Magnitude
	local centro = (inicio + fin) / 2
	local alto = ConfigMapa.ALTURA_CINTA
	local cf = CFrame.lookAt(centro, fin) * CFrame.new(0, alto / 2, 0)

	local modelo = Instance.new("Model")
	modelo.Name = `Cinta_{id}`
	local banda = crearParte({
		nombre = "Banda",
		tamano = Vector3.new(datos.ancho, alto, largo),
		cframe = cf,
		color = definicion.color,
		padre = modelo,
	})
	banda:SetAttribute("Cinta", id)
	for _, lado in { -1, 1 } do
		crearParte({
			nombre = "Borde",
			tamano = Vector3.new(0.4, alto + 0.6, largo),
			cframe = cf * CFrame.new(lado * (datos.ancho / 2 + 0.2), 0.3, 0),
			color = Color3.fromRGB(240, 200, 40),
			colisiona = false, -- decorativo (así nadie se traba al cruzar)
			padre = modelo,
		})
	end

	-- Cartel al inicio con el nombre y el requisito
	local poste = crearParte({
		nombre = "Cartel",
		tamano = Vector3.new(1, 6, 1),
		cframe = CFrame.new(inicio + Vector3.new(-3, 3, 0) + Vector3.new(0, 0, datos.ancho)),
		color = Color3.fromRGB(60, 60, 60),
		padre = modelo,
	})
	local etiqueta = Instance.new("BillboardGui")
	etiqueta.Size = UDim2.fromOffset(220, 60)
	etiqueta.StudsOffset = Vector3.new(0, 4.5, 0)
	etiqueta.MaxDistance = 120
	etiqueta.LightInfluence = 0
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.TextScaled = true
	texto.TextColor3 = definicion.color:Lerp(Color3.new(1, 1, 1), 0.4)
	texto.TextStrokeTransparency = 0.2
	texto.Text = if definicion.requisitoRebirths > 0
		then `{definicion.nombre}\n🔒 Rebirth {definicion.requisitoRebirths}`
		else definicion.nombre
	texto.Parent = etiqueta
	etiqueta.Parent = poste

	modelo.Parent = carpeta

	MapaService.Cintas[id] = {
		id = id,
		inicio = inicio,
		fin = fin,
		direccion = vector.Unit,
		largo = largo,
		altura = alto,
	}
end

----------------------------------------------------------------------------- consultas

-- ¿Está la posición dentro de la base (entre sus paredes)?
function MapaService.DentroDeBase(base: BaseMapa, posicion: Vector3): boolean
	local local_ = base.cframe:PointToObjectSpace(posicion)
	return math.abs(local_.X) < MEDIDAS.ANCHO / 2
		and math.abs(local_.Z) < MEDIDAS.FONDO / 2
		and local_.Y > -3
		and local_.Y < MEDIDAS.ALTO_PARED + 6
end

-- Posición (en el mundo) de un Crunchi en la cinta, según el tiempo transcurrido.
function MapaService.PosicionEnCinta(cintaId: string, velocidad: number, segundos: number): Vector3?
	local cinta = MapaService.Cintas[cintaId]
	if cinta == nil then
		return nil
	end
	local distancia = math.clamp(velocidad * segundos, 0, cinta.largo)
	return cinta.inicio + cinta.direccion * distancia + Vector3.new(0, cinta.altura, 0)
end

----------------------------------------------------------------------------- inicio

function MapaService.Iniciar()
	local carpeta = Instance.new("Folder")
	carpeta.Name = "MapaGenerado"

	-- La plantilla "Baseplate" de Studio tiene su propio piso gris: lo ocultamos (solo
	-- mientras el juego corre; no cambia tu archivo) para que se vea el nuestro.
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
	end
	-- Desactivamos los SpawnLocation que haya y creamos uno propio en la avenida.
	for _, hijo in workspace:GetChildren() do
		if hijo:IsA("SpawnLocation") then
			hijo.Enabled = false
		end
	end

	crearParte({
		nombre = "Suelo",
		tamano = ConfigMapa.SUELO.TAMANO,
		cframe = CFrame.new(0, -0.5 + 0.01, 0),
		color = ConfigMapa.SUELO.COLOR,
		material = Enum.Material.Grass,
		padre = carpeta,
	})
	crearParte({
		nombre = "Avenida",
		tamano = ConfigMapa.AVENIDA.TAMANO,
		cframe = CFrame.new(0, ConfigMapa.AVENIDA.TAMANO.Y / 2 + 0.01, 0),
		color = ConfigMapa.AVENIDA.COLOR,
		padre = carpeta,
	})

	local aparicion = Instance.new("SpawnLocation")
	aparicion.Name = "AparicionCentral"
	aparicion.Anchored = true
	aparicion.Size = Vector3.new(6, 1, 6)
	aparicion.CFrame = CFrame.new(ConfigMapa.APARICION_CENTRAL - Vector3.new(0, 2.5, 0))
	aparicion.Transparency = 1
	aparicion.CanCollide = false
	aparicion.Duration = 0 -- sin campo de fuerza de reaparición
	aparicion.Neutral = true
	aparicion.Parent = carpeta

	local carpetaCintas = Instance.new("Folder")
	carpetaCintas.Name = "Cintas"
	carpetaCintas.Parent = carpeta
	for _, cinta in Catalogo.datos.cintas do
		construirCinta(carpetaCintas, cinta.id)
	end

	local carpetaBases = Instance.new("Folder")
	carpetaBases.Name = "Bases"
	carpetaBases.Parent = carpeta
	for indice, centro in ConfigMapa.BASES do
		table.insert(MapaService.Bases, construirBase(carpetaBases, indice, centro))
	end

	carpeta.Parent = workspace
	MapaService.Carpeta = carpeta
end

return MapaService
