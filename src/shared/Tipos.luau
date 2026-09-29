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
