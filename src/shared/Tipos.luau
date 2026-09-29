--!strict
--[[
	Tipos
	Forma de los datos guardados de cada jugador (lo que ProfileStore guarda en DataStore).

	⚠️ Reglas para los datos guardados (limitaciones de DataStore):
	  - Nada de Instances, Vector3, Color3 ni funciones: solo números, textos, booleanos y tablas.
	  - Las listas (arrays) no pueden tener huecos.
	  - No mezclar claves numéricas y de texto en la misma tabla.

	Si cambias la forma de algo que ya existe (renombrar un campo, cambiar su tipo), sube
	VERSION_DATOS en DatosService y agrega una migración allí.
]]

export type CrunchiGuardado = {
	uid: string, -- identificador único de ESTE Crunchi (para evitar duplicados)
	id: string, -- tipo de Crunchi (Config/Crunchis)
	mut: string, -- mutación (Config/Mutaciones)
	lugar: number, -- número de pedestal (1, 2, 3...) o 0 si está en el depósito
}

export type Estadisticas = {
	tiempoJugado: number, -- segundos totales
	sesiones: number,
	comprasCinta: number,
	cobros: number,
	robosExitosos: number,
	robosSufridos: number,
	defensas: number, -- robos frustrados con el periódico
	gananciaTotal: number, -- dinero ganado en total (histórico)
}

export type Ajustes = {
	musica: boolean,
	efectos: boolean,
	ahorro: boolean, -- "modo ahorro": menos partículas y efectos
}

export type MisionGuardada = {
	id: string,
	progreso: number,
	reclamada: boolean,
}

export type Misiones = {
	dia: number, -- día (UTC) de las diarias actuales
	diarias: { MisionGuardada },
	semana: number,
	semanales: { MisionGuardada },
	cambiosUsados: number,
	bonusDiario: boolean, -- ya se dio el premio por completar las 3 diarias
}

export type Login = {
	diasTotales: number, -- días distintos que se conectó (el calendario avanza con esto)
	ultimoDia: number,
	racha: number,
	pendiente: boolean, -- recompensa del calendario de hoy sin reclamar
}

export type Macetero = {
	semilla: string, -- "" = vacío
	listaEn: number, -- os.time() en que estará lista
}

export type Offline = {
	ingresoAlSalir: number, -- ingreso base por segundo al desconectarse
	pendiente: number, -- dinero offline por cobrar
}

export type Compras = {
	primeraCompraDinero: boolean, -- ya usó el bonus x2 de la primera compra de dinero
	packInicial: boolean,
	vecesOfertaPack: number, -- cuántas veces se le ofreció el Pack Inicial (máximo 3)
	pruebaX2: boolean, -- ya recibió el boost x2 de prueba gratis
	robuxGastados: number,
}

export type PaseGuardado = {
	temporada: string,
	xp: number,
	premium: boolean,
	gratis: { [string]: boolean }, -- nivel ("5") → reclamado
	premiumes: { [string]: boolean },
	minutosJuego: number,
	diaXp: number,
	xpJuegoDia: number,
}

export type Datos = {
	version: number,
	dinero: number,
	crunchis: { CrunchiGuardado },
	contadorUid: number, -- para generar identificadores únicos de Crunchis
	rebirths: number,
	-- Índice: "crunchiId" y "crunchiId:mutacion" → fecha (os.time) de la primera vez que lo tuvo.
	indice: { [string]: number },
	stats: Estadisticas,
	-- Pasos del embudo de Analytics ya registrados (para registrar cada uno una sola vez).
	onboarding: { [string]: boolean },
	primeraConexion: number,
	ultimaConexion: number,
	-- PurchaseId de compras con Robux ya entregadas (para no entregar nunca dos veces).
	recibos: { string },
	ajustes: Ajustes,

	-- Fase 2
	mejorAmigo: string, -- uid del Crunchi que se conserva al hacer rebirth ("" = el más valioso)
	setsCompletados: { [string]: number }, -- setId → fecha
	hitosIndice: { [string]: boolean }, -- "25", "50"... → reclamado
	titulos: { [string]: boolean }, -- títulos desbloqueados
	tituloEquipado: string,
	misiones: Misiones,
	login: Login,
	tickets: { [string]: number }, -- canastas gratis por abrir: canastaId → cantidad
	semillas: { [string]: number }, -- semillaId → cantidad
	macetero: Macetero,
	offline: Offline,

	-- Fase 3
	compras: Compras,
	boosts: { x2Hasta: number },
	pase: PaseGuardado,
	cosmeticos: { [string]: boolean },
	equipados: { aura: string, estela: string },

	-- Fase 4
	almacen: { proximo: number, veces: number }, -- Almacén FrutaMax: próximo intento (os.time)
	insignias: { [string]: boolean }, -- insignias de Roblox ya entregadas (clave de Config/Insignias)
}

-- Estado que el servidor comparte SOLO con el dueño (no con otros jugadores).
export type EstadoPrivado = { [string]: any }

-- Un Crunchi en la cinta transportadora (lo conocen servidor y clientes).
export type ItemCinta = {
	id: number,
	cinta: string,
	crunchi: string,
	mut: string,
	t0: number, -- momento (tiempo de servidor) en que apareció al inicio de la cinta
}

return {}
