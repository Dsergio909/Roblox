--!strict
--[[
	Interfaz/UI
	Funciones para construir la interfaz desde código, de forma corta y consistente.

	  local boton = UI.Boton({ texto = "Tienda", color = Tema.COLORES.verde, alPulsar = fn })
	  local pantalla = UI.Pantalla("HUD", 1)

	Todas las pantallas:
	  - respetan el notch y las esquinas del celular (ScreenInsets = DeviceSafeInsets),
	  - se escalan solas según el tamaño de la pantalla (UIScale),
	  - no se reinician al morir (ResetOnSpawn = false).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Tema = require(script.Parent:WaitForChild("Tema"))

local UI = {}

local escalas: { UIScale } = {}

local function calcularEscala(): number
	local camara = workspace.CurrentCamera
	local alto = if camara then camara.ViewportSize.Y else Tema.ALTO_REFERENCIA
	return math.clamp(alto / Tema.ALTO_REFERENCIA, Tema.ESCALA_MIN, Tema.ESCALA_MAX)
end

local function actualizarEscalas()
	local escala = calcularEscala()
	for _, uiScale in escalas do
		uiScale.Scale = escala
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

-- ScreenGui con escala automática. `orden` decide qué pantalla queda encima.
function UI.Pantalla(nombre: string, orden: number?): ScreenGui
	local pantalla = UI.Crear("ScreenGui", {
		Name = nombre,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = orden or 0,
	}) :: ScreenGui
	local uiScale = UI.Crear("UIScale", { Scale = calcularEscala(), Parent = pantalla }) :: UIScale
	table.insert(escalas, uiScale)
	local jugador = Players.LocalPlayer
	pantalla.Parent = jugador:WaitForChild("PlayerGui")
	return pantalla
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
