--!strict
--[[
	Config/Productos
	Todo lo que se compra con Robux. Ver docs/GAME_DESIGN.md §8.

	TODO (configuración de Roblox, al final): crea cada Game Pass y Developer Product en el
	Creator Dashboard y pega aquí su ID (el número). Mientras el id sea 0, el botón existe
	pero avisa "todavía no está configurado". Ver docs/CONFIGURACION_ROBLOX.md.

	`precio` es SOLO una referencia para mostrar si Roblox no responde: el precio real es el
	que pongas en el Creator Dashboard, y el juego lo lee de Roblox para mostrarlo.

	⚠️ Líneas rojas (no negociables):
	  - Nada que se compre da ventaja para robar o para evitar robos.
	  - Lo aleatorio pagado muestra sus probabilidades y se oculta donde la ley lo restringe.
	  - Ninguna oferta interrumpe el juego; máximo una oferta automática por sesión.
]]

export type Pase = {
	id: number,
	nombre: string,
	precio: number,
	icono: string,
	descripcion: string,
}

export type Producto = {
	id: number,
	nombre: string,
	precio: number,
	icono: string,
	tipo: string, -- "dinero" | "boost" | "suerte" | "offline_x2" | "canasta" | "pase_nivel" | "pase_premium" | "pack_inicial"
	descripcion: string,
	minutos: number?, -- dinero: minutos de ingreso; boost/suerte: duración
	minimo: number?, -- dinero mínimo del paquete
	etiqueta: string?, -- "Más popular", "Mejor valor"
	canasta: string?, -- id de Config/Canastas (tipo "canasta")
}

local function P(pase: Pase): Pase
	return pase
end
local function D(producto: Producto): Producto
	return producto
end

local Productos = {
	PASES = {
		VIP = P({
			id = 0, -- TODO
			nombre = "VIP",
			precio = 199,
			icono = "👑",
			descripcion = "Etiqueta [VIP] en el chat y sobre tu cabeza, Aura Dorada, Terraza VIP, +1 cambio de misión diario y ganancias offline de hasta 6 h.",
		}),
		X2_DINERO = P({
			id = 0, -- TODO
			nombre = "x2 Dinero",
			precio = 399,
			icono = "💰",
			descripcion = "Ganas el doble de dinero, para siempre.",
		}),
		AUTO_COBRO = P({
			id = 0, -- TODO
			nombre = "Auto-Cobro",
			precio = 149,
			icono = "🧲",
			descripcion = "El dinero de tus pedestales va directo a tu saldo, sin pisar los botones.",
		}),
		PISO_EXTRA = P({
			id = 0, -- TODO
			nombre = "Piso Extra",
			precio = 299,
			icono = "🏗️",
			descripcion = "+4 pedestales en tu base (además de los que ganas con rebirths).",
		}),
		DEPOSITO_XL = P({
			id = 0, -- TODO
			nombre = "Depósito XL",
			precio = 99,
			icono = "📦",
			descripcion = "Tu depósito pasa de 10 a 40 lugares.",
		}),
		APERTURA_TRIPLE = P({
			id = 0, -- TODO
			nombre = "Apertura Triple",
			precio = 99,
			icono = "🧺",
			descripcion = "Abre 3 canastas a la vez (se siguen pagando con dinero del juego).",
		}),
		ESTELA_ARCOIRIS = P({
			id = 0, -- TODO
			nombre = "Estela Arcoíris",
			precio = 99,
			icono = "🌈",
			descripcion = "Una estela arcoíris que te sigue a todas partes.",
		}),
		MASCOTAS_EXTRA = P({
			id = 0, -- TODO
			nombre = "Mascotas Extra",
			precio = 149,
			icono = "🐾",
			descripcion = "Lleva 2 Bichitos más equipados a la vez (solo suben tu ingreso).",
		}),
		AURA_LLAMA = P({
			id = 0, -- TODO
			nombre = "Aura Llama Verde",
			precio = 149,
			icono = "🔥",
			descripcion = "Un aura de llamas verdes a tu alrededor.",
		}),
	} :: { [string]: Pase },

	PRODUCTOS = {
		DINERO_PUNADO = D({
			id = 0, -- TODO
			nombre = "Puñado de dinero",
			precio = 29,
			icono = "💵",
			tipo = "dinero",
			minutos = 10,
			minimo = 1000,
			descripcion = "10 minutos de tu ingreso",
		}),
		DINERO_CANASTA = D({
			id = 0, -- TODO
			nombre = "Canasta de dinero",
			precio = 99,
			icono = "💰",
			tipo = "dinero",
			minutos = 45,
			minimo = 5000,
			descripcion = "45 minutos de tu ingreso",
		}),
		DINERO_CARRETILLA = D({
			id = 0, -- TODO
			nombre = "Carretilla de dinero",
			precio = 299,
			icono = "🛒",
			tipo = "dinero",
			minutos = 180,
			minimo = 20000,
			etiqueta = "Más popular",
			descripcion = "3 horas de tu ingreso",
		}),
		DINERO_CAMION = D({
			id = 0, -- TODO
			nombre = "Camión de dinero",
			precio = 799,
			icono = "🚚",
			tipo = "dinero",
			minutos = 600,
			minimo = 80000,
			etiqueta = "Mejor valor",
			descripcion = "10 horas de tu ingreso",
		}),
		BOOST_X2 = D({
			id = 0, -- TODO
			nombre = "Boost x2 (30 min)",
			precio = 49,
			icono = "⚡",
			tipo = "boost",
			minutos = 30,
			descripcion = "Ganas el doble durante 30 minutos (se suma al tiempo que te quede)",
		}),
		SUERTE_SERVIDOR = D({
			id = 0, -- TODO
			nombre = "Suerte del Servidor (15 min)",
			precio = 79,
			icono = "🍀",
			tipo = "suerte",
			minutos = 15,
			descripcion = "Duplica la probabilidad de Épicos o mejores en las cintas PARA TODO EL SERVIDOR",
		}),
		OFFLINE_X2 = D({
			id = 0, -- TODO
			nombre = "Duplicar ganancias offline",
			precio = 25,
			icono = "💤",
			tipo = "offline_x2",
			descripcion = "Duplica lo que ganaste mientras no estabas",
		}),
		CANASTA_SORPRESA = D({
			id = 0, -- TODO
			nombre = "Canasta Sorpresa",
			precio = 149,
			icono = "🎁",
			tipo = "canasta",
			canasta = "sorpresa",
			descripcion = "Un Crunchi Épico o mejor garantizado",
		}),
		PASE_NIVEL = D({
			id = 0, -- TODO
			nombre = "Saltar nivel del Pase",
			precio = 29,
			icono = "⏩",
			tipo = "pase_nivel",
			descripcion = "+1 nivel del Pase Crunch",
		}),
		PASE_PREMIUM = D({
			id = 0, -- TODO
			nombre = "Pase Crunch Premium",
			precio = 299,
			icono = "⭐",
			tipo = "pase_premium",
			descripcion = "Desbloquea el camino premium de la temporada actual",
		}),
		PACK_INICIAL = D({
			id = 0, -- TODO
			nombre = "Pack Inicial",
			precio = 99,
			icono = "🚀",
			tipo = "pack_inicial",
			minutos = 60,
			minimo = 50000,
			descripcion = "1 h de tu ingreso + Manzana Cohete (Legendario) + Boost x2 de 1 h + título «Crunchero»",
		}),
	} :: { [string]: Producto },

	-- La primera compra de dinero entrega este múltiplo (una sola vez, avisado claramente).
	PRIMERA_COMPRA_MULTIPLICADOR = 2,

	-- Pack Inicial: qué entrega y cuándo se ofrece (una tarjeta lateral, nunca un pop-up).
	PACK_INICIAL = {
		CRUNCHI = "manzana_cohete",
		BOOST_MINUTOS = 60,
		TITULO = "Crunchero",
		OFRECER_A_LOS_MINUTOS = 7,
		VECES_MAXIMAS_OFRECIDO = 3, -- en total (una por sesión como mucho)
	},

	-- Prueba gratis: a los 3 minutos de la primera sesión, un boost x2 de 5 minutos.
	PRUEBA_X2 = { A_LOS_MINUTOS = 3, DURACION_MINUTOS = 5 },

	-- Suerte del Servidor: multiplicador de peso para estas rarezas mientras está activa.
	SUERTE = { epico = 2, legendario = 2, mitico = 2, secreto = 2 } :: { [string]: number },
}

return table.freeze(Productos)
