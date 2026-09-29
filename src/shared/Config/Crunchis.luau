--!strict
--[[
	Config/Crunchis
	El catálogo de Crunchis. AGREGAR UN CRUNCHI NUEVO = agregar una entrada a esta lista.

	Campos obligatorios:
	  id           identificador interno único, en minúsculas y sin espacios.
	               ⚠️ No lo cambies una vez publicado: se guarda en los datos de los jugadores.
	  nombre       nombre visible
	  rareza       id de Config/Rarezas ("comun", "pococomun", "raro", "epico", "legendario", "mitico", "secreto")
	  ingreso      dinero por segundo (antes de mutaciones y bonus)
	  precio       precio en la cinta (antes de mutaciones)
	  set          id de Config/Sets (colección a la que pertenece)
	  descripcion  frase corta y graciosa para el Índice

	Campos opcionales (solo afectan al modelo PLACEHOLDER, hecho con partes simples):
	  escala       tamaño (si no se pone, usa la escala de su rareza)
	  ojos         "normal" | "bizcos" | "grandes" | "enojados" | "espiral"
	  boca         "sonrisa" | "torcida" | "o" | "dientes" | "abierta"
	  piezas       accesorio hecho con partes: forma, tamaño, posición, rotación (grados), color...
	               La posición es relativa al centro del cuerpo, con el cuerpo midiendo 3 studs.
	               El frente de la cara es -Z; la espalda es +Z; arriba es +Y.

	Cuando tengas el modelo 3D real, ponlo en ReplicatedStorage > Modelos > Crunchis con el
	mismo nombre que el id, y el juego lo usará automáticamente en lugar del placeholder.
]]

export type Pieza = {
	forma: string, -- "Block" | "Ball" | "Cylinder" | "Wedge"
	tamano: Vector3,
	posicion: Vector3,
	rotacion: Vector3?,
	color: Color3,
	material: string?,
	transparencia: number?,
}

export type Crunchi = {
	id: string,
	nombre: string,
	rareza: string,
	ingreso: number,
	precio: number,
	set: string,
	descripcion: string,
	escala: number?,
	ojos: string?,
	boca: string?,
	piezas: { Pieza }?,
}

-- Rotación que pone un cilindro "de pie" (en Roblox el eje del cilindro es X).
local DE_PIE = Vector3.new(0, 0, 90)

-- Ayuda a Luau a entender que cada tabla es una Pieza (con campos opcionales).
local function P(pieza: Pieza): Pieza
	return pieza
end

local MARRON = Color3.fromRGB(125, 82, 45)
local NEGRO = Color3.fromRGB(30, 30, 30)
local ORO = Color3.fromRGB(255, 200, 40)

local Crunchis: { Crunchi } = {
	---------------------------------------------------------------- COMUNES
	{
		id = "crunchito_bobo",
		nombre = "Crunchito Bobo",
		rareza = "comun",
		ingreso = 1,
		precio = 20,
		set = "caras_locas",
		descripcion = "No sabe dónde está. Tampoco le importa.",
		ojos = "bizcos",
		boca = "torcida",
	},
	{
		id = "mochilin",
		nombre = "Mochilín",
		rareza = "comun",
		ingreso = 2,
		precio = 45,
		set = "aventureros",
		descripcion = "Lleva una mochila vacía por si encuentra algo.",
		piezas = {
			P({
				forma = "Block",
				tamano = Vector3.new(1.6, 1.8, 0.8),
				posicion = Vector3.new(0, 0, 1.55),
				color = Color3.fromRGB(140, 90, 50),
			}),
		},
	},
	{
		id = "pepito_pepita",
		nombre = "Pepito Pepita",
		rareza = "comun",
		ingreso = 3,
		precio = 75,
		set = "huerto",
		descripcion = "Sus pecas son semillas. Está muy orgulloso.",
		piezas = {
			P({
				forma = "Ball",
				tamano = Vector3.new(0.28, 0.28, 0.28),
				posicion = Vector3.new(-0.75, -0.1, -1.28),
				color = MARRON,
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.28, 0.28, 0.28),
				posicion = Vector3.new(0.75, -0.1, -1.28),
				color = MARRON,
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.24, 0.24, 0.24),
				posicion = Vector3.new(0.3, 0.95, -1.15),
				color = MARRON,
			}),
		},
	},

	---------------------------------------------------------------- POCO COMUNES
	{
		id = "manzana_sudada",
		nombre = "Manzana Sudada",
		rareza = "pococomun",
		ingreso = 8,
		precio = 300,
		set = "caras_locas",
		descripcion = "Siempre cree que la van a robar. Tiene razón.",
		ojos = "grandes",
		boca = "o",
		piezas = {
			P({
				forma = "Ball",
				tamano = Vector3.new(0.45, 0.6, 0.45),
				posicion = Vector3.new(1.1, 0.9, -0.8),
				color = Color3.fromRGB(120, 200, 255),
				transparencia = 0.2,
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.4, 0.55, 0.4),
				posicion = Vector3.new(-1.2, 0.6, -0.7),
				color = Color3.fromRGB(120, 200, 255),
				transparencia = 0.2,
			}),
		},
	},
	{
		id = "don_gusano",
		nombre = "Don Gusano",
		rareza = "pococomun",
		ingreso = 12,
		precio = 480,
		set = "huerto",
		descripcion = "El gusano se mudó y ahora es su bigote.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(2, 0.35, 0.35),
				posicion = Vector3.new(0, -0.15, -1.45),
				color = Color3.fromRGB(255, 140, 170),
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.45, 0.45, 0.45),
				posicion = Vector3.new(1.05, -0.15, -1.35),
				color = Color3.fromRGB(255, 140, 170),
			}),
		},
	},
	{
		id = "taladrin",
		nombre = "Taladrín",
		rareza = "pococomun",
		ingreso = 18,
		precio = 750,
		set = "obreros",
		descripcion = "Hace agujeros. Nadie le pidió agujeros.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(1.4, 0.9, 0.9),
				posicion = Vector3.new(0, 2.1, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(150, 150, 160),
				material = "Metal",
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.5, 0.5, 0.5),
				posicion = Vector3.new(0, 2.85, 0),
				color = Color3.fromRGB(90, 90, 100),
				material = "Metal",
			}),
		},
	},

	---------------------------------------------------------------- RAROS
	{
		id = "casco_crunch",
		nombre = "Casco Crunch",
		rareza = "raro",
		ingreso = 45,
		precio = 3500,
		set = "obreros",
		descripcion = "Seguridad ante todo. Excepto cuando corre.",
		piezas = {
			P({
				forma = "Ball",
				tamano = Vector3.new(3.1, 1.6, 3.1),
				posicion = Vector3.new(0, 1.15, 0),
				color = Color3.fromRGB(255, 140, 0),
			}),
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.2, 3.6, 3.6),
				posicion = Vector3.new(0, 0.95, -0.2),
				rotacion = DE_PIE,
				color = Color3.fromRGB(255, 140, 0),
			}),
		},
	},
	{
		id = "explorador_pip",
		nombre = "Explorador Pip",
		rareza = "raro",
		ingreso = 70,
		precio = 5600,
		set = "aventureros",
		descripcion = "Ha explorado toda la cinta. Dos veces.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(1, 2.6, 2.6),
				posicion = Vector3.new(0, 1.55, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(255, 210, 60),
			}),
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.15, 3.6, 3.6),
				posicion = Vector3.new(0, 1.1, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(255, 210, 60),
			}),
		},
	},
	{
		id = "sonrisota",
		nombre = "Sonrisota",
		rareza = "raro",
		ingreso = 100,
		precio = 8000,
		set = "caras_locas",
		descripcion = "Tiene 40 dientes y los muestra todos.",
		ojos = "grandes",
		boca = "dientes",
		piezas = {
			P({
				forma = "Ball",
				tamano = Vector3.new(0.55, 0.4, 0.3),
				posicion = Vector3.new(-0.95, -0.2, -1.1),
				color = Color3.fromRGB(255, 130, 150),
				transparencia = 0.3,
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.55, 0.4, 0.3),
				posicion = Vector3.new(0.95, -0.2, -1.1),
				color = Color3.fromRGB(255, 130, 150),
				transparencia = 0.3,
			}),
		},
	},

	---------------------------------------------------------------- ÉPICOS
	{
		id = "catapultin",
		nombre = "Catapultín",
		rareza = "epico",
		ingreso = 250,
		precio = 37500,
		set = "obreros",
		descripcion = "Se lanza solo. Aterriza mal.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.3, 1.2, 1.2),
				posicion = Vector3.new(-1.6, -1, 0),
				color = MARRON,
			}),
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.3, 1.2, 1.2),
				posicion = Vector3.new(1.6, -1, 0),
				color = MARRON,
			}),
			P({
				forma = "Block",
				tamano = Vector3.new(0.4, 0.4, 3.2),
				posicion = Vector3.new(0, 0.6, 1.9),
				rotacion = Vector3.new(35, 0, 0),
				color = MARRON,
			}),
		},
	},
	{
		id = "globo_crunch",
		nombre = "Globo Crunch",
		rareza = "epico",
		ingreso = 400,
		precio = 60000,
		set = "aventureros",
		descripcion = "Quería volar. Ahora no sabe bajar.",
		piezas = {
			P({
				forma = "Ball",
				tamano = Vector3.new(3.2, 3.8, 3.2),
				posicion = Vector3.new(0, 4.6, 0),
				color = Color3.fromRGB(230, 60, 60),
			}),
			P({
				forma = "Cylinder",
				tamano = Vector3.new(1.6, 0.08, 0.08),
				posicion = Vector3.new(0, 2.35, 0),
				rotacion = DE_PIE,
				color = MARRON,
			}),
		},
	},
	{
		id = "chispitas",
		nombre = "Chispitas",
		rareza = "epico",
		ingreso = 600,
		precio = 90000,
		set = "explosivos",
		descripcion = "Su rabito es una mecha. Nadie se le acerca.",
		boca = "abierta",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(1, 0.2, 0.2),
				posicion = Vector3.new(0, 2, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(60, 50, 40),
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.6, 0.6, 0.6),
				posicion = Vector3.new(0, 2.6, 0),
				color = Color3.fromRGB(255, 150, 30),
				material = "Neon",
			}),
		},
	},

	---------------------------------------------------------------- LEGENDARIOS
	{
		id = "manzana_cohete",
		nombre = "Manzana Cohete",
		rareza = "legendario",
		ingreso = 1500,
		precio = 450000,
		set = "explosivos",
		descripcion = "Va a la luna. Por ahora, va a tu base.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(2.6, 1.2, 1.2),
				posicion = Vector3.new(0, 0.2, 1.7),
				rotacion = DE_PIE,
				color = Color3.fromRGB(220, 220, 230),
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(1.2, 1.2, 1.2),
				posicion = Vector3.new(0, 1.5, 1.7),
				color = Color3.fromRGB(230, 50, 50),
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.9, 1.4, 0.9),
				posicion = Vector3.new(0, -1.3, 1.7),
				color = Color3.fromRGB(255, 140, 30),
				material = "Neon",
			}),
		},
	},
	{
		id = "rey_semilla",
		nombre = "Rey Semilla",
		rareza = "legendario",
		ingreso = 2500,
		precio = 750000,
		set = "huerto",
		descripcion = "Gobierna el huerto. El huerto no lo sabe.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.7, 1.8, 1.8),
				posicion = Vector3.new(0, 1.65, 0),
				rotacion = DE_PIE,
				color = ORO,
				material = "Metal",
			}),
			P({
				forma = "Block",
				tamano = Vector3.new(2.6, 2.4, 0.2),
				posicion = Vector3.new(0, -0.1, 1.45),
				color = Color3.fromRGB(180, 30, 40),
			}),
		},
	},
	{
		id = "giganton",
		nombre = "Gigantón",
		rareza = "legendario",
		ingreso = 4000,
		precio = 1200000,
		set = "caras_locas",
		descripcion = "Nadie sabe cómo creció tanto. Él tampoco.",
		escala = 2,
		ojos = "grandes",
		boca = "abierta",
	},

	---------------------------------------------------------------- MÍTICOS
	{
		id = "ojos_laser",
		nombre = "Ojos Láser",
		rareza = "mitico",
		ingreso = 10000,
		precio = 6000000,
		set = "explosivos",
		descripcion = "Mira fijo a los ladrones. Literalmente los quema con la mirada.",
		ojos = "enojados",
		piezas = {
			P({
				forma = "Block",
				tamano = Vector3.new(2.4, 0.45, 0.25),
				posicion = Vector3.new(0, 0.35, -1.55),
				color = Color3.fromRGB(255, 40, 40),
				material = "Neon",
			}),
		},
	},
	{
		id = "mecha_crunch",
		nombre = "Mecha-Crunch",
		rareza = "mitico",
		ingreso = 16000,
		precio = 9600000,
		set = "obreros",
		descripcion = "Mitad manzana, mitad robot, 100 % crujiente.",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.8, 2.8, 2.8),
				posicion = Vector3.new(0, -0.9, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(120, 125, 135),
				material = "Metal",
			}),
			P({
				forma = "Cylinder",
				tamano = Vector3.new(1.2, 0.12, 0.12),
				posicion = Vector3.new(0.6, 2.1, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(120, 125, 135),
			}),
			P({
				forma = "Ball",
				tamano = Vector3.new(0.3, 0.3, 0.3),
				posicion = Vector3.new(0.6, 2.75, 0),
				color = Color3.fromRGB(255, 40, 40),
				material = "Neon",
			}),
		},
	},
	{
		id = "ninja_verde",
		nombre = "Ninja Verde",
		rareza = "mitico",
		ingreso = 25000,
		precio = 15000000,
		set = "aventureros",
		descripcion = "Nunca lo ves venir. Bueno, es verde y redondo: sí lo ves.",
		ojos = "enojados",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.5, 2.5, 2.5),
				posicion = Vector3.new(0, 1, 0),
				rotacion = DE_PIE,
				color = NEGRO,
			}),
			P({
				forma = "Block",
				tamano = Vector3.new(0.3, 0.25, 1.2),
				posicion = Vector3.new(0.3, 1, 1.6),
				rotacion = Vector3.new(0, 20, 0),
				color = NEGRO,
			}),
		},
	},

	---------------------------------------------------------------- SECRETOS
	{
		id = "manzana_nuclear",
		nombre = "Manzana Nuclear",
		rareza = "secreto",
		ingreso = 75000,
		precio = 90000000,
		set = "explosivos",
		descripcion = "Brilla en la oscuridad. Y en la luz. Y siempre.",
		ojos = "grandes",
		boca = "dientes",
		piezas = {
			P({
				forma = "Ball",
				tamano = Vector3.new(3.6, 3.6, 3.6),
				posicion = Vector3.new(0, 0, 0),
				color = Color3.fromRGB(140, 255, 60),
				material = "Neon",
				transparencia = 0.7,
			}),
		},
	},
	{
		id = "corazon_oro",
		nombre = "Corazón de Oro",
		rareza = "secreto",
		ingreso = 120000,
		precio = 150000000,
		set = "huerto",
		descripcion = "Por dentro es puro oro. Por fuera, puro drama.",
		piezas = {
			P({
				forma = "Block",
				tamano = Vector3.new(1.1, 1.1, 0.35),
				posicion = Vector3.new(0, 2.4, 0),
				rotacion = Vector3.new(0, 0, 45),
				color = ORO,
				material = "Neon",
			}),
		},
	},
	{
		id = "crunch_omega",
		nombre = "Crunch Omega",
		rareza = "secreto",
		ingreso = 200000,
		precio = 250000000,
		set = "caras_locas",
		descripcion = "El último Crunchi. Ha visto cosas que no puede explicar.",
		ojos = "espiral",
		boca = "abierta",
		piezas = {
			P({
				forma = "Cylinder",
				tamano = Vector3.new(0.15, 4.6, 4.6),
				posicion = Vector3.new(0, 0, 0),
				rotacion = DE_PIE,
				color = Color3.fromRGB(170, 80, 255),
				material = "Neon",
				transparencia = 0.3,
			}),
		},
	},
}

return Crunchis
