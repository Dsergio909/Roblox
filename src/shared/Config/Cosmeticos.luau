--!strict
--[[
	Config/Cosmeticos
	Auras y estelas: ESTATUS visible para todos, sin ninguna ventaja de juego.

	Cómo se consiguen (campo "fuente"):
	  "dinero"    se compran con dinero del juego (precioDinero) → los jugadores gratis
	              también tienen estatus
	  "pase:X"    se tienen si compraste el Game Pass X (Config/Productos.PASES)
	  "premio"    se ganan (hitos del Índice, Pase de Temporada...)

	Rendimiento: cada cliente dibuja los cosméticos de los demás solo si están cerca, y el
	"Modo ahorro" los desactiva (ver CosmeticosController).
]]

export type Cosmetico = {
	id: string,
	tipo: string, -- "aura" | "estela"
	nombre: string,
	color: Color3,
	color2: Color3?,
	arcoiris: boolean?,
	fuente: string,
	precioDinero: number?,
}

local function C(cosmetico: Cosmetico): Cosmetico
	return cosmetico
end

local Cosmeticos: { Cosmetico } = {
	-- Con dinero del juego
	C({
		id = "aura_brillo",
		tipo = "aura",
		nombre = "Aura Brillante",
		color = Color3.fromRGB(255, 255, 200),
		fuente = "dinero",
		precioDinero = 25000,
	}),
	C({
		id = "estela_verde",
		tipo = "estela",
		nombre = "Estela Manzana",
		color = Color3.fromRGB(126, 217, 87),
		color2 = Color3.fromRGB(40, 120, 30),
		fuente = "dinero",
		precioDinero = 250000,
	}),
	C({
		id = "aura_azul",
		tipo = "aura",
		nombre = "Aura Eléctrica",
		color = Color3.fromRGB(90, 180, 255),
		fuente = "dinero",
		precioDinero = 5000000,
	}),
	-- Game Passes
	C({
		id = "aura_dorada",
		tipo = "aura",
		nombre = "Aura Dorada (VIP)",
		color = Color3.fromRGB(255, 200, 40),
		fuente = "pase:VIP",
	}),
	C({
		id = "aura_llama",
		tipo = "aura",
		nombre = "Aura Llama Verde",
		color = Color3.fromRGB(120, 255, 60),
		color2 = Color3.fromRGB(20, 120, 20),
		fuente = "pase:AURA_LLAMA",
	}),
	C({
		id = "estela_arcoiris",
		tipo = "estela",
		nombre = "Estela Arcoíris",
		color = Color3.fromRGB(255, 80, 80),
		arcoiris = true,
		fuente = "pase:ESTELA_ARCOIRIS",
	}),
	-- Premios
	C({
		id = "aura_coleccionista",
		tipo = "aura",
		nombre = "Aura del Coleccionista",
		color = Color3.fromRGB(180, 110, 255),
		fuente = "premio",
	}),
	C({
		id = "estela_maestro",
		tipo = "estela",
		nombre = "Estela del Maestro",
		color = Color3.fromRGB(255, 220, 90),
		color2 = Color3.fromRGB(180, 110, 255),
		fuente = "premio",
	}),
	C({
		id = "aura_temporada1",
		tipo = "aura",
		nombre = "Aura de Temporada 1",
		color = Color3.fromRGB(255, 140, 60),
		fuente = "premio",
	}),
	C({
		id = "estela_temporada1",
		tipo = "estela",
		nombre = "Estela de Temporada 1",
		color = Color3.fromRGB(255, 140, 60),
		color2 = Color3.fromRGB(255, 220, 90),
		fuente = "premio",
	}),
	C({
		id = "aura_temporada1_premium",
		tipo = "aura",
		nombre = "Aura Nuclear (Premium T1)",
		color = Color3.fromRGB(140, 255, 60),
		color2 = Color3.fromRGB(255, 255, 255),
		fuente = "premio",
	}),
	C({
		id = "estela_temporada1_premium",
		tipo = "estela",
		nombre = "Estela Cohete (Premium T1)",
		color = Color3.fromRGB(255, 120, 30),
		color2 = Color3.fromRGB(255, 240, 120),
		fuente = "premio",
	}),
}

return Cosmeticos
