--!strict
--[[
	Config/Clasificacion
	Tablas de clasificación GLOBALES (todos los servidores) del "Salón de la Fama", junto a
	la entrada del Almacén. Usan OrderedDataStore (solo funcionan con el juego publicado y,
	en Studio, con "Enable Studio Access to API Services").

	El puntaje de cada tabla sale de los datos del jugador:
	  rebirths   cantidad de rebirths
	  robos      robos exitosos
	  indice     entradas del Índice (Crunchis + variantes con mutación)
]]

export type Tabla = { id: string, titulo: string, color: Color3 }

local function T(tabla: Tabla): Tabla
	return tabla
end

local Clasificacion = {
	TABLAS = {
		T({ id = "rebirths", titulo = "🔁 Top Rebirths", color = Color3.fromRGB(180, 120, 255) }),
		T({ id = "robos", titulo = "🦹 Top Robos", color = Color3.fromRGB(255, 110, 110) }),
		T({ id = "indice", titulo = "📖 Top Coleccionistas", color = Color3.fromRGB(110, 200, 255) }),
	},
	CANTIDAD = 10, -- puestos visibles en cada cartel
	LEER_CADA = 180, -- segundos entre actualizaciones de los carteles
	SUBIR_CADA = 300, -- segundos entre subidas del puntaje de cada jugador (y al salir)
	PREFIJO_DATASTORE = "CrunchHeist_Top_", -- + id de la tabla

	-- Carteles: al noroeste de la avenida, mirando hacia ella (+X).
	POSICION = Vector3.new(-150, 0, 22), -- pie del primer cartel
	SEPARACION = 13, -- entre carteles (hacia +Z)
}

return table.freeze(Clasificacion)
