--!strict
--[[
	Config/Consumibles
	Objetos de un solo uso que se guardan en la 🎒 Mochila. Se compran con DINERO DEL JUEGO
	(precio en minutos de tu ingreso, para que nunca queden baratos ni carísimos) o se ganan
	en misiones y en el Pase.

	⚠️ Ninguno ayuda a robar ni a evitar robos (nada de velocidad, saltos ni escudos).

	efecto:
	  ingreso    multiplica tu ingreso (valor) durante `duracion` segundos; se acumula hasta
	             `maxDuracion`
	  autocobro  cobra tus pedestales solo durante `duracion` segundos (se acumula)
	  macetero   reduce el tiempo que le falta a tu planta (valor = fracción que queda: 0.5 = la mitad)
	  almacen    quita la espera del Almacén FrutaMax
	  confeti    explosión de confeti que ven todos los de alrededor (solo diversión)
]]

export type Consumible = {
	id: string,
	nombre: string,
	icono: string,
	descripcion: string,
	efecto: string,
	valor: number,
	duracion: number,
	maxDuracion: number,
	precioMinutos: number, -- precio = estos minutos de tu ingreso...
	precioMinimo: number, -- ...pero nunca menos que esto
	requisitoRebirths: number,
}

local function C(consumible: Consumible): Consumible
	return consumible
end

local Consumibles = {
	LISTA = {
		C({
			id = "jugo_turbo",
			nombre = "Jugo Turbo",
			icono = "🧃",
			descripcion = "+50 % de ingreso por 10 minutos. Se acumula hasta 1 hora.",
			efecto = "ingreso",
			valor = 1.5,
			duracion = 600,
			maxDuracion = 3600,
			precioMinutos = 4,
			precioMinimo = 300,
			requisitoRebirths = 0,
		}),
		C({
			id = "iman",
			nombre = "Imán de Monedas",
			icono = "🧲",
			descripcion = "Cobra tus pedestales solo durante 10 minutos.",
			efecto = "autocobro",
			valor = 0,
			duracion = 600,
			maxDuracion = 3600,
			precioMinutos = 2,
			precioMinimo = 150,
			requisitoRebirths = 0,
		}),
		C({
			id = "fertilizante",
			nombre = "Fertilizante Mágico",
			icono = "🧪",
			descripcion = "Tu planta del macetero crece al instante la mitad de lo que le falta.",
			efecto = "macetero",
			valor = 0.5,
			duracion = 0,
			maxDuracion = 0,
			precioMinutos = 5,
			precioMinimo = 400,
			requisitoRebirths = 0,
		}),
		C({
			id = "reloj_almacen",
			nombre = "Reloj del Almacén",
			icono = "⏱️",
			descripcion = "Quita la espera del Almacén FrutaMax: ¡otra caja ya!",
			efecto = "almacen",
			valor = 0,
			duracion = 0,
			maxDuracion = 0,
			precioMinutos = 8,
			precioMinimo = 2000,
			requisitoRebirths = 1,
		}),
		C({
			id = "confeti",
			nombre = "Bomba de Confeti",
			icono = "🎉",
			descripcion = "¡Celebra! Una explosión de confeti que ven todos a tu alrededor.",
			efecto = "confeti",
			valor = 0,
			duracion = 0,
			maxDuracion = 0,
			precioMinutos = 0.5,
			precioMinimo = 50,
			requisitoRebirths = 0,
		}),
	} :: { Consumible },

	MAXIMO_POR_OBJETO = 99,
	COMPRA_MAXIMA = 10, -- cuántos se pueden comprar de una vez
	ESPERA_CONFETI = 5, -- segundos entre bombas de confeti (para que no se abuse)
}

return table.freeze(Consumibles)
