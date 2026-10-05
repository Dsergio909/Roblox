--!strict
--[[
	Interfaz/Tema
	Colores, tipografía y medidas de toda la interfaz. Cambiar aquí cambia todo el juego.

	Medidas pensadas para CELULAR primero: la interfaz se diseña para una pantalla de
	referencia de 420 píxeles de alto (un celular en horizontal) y se escala sola con
	UIScale en pantallas más grandes (ver Interfaz/UI).
]]

local Tema = {
	ALTO_REFERENCIA = 420, -- alto de pantalla para el que se diseñó la interfaz
	ESCALA_MIN = 0.85,
	ESCALA_MAX = 1.6,

	FUENTE = Enum.Font.FredokaOne,

	-- Tamaño mínimo de un botón táctil (≈ 44–48 pt recomendados para dedos).
	BOTON_MIN = 48,

	COLORES = {
		fondo = Color3.fromRGB(22, 24, 34),
		fondoClaro = Color3.fromRGB(40, 44, 60),
		texto = Color3.fromRGB(255, 255, 255),
		textoSuave = Color3.fromRGB(190, 196, 215),
		dinero = Color3.fromRGB(255, 221, 87),
		verde = Color3.fromRGB(110, 225, 90),
		rojo = Color3.fromRGB(255, 72, 72),
		azul = Color3.fromRGB(70, 160, 255),
		morado = Color3.fromRGB(166, 77, 255),
		naranja = Color3.fromRGB(255, 150, 40),
		borde = Color3.fromRGB(0, 0, 0),
	},

	TRANSPARENCIA_FONDO = 0.2,
	RADIO = UDim.new(0, 12),
}

-- Color de cada tipo de notificación.
Tema.COLOR_NOTIFICACION = {
	info = Tema.COLORES.azul,
	exito = Tema.COLORES.verde,
	error = Tema.COLORES.rojo,
	alerta = Tema.COLORES.naranja,
	sinDinero = Tema.COLORES.rojo,
} :: { [string]: Color3 }

return Tema
