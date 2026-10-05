--!strict
--[[
	Config/Eventos
	Eventos automáticos del servidor. AGREGAR UN EVENTO = agregar una entrada.

	Cada cierto tiempo (INTERVALO_MINUTOS) empieza el siguiente evento de ROTACION. Los
	eventos de TEMPORADA (con fechas reales de inicio y fin) entran en la rotación solo
	mientras estén vigentes: si dice "limitado", lo es de verdad.

	Campos:
	  id, nombre, icono, color
	  tipo            "lluvia" (manzanas cayendo), "redada" (Agentes que etiquetan
	                  Crunchis; se defienden entre todos con el periódico), "hora" (solo
	                  modificadores)
	  duracion        minutos
	  mutaciones      multiplicadores de probabilidad de mutación mientras dura
	                  (si la mutación normalmente no sale, el número es su peso directo:
	                  radiactivo = 3 ≈ 3 %)
	  rarezas         multiplicadores de probabilidad de rareza en las cintas
	  multIngreso     multiplicador de ingreso para todos (1 = nada)
	  inicio / fin    (opcional) fechas reales (os.time UTC) para eventos de temporada
]]

export type Evento = {
	id: string,
	nombre: string,
	icono: string,
	color: Color3,
	tipo: string,
	duracion: number,
	mutaciones: { [string]: number }?,
	rarezas: { [string]: number }?,
	multIngreso: number?,
	descripcion: string,
	inicio: number?,
	fin: number?,
}

local function E(evento: Evento): Evento
	return evento
end

local Eventos = {
	INTERVALO_MINUTOS = 8, -- minutos entre el final de un evento y el inicio del siguiente
	PRIMERO_A_LOS_MINUTOS = 5, -- el primero, tras abrir el servidor

	ROTACION = {
		E({
			id = "lluvia",
			nombre = "Lluvia de Manzanas",
			icono = "🌧️",
			color = Color3.fromRGB(120, 220, 255),
			tipo = "lluvia",
			duracion = 3,
			mutaciones = { dorado = 3, diamante = 3, arcoiris = 3 },
			descripcion = "¡Caen manzanas del cielo! Más mutaciones en las cintas.",
		}),
		E({
			id = "redada",
			nombre = "Redada FrutaMax",
			icono = "🚨",
			color = Color3.fromRGB(255, 70, 70),
			tipo = "redada",
			duracion = 2,
			descripcion = "¡Agentes etiquetan tus Crunchis! Dales con el periódico para ganar monedas.",
		}),
		E({
			id = "hora_dorada",
			nombre = "Hora Dorada",
			icono = "✨",
			color = Color3.fromRGB(255, 200, 40),
			tipo = "hora",
			duracion = 3,
			mutaciones = { dorado = 5 },
			multIngreso = 1.5,
			descripcion = "¡Todos ganan x1.5 y salen muchos Crunchis Dorados!",
		}),
		E({
			id = "noche_nuclear",
			nombre = "Noche Nuclear",
			icono = "☢️",
			color = Color3.fromRGB(140, 255, 60),
			tipo = "hora",
			duracion = 3,
			mutaciones = { radiactivo = 3 },
			rarezas = { epico = 1.5, legendario = 1.5 },
			descripcion = "Solo en esta noche: ¡mutación Radiactiva (x4)!",
		}),
	},

	-- Ejemplo de evento de temporada (con fechas reales). Quita el comentario y ajusta.
	-- TEMPORADA = {
	-- 	E({ id = "halloween", nombre = "Halloween Crunch", icono = "🎃", color = Color3.fromRGB(255,140,0),
	-- 		tipo = "lluvia", duracion = 4, mutaciones = { radiactivo = 5 },
	-- 		descripcion = "¡Crunchis embrujados!", inicio = 1793145600, fin = 1793750400 }),
	-- },
	TEMPORADA = {} :: { Evento },

	-- Redada: agentes extra que entran a las bases y ETIQUETAN Crunchis (pausan su
	-- ingreso un rato). Todos se defienden con el periódico y ganan monedas.
	-- Nunca entran a bases con escudo o con el cerrojo puesto (las protecciones valen).
	REDADA = {
		AGENTES = 5,
		VELOCIDAD = 11,
		SEGUNDOS_ETIQUETA = 25, -- el Crunchi etiquetado no produce durante este tiempo
		RECOMPENSA_MINUTOS = 2, -- dinero por golpear a un agente = N minutos de tu ingreso
		RECOMPENSA_MINIMA = 50,
		MAX_RECOMPENSAS = 6, -- por jugador y por redada (evita "granjear" agentes)
		REGRESO_SEGUNDOS = 6, -- un agente golpeado vuelve a entrar tras este tiempo
	},

	-- Lluvia: manzanas decorativas que caen cerca de cada jugador (solo en su dispositivo).
	LLUVIA = {
		MANZANAS_POR_SEGUNDO = 6, -- se reduce con el Modo ahorro
		MAX_MANZANAS = 30,
	},
}

return table.freeze(Eventos)
