--!strict
--[[
	Config/Canastas
	Canastas sorpresa que se compran con DINERO DEL JUEGO (o con tickets gratis de
	recompensas). Dan un Crunchi al azar según las probabilidades de cada una.

	⚠️ Las probabilidades SIEMPRE se muestran al jugador antes de abrir (la UI las calcula
	de estos mismos pesos, así que nunca pueden ser distintas de las reales).

	Campos:
	  id, nombre, color
	  precio              en dinero del juego (0 = solo con ticket)
	  requisitoRebirths   rebirths necesarios para comprarla
	  pesos               probabilidad relativa por rareza
	  soloTicket          true = no se vende, solo se consigue como recompensa
]]

export type Canasta = {
	id: string,
	nombre: string,
	color: Color3,
	precio: number,
	requisitoRebirths: number,
	pesos: { [string]: number },
	soloTicket: boolean,
}

local function C(canasta: Canasta): Canasta
	return canasta
end

local Canastas: { Canasta } = {
	C({
		id = "madera",
		nombre = "Canasta de Madera",
		color = Color3.fromRGB(170, 115, 60),
		precio = 1000,
		requisitoRebirths = 0,
		pesos = { comun = 70, pococomun = 25, raro = 5 },
		soloTicket = false,
	}),
	C({
		id = "hierro",
		nombre = "Canasta de Hierro",
		color = Color3.fromRGB(160, 170, 185),
		precio = 50000,
		requisitoRebirths = 0,
		pesos = { pococomun = 50, raro = 35, epico = 13, legendario = 2 },
		soloTicket = false,
	}),
	C({
		id = "dorada",
		nombre = "Canasta Dorada",
		color = Color3.fromRGB(255, 200, 40),
		precio = 2000000,
		requisitoRebirths = 0,
		pesos = { raro = 45, epico = 38, legendario = 14, mitico = 2.8, secreto = 0.2 },
		soloTicket = false,
	}),
	C({
		id = "celestial",
		nombre = "Canasta Celestial",
		color = Color3.fromRGB(120, 170, 255),
		precio = 500000000,
		requisitoRebirths = 5,
		pesos = { epico = 50, legendario = 35, mitico = 13, secreto = 2 },
		soloTicket = false,
	}),
	-- Se compra con Robux (producto CANASTA_SORPRESA). Probabilidades SIEMPRE visibles en la
	-- tienda y oculta para jugadores de países que restringen objetos aleatorios de pago.
	C({
		id = "sorpresa",
		nombre = "Canasta Sorpresa",
		color = Color3.fromRGB(255, 90, 160),
		precio = 0,
		requisitoRebirths = 0,
		pesos = { epico = 70, legendario = 24, mitico = 5, secreto = 1 },
		soloTicket = true,
	}),
	C({
		id = "epica",
		nombre = "Canasta Épica",
		color = Color3.fromRGB(166, 77, 255),
		precio = 0,
		requisitoRebirths = 0,
		pesos = { epico = 80, legendario = 18, mitico = 2 },
		soloTicket = true,
	}),
}

return Canastas
