--!strict
--[[
	Config/Rarezas
	Las 7 rarezas de los Crunchis, de la más común a la más rara.

	Campos:
	  id        identificador interno (no cambiarlo una vez publicado: se guarda en los datos)
	  nombre    texto que ve el jugador
	  orden     1 = más común. Sirve para comparar ("Legendario o superior")
	  color     color de la rareza en la UI y los brillos
	  escala    tamaño del modelo (las rarezas altas se ven más grandes e impresionantes)
	  anunciar  si es true, todo el servidor ve un anuncio cuando alguien COMPRA o ROBA uno
	            (el anuncio al APARECER en la cinta se configura en Config/Cintas)

	Las probabilidades de aparición NO están aquí: dependen de cada cinta (ver Config/Cintas).
]]

export type Rareza = {
	id: string,
	nombre: string,
	orden: number,
	color: Color3,
	escala: number,
	anunciar: boolean,
}

local Rarezas: { Rareza } = {
	{
		id = "comun",
		nombre = "Común",
		orden = 1,
		color = Color3.fromRGB(176, 176, 176),
		escala = 1,
		anunciar = false,
	},
	{
		id = "pococomun",
		nombre = "Poco común",
		orden = 2,
		color = Color3.fromRGB(91, 209, 91),
		escala = 1.05,
		anunciar = false,
	},
	{
		id = "raro",
		nombre = "Raro",
		orden = 3,
		color = Color3.fromRGB(63, 169, 245),
		escala = 1.1,
		anunciar = false,
	},
	{
		id = "epico",
		nombre = "Épico",
		orden = 4,
		color = Color3.fromRGB(166, 77, 255),
		escala = 1.2,
		anunciar = false,
	},
	{
		id = "legendario",
		nombre = "Legendario",
		orden = 5,
		color = Color3.fromRGB(255, 201, 51),
		escala = 1.3,
		anunciar = true,
	},
	{
		id = "mitico",
		nombre = "Mítico",
		orden = 6,
		color = Color3.fromRGB(255, 77, 109),
		escala = 1.45,
		anunciar = true,
	},
	{
		id = "secreto",
		nombre = "Secreto",
		orden = 7,
		color = Color3.fromRGB(40, 40, 40),
		escala = 1.6,
		anunciar = true,
	},
}

return Rarezas
