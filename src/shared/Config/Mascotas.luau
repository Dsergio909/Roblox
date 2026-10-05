--!strict
--[[
	Config/Mascotas
	Los Bichitos de la Huerta: mascotas que te siguen y suben tu INGRESO (nada más).

	⚠️ Reglas (ver docs/GAME_DESIGN.md §8.7):
	  - Los huevos se compran con DINERO DEL JUEGO y muestran la probabilidad de CADA
	    bichito antes de comprar (las mismas que usa el servidor).
	  - Las mascotas no ayudan a robar ni a evitar robos: solo dan bonus de ingreso, con tope.
	  - No hay huevos que se compren con Robux.

	Mascota:
	  id, nombre, icono (emoji para la UI), rareza (id de Config/Rarezas)
	  bonus        ingreso extra (0.05 = +5 %), se SUMA con los demás bonus aditivos
	  color/color2 colores del modelo placeholder
	  forma        "gusano" | "bicho" | "volador" (cómo se dibuja el placeholder)

	Huevo:
	  precio en dinero del juego, requisitoRebirths, y pesos POR MASCOTA (la probabilidad de
	  cada una es su peso / la suma).

	Modelo real de una mascota: ReplicatedStorage > Modelos > Mascotas > <id> (Model con
	PrimaryPart). Ver docs/ASSETS_PENDIENTES.md.
]]

export type Mascota = {
	id: string,
	nombre: string,
	icono: string,
	rareza: string,
	bonus: number,
	color: Color3,
	color2: Color3,
	forma: string,
}

export type Huevo = {
	id: string,
	nombre: string,
	icono: string,
	color: Color3,
	precio: number,
	requisitoRebirths: number,
	pesos: { [string]: number },
}

local function M(mascota: Mascota): Mascota
	return mascota
end
local function H(huevo: Huevo): Huevo
	return huevo
end

local Mascotas = {
	LISTA = {
		M({
			id = "gusanito",
			nombre = "Gusanito Glotón",
			icono = "🐛",
			rareza = "comun",
			bonus = 0.02,
			color = Color3.fromRGB(140, 220, 90),
			color2 = Color3.fromRGB(90, 160, 60),
			forma = "gusano",
		}),
		M({
			id = "mariquita",
			nombre = "Mariquita Puntitos",
			icono = "🐞",
			rareza = "comun",
			bonus = 0.02,
			color = Color3.fromRGB(230, 40, 40),
			color2 = Color3.fromRGB(25, 25, 25),
			forma = "bicho",
		}),
		M({
			id = "caracol",
			nombre = "Caracol Turbo",
			icono = "🐌",
			rareza = "pococomun",
			bonus = 0.03,
			color = Color3.fromRGB(205, 165, 105),
			color2 = Color3.fromRGB(150, 100, 60),
			forma = "gusano",
		}),
		M({
			id = "hormiga",
			nombre = "Hormiga Forzuda",
			icono = "🐜",
			rareza = "pococomun",
			bonus = 0.03,
			color = Color3.fromRGB(120, 60, 40),
			color2 = Color3.fromRGB(70, 35, 25),
			forma = "bicho",
		}),
		M({
			id = "abejita",
			nombre = "Abejita Zumbona",
			icono = "🐝",
			rareza = "raro",
			bonus = 0.05,
			color = Color3.fromRGB(255, 210, 40),
			color2 = Color3.fromRGB(30, 30, 30),
			forma = "volador",
		}),
		M({
			id = "mariposa",
			nombre = "Mariposa Pétalo",
			icono = "🦋",
			rareza = "raro",
			bonus = 0.05,
			color = Color3.fromRGB(120, 160, 255),
			color2 = Color3.fromRGB(255, 150, 220),
			forma = "volador",
		}),
		M({
			id = "grillo",
			nombre = "Grillo Cantor",
			icono = "🦗",
			rareza = "epico",
			bonus = 0.08,
			color = Color3.fromRGB(90, 200, 90),
			color2 = Color3.fromRGB(40, 120, 40),
			forma = "bicho",
		}),
		M({
			id = "luciernaga",
			nombre = "Luciérnaga Lumi",
			icono = "✨",
			rareza = "epico",
			bonus = 0.08,
			color = Color3.fromRGB(255, 255, 140),
			color2 = Color3.fromRGB(60, 60, 40),
			forma = "volador",
		}),
		M({
			id = "colibri",
			nombre = "Colibrí Relámpago",
			icono = "🐦",
			rareza = "legendario",
			bonus = 0.12,
			color = Color3.fromRGB(60, 220, 200),
			color2 = Color3.fromRGB(240, 60, 120),
			forma = "volador",
		}),
		M({
			id = "topo",
			nombre = "Topo Excavador",
			icono = "🐹",
			rareza = "legendario",
			bonus = 0.12,
			color = Color3.fromRGB(110, 90, 80),
			color2 = Color3.fromRGB(255, 170, 170),
			forma = "bicho",
		}),
		M({
			id = "dragoncito",
			nombre = "Dragoncito de Semilla",
			icono = "🐉",
			rareza = "mitico",
			bonus = 0.2,
			color = Color3.fromRGB(80, 200, 120),
			color2 = Color3.fromRGB(255, 220, 80),
			forma = "volador",
		}),
		M({
			id = "fenix",
			nombre = "Fénix de Manzana",
			icono = "🔥",
			rareza = "secreto",
			bonus = 0.3,
			color = Color3.fromRGB(255, 120, 40),
			color2 = Color3.fromRGB(255, 220, 60),
			forma = "volador",
		}),
	} :: { Mascota },

	HUEVOS = {
		H({
			id = "huerta",
			nombre = "Huevo de Huerta",
			icono = "🥚",
			color = Color3.fromRGB(240, 230, 200),
			precio = 2500,
			requisitoRebirths = 0,
			pesos = {
				gusanito = 35,
				mariquita = 35,
				caracol = 12,
				hormiga = 12,
				abejita = 3,
				mariposa = 2.5,
				grillo = 0.4,
				luciernaga = 0.1,
			},
		}),
		H({
			id = "dorado",
			nombre = "Huevo Dorado",
			icono = "🟡",
			color = Color3.fromRGB(255, 200, 50),
			precio = 750000,
			requisitoRebirths = 1,
			pesos = {
				caracol = 25,
				hormiga = 25,
				abejita = 18,
				mariposa = 18,
				grillo = 6,
				luciernaga = 6,
				colibri = 1,
				topo = 0.9,
				dragoncito = 0.1,
			},
		}),
		H({
			id = "celestial",
			nombre = "Huevo Celestial",
			icono = "🌌",
			color = Color3.fromRGB(150, 120, 255),
			precio = 250000000,
			requisitoRebirths = 4,
			pesos = {
				grillo = 30,
				luciernaga = 30,
				colibri = 16,
				topo = 16,
				dragoncito = 6.5,
				fenix = 1.5,
			},
		}),
	} :: { Huevo },

	-- Cuántas mascotas puedes llevar equipadas a la vez.
	ESPACIOS_BASE = 2,
	ESPACIOS_POR_REBIRTH = { 2, 5 }, -- cada rebirth de la lista suma un espacio
	ESPACIOS_PASE = 2, -- Game Pass "Mascotas Extra" (Config/Productos)
	BONUS_MAXIMO = 0.6, -- tope del bonus de ingreso de todas las mascotas juntas (+60 %)
	INVENTARIO_MAXIMO = 60,

	-- Dinero que recibes al liberar una mascota (por rareza).
	LIBERAR = {
		comun = 300,
		pococomun = 800,
		raro = 4000,
		epico = 60000,
		legendario = 400000,
		mitico = 4000000,
		secreto = 40000000,
	} :: { [string]: number },

	-- Estas rarezas se anuncian a todo el servidor al salir de un huevo.
	ANUNCIAR_DESDE = 6, -- orden de rareza (6 = Mítico)
}

return table.freeze(Mascotas)
