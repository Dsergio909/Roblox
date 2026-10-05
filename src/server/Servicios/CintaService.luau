--!strict
--[[
	CintaService
	Hace aparecer Crunchis en las cintas y procesa las compras.

	Decisión de rendimiento: el servidor NO mueve modelos por la cinta. Solo anuncia
	"apareció el Crunchi #57 en el segundo T". Cada cliente dibuja y mueve su propia copia
	(suave y sin costo de red), y el servidor calcula dónde está cada uno con la misma
	fórmula cuando alguien intenta comprarlo:
	    posición = inicio + dirección × velocidad × (ahora − T)

	Compra (todo validado en el servidor): el Crunchi existe, el jugador está cerca, tiene
	el rebirth requerido, tiene dinero y un pedestal libre.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type ItemCinta = Tipos.ItemCinta

local DISTANCIA_COMPRA = 16 -- studs (con margen por la latencia)
local MAX_ITEMS_POR_CINTA = 60

local CintaService = {
	-- (jugador, crunchi: CrunchiGuardado, precio)
	Comprado = Senal.nueva(),
	-- (item: ItemCinta)
	Aparecio = Senal.nueva(),
}

local items: { [number]: ItemCinta } = {}
local siguienteId = 0
local proximaAparicion: { [string]: number } = {}
local aleatorio = Random.new()

-- Modificadores temporales (eventos, "Suerte del servidor"): nombre → función.
type ModRareza = (cintaId: string) -> { [string]: number }?
type ModMutacion = () -> { [string]: number }?
local modificadoresRareza: { [string]: ModRareza } = {}
local modificadoresMutacion: { [string]: ModMutacion } = {}

local function numeroAleatorio(): number
	return aleatorio:NextNumber()
end

----------------------------------------------------------------------------- probabilidades

function CintaService.RegistrarModificadorRareza(nombre: string, fn: ModRareza)
	modificadoresRareza[nombre] = fn
end

function CintaService.RegistrarModificadorMutacion(nombre: string, fn: ModMutacion)
	modificadoresMutacion[nombre] = fn
end

-- Pesos de rareza vigentes AHORA para una cinta (base × modificadores activos).
-- Los mismos que ve el jugador en la UI de probabilidades.
function CintaService.PesosRareza(cintaId: string): Azar.Pesos
	local cinta = Catalogo.datos.cinta[cintaId]
	local pesos: Azar.Pesos = table.clone(cinta.pesos)
	for _, fn in modificadoresRareza do
		local ok, factores = pcall(fn, cintaId)
		if ok and factores then
			pesos = Azar.Multiplicar(pesos, factores)
		end
	end
	return pesos
end

function CintaService.PesosMutacion(): Azar.Pesos
	local pesos: Azar.Pesos = table.clone(Catalogo.datos.pesosMutacion)
	for _, fn in modificadoresMutacion do
		local ok, factores = pcall(fn)
		if ok and factores then
			-- Una mutación con peso base 0 (p. ej. Radiactivo) puede activarse con un
			-- factor que sea un peso absoluto: usamos max(peso × factor, factor si peso = 0).
			for clave, factor in factores do
				local base = pesos[clave] or 0
				pesos[clave] = if base > 0 then base * factor else factor
			end
		end
	end
	return pesos
end

----------------------------------------------------------------------------- aparición

local function posicionDe(item: ItemCinta, momento: number): Vector3?
	local cinta = Catalogo.datos.cinta[item.cinta]
	return MapaService.PosicionEnCinta(item.cinta, cinta.velocidad, momento - item.t0)
end

local function vigente(item: ItemCinta, momento: number): boolean
	local cinta = Catalogo.datos.cinta[item.cinta]
	local mapa = MapaService.Cintas[item.cinta]
	if cinta == nil or mapa == nil then
		return false
	end
	return (momento - item.t0) * cinta.velocidad < mapa.largo
end

local function contarEnCinta(cintaId: string): number
	local cantidad = 0
	for _, item in items do
		if item.cinta == cintaId then
			cantidad += 1
		end
	end
	return cantidad
end

-- Pone un Crunchi en una cinta. Si no se indica cuál, se sortea con las probabilidades.
function CintaService.Aparecer(cintaId: string, crunchiId: string?, mutacionId: string?): ItemCinta?
	local cinta = Catalogo.datos.cinta[cintaId]
	if cinta == nil or MapaService.Cintas[cintaId] == nil then
		return nil
	end
	if contarEnCinta(cintaId) >= MAX_ITEMS_POR_CINTA then
		return nil
	end

	local elegido = crunchiId
	if elegido == nil then
		local rarezaId = Azar.Ponderado(CintaService.PesosRareza(cintaId), numeroAleatorio)
		local candidatos = if rarezaId then Catalogo.datos.porRareza[rarezaId] else nil
		local crunchi = if candidatos then Azar.Elegir(candidatos, numeroAleatorio) else nil
		if crunchi == nil then
			return nil
		end
		elegido = crunchi.id
	end
	if elegido == nil or Catalogo.datos.crunchi[elegido] == nil then
		return nil
	end
	local mutacion = mutacionId or Azar.Ponderado(CintaService.PesosMutacion(), numeroAleatorio) or "normal"

	siguienteId += 1
	local item: ItemCinta = {
		id = siguienteId,
		cinta = cintaId,
		crunchi = elegido,
		mut = mutacion,
		t0 = Reloj.Ahora(),
	}
	items[item.id] = item
	RedServidor.EnviarATodos("CintaNuevo", item)

	local rareza = Catalogo.RarezaDe(elegido)
	local desde = Catalogo.datos.rareza[cinta.anunciarDesde]
	if rareza and desde and rareza.orden >= desde.orden then
		RedServidor.EnviarATodos(
			"Anuncio",
			`¡Un Crunchi {string.upper(rareza.nombre)} apareció en la {cinta.nombre}!`,
			rareza.id
		)
	end
	CintaService.Aparecio:Disparar(item)
	return item
end

local function quitar(itemId: number, compradorUserId: number?)
	if items[itemId] then
		items[itemId] = nil
		RedServidor.EnviarATodos("CintaRemovido", itemId, compradorUserId)
	end
end

local function ciclo()
	local momento = Reloj.Ahora()
	-- Limpiar los que ya llegaron al final (los clientes los quitan solos).
	for id, item in items do
		if not vigente(item, momento) then
			items[id] = nil
		end
	end
	-- Hacer aparecer nuevos según el intervalo de cada cinta (aunque no haya nadie: así
	-- quien entre encuentra la cinta llena; sin clientes no cuesta red).
	for _, cinta in Catalogo.datos.cintas do
		local proxima = proximaAparicion[cinta.id] or 0
		if momento >= proxima then
			proximaAparicion[cinta.id] = momento + cinta.intervalo
			CintaService.Aparecer(cinta.id)
		end
	end
end

----------------------------------------------------------------------------- compra

local function comprar(jugador: Player, itemId: any)
	if type(itemId) ~= "number" then
		return
	end
	local item = items[itemId]
	if item == nil then
		RedServidor.Notificar(jugador, "¡Alguien lo compró primero!", "error")
		return
	end
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	local cinta = Catalogo.datos.cinta[item.cinta]
	if datos.rebirths < cinta.requisitoRebirths then
		RedServidor.Notificar(jugador, `🔒 Necesitas Rebirth {cinta.requisitoRebirths} para comprar aquí`, "error")
		return
	end
	if jugador:GetAttribute("Cargando") == true then
		RedServidor.Notificar(jugador, "¡Primero lleva el Crunchi que cargas a tu base!", "error")
		return
	end

	-- Distancia (horizontal) entre el jugador y el Crunchi, calculada en el servidor.
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	local posicion = posicionDe(item, Reloj.Ahora())
	if not (raiz and raiz:IsA("BasePart")) or posicion == nil then
		return
	end
	local diferencia = raiz.Position - posicion
	if Vector3.new(diferencia.X, 0, diferencia.Z).Magnitude > DISTANCIA_COMPRA then
		RedServidor.Notificar(jugador, "Acércate más para comprarlo", "error")
		return
	end

	-- Pedestal libre o, si la base está llena, el depósito.
	if BaseService.Destino(jugador) == nil then
		RedServidor.Notificar(
			jugador,
			"¡Tu base y tu depósito están llenos! Vende o guarda un Crunchi para hacer espacio.",
			"error"
		)
		return
	end

	local _, precio = Catalogo.Valor(item.crunchi, item.mut)
	if not EconomiaService.Gastar(jugador, precio, AnaliticaService.Tipo.Tienda, item.crunchi) then
		RedServidor.Notificar(
			jugador,
			`Te faltan {Formato.Dinero(precio - EconomiaService.Dinero(jugador))}`,
			"sinDinero"
		)
		return
	end

	-- ¡Comprado!
	quitar(item.id, jugador.UserId)
	datos.stats.comprasCinta += 1
	local crunchi, esNuevo = BaseService.Otorgar(jugador, item.crunchi, item.mut)
	if crunchi == nil then
		-- No debería pasar (revisamos el espacio antes), pero si pasa, devolvemos el dinero.
		EconomiaService.Agregar(jugador, precio, AnaliticaService.Tipo.Tienda, "reembolso")
		return
	end
	if crunchi.lugar == 0 then
		RedServidor.Notificar(jugador, "Tu base está llena: lo guardamos en el depósito 📦", "info")
	end

	RedServidor.Enviar("Efecto", jugador, "Compra", { crunchi = crunchi.id, mut = crunchi.mut, nuevo = esNuevo })
	local rareza = Catalogo.RarezaDe(crunchi.id)
	if rareza and rareza.anunciar then
		RedServidor.EnviarATodos(
			"Anuncio",
			`¡{jugador.DisplayName} compró {Catalogo.NombreCompleto(crunchi.id, crunchi.mut)}!`,
			rareza.id
		)
	end
	CintaService.Comprado:Disparar(jugador, crunchi, precio)
end

----------------------------------------------------------------------------- inicio

function CintaService.Iniciar()
	RedServidor.Escuchar("ComprarCinta", 4, 6, comprar)
	RedServidor.Responder("PedirCinta", 1, 3, function(_jugador: Player)
		local lista: { ItemCinta } = {}
		local momento = Reloj.Ahora()
		for _, item in items do
			if vigente(item, momento) then
				table.insert(lista, item)
			end
		end
		return lista
	end)

	-- Al arrancar, llenamos las cintas como si llevaran un rato funcionando (así el
	-- primer jugador no ve una cinta vacía).
	local momento = Reloj.Ahora()
	for _, cinta in Catalogo.datos.cintas do
		local mapa = MapaService.Cintas[cinta.id]
		if mapa then
			local duracion = mapa.largo / cinta.velocidad
			local t = duracion - cinta.intervalo
			while t > 0 do
				local item = CintaService.Aparecer(cinta.id)
				if item then
					item.t0 = momento - t
				end
				t -= cinta.intervalo
			end
			proximaAparicion[cinta.id] = momento + cinta.intervalo
		end
	end

	Reloj.Cada(0.25, ciclo)
end

-- Para comandos de admin: cuántos Crunchis hay en las cintas.
function CintaService.Cantidad(): number
	local cantidad = 0
	for _ in items do
		cantidad += 1
	end
	return cantidad
end

return CintaService
