--!strict
--[[
	Config/Almacen
	El Almacén FrutaMax: ROBAR SIN VÍCTIMAS. Entras al edificio de FrutaMax, cruzas un
	pasillo de láseres de escáner sin tocarlos y sacas una caja de la bodega. Adentro hay
	un Crunchi al azar (probabilidades visibles en el cartel de la entrada).

	Se desbloquea con Rebirth 1. Tiene tiempo de espera entre intentos.
]]

-- Cada láser es una cortina roja vertical (del piso al techo) de ANCHO_LASER studs que
-- se desliza de lado a lado. Para pasar hay que esperar a que deje libre tu lado.
-- Posición lateral en el segundo t:  amplitud × sin(2π × velocidad × t + fase)
-- (la misma fórmula en el servidor y en el cliente: ver Logica/Laseres).
export type Laser = {
	z: number, -- a cuántos studs de la entrada está (a lo largo del pasillo)
	amplitud: number, -- cuánto se aleja del centro hacia cada lado
	velocidad: number, -- vueltas por segundo
	fase: number, -- desfase (radianes) para que no se muevan todos juntos
}

local Almacen = {
	REQUISITO_REBIRTHS = 1,
	COOLDOWN_SEGUNDOS = 10 * 60, -- tras sacar una caja (se guarda: salir y entrar no lo reinicia)
	REINTENTO_SEGUNDOS = 15, -- tras tocar un láser: fallar no castiga, solo esperas un poco
	TIEMPO_MAXIMO = 90, -- segundos para llegar a la bodega desde que entras
	TIEMPO_MINIMO = 3, -- nadie cruza el pasillo más rápido (antitrampas)

	PESOS = { raro = 50, epico = 35, legendario = 12, mitico = 2.8, secreto = 0.2 },

	-- Edificio (al oeste de la avenida). La puerta mira a la avenida (este) y el pasillo
	-- avanza hacia el oeste hasta la bodega.
	ENTRADA = Vector3.new(-172, 0.6, 0), -- centro de la puerta, a nivel del piso
	LARGO_PASILLO = 56, -- de la puerta a la bodega
	LARGO_BODEGA = 12, -- sala del fondo con la caja fuerte
	ANCHO_PASILLO = 14,
	ALTO = 10, -- paredes más altas que un salto: solo se entra por la puerta

	LASERES = {
		{ z = 10, amplitud = 3.5, velocidad = 0.3, fase = 0 },
		{ z = 18, amplitud = 3.5, velocidad = 0.4, fase = 1.2 },
		{ z = 26, amplitud = 3.5, velocidad = 0.5, fase = 2.1 },
		{ z = 34, amplitud = 3.5, velocidad = 0.55, fase = 0.6 },
		{ z = 42, amplitud = 3.5, velocidad = 0.65, fase = 3 },
		{ z = 50, amplitud = 3.5, velocidad = 0.75, fase = 1.7 },
	} :: { Laser },
	ANCHO_LASER = 7, -- ancho de cada cortina (a lo ancho del pasillo)
	HOLGURA = 0.35, -- studs de tolerancia a favor del jugador (latencia de internet)
}

return table.freeze(Almacen)
