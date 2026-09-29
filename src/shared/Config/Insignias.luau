--!strict
--[[
	Config/Insignias
	Insignias (badges) de Roblox que el juego entrega solo. Se revisan con los datos del
	jugador, así que también las recibe quien ya cumplía el requisito antes de que existieran.

	TODO (configuración de Roblox, al final): crea cada insignia en el Creator Dashboard
	(Experiencia → Engagement → Badges) y pega aquí su ID. Con id 0 no se entrega (no pasa
	nada). Ver docs/CONFIGURACION_ROBLOX.md.

	condicion (qué dato se mira) y minimo (desde cuánto):
	  comprasCinta   Crunchis comprados en las cintas
	  robosExitosos  robos exitosos
	  defensas       ladrones detenidos con el periódico
	  rebirths       rebirths
	  sets           sets del Índice completados
	  indice         porcentaje del Índice (0 a 100)
	  almacen        cajas sacadas del Almacén FrutaMax
]]

export type Insignia = {
	clave: string, -- identificador interno (no cambiar tras publicar)
	id: number,
	nombre: string,
	descripcion: string,
	condicion: string,
	minimo: number,
}

local function I(insignia: Insignia): Insignia
	return insignia
end

local Insignias: { Insignia } = {
	I({
		clave = "primer_crunchi",
		id = 0, -- TODO
		nombre = "¡Mi primer Crunchi!",
		descripcion = "Compraste tu primer Crunchi en la cinta.",
		condicion = "comprasCinta",
		minimo = 1,
	}),
	I({
		clave = "primer_robo",
		id = 0, -- TODO
		nombre = "Manos rápidas",
		descripcion = "Robaste tu primer Crunchi y lo llevaste a tu base.",
		condicion = "robosExitosos",
		minimo = 1,
	}),
	I({
		clave = "primera_defensa",
		id = 0, -- TODO
		nombre = "¡Periodicazo!",
		descripcion = "Detuviste a un ladrón con el periódico.",
		condicion = "defensas",
		minimo = 1,
	}),
	I({
		clave = "primer_rebirth",
		id = 0, -- TODO
		nombre = "Renacer Crujiente",
		descripcion = "Hiciste tu primer rebirth.",
		condicion = "rebirths",
		minimo = 1,
	}),
	I({
		clave = "rebirth_5",
		id = 0, -- TODO
		nombre = "Veterano de Villa Crunch",
		descripcion = "Llegaste a Rebirth 5.",
		condicion = "rebirths",
		minimo = 5,
	}),
	I({
		clave = "primer_set",
		id = 0, -- TODO
		nombre = "Coleccionista",
		descripcion = "Completaste tu primer set del Índice.",
		condicion = "sets",
		minimo = 1,
	}),
	I({
		clave = "indice_100",
		id = 0, -- TODO
		nombre = "Índice Completo",
		descripcion = "Tuviste los 21 Crunchis al menos una vez.",
		condicion = "indice",
		minimo = 100,
	}),
	I({
		clave = "almacen",
		id = 0, -- TODO
		nombre = "Golpe al Almacén",
		descripcion = "Sacaste una caja del Almacén FrutaMax sin tocar los láseres.",
		condicion = "almacen",
		minimo = 1,
	}),
}

return Insignias
