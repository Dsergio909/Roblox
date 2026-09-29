--!strict
--[[
	Config/Sets
	Colecciones de Crunchis. Completar un set (tener cada uno al menos una vez) da una
	recompensa permanente que NO se pierde con el rebirth.

	Campos:
	  id       identificador (el campo "set" de cada Crunchi apunta aquí)
	  nombre   texto visible
	  bonus    ingreso extra permanente (0.03 = +3 %)
	  titulo   título que el jugador puede mostrar sobre su cabeza
]]

export type Set = {
	id: string,
	nombre: string,
	bonus: number,
	titulo: string,
}

local Sets: { Set } = {
	{ id = "caras_locas", nombre = "Caras Locas", bonus = 0.03, titulo = "Coleccionista de Caras" },
	{ id = "huerto", nombre = "Huerto", bonus = 0.03, titulo = "Rey del Huerto" },
	{ id = "obreros", nombre = "Obreros", bonus = 0.03, titulo = "Jefe de Obra" },
	{ id = "aventureros", nombre = "Aventureros", bonus = 0.03, titulo = "Gran Explorador" },
	{ id = "explosivos", nombre = "Explosivos", bonus = 0.03, titulo = "Experto en Chispas" },
}

return Sets
