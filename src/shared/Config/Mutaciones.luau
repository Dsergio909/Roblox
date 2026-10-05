--!strict
--[[
	Config/Mutaciones
	Variantes aleatorias de un Crunchi. Una mutación multiplica su ingreso Y su precio.

	Campos:
	  id        identificador interno (se guarda en los datos: no cambiarlo tras publicar)
	  nombre    texto visible
	  mult      multiplicador de ingreso y precio
	  peso      probabilidad relativa al aparecer en la cinta (0 = solo en eventos)
	  color     color del cuerpo (nil = el color normal del Crunchi)
	  material  nombre de Enum.Material para el cuerpo
	  neon      si el cuerpo brilla (usar poco: cuesta rendimiento en celulares)

	Con los pesos de abajo: Dorado 4 %, Diamante 1 %, Arcoíris 0.2 %.
	Los eventos pueden cambiar estos pesos temporalmente (ver Config/Eventos en la Fase 4).
]]

export type Mutacion = {
	id: string,
	nombre: string,
	mult: number,
	peso: number,
	color: Color3?,
	material: string,
	neon: boolean,
}

local Mutaciones: { Mutacion } = {
	{
		id = "normal",
		nombre = "Normal",
		mult = 1,
		peso = 94.8,
		color = nil,
		material = "SmoothPlastic",
		neon = false,
	},
	{
		id = "dorado",
		nombre = "Dorado",
		mult = 2,
		peso = 4,
		color = Color3.fromRGB(255, 196, 37),
		material = "Metal",
		neon = false,
	},
	{
		id = "diamante",
		nombre = "Diamante",
		mult = 3,
		peso = 1,
		color = Color3.fromRGB(120, 230, 255),
		material = "Glass",
		neon = false,
	},
	{
		id = "arcoiris",
		nombre = "Arcoíris",
		mult = 5,
		peso = 0.2,
		color = Color3.fromRGB(255, 90, 200),
		material = "SmoothPlastic",
		neon = false,
	},
	{
		id = "radiactivo",
		nombre = "Radiactivo",
		mult = 4,
		peso = 0,
		color = Color3.fromRGB(140, 255, 60),
		material = "Neon",
		neon = true,
	},
}

return Mutaciones
