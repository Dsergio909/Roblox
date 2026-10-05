--!strict
--[[
	Config/Misiones
	Misiones diarias y semanales. Cada día (a las 00:00 UTC) el jugador recibe DIARIAS_POR_DIA
	misiones al azar del pool DIARIAS; cada lunes, SEMANALES_POR_SEMANA del pool SEMANALES.

	Campos de una misión:
	  id          identificador único
	  tipo        qué se cuenta (ver TIPOS abajo)
	  meta        cuántas veces
	  parametro   (opcional) p. ej. la rareza mínima para "conseguir_rareza"
	  texto       lo que ve el jugador ({meta} se reemplaza por el número)
	  minutos     recompensa en MINUTOS de tu ingreso actual (así nunca queda vieja)
	  xp          experiencia del Pase de Temporada (Fase 3)
	  semillas    (opcional) semillas para el macetero
	  objeto      (opcional) { id, cantidad } de Config/Consumibles para la Mochila

	TIPOS que el juego sabe contar:
	  comprar            comprar Crunchis en la cinta
	  cobrar             cobrar botones de cobro
	  robar_o_defender   robar con éxito O frustrar un robo con el periódico
	                     (así nadie está obligado a robar para completarla)
	  abrir_canasta      abrir canastas
	  conseguir_rareza   conseguir un Crunchi de esa rareza o mejor (comprar, robar, canasta, macetero)
	  jugar_minutos      minutos jugados
	  cerrar_base        usar el cerrojo
	  cosechar           cosechar el macetero
	  completar_diarias  completar misiones diarias (solo semanales)
	  abrir_huevo        abrir huevos de Bichitos (mascotas)
	  usar_objeto        usar objetos de la Mochila
]]

export type Mision = {
	id: string,
	tipo: string,
	meta: number,
	parametro: string?,
	texto: string,
	minutos: number,
	xp: number,
	semillas: number?,
	objeto: { id: string, cantidad: number }?,
}

local function M(mision: Mision): Mision
	return mision
end

local Misiones = {
	DIARIAS_POR_DIA = 3,
	SEMANALES_POR_SEMANA = 3,
	CAMBIOS_GRATIS_POR_DIA = 1,
	-- Premio por completar las 3 diarias del día.
	BONUS_DIARIO = { canasta = "madera", cantidad = 1, xp = 100 },
	-- Recompensa mínima en dinero (para jugadores recién empezados).
	DINERO_MINIMO = 100,

	DIARIAS = {
		M({
			id = "d_comprar_8",
			tipo = "comprar",
			meta = 8,
			texto = "Compra {meta} Crunchis en la cinta",
			minutos = 5,
			xp = 100,
		}),
		M({ id = "d_cobrar_40", tipo = "cobrar", meta = 40, texto = "Cobra {meta} veces", minutos = 5, xp = 100 }),
		M({
			id = "d_robar_defender",
			tipo = "robar_o_defender",
			meta = 1,
			texto = "Roba un Crunchi o detén un robo",
			minutos = 8,
			xp = 100,
		}),
		M({
			id = "d_canasta_2",
			tipo = "abrir_canasta",
			meta = 2,
			texto = "Abre {meta} canastas",
			minutos = 5,
			xp = 100,
		}),
		M({
			id = "d_raro",
			tipo = "conseguir_rareza",
			meta = 1,
			parametro = "raro",
			texto = "Consigue un Crunchi Raro o mejor",
			minutos = 6,
			xp = 100,
		}),
		M({
			id = "d_jugar_15",
			tipo = "jugar_minutos",
			meta = 15,
			texto = "Juega {meta} minutos",
			minutos = 5,
			xp = 100,
			semillas = 1,
		}),
		M({
			id = "d_cerrojo_3",
			tipo = "cerrar_base",
			meta = 3,
			texto = "Cierra tu base {meta} veces",
			minutos = 4,
			xp = 100,
		}),
		M({ id = "d_cosechar", tipo = "cosechar", meta = 1, texto = "Cosecha tu macetero", minutos = 6, xp = 100 }),
		M({
			id = "d_huevo_3",
			tipo = "abrir_huevo",
			meta = 3,
			texto = "Abre {meta} huevos de Bichito",
			minutos = 6,
			xp = 100,
		}),
		M({
			id = "d_objeto_2",
			tipo = "usar_objeto",
			meta = 2,
			texto = "Usa {meta} objetos de tu Mochila",
			minutos = 5,
			xp = 100,
			objeto = { id = "jugo_turbo", cantidad = 1 },
		}),
	},

	SEMANALES = {
		M({
			id = "s_comprar_100",
			tipo = "comprar",
			meta = 100,
			texto = "Compra {meta} Crunchis",
			minutos = 30,
			xp = 500,
			semillas = 2,
		}),
		M({
			id = "s_legendario",
			tipo = "conseguir_rareza",
			meta = 1,
			parametro = "legendario",
			texto = "Consigue un Crunchi Legendario o mejor",
			minutos = 40,
			xp = 500,
		}),
		M({
			id = "s_robar_defender_8",
			tipo = "robar_o_defender",
			meta = 8,
			texto = "Roba o detén {meta} robos",
			minutos = 30,
			xp = 500,
		}),
		M({
			id = "s_diarias_10",
			tipo = "completar_diarias",
			meta = 10,
			texto = "Completa {meta} misiones diarias",
			minutos = 30,
			xp = 500,
			semillas = 1,
		}),
		M({
			id = "s_canastas_15",
			tipo = "abrir_canasta",
			meta = 15,
			texto = "Abre {meta} canastas",
			minutos = 30,
			xp = 500,
		}),
		M({
			id = "s_huevos_20",
			tipo = "abrir_huevo",
			meta = 20,
			texto = "Abre {meta} huevos de Bichito",
			minutos = 30,
			xp = 500,
			objeto = { id = "jugo_turbo", cantidad = 2 },
		}),
		M({
			id = "s_objetos_10",
			tipo = "usar_objeto",
			meta = 10,
			texto = "Usa {meta} objetos de tu Mochila",
			minutos = 30,
			xp = 500,
			objeto = { id = "iman", cantidad = 2 },
		}),
		M({
			id = "s_jugar_180",
			tipo = "jugar_minutos",
			meta = 180,
			texto = "Juega {meta} minutos",
			minutos = 30,
			xp = 500,
		}),
	},
}

return table.freeze(Misiones)
