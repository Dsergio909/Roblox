--!strict
--[[
	Interfaz/Ventana
	Ventanas (menús) centradas en la pantalla. Solo hay UNA abierta a la vez: abrir otra
	cierra la anterior. Se adaptan solas a celulares (verticales y horizontales).

	  local v = Ventana.nueva("Índice", 540, 330, Tema.COLORES.morado)
	  v.alAbrir = function() refrescar() end
	  v:Abrir()   v:Cerrar()   v:Alternar()
	  -- el contenido va dentro de v.contenido (Frame)

	Las ventanas NUNCA se abren solas durante el juego (salvo la bienvenida, una vez al
	entrar): se abren cuando el jugador toca un botón.
]]

local Interfaz = script.Parent
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))

local Ventana = {}
Ventana.__index = Ventana

export type Ventana = typeof(setmetatable(
	{} :: {
		marco: Frame,
		contenido: Frame,
		titulo: TextLabel,
		alAbrir: (() -> ())?,
		alCerrar: (() -> ())?,
	},
	Ventana
))

local pantalla: ScreenGui? = nil
local abierta: Ventana? = nil

local ALTO_ENCABEZADO = 46

local function obtenerPantalla(): ScreenGui
	if pantalla == nil then
		pantalla = UI.Pantalla("Ventanas", 30)
	end
	return pantalla :: ScreenGui
end

function Ventana.nueva(titulo: string, ancho: number, alto: number, color: Color3?): Ventana
	local acento = color or Tema.COLORES.azul
	local marco = UI.Panel({
		Name = `Ventana_{titulo}`,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 10),
		Size = UDim2.fromOffset(ancho, alto),
		BackgroundTransparency = 0.04,
		Visible = false,
		Active = true, -- los toques no atraviesan la ventana
		Parent = obtenerPantalla(),
	})
	UI.Escalar(marco, ancho, alto)
	UI.Borde(marco, acento, 3)

	local encabezado = UI.Crear("Frame", {
		Name = "Encabezado",
		BackgroundColor3 = acento,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, 0, 0, ALTO_ENCABEZADO),
		Parent = marco,
	})
	UI.Esquinas(encabezado)
	local textoTitulo = UI.Texto({
		texto = titulo,
		tamano = UDim2.new(1, -70, 1, 0),
		posicion = UDim2.fromOffset(14, 0),
		tamanoLetra = 26,
		alineacion = Enum.TextXAlignment.Left,
		padre = encabezado,
	})

	local contenido = UI.Crear("Frame", {
		Name = "Contenido",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, ALTO_ENCABEZADO + 8),
		Size = UDim2.new(1, -20, 1, -(ALTO_ENCABEZADO + 16)),
		Parent = marco,
	}) :: Frame

	local self = setmetatable({
		marco = marco,
		contenido = contenido,
		titulo = textoTitulo,
		alAbrir = nil,
		alCerrar = nil,
	}, Ventana)

	UI.Boton({
		texto = "✕",
		color = Tema.COLORES.rojo,
		tamano = UDim2.fromOffset(48, 40),
		posicion = UDim2.new(1, -6, 0, 3),
		ancla = Vector2.new(1, 0),
		tamanoLetra = 22,
		alPulsar = function()
			self:Cerrar()
		end,
		padre = encabezado,
	})
	return self
end

function Ventana.Abrir(self: Ventana)
	if abierta and abierta ~= self then
		abierta:Cerrar()
	end
	abierta = self
	if self.alAbrir then
		self.alAbrir()
	end
	self.marco.Visible = true
end

function Ventana.Cerrar(self: Ventana)
	if not self.marco.Visible then
		return
	end
	self.marco.Visible = false
	if abierta == self then
		abierta = nil
	end
	if self.alCerrar then
		self.alCerrar()
	end
end

function Ventana.Alternar(self: Ventana)
	if self.marco.Visible then
		self:Cerrar()
	else
		self:Abrir()
	end
end

function Ventana.EstaAbierta(self: Ventana): boolean
	return self.marco.Visible
end

-- ¿Hay alguna ventana abierta? (para no mostrar ofertas encima de un menú, Fase 3)
function Ventana.HayAbierta(): boolean
	return abierta ~= nil
end

return Ventana
