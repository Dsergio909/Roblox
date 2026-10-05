--!strict
--[[
	Config/Cintas
	Las cintas transportadoras donde aparecen Crunchis para comprar.

	Campos:
	  id                  identificador (la posición en el mapa está en Config/Mapa)
	  nombre              texto visible
	  intervalo           segundos entre cada Crunchi que aparece
	  velocidad           studs por segundo que avanza la cinta
	  requisitoRebirths   rebirths necesarios para COMPRAR en esta cinta (todos pueden verla)
	  pesos               probabilidad relativa de cada rareza. No hace falta que sumen 100:
	                      el juego las convierte en porcentajes. Las rarezas que no aparecen, no salen.
	  color               color de la cinta
	  anunciarDesde       rareza mínima que se anuncia a todo el servidor al aparecer
	                      (en las cintas de rarezas altas se anuncia menos, para no saturar)

	Con la cinta principal (un Crunchi cada 3 s = 20 por minuto):
	  un Legendario (1.2 %) sale en promedio cada ~4 minutos en todo el servidor,
	  un Mítico (0.25 %) cada ~20 minutos y un Secreto (0.05 %) cada ~100 minutos.
]]

export type Cinta = {
	id: string,
	nombre: string,
	intervalo: number,
	velocidad: number,
	requisitoRebirths: number,
	pesos: { [string]: number },
	color: Color3,
	anunciarDesde: string,
}

local Cintas: { Cinta } = {
	{
		id = "principal",
		nombre = "Cinta Principal",
		intervalo = 3,
		velocidad = 7,
		requisitoRebirths = 0,
		pesos = {
			comun = 55,
			pococomun = 28,
			raro = 11.5,
			epico = 4,
			legendario = 1.2,
			mitico = 0.25,
			secreto = 0.05,
		},
		color = Color3.fromRGB(60, 60, 66),
		anunciarDesde = "epico",
	},
	{
		id = "dorada",
		nombre = "Cinta Dorada",
		intervalo = 6,
		velocidad = 6,
		requisitoRebirths = 3,
		pesos = {
			raro = 60,
			epico = 28,
			legendario = 9,
			mitico = 2.5,
			secreto = 0.5,
		},
		color = Color3.fromRGB(200, 160, 40),
		anunciarDesde = "legendario",
	},
	{
		id = "celestial",
		nombre = "Cinta Celestial",
		intervalo = 8,
		velocidad = 5,
		requisitoRebirths = 6,
		pesos = {
			epico = 55,
			legendario = 32,
			mitico = 12,
			secreto = 1,
		},
		color = Color3.fromRGB(120, 170, 255),
		anunciarDesde = "mitico",
	},
}

return Cintas
