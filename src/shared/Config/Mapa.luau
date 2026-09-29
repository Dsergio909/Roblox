--!strict
--[[
	Config/Mapa
	Posiciones y medidas del mapa PLACEHOLDER que se genera con partes de colores.

	Si en Studio creas una carpeta "Mapa" en Workspace con tu propio mapa, el juego NO
	generará este (ver docs/ASSETS_PENDIENTES.md para saber qué piezas debe tener).

	Sistema de coordenadas: la avenida va a lo largo del eje X. Las bases 1–4 están al norte
	(Z positivo) y las 5–8 al sur (Z negativo). Cada base mira hacia la avenida.
]]

local Mapa = {
	NOMBRE_CARPETA = "Mapa",

	AVENIDA = {
		TAMANO = Vector3.new(320, 0.05, 60), -- muy delgada: es "pintura" sobre el suelo
		COLOR = Color3.fromRGB(95, 95, 105),
	},
	SUELO = {
		TAMANO = Vector3.new(400, 1, 220),
		COLOR = Color3.fromRGB(110, 190, 90),
	},

	-- Cintas: de dónde a dónde van (a la altura del suelo; los Crunchis van encima).
	CINTAS = {
		principal = { inicio = Vector3.new(-140, 0, 0), fin = Vector3.new(140, 0, 0), ancho = 5 },
		dorada = { inicio = Vector3.new(-140, 0, 11), fin = Vector3.new(140, 0, 11), ancho = 4 },
		celestial = { inicio = Vector3.new(-140, 0, -11), fin = Vector3.new(140, 0, -11), ancho = 4 },
	} :: { [string]: { inicio: Vector3, fin: Vector3, ancho: number } },
	ALTURA_CINTA = 0.8, -- grosor visible de la cinta sobre el suelo

	-- Centro de cada base (a nivel del piso de la base). La base mira hacia Z = 0.
	BASES = {
		Vector3.new(-99, 0.4, 56),
		Vector3.new(-33, 0.4, 56),
		Vector3.new(33, 0.4, 56),
		Vector3.new(99, 0.4, 56),
		Vector3.new(-99, 0.4, -56),
		Vector3.new(-33, 0.4, -56),
		Vector3.new(33, 0.4, -56),
		Vector3.new(99, 0.4, -56),
	},
	COLORES_BASE = {
		Color3.fromRGB(255, 214, 165),
		Color3.fromRGB(190, 225, 255),
		Color3.fromRGB(255, 190, 210),
		Color3.fromRGB(205, 245, 190),
		Color3.fromRGB(230, 205, 255),
		Color3.fromRGB(255, 240, 170),
		Color3.fromRGB(180, 240, 235),
		Color3.fromRGB(255, 205, 180),
	},

	-- Medidas de una base (en coordenadas locales: -Z es el frente, donde está la puerta).
	BASE = {
		ANCHO = 48,
		FONDO = 44,
		ALTO_PARED = 8,
		ANCHO_PUERTA = 12,
		-- Columnas (X) y filas (Z) de la cuadrícula de pedestales. Fila 1 = fondo.
		COLUMNAS = { -16, -8, 0, 8, 16 },
		FILAS = { 15, 7, -1, -9 },
		DIAMETRO_PEDESTAL = 4,
		ALTO_PEDESTAL = 1.2,
		DISTANCIA_BOTON_COBRO = 3.6, -- qué tan adelante del pedestal está su botón de cobro
		POSICION_CERROJO = Vector3.new(-19, 0, -17),
		POSICION_MACETERO = Vector3.new(19, 0, -17),
		POSICION_APARICION = Vector3.new(0, 3, -16),
	},

	-- Donde aparecen los jugadores antes de tener base asignada.
	APARICION_CENTRAL = Vector3.new(0, 3, 22),
}

return table.freeze(Mapa)
