--!strict
--[[
	Config/Armas
	Armas de DEFENSA (cartoon): sirven para golpear a quien carga un Crunchi robado, a los
	intrusos en tu base y a los agentes de la Redada. No hacen daño: empujan.

	⚠️ Reglas (no negociables, ver docs/GAME_DESIGN.md §5 y §8.7):
	  - NINGUNA arma se compra: ni con Robux ni con dinero del juego (el dinero se puede
	    comprar con Robux). Todas se DESBLOQUEAN jugando.
	  - Todas son "de lado" (sidegrades): más alcance = golpe más lento. Cualquier golpe
	    detiene igual a un ladrón. El periódico inicial sigue siendo competitivo.

	Campos:
	  alcance       studs hasta donde llega el golpe
	  cono          qué tan "de frente" tiene que estar el objetivo: 1 = solo justo enfrente,
	                0 = media vuelta (90° a cada lado), negativo = casi todo alrededor
	  cooldown      segundos entre golpes
	  empuje        fuerza horizontal del empujón (y empujeArriba la vertical)
	  tamano/color/forma/material   el modelo placeholder (forma "Block" o "Ball")
	  sonido        clave de Config/Sonidos
	  desbloqueo    { tipo, valor }:
	                  inicial    lo tienen todos
	                  rebirths   llegar a ese rebirth
	                  defensas   detener a esa cantidad de ladrones
	                  indice     tener ese porcentaje del Índice
	                  almacen    sacar esa cantidad de cajas del Almacén
	                  agentes    golpear a esa cantidad de agentes de la Redada

	Modelo real: ReplicatedStorage > Modelos > Armas > <id> (una Tool con su Handle).
	Ver docs/ASSETS_PENDIENTES.md.
]]

export type Desbloqueo = { tipo: string, valor: number }

export type Arma = {
	id: string,
	nombre: string,
	icono: string,
	descripcion: string,
	alcance: number,
	cono: number,
	cooldown: number,
	empuje: number,
	empujeArriba: number,
	tamano: Vector3,
	color: Color3,
	forma: string,
	material: string,
	sonido: string,
	desbloqueo: Desbloqueo,
}

local function A(arma: Arma): Arma
	return arma
end

local Armas = {
	INICIAL = "periodico",

	LISTA = {
		A({
			id = "periodico",
			nombre = "Periódico Enrollado",
			icono = "🗞️",
			descripcion = "El clásico. Equilibrado en todo.",
			alcance = 8,
			cono = 0.2,
			cooldown = 0.8,
			empuje = 55,
			empujeArriba = 28,
			tamano = Vector3.new(0.5, 0.5, 3),
			color = Color3.fromRGB(235, 235, 225),
			forma = "Block",
			material = "SmoothPlastic",
			sonido = "Golpe",
			desbloqueo = { tipo = "inicial", valor = 0 },
		}),
		A({
			id = "chancla",
			nombre = "Chancla Voladora",
			icono = "🩴",
			descripcion = "Corto alcance, pero la más rápida y casi no hay que apuntar.",
			alcance = 6.5,
			cono = -0.1,
			cooldown = 0.55,
			empuje = 45,
			empujeArriba = 30,
			tamano = Vector3.new(1.2, 0.3, 2.6),
			color = Color3.fromRGB(60, 170, 255),
			forma = "Block",
			material = "SmoothPlastic",
			sonido = "Chancla",
			desbloqueo = { tipo = "defensas", valor = 3 },
		}),
		A({
			id = "matamoscas",
			nombre = "Matamoscas Gigante",
			icono = "🪰",
			descripcion = "Llega lejos, pero tarda en volver a golpear.",
			alcance = 10.5,
			cono = 0.35,
			cooldown = 1.1,
			empuje = 50,
			empujeArriba = 25,
			tamano = Vector3.new(2.2, 0.2, 4.2),
			color = Color3.fromRGB(255, 90, 90),
			forma = "Block",
			material = "SmoothPlastic",
			sonido = "Golpe",
			desbloqueo = { tipo = "rebirths", valor = 1 },
		}),
		A({
			id = "pez",
			nombre = "Pez de Goma Chillón",
			icono = "🐟",
			descripcion = "Como el periódico, un poco más rápido. ¡Y chilla!",
			alcance = 8,
			cono = 0.2,
			cooldown = 0.75,
			empuje = 55,
			empujeArriba = 35,
			tamano = Vector3.new(0.8, 1.2, 2.8),
			color = Color3.fromRGB(255, 170, 40),
			forma = "Block",
			material = "SmoothPlastic",
			sonido = "Chillido",
			desbloqueo = { tipo = "indice", valor = 50 },
		}),
		A({
			id = "baguette",
			nombre = "Baguette Dura",
			icono = "🥖",
			descripcion = "Empuja muchísimo: saca a los intrusos volando de tu base.",
			alcance = 8.5,
			cono = 0.2,
			cooldown = 0.9,
			empuje = 85,
			empujeArriba = 40,
			tamano = Vector3.new(0.7, 0.7, 3.6),
			color = Color3.fromRGB(205, 150, 80),
			forma = "Block",
			material = "SmoothPlastic",
			sonido = "Golpe",
			desbloqueo = { tipo = "rebirths", valor = 3 },
		}),
		A({
			id = "globo",
			nombre = "Globo de Agua",
			icono = "🎈",
			descripcion = "El de más alcance, pero hay que apuntar bien y recargar.",
			alcance = 15,
			cono = 0.85,
			cooldown = 2.2,
			empuje = 35,
			empujeArriba = 20,
			tamano = Vector3.new(1.4, 1.4, 1.4),
			color = Color3.fromRGB(80, 180, 255),
			forma = "Ball",
			material = "Glass",
			sonido = "Splash",
			desbloqueo = { tipo = "almacen", valor = 3 },
		}),
		A({
			id = "paraguas",
			nombre = "Paraguas Rebotón",
			icono = "☂️",
			descripcion = "Golpea casi todo a tu alrededor. Ideal contra las Redadas.",
			alcance = 7.5,
			cono = -0.4,
			cooldown = 1,
			empuje = 65,
			empujeArriba = 30,
			tamano = Vector3.new(0.4, 0.4, 4),
			color = Color3.fromRGB(170, 90, 255),
			forma = "Block",
			material = "SmoothPlastic",
			sonido = "Golpe",
			desbloqueo = { tipo = "agentes", valor = 10 },
		}),
	} :: { Arma },
}

return table.freeze(Armas)
