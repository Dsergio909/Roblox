--!strict
--[[
	Logica/CatalogoPuro
	Construye índices rápidos (por id, por rareza, por set...) a partir de las tablas de
	Config y VALIDA que la configuración tenga sentido (ids repetidos, rarezas que no
	existen, precios negativos...). Si hay un error de configuración, el juego avisa al
	arrancar en vez de fallar a mitad de una partida.

	Módulo puro (sin Roblox): recibe las tablas de Config como parámetros. Se usa desde
	Shared/Catalogo (en el juego) y desde tests/ (fuera de Studio).
]]

local CatalogoPuro = {}

-- Tipos mínimos (coinciden con los de Config/*; solo los campos que se usan aquí).
export type Rareza = { id: string, nombre: string, orden: number, color: Color3, escala: number, anunciar: boolean }
export type Mutacion = {
	id: string,
	nombre: string,
	mult: number,
	peso: number,
	color: Color3?,
	material: string,
	neon: boolean,
}
export type SetDef = { id: string, nombre: string, bonus: number, titulo: string }
export type Pieza = {
	forma: string,
	tamano: Vector3,
	posicion: Vector3,
	rotacion: Vector3?,
	color: Color3,
	material: string?,
	transparencia: number?,
}
export type Crunchi = {
	id: string,
	nombre: string,
	rareza: string,
	ingreso: number,
	precio: number,
	set: string,
	descripcion: string,
	escala: number?,
	ojos: string?,
	boca: string?,
	piezas: { Pieza }?,
}
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

export type Catalogo = {
	rarezas: { Rareza },
	rareza: { [string]: Rareza },
	mutaciones: { Mutacion },
	mutacion: { [string]: Mutacion },
	pesosMutacion: { [string]: number },
	sets: { SetDef },
	set: { [string]: SetDef },
	crunchis: { Crunchi },
	crunchi: { [string]: Crunchi },
	porRareza: { [string]: { Crunchi } },
	porSet: { [string]: { Crunchi } },
	cintas: { Cinta },
	cinta: { [string]: Cinta },
}

local function indexar<T>(
	lista: { T },
	obtenerId: (T) -> string,
	nombreLista: string,
	errores: { string }
): { [string]: T }
	local mapa: { [string]: T } = {}
	for posicion, elemento in lista do
		local id = obtenerId(elemento)
		if mapa[id] ~= nil then
			table.insert(errores, `{nombreLista}: el id "{id}" está repetido (posición {posicion})`)
		end
		mapa[id] = elemento
	end
	return mapa
end

function CatalogoPuro.Construir(
	rarezas: { Rareza },
	mutaciones: { Mutacion },
	sets: { SetDef },
	crunchis: { Crunchi },
	cintas: { Cinta }
): (Catalogo, { string })
	local errores: { string } = {}

	-- Rarezas ordenadas por "orden"
	local rarezasOrdenadas = table.clone(rarezas)
	table.sort(rarezasOrdenadas, function(a, b)
		return a.orden < b.orden
	end)
	local rarezaPorId = indexar(rarezasOrdenadas, function(r)
		return r.id
	end, "Rarezas", errores)

	local mutacionPorId = indexar(mutaciones, function(m)
		return m.id
	end, "Mutaciones", errores)
	local normal = mutacionPorId["normal"]
	if normal == nil then
		table.insert(errores, 'Mutaciones: falta la mutación "normal"')
	elseif normal.mult ~= 1 then
		table.insert(errores, 'Mutaciones: "normal" debe tener mult = 1')
	end
	local pesosMutacion: { [string]: number } = {}
	for _, mutacion in mutaciones do
		if mutacion.mult <= 0 then
			table.insert(errores, `Mutaciones: "{mutacion.id}" tiene mult <= 0`)
		end
		pesosMutacion[mutacion.id] = mutacion.peso
	end

	local setPorId = indexar(sets, function(s)
		return s.id
	end, "Sets", errores)

	local crunchiPorId = indexar(crunchis, function(c)
		return c.id
	end, "Crunchis", errores)

	local porRareza: { [string]: { Crunchi } } = {}
	local porSet: { [string]: { Crunchi } } = {}
	for _, rareza in rarezasOrdenadas do
		porRareza[rareza.id] = {}
	end
	for _, set in sets do
		porSet[set.id] = {}
	end

	for _, crunchi in crunchis do
		if string.match(crunchi.id, "^[a-z0-9_]+$") == nil then
			table.insert(errores, `Crunchis: el id "{crunchi.id}" solo puede tener minúsculas, números y _`)
		end
		if rarezaPorId[crunchi.rareza] == nil then
			table.insert(errores, `Crunchis: "{crunchi.id}" tiene una rareza que no existe: "{crunchi.rareza}"`)
		else
			table.insert(porRareza[crunchi.rareza], crunchi)
		end
		if setPorId[crunchi.set] == nil then
			table.insert(errores, `Crunchis: "{crunchi.id}" tiene un set que no existe: "{crunchi.set}"`)
		else
			table.insert(porSet[crunchi.set], crunchi)
		end
		if not (crunchi.ingreso > 0) then
			table.insert(errores, `Crunchis: "{crunchi.id}" debe tener ingreso > 0`)
		end
		if not (crunchi.precio > 0) then
			table.insert(errores, `Crunchis: "{crunchi.id}" debe tener precio > 0`)
		end
	end

	for _, lista in porRareza do
		table.sort(lista, function(a, b)
			return a.precio < b.precio
		end)
	end

	local cintaPorId = indexar(cintas, function(c)
		return c.id
	end, "Cintas", errores)
	for _, cinta in cintas do
		if not (cinta.intervalo > 0) or not (cinta.velocidad > 0) then
			table.insert(errores, `Cintas: "{cinta.id}" necesita intervalo y velocidad > 0`)
		end
		local hayPeso = false
		for rarezaId, peso in cinta.pesos do
			if rarezaPorId[rarezaId] == nil then
				table.insert(errores, `Cintas: "{cinta.id}" usa una rareza que no existe: "{rarezaId}"`)
			elseif peso > 0 then
				hayPeso = true
				if #porRareza[rarezaId] == 0 then
					table.insert(
						errores,
						`Cintas: "{cinta.id}" puede sacar "{rarezaId}" pero no hay Crunchis de esa rareza`
					)
				end
			end
		end
		if rarezaPorId[cinta.anunciarDesde] == nil then
			table.insert(errores, `Cintas: "{cinta.id}" tiene anunciarDesde con una rareza que no existe`)
		end
		if not hayPeso then
			table.insert(errores, `Cintas: "{cinta.id}" no tiene ninguna rareza con peso > 0`)
		end
	end

	local catalogo: Catalogo = {
		rarezas = rarezasOrdenadas,
		rareza = rarezaPorId,
		mutaciones = mutaciones,
		mutacion = mutacionPorId,
		pesosMutacion = pesosMutacion,
		sets = sets,
		set = setPorId,
		crunchis = crunchis,
		crunchi = crunchiPorId,
		porRareza = porRareza,
		porSet = porSet,
		cintas = cintas,
		cinta = cintaPorId,
	}
	return catalogo, errores
end

-- Ingreso por segundo (sin bonus) y precio de un Crunchi con mutación.
function CatalogoPuro.Valor(catalogo: Catalogo, crunchiId: string, mutacionId: string): (number, number)
	local crunchi = catalogo.crunchi[crunchiId]
	if crunchi == nil then
		return 0, 0
	end
	local mutacion = catalogo.mutacion[mutacionId]
	local mult = if mutacion then mutacion.mult else 1
	return crunchi.ingreso * mult, math.floor(crunchi.precio * mult)
end

-- Orden numérico de la rareza de un Crunchi (1 = común). 0 si no existe.
function CatalogoPuro.OrdenDe(catalogo: Catalogo, crunchiId: string): number
	local crunchi = catalogo.crunchi[crunchiId]
	if crunchi == nil then
		return 0
	end
	local rareza = catalogo.rareza[crunchi.rareza]
	return if rareza then rareza.orden else 0
end

--[[
	Pesos de mutación de canastas, semillas y Almacén. Son FIJOS (los eventos solo cambian
	las cintas), así las probabilidades que se muestran antes de abrir siempre son las
	reales. `bonus` multiplica todas las mutaciones que no son "normal" (semillas).
]]
function CatalogoPuro.PesosMutacionFijos(catalogo: Catalogo, bonus: number?): { [string]: number }
	local pesos = table.clone(catalogo.pesosMutacion)
	if bonus and bonus ~= 1 then
		for clave, peso in pesos do
			if clave ~= "normal" then
				pesos[clave] = peso * bonus
			end
		end
	end
	return pesos
end

return CatalogoPuro
