--!strict
--[[
	Logica/Laseres
	Dónde está cada láser del Almacén FrutaMax y si una persona lo toca. Módulo puro (sin
	Roblox), probado en tests/.

	El servidor (para decidir si tocaste un láser) y el cliente (para dibujarlos) usan esta
	MISMA fórmula con el reloj del servidor, así los dos ven los láseres en el mismo lugar.

	Coordenadas del pasillo:
	  avance  studs desde la puerta hacia la bodega
	  lado    studs desde el centro del pasillo (negativo = un lado, positivo = el otro)
]]

export type Laser = { z: number, amplitud: number, velocidad: number, fase: number }

local Laseres = {}

local DOS_PI = 2 * math.pi
Laseres.GROSOR = 0.5 -- grosor de la cortina de luz (a lo largo del pasillo)
Laseres.MEDIO_JUGADOR = 1 -- medio ancho de un personaje
Laseres.MEDIO_FONDO_JUGADOR = 0.5 -- medio grosor de un personaje

-- Posición lateral del centro del láser en el segundo t (reloj del servidor).
function Laseres.Lado(laser: Laser, t: number): number
	return laser.amplitud * math.sin(DOS_PI * laser.velocidad * t + laser.fase)
end

-- ¿Una persona en (avance, lado) toca el láser en el segundo t?
-- `holgura` achica la zona peligrosa a favor del jugador (latencia de internet).
function Laseres.Toca(laser: Laser, t: number, avance: number, lado: number, ancho: number, holgura: number): boolean
	local margenAvance = Laseres.GROSOR / 2 + Laseres.MEDIO_FONDO_JUGADOR - holgura
	if math.abs(avance - laser.z) >= margenAvance then
		return false
	end
	return math.abs(lado - Laseres.Lado(laser, t)) < ancho / 2 + Laseres.MEDIO_JUGADOR - holgura
end

--[[
	¿La persona tocó el láser al moverse de (t0, avance0, lado0) a (t1, avance1, lado1)?
	Revisa el TRAMO completo y no solo el punto final: si el servidor recibe la posición
	pocas veces por segundo, alguien que corre podría "saltarse" la cortina entre dos
	muestras sin tocarla.
]]
function Laseres.Cruza(
	laser: Laser,
	t0: number,
	avance0: number,
	lado0: number,
	t1: number,
	avance1: number,
	lado1: number,
	ancho: number,
	holgura: number
): boolean
	local margen = Laseres.GROSOR / 2 + Laseres.MEDIO_FONDO_JUGADOR - holgura
	local desde, hasta = 0, 1
	local delta = avance1 - avance0
	if math.abs(delta) > 1e-6 then
		local a = (laser.z - margen - avance0) / delta
		local b = (laser.z + margen - avance0) / delta
		desde = math.max(0, math.min(a, b))
		hasta = math.min(1, math.max(a, b))
		if desde > hasta then
			return false -- el tramo no pasa por la cortina
		end
	elseif math.abs(avance0 - laser.z) >= margen then
		return false
	end
	local MUESTRAS = 4
	for i = 0, MUESTRAS do
		local s = desde + (hasta - desde) * i / MUESTRAS
		local t = t0 + (t1 - t0) * s
		local avance = avance0 + delta * s
		local lado = lado0 + (lado1 - lado0) * s
		if Laseres.Toca(laser, t, avance, lado, ancho, holgura) then
			return true
		end
	end
	return false
end

-- Índice del primer láser tocado en el tramo, o nil.
function Laseres.Tocado(
	lista: { Laser },
	t0: number,
	avance0: number,
	lado0: number,
	t1: number,
	avance1: number,
	lado1: number,
	ancho: number,
	holgura: number
): number?
	for indice, laser in lista do
		if Laseres.Cruza(laser, t0, avance0, lado0, t1, avance1, lado1, ancho, holgura) then
			return indice
		end
	end
	return nil
end

-- ¿Siempre queda un hueco para pasar? (el láser no tapa todo el pasillo en ningún momento)
function Laseres.DejaHueco(laser: Laser, anchoPasillo: number, ancho: number): boolean
	-- En el centro de su recorrido, el láser deja libres los dos lados:
	local libre = anchoPasillo / 2 - ancho / 2
	-- En los extremos, deja libre el lado opuesto:
	local libreExtremo = anchoPasillo / 2 + laser.amplitud - ancho / 2
	return libre >= 2 * Laseres.MEDIO_JUGADOR + 0.5 and libreExtremo >= 2 * Laseres.MEDIO_JUGADOR + 0.5
end

return Laseres
