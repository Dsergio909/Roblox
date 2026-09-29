--!strict
--[[
	Config/Semillas
	Semillas para el MACETERO de tu base. Se plantan y crecen en tiempo real, incluso
	desconectado: es el gancho para volver ("¡mi planta ya está lista!").

	Al cosechar sale un Crunchi al azar con las probabilidades de `pesos`, y la
	probabilidad de mutación se multiplica por `bonusMutacion` (plantas = más mutaciones).

	Campos: id, nombre, color, minutos (tiempo de crecimiento), pesos, bonusMutacion
]]

export type Semilla = {
	id: string,
	nombre: string,
	color: Color3,
	minutos: number,
	pesos: { [string]: number },
	bonusMutacion: number,
}

local function S(semilla: Semilla): Semilla
	return semilla
end

local Semillas: { Semilla } = {
	S({
		id = "comun",
		nombre = "Semilla Común",
		color = Color3.fromRGB(140, 200, 90),
		minutos = 30,
		pesos = { comun = 40, pococomun = 40, raro = 17, epico = 3 },
		bonusMutacion = 3,
	}),
	S({
		id = "dorada",
		nombre = "Semilla Dorada",
		color = Color3.fromRGB(255, 200, 40),
		minutos = 120,
		pesos = { raro = 50, epico = 38, legendario = 11, mitico = 1 },
		bonusMutacion = 4,
	}),
	S({
		id = "estelar",
		nombre = "Semilla Estelar",
		color = Color3.fromRGB(150, 120, 255),
		minutos = 480,
		pesos = { epico = 55, legendario = 35, mitico = 9, secreto = 1 },
		bonusMutacion = 5,
	}),
}

return Semillas
