--!strict
--[[
	Interfaz/UI
	Funciones para construir la interfaz desde código, de forma corta y consistente.

	  local boton = UI.Boton({ texto = "Tienda", color = Tema.COLORES.verde, alPulsar = fn })
	  local pantalla = UI.Pantalla("HUD", 1)

	Todas las pantallas respetan el notch y las esquinas del celular
	(ScreenInsets = DeviceSafeInsets) y no se reinician al morir (ResetOnSpawn = false).

	Escala: cada elemento principal (panel, columna de botones, ventana) lleva su propio
	UIScale con UI.Escalar(). Así crece o se achica DESDE SU PUNTO DE ANCLAJE (un panel
	centrado sigue centrado) y, si se le indica su tamaño base, nunca se sale de la pantalla.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Tema = require(script.Parent:WaitForChild("Tema"))

local UI = {}

type Escalado = { uiScale: UIScale, ancho: number?, alto: number? }
local escalas: { Escalado } = {}

-- Espacio que ocupan la barra superior de Roblox y los márgenes (aprox.).
local MARGEN_ALTO = 70
local MARGEN_ANCHO = 16

local function tamanoPantalla(): Vector2
	local camara = workspace.CurrentCamera
	return if camara then camara.ViewportSize else Vector2.new(800, Tema.ALTO_REFERENCIA)
end

local function calcularEscala(): number
	local pantalla = tamanoPantalla()
	return math.clamp(pantalla.Y / Tema.ALTO_REFERENCIA, Tema.ESCALA_MIN, Tema.ESCALA_MAX)
end

local function escalaPara(escalado: Escalado): number
	local escala = calcularEscala()
	local pantalla = tamanoPantalla()
	if escalado.ancho then
		escala = math.min(escala, (pantalla.X - MARGEN_ANCHO) / escalado.ancho)
	end
	if escalado.alto then
		escala = math.min(escala, (pantalla.Y - MARGEN_ALTO) / escalado.alto)
	end
	return math.max(0.3, escala)
end

local function actualizarEscalas()
	for _, escalado in escalas do
		escalado.uiScale.Scale = escalaPara(escalado)
	end
end

-- Llamar una vez al iniciar: mantiene la escala al girar el celular o cambiar la ventana.
function UI.Iniciar()
	local function conectarCamara()
		local camara = workspace.CurrentCamera
		if camara then
			camara:GetPropertyChangedSignal("ViewportSize"):Connect(actualizarEscalas)
		end
		actualizarEscalas()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(conectarCamara)
	conectarCamara()
end

function UI.Escala(): number
	return calcularEscala()
end

-- Crea una instancia con propiedades e hijos: UI.Crear("Frame", { Size = ... }, { hijo1, hijo2 })
function UI.Crear(clase: string, propiedades: { [string]: any }?, hijos: { Instance }?): any
	local instancia = Instance.new(clase) :: any
	local padre = nil
	local props: { [string]: any } = propiedades or {}
	for propiedad, valor in props do
		if propiedad == "Parent" then
			padre = valor
		else
			instancia[propiedad] = valor
		end
	end
	local listaHijos: { Instance } = hijos or {}
	for _, hijo in listaHijos do
		hijo.Parent = instancia
	end
	if padre then
		instancia.Parent = padre
	end
	return instancia
end

-- ScreenGui para celular. `orden` decide qué pantalla queda encima.
function UI.Pantalla(nombre: string, orden: number?): ScreenGui
	local pantalla = UI.Crear("ScreenGui", {
		Name = nombre,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = orden or 0,
	}) :: ScreenGui
	local jugador = Players.LocalPlayer
	pantalla.Parent = jugador:WaitForChild("PlayerGui")
	return pantalla
end

--[[
	Hace que un elemento se escale con la pantalla. Si se pasan `ancho`/`alto` (su tamaño
	sin escalar), además se achica lo necesario para caber siempre en la pantalla
	(p. ej. una ventana en un celular vertical).
]]
function UI.Escalar(objeto: GuiObject, ancho: number?, alto: number?): UIScale
	local uiScale = UI.Crear("UIScale", { Name = "Escala", Parent = objeto }) :: UIScale
	local escalado: Escalado = { uiScale = uiScale, ancho = ancho, alto = alto }
	uiScale.Scale = escalaPara(escalado)
	table.insert(escalas, escalado)
	uiScale.Destroying:Connect(function()
		local indice = table.find(escalas, escalado)
		if indice then
			table.remove(escalas, indice)
		end
	end)
	return uiScale
end

function UI.Esquinas(padre: Instance, radio: UDim?): UICorner
	return UI.Crear("UICorner", { CornerRadius = radio or Tema.RADIO, Parent = padre })
end

function UI.Borde(padre: Instance, color: Color3?, grosor: number?): UIStroke
	return UI.Crear("UIStroke", {
		Color = color or Tema.COLORES.borde,
		Thickness = grosor or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = padre,
	})
end

function UI.Margen(padre: Instance, pixeles: number)
	UI.Crear("UIPadding", {
		PaddingLeft = UDim.new(0, pixeles),
		PaddingRight = UDim.new(0, pixeles),
		PaddingTop = UDim.new(0, pixeles),
		PaddingBottom = UDim.new(0, pixeles),
		Parent = padre,
	})
end

export type OpcionesTexto = {
	texto: string,
	tamano: UDim2?,
	posicion: UDim2?,
	ancla: Vector2?,
	color: Color3?,
	tamanoLetra: number?,
	alineacion: Enum.TextXAlignment?,
	contorno: boolean?,
	padre: Instance?,
}

-- Texto con contorno (legible sobre cualquier fondo).
function UI.Texto(opciones: OpcionesTexto): TextLabel
	local label = UI.Crear("TextLabel", {
		BackgroundTransparency = 1,
		Size = opciones.tamano or UDim2.new(1, 0, 0, 24),
		Position = opciones.posicion or UDim2.new(),
		AnchorPoint = opciones.ancla or Vector2.zero,
		Font = Tema.FUENTE,
		Text = opciones.texto,
		TextColor3 = opciones.color or Tema.COLORES.texto,
		TextSize = opciones.tamanoLetra or 20,
		TextXAlignment = opciones.alineacion or Enum.TextXAlignment.Center,
		TextWrapped = true,
		Parent = opciones.padre,
	}) :: TextLabel
	if opciones.contorno ~= false then
		UI.Crear("UIStroke", {
			Color = Tema.COLORES.borde,
			Thickness = 1.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Parent = label,
		})
	end
	return label
end

export type OpcionesBoton = {
	texto: string,
	color: Color3?,
	tamano: UDim2?,
	posicion: UDim2?,
	ancla: Vector2?,
	tamanoLetra: number?,
	alPulsar: (() -> ())?,
	padre: Instance?,
}

-- Botón grande, redondeado, con efecto al pulsarlo. Funciona igual con dedo, mouse y control.
function UI.Boton(opciones: OpcionesBoton): TextButton
	local color = opciones.color or Tema.COLORES.azul
	local boton = UI.Crear("TextButton", {
		Size = opciones.tamano or UDim2.fromOffset(140, Tema.BOTON_MIN),
		Position = opciones.posicion or UDim2.new(),
		AnchorPoint = opciones.ancla or Vector2.zero,
		BackgroundColor3 = color,
		AutoButtonColor = true,
		Font = Tema.FUENTE,
		Text = opciones.texto,
		TextColor3 = Tema.COLORES.texto,
		TextSize = opciones.tamanoLetra or 20,
		TextWrapped = true,
		Parent = opciones.padre,
	}) :: TextButton
	UI.Esquinas(boton)
	UI.Borde(boton, Color3.new(color.R * 0.55, color.G * 0.55, color.B * 0.55), 3)
	UI.Crear("UIStroke", {
		Color = Tema.COLORES.borde,
		Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = boton,
	})
	-- Tamaño mínimo táctil
	UI.Crear("UISizeConstraint", { MinSize = Vector2.new(Tema.BOTON_MIN, Tema.BOTON_MIN), Parent = boton })

	local escala = UI.Crear("UIScale", { Parent = boton }) :: UIScale
	boton.MouseButton1Down:Connect(function()
		TweenService:Create(escala, TweenInfo.new(0.06), { Scale = 0.92 }):Play()
	end)
	local function soltar()
		TweenService:Create(escala, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	boton.MouseButton1Up:Connect(soltar)
	boton.MouseLeave:Connect(soltar)
	if opciones.alPulsar then
		local fn = opciones.alPulsar
		boton.Activated:Connect(function()
			fn()
		end)
	end
	return boton
end

-- Panel oscuro redondeado (base de ventanas y píldoras del HUD).
function UI.Panel(propiedades: { [string]: any }): Frame
	local props = table.clone(propiedades)
	props.BackgroundColor3 = props.BackgroundColor3 or Tema.COLORES.fondo
	props.BackgroundTransparency = props.BackgroundTransparency or Tema.TRANSPARENCIA_FONDO
	props.BorderSizePixel = 0
	local panel = UI.Crear("Frame", props) :: Frame
	UI.Esquinas(panel)
	return panel
end

-- Lista con scroll vertical que crece según su contenido.
function UI.Lista(propiedades: { [string]: any }, separacion: number?): ScrollingFrame
	local props = table.clone(propiedades)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.BorderSizePixel = 0
	props.ScrollBarThickness = props.ScrollBarThickness or 6
	props.CanvasSize = UDim2.new()
	props.AutomaticCanvasSize = Enum.AutomaticSize.Y
	props.ScrollingDirection = Enum.ScrollingDirection.Y
	local lista = UI.Crear("ScrollingFrame", props) :: ScrollingFrame
	UI.Crear("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, separacion or 6),
		Parent = lista,
	})
	return lista
end

-- Borra los hijos de una lista (menos el layout y el padding).
function UI.Vaciar(contenedor: Instance)
	for _, hijo in contenedor:GetChildren() do
		if not (hijo:IsA("UIListLayout") or hijo:IsA("UIGridLayout") or hijo:IsA("UIPadding")) then
			hijo:Destroy()
		end
	end
end

-- Barra de progreso. Devuelve el marco y una función para cambiar el progreso (0 a 1).
function UI.Barra(padre: Instance, tamano: UDim2, color: Color3, posicion: UDim2?): (Frame, (number) -> ())
	local fondo = UI.Crear("Frame", {
		Name = "Barra",
		Size = tamano,
		Position = posicion or UDim2.new(),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		BorderSizePixel = 0,
		Parent = padre,
	}) :: Frame
	UI.Esquinas(fondo, UDim.new(1, 0))
	local relleno = UI.Crear("Frame", {
		Name = "Relleno",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = fondo,
	}) :: Frame
	UI.Esquinas(relleno, UDim.new(1, 0))
	local function fijar(progreso: number)
		relleno.Size = UDim2.fromScale(math.clamp(progreso, 0, 1), 1)
	end
	return fondo, fijar
end

-- Pequeña animación de "rebote" (al ganar dinero, al aparecer algo...).
function UI.Rebote(objeto: GuiObject, fuerza: number?)
	local escala = objeto:FindFirstChild("Rebote") :: UIScale?
	if escala == nil then
		local nueva = Instance.new("UIScale")
		nueva.Name = "Rebote"
		nueva.Parent = objeto
		escala = nueva
	end
	local s = escala :: UIScale
	s.Scale = 1 + (fuerza or 0.12)
	TweenService:Create(s, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

return UI
