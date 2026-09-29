--!strict
--[[
	BaseService
	La base de cada jugador: asignación, pedestales, cobro, venta, cerrojo y escudos.

	Cómo se calcula el dinero de un pedestal (eficiente, sin un bucle por segundo):
	  Cada pedestal guarda  acumulado (dinero ya generado), desde (momento) y tasa ($/s).
	  El dinero actual es:  acumulado + tasa × (ahora − desde)
	  Solo cuando algo cambia (cobrar, cambiar la tasa) se "asienta" el valor. El cliente
	  recibe esos tres números como atributos y calcula él mismo el contador que ve subir.

	Los datos guardados (DatosService) son la fuente de verdad: cada Crunchi guardado tiene
	un "lugar" (número de pedestal). Este servicio solo refleja esos datos en el mundo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigBase = require(Config:WaitForChild("Base"))
local ConfigRobo = require(Config:WaitForChild("Robo"))
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local ModeloCrunchi = require(Shared:WaitForChild("ModeloCrunchi"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))
local Ingreso = require(Shared:WaitForChild("Logica"):WaitForChild("Ingreso"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type CrunchiGuardado = Tipos.CrunchiGuardado

type EstadoPedestal = {
	acumulado: number,
	desde: number,
	tasa: number,
	uid: string?,
	crunchiId: string?,
	mutacion: string?,
	modelo: Model?,
	enRobo: boolean,
	reservado: boolean,
}

export type EstadoBase = {
	jugador: Player,
	mapa: MapaService.BaseMapa,
	pedestales: { EstadoPedestal },
	cerrojoHasta: number,
	revanchaHasta: number,
	escudoHasta: number,
	escudoTipo: string,
	robosSufridos: { number },
	conexiones: { RBXScriptConnection },
}

local BaseService = {
	Cobrado = Senal.nueva(), -- (jugador, cantidad)
	CrunchiColocado = Senal.nueva(), -- (jugador, crunchi: CrunchiGuardado)
	Vendido = Senal.nueva(), -- (jugador, crunchi: CrunchiGuardado, precio)
	IntentoRobo = Senal.nueva(), -- (ladron, dueno, uid)
}

local estados: { [Player]: EstadoBase } = {}
local duenos: { [number]: Player } = {}
local extrasPedestales: { [string]: (Player) -> number } = {}

----------------------------------------------------------------------------- utilidades

local function ahora(): number
	return Reloj.Ahora()
end

local function raizDe(jugador: Player): BasePart?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function buscarGuardado(datos: Tipos.Datos, uid: string): (CrunchiGuardado?, number?)
	for indice, crunchi in datos.crunchis do
		if crunchi.uid == uid then
			return crunchi, indice
		end
	end
	return nil, nil
end

local function asentar(pedestal: EstadoPedestal, momento: number)
	pedestal.acumulado = Ingreso.Acumulado(pedestal.acumulado, pedestal.tasa, pedestal.desde, momento)
	pedestal.desde = momento
end

local function publicarPedestal(estado: EstadoBase, lugar: number)
	local pedestal = estado.pedestales[lugar]
	local modelo = estado.mapa.pedestales[lugar].modelo
	modelo:SetAttribute("Acumulado", pedestal.acumulado)
	modelo:SetAttribute("Desde", pedestal.desde)
	modelo:SetAttribute("Tasa", pedestal.tasa)
	modelo:SetAttribute("Ocupado", pedestal.uid ~= nil)
	modelo:SetAttribute("EnRobo", pedestal.enRobo)
end

local function publicarBase(estado: EstadoBase)
	local modelo = estado.mapa.modelo
	modelo:SetAttribute("CerrojoHasta", estado.cerrojoHasta)
	modelo:SetAttribute("EscudoHasta", estado.escudoHasta)
	modelo:SetAttribute("EscudoTipo", estado.escudoTipo)
	modelo:SetAttribute("RevanchaHasta", estado.revanchaHasta)
end

local function actualizarIngresoTotal(estado: EstadoBase)
	local total = 0
	for _, pedestal in estado.pedestales do
		total += pedestal.tasa
	end
	estado.jugador:SetAttribute("IngresoSeg", total)
end

----------------------------------------------------------------------------- capacidad

-- Otros servicios (p. ej. el Game Pass "Piso Extra") pueden sumar pedestales.
function BaseService.RegistrarPedestalesExtra(nombre: string, proveedor: (Player) -> number)
	extrasPedestales[nombre] = proveedor
end

function BaseService.PedestalesDisponibles(jugador: Player): number
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return 0
	end
	local gratis = math.min(
		ConfigBase.PEDESTALES_MAX_GRATIS,
		ConfigBase.PEDESTALES_INICIALES + datos.rebirths * ConfigBase.PEDESTALES_POR_REBIRTH
	)
	local extra = 0
	for _, proveedor in extrasPedestales do
		local ok, valor = pcall(proveedor, jugador)
		if ok and type(valor) == "number" then
			extra += valor
		end
	end
	return math.min(ConfigBase.PEDESTALES_TOTAL, gratis + extra)
end

function BaseService.Bovedas(rebirths: number): number
	local cantidad = 0
	for _, nivel in ConfigBase.BOVEDAS do
		if rebirths >= nivel.rebirths then
			cantidad = math.max(cantidad, nivel.cantidad)
		end
	end
	return cantidad
end

function BaseService.EsBoveda(jugador: Player, lugar: number): boolean
	local datos = DatosService.Obtener(jugador)
	return datos ~= nil and lugar <= BaseService.Bovedas(datos.rebirths)
end

local function pintarPedestales(mapa: MapaService.BaseMapa, disponibles: number, bovedas: number)
	for indice, pedestal in mapa.pedestales do
		local desbloqueado = indice <= disponibles
		local boveda = indice <= bovedas
		pedestal.pedestal.Transparency = if desbloqueado then 0 else 0.8
		pedestal.pedestal.Color = if boveda then Color3.fromRGB(235, 190, 70) else Color3.fromRGB(225, 225, 232)
		pedestal.boton.Transparency = if desbloqueado then 0 else 1
		pedestal.modelo:SetAttribute("Desbloqueado", desbloqueado)
		pedestal.modelo:SetAttribute("Boveda", boveda)
	end
end

----------------------------------------------------------------------------- consultas

function BaseService.Estado(jugador: Player): EstadoBase?
	return estados[jugador]
end

function BaseService.Duenos(): { [number]: Player }
	return duenos
end

function BaseService.LugarDe(jugador: Player, uid: string): number?
	local estado = estados[jugador]
	if estado == nil then
		return nil
	end
	for lugar, pedestal in estado.pedestales do
		if pedestal.uid == uid then
			return lugar
		end
	end
	return nil
end

-- Primer pedestal desbloqueado, vacío y sin reservar.
function BaseService.LugarLibre(jugador: Player): number?
	local estado = estados[jugador]
	if estado == nil then
		return nil
	end
	local disponibles = BaseService.PedestalesDisponibles(jugador)
	for lugar = 1, disponibles do
		local pedestal = estado.pedestales[lugar]
		if pedestal.uid == nil and not pedestal.reservado then
			return lugar
		end
	end
	return nil
end

function BaseService.Reservar(jugador: Player, lugar: number, reservado: boolean)
	local estado = estados[jugador]
	if estado and estado.pedestales[lugar] then
		estado.pedestales[lugar].reservado = reservado
	end
end

function BaseService.DentroDeSuBase(jugador: Player): boolean
	local estado = estados[jugador]
	local raiz = raizDe(jugador)
	return estado ~= nil and raiz ~= nil and MapaService.DentroDeBase(estado.mapa, raiz.Position)
end

-- ¿Está `objetivo` dentro de la base de `dueno`?
function BaseService.EstaEnBaseDe(objetivo: Player, dueno: Player): boolean
	local estado = estados[dueno]
	local raiz = raizDe(objetivo)
	return estado ~= nil and raiz ~= nil and MapaService.DentroDeBase(estado.mapa, raiz.Position)
end

----------------------------------------------------------------------------- tasas

-- Recalcula el ingreso de todos los pedestales (cuando cambian bonus o multiplicadores).
function BaseService.Recalcular(jugador: Player)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	local multiplicador = EconomiaService.Multiplicador(jugador)
	local momento = ahora()
	for lugar, pedestal in estado.pedestales do
		asentar(pedestal, momento)
		if pedestal.uid and pedestal.crunchiId and not pedestal.enRobo then
			local base = Catalogo.Valor(pedestal.crunchiId, pedestal.mutacion or "normal")
			pedestal.tasa = Ingreso.PorSegundo(base, 1, multiplicador)
		else
			pedestal.tasa = 0
		end
		publicarPedestal(estado, lugar)
	end
	actualizarIngresoTotal(estado)
	estado.jugador:SetAttribute("Multiplicador", multiplicador)
end

----------------------------------------------------------------------------- modelos

local function crearModelo(estado: EstadoBase, lugar: number, crunchi: CrunchiGuardado)
	local pedestalMapa = estado.mapa.pedestales[lugar]
	local modelo = ModeloCrunchi.Crear(crunchi.id, crunchi.mut)
	modelo:PivotTo(pedestalMapa.ancla)
	modelo:SetAttribute("Uid", crunchi.uid)
	modelo:SetAttribute("Lugar", lugar)

	local ingresoBase, precio = Catalogo.Valor(crunchi.id, crunchi.mut)
	local precioVenta = math.floor(precio * ConfigEconomia.VENTA_PORCENTAJE)
	local etiqueta = ModeloCrunchi.CrearEtiqueta(crunchi.id, crunchi.mut, {
		ingresoPorSegundo = ingresoBase,
		distanciaMaxima = 40,
		formatoDinero = Formato.Dinero,
	})
	etiqueta.Parent = modelo

	local cuerpo = modelo.PrimaryPart :: BasePart
	local dueno = estado.jugador
	local uid = crunchi.uid

	-- Dos acciones sobre el mismo Crunchi. El cliente muestra solo la que corresponde
	-- (robar si no es tuyo, vender si es tuyo), y el servidor lo valida igual.
	local robar = Instance.new("ProximityPrompt")
	robar.Name = "Robar"
	robar.ActionText = "Robar"
	robar.ObjectText = Catalogo.NombreCompleto(crunchi.id, crunchi.mut)
	robar.HoldDuration = ConfigRobo.TIEMPO_ROBAR
	robar.MaxActivationDistance = ConfigRobo.DISTANCIA_MAXIMA - 2
	robar.RequiresLineOfSight = false
	robar.KeyboardKeyCode = Enum.KeyCode.E
	robar.Parent = cuerpo
	robar.Triggered:Connect(function(ladron: Player)
		BaseService.IntentoRobo:Disparar(ladron, dueno, uid)
	end)

	local vender = Instance.new("ProximityPrompt")
	vender.Name = "Vender"
	vender.ActionText = `Vender {Formato.Dinero(precioVenta)}`
	vender.ObjectText = Catalogo.NombreCompleto(crunchi.id, crunchi.mut)
	vender.HoldDuration = 1.2
	vender.MaxActivationDistance = 8
	vender.RequiresLineOfSight = false
	vender.KeyboardKeyCode = Enum.KeyCode.F
	vender.GamepadKeyCode = Enum.KeyCode.ButtonY
	vender.Parent = cuerpo
	vender.Triggered:Connect(function(quien: Player)
		if quien == dueno then
			BaseService.Vender(dueno, uid)
		end
	end)

	modelo.Parent = pedestalMapa.modelo
	estado.pedestales[lugar].modelo = modelo
end

-- Pone en el mundo un Crunchi que YA está en los datos del jugador (con su lugar).
function BaseService.Colocar(jugador: Player, crunchi: CrunchiGuardado)
	local estado = estados[jugador]
	if estado == nil or crunchi.lugar < 1 then
		return
	end
	local pedestal = estado.pedestales[crunchi.lugar]
	if pedestal == nil then
		return
	end
	if pedestal.modelo then
		pedestal.modelo:Destroy()
		pedestal.modelo = nil
	end
	asentar(pedestal, ahora())
	pedestal.uid = crunchi.uid
	pedestal.crunchiId = crunchi.id
	pedestal.mutacion = crunchi.mut
	pedestal.enRobo = false
	pedestal.reservado = false
	crearModelo(estado, crunchi.lugar, crunchi)
	BaseService.Recalcular(jugador)
	BaseService.CrunchiColocado:Disparar(jugador, crunchi)
end

-- Saca el modelo del pedestal (para que el ladrón lo cargue). Deja de producir dinero.
function BaseService.TomarModelo(jugador: Player, lugar: number): Model?
	local estado = estados[jugador]
	local pedestal = estado and estado.pedestales[lugar]
	if estado == nil or pedestal == nil or pedestal.uid == nil or pedestal.enRobo then
		return nil
	end
	asentar(pedestal, ahora())
	pedestal.enRobo = true
	pedestal.tasa = 0
	local modelo = pedestal.modelo
	pedestal.modelo = nil
	publicarPedestal(estado, lugar)
	actualizarIngresoTotal(estado)
	return modelo
end

-- El robo falló: el Crunchi vuelve a su pedestal.
function BaseService.DevolverCrunchi(jugador: Player, uid: string)
	local estado = estados[jugador]
	local datos = DatosService.Obtener(jugador)
	if estado == nil or datos == nil then
		return
	end
	local crunchi = buscarGuardado(datos, uid)
	if crunchi == nil then
		return
	end
	local pedestal = estado.pedestales[crunchi.lugar]
	if pedestal then
		pedestal.enRobo = false
	end
	BaseService.Colocar(jugador, crunchi)
end

-- El robo tuvo éxito: el pedestal queda vacío (el dinero pendiente se queda en el botón).
function BaseService.VaciarPedestal(jugador: Player, lugar: number)
	local estado = estados[jugador]
	local pedestal = estado and estado.pedestales[lugar]
	if estado == nil or pedestal == nil then
		return
	end
	asentar(pedestal, ahora())
	if pedestal.modelo then
		pedestal.modelo:Destroy()
	end
	pedestal.modelo = nil
	pedestal.uid = nil
	pedestal.crunchiId = nil
	pedestal.mutacion = nil
	pedestal.enRobo = false
	pedestal.tasa = 0
	publicarPedestal(estado, lugar)
	actualizarIngresoTotal(estado)
end

----------------------------------------------------------------------------- acciones

function BaseService.Cobrar(jugador: Player, lugar: number)
	local estado = estados[jugador]
	local pedestal = estado and estado.pedestales[lugar]
	if estado == nil or pedestal == nil then
		return
	end
	asentar(pedestal, ahora())
	local cantidad = math.floor(pedestal.acumulado)
	if cantidad < 1 then
		return
	end
	pedestal.acumulado -= cantidad
	publicarPedestal(estado, lugar)
	EconomiaService.Agregar(jugador, cantidad, AnaliticaService.Tipo.Juego, "cobro", true)
	local datos = DatosService.Obtener(jugador)
	if datos then
		datos.stats.cobros += 1
	end
	RedServidor.Enviar("Cobro", jugador, lugar, cantidad)
	BaseService.Cobrado:Disparar(jugador, cantidad)
end

function BaseService.Vender(jugador: Player, uid: string)
	local estado = estados[jugador]
	local datos = DatosService.Obtener(jugador)
	if estado == nil or datos == nil then
		return
	end
	local crunchi, indice = buscarGuardado(datos, uid)
	if crunchi == nil or indice == nil then
		return
	end
	local pedestal = estado.pedestales[crunchi.lugar]
	if pedestal and pedestal.enRobo then
		RedServidor.Notificar(jugador, "¡No puedes venderlo mientras te lo están robando!", "error")
		return
	end
	local _, precio = Catalogo.Valor(crunchi.id, crunchi.mut)
	local precioVenta = Ingreso.PrecioVenta(precio, 1, ConfigEconomia.VENTA_PORCENTAJE)

	table.remove(datos.crunchis, indice)
	if pedestal then
		BaseService.VaciarPedestal(jugador, crunchi.lugar)
	end
	EconomiaService.Agregar(jugador, precioVenta, AnaliticaService.Tipo.Juego, "venta")
	RedServidor.Notificar(
		jugador,
		`Vendiste {Catalogo.NombreCompleto(crunchi.id, crunchi.mut)} por {Formato.Dinero(precioVenta)}`,
		"exito"
	)
	BaseService.Vendido:Disparar(jugador, crunchi, precioVenta)
end

function BaseService.ActivarCerrojo(jugador: Player)
	local estado = estados[jugador]
	local datos = DatosService.Obtener(jugador)
	if estado == nil or datos == nil then
		return
	end
	local momento = ahora()
	if estado.cerrojoHasta > momento then
		RedServidor.Notificar(jugador, "Tu base ya está cerrada.", "info")
		return
	end
	if estado.revanchaHasta > momento then
		RedServidor.Notificar(
			jugador,
			`Robaste hace poco: tu cerrojo se recarga en {math.ceil(estado.revanchaHasta - momento)} s`,
			"error"
		)
		return
	end
	local duracion = math.min(
		ConfigBase.CERROJO_MAXIMO,
		ConfigBase.CERROJO_DURACION + datos.rebirths * ConfigBase.CERROJO_POR_REBIRTH
	)
	estado.cerrojoHasta = momento + duracion
	publicarBase(estado)
	RedServidor.Enviar("Efecto", jugador, "Cerrojo")
	RedServidor.Notificar(jugador, `🔒 Base cerrada por {duracion} segundos`, "exito")
end

----------------------------------------------------------------------------- escudos

function BaseService.EscudoRestante(jugador: Player): number
	local estado = estados[jugador]
	if estado == nil then
		return 0
	end
	return math.max(0, estado.escudoHasta - ahora())
end

function BaseService.CerrojoActivo(jugador: Player): boolean
	local estado = estados[jugador]
	return estado ~= nil and estado.cerrojoHasta > ahora()
end

function BaseService.ActivarEscudo(jugador: Player, segundos: number, tipo: string)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	local hasta = ahora() + segundos
	if hasta > estado.escudoHasta then
		estado.escudoHasta = hasta
		estado.escudoTipo = tipo
		publicarBase(estado)
	end
end

function BaseService.QuitarEscudo(jugador: Player)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	estado.escudoHasta = 0
	estado.escudoTipo = ""
	publicarBase(estado)
end

-- Tras robar: el cerrojo del ladrón se desactiva y no se puede usar por un rato.
function BaseService.ActivarRevancha(jugador: Player)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	estado.cerrojoHasta = 0
	estado.revanchaHasta = ahora() + ConfigRobo.REVANCHA
	publicarBase(estado)
end

-- Cuenta un robo sufrido. Si se alcanza el límite, la base recibe un escudo de alivio.
function BaseService.RegistrarRoboSufrido(jugador: Player)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	local momento = ahora()
	table.insert(estado.robosSufridos, momento)
	local recientes = {}
	for _, instante in estado.robosSufridos do
		if momento - instante <= ConfigRobo.VENTANA_ROBOS then
			table.insert(recientes, instante)
		end
	end
	estado.robosSufridos = recientes
	if #recientes >= ConfigRobo.LIMITE_ROBOS then
		estado.robosSufridos = {}
		BaseService.ActivarEscudo(jugador, ConfigRobo.ESCUDO_ALIVIO, "alivio")
		RedServidor.Notificar(
			jugador,
			`🛡️ Te robaron mucho: tu base tiene escudo por {math.floor(ConfigRobo.ESCUDO_ALIVIO / 60)} minutos`,
			"info"
		)
	end
end

----------------------------------------------------------------------------- asignación

local function llevarABase(jugador: Player)
	local estado = estados[jugador]
	local personaje = jugador.Character
	if estado == nil or personaje == nil then
		return
	end
	local raiz = personaje:WaitForChild("HumanoidRootPart", 5)
	if raiz and estados[jugador] == estado then
		task.defer(function()
			if personaje.Parent then
				personaje:PivotTo(estado.mapa.aparicion)
			end
		end)
	end
end

function BaseService.Liberar(jugador: Player)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	estados[jugador] = nil
	duenos[estado.mapa.indice] = nil

	-- El dinero sin cobrar no se pierde: pasa al saldo del jugador.
	local momento = ahora()
	local pendiente = 0
	for _, pedestal in estado.pedestales do
		asentar(pedestal, momento)
		pendiente += math.floor(pedestal.acumulado)
		if pedestal.modelo then
			pedestal.modelo:Destroy()
		end
	end
	if pendiente > 0 then
		EconomiaService.Agregar(jugador, pendiente, AnaliticaService.Tipo.Juego, "cobro_salida")
	end

	for _, conexion in estado.conexiones do
		conexion:Disconnect()
	end

	local mapa = estado.mapa
	for indice, pedestalMapa in mapa.pedestales do
		for _, hijo in pedestalMapa.modelo:GetChildren() do
			if hijo:IsA("Model") then
				hijo:Destroy()
			end
		end
		pedestalMapa.modelo:SetAttribute("Acumulado", 0)
		pedestalMapa.modelo:SetAttribute("Tasa", 0)
		pedestalMapa.modelo:SetAttribute("Ocupado", false)
		pedestalMapa.modelo:SetAttribute("EnRobo", false)
		pedestalMapa.modelo:SetAttribute("Indice", indice)
	end
	pintarPedestales(mapa, ConfigBase.PEDESTALES_INICIALES, 1)
	mapa.modelo:SetAttribute("Dueno", 0)
	mapa.modelo:SetAttribute("DuenoNombre", "")
	mapa.modelo:SetAttribute("CerrojoHasta", 0)
	mapa.modelo:SetAttribute("EscudoHasta", 0)
	mapa.modelo:SetAttribute("EscudoTipo", "")
	mapa.modelo:SetAttribute("RevanchaHasta", 0)
	mapa.letrero.Text = "Base libre"
	pcall(function()
		mapa.modelo:RemovePersistentPlayer(jugador)
	end)
	if jugador.Parent then
		jugador:SetAttribute("Base", nil)
		jugador:SetAttribute("IngresoSeg", 0)
	end
end

function BaseService.Asignar(jugador: Player, datos: Tipos.Datos)
	if estados[jugador] then
		BaseService.Liberar(jugador)
	end

	local mapa: MapaService.BaseMapa? = nil
	for _, base in MapaService.Bases do
		if not duenos[base.indice] then
			mapa = base
			break
		end
	end
	if mapa == nil then
		warn(`[Base] No hay bases libres para {jugador.Name}. ¿El servidor admite más jugadores que bases?`)
		return
	end

	local momento = ahora()
	local pedestales: { EstadoPedestal } = {}
	for _ = 1, #mapa.pedestales do
		table.insert(pedestales, {
			acumulado = 0,
			desde = momento,
			tasa = 0,
			uid = nil,
			crunchiId = nil,
			mutacion = nil,
			modelo = nil,
			enRobo = false,
			reservado = false,
		})
	end

	local estado: EstadoBase = {
		jugador = jugador,
		mapa = mapa,
		pedestales = pedestales,
		cerrojoHasta = 0,
		revanchaHasta = 0,
		escudoHasta = 0,
		escudoTipo = "",
		robosSufridos = {},
		conexiones = {},
	}
	estados[jugador] = estado
	duenos[mapa.indice] = jugador

	mapa.modelo:SetAttribute("Dueno", jugador.UserId)
	mapa.modelo:SetAttribute("DuenoNombre", jugador.DisplayName)
	mapa.letrero.Text = `Base de {jugador.DisplayName}`
	pcall(function()
		mapa.modelo:AddPersistentPlayer(jugador)
	end)
	jugador:SetAttribute("Base", mapa.indice)

	local disponibles = BaseService.PedestalesDisponibles(jugador)
	pintarPedestales(mapa, disponibles, BaseService.Bovedas(datos.rebirths))

	-- Colocar los Crunchis guardados. Si alguno tiene un lugar inválido u ocupado, se le
	-- busca otro; si no hay espacio, queda en el depósito (lugar 0) sin perderse.
	for _, crunchi in datos.crunchis do
		if Catalogo.datos.crunchi[crunchi.id] == nil then
			warn(`[Base] {jugador.Name} tiene un Crunchi desconocido "{crunchi.id}" (se conserva en el depósito)`)
			crunchi.lugar = 0
		elseif crunchi.lugar >= 1 then
			local lugar = crunchi.lugar
			if lugar > disponibles or pedestales[lugar].uid ~= nil then
				local libre = BaseService.LugarLibre(jugador)
				crunchi.lugar = libre or 0
			end
			if crunchi.lugar >= 1 then
				local pedestal = pedestales[crunchi.lugar]
				pedestal.uid = crunchi.uid
				pedestal.crunchiId = crunchi.id
				pedestal.mutacion = crunchi.mut
				crearModelo(estado, crunchi.lugar, crunchi)
			end
		end
	end

	-- Escudo al entrar (o de novato si todavía tiene poco tiempo de juego).
	local restanteNovato = math.max(0, ConfigRobo.NOVATO_SEGUNDOS - datos.stats.tiempoJugado)
	if restanteNovato > ConfigRobo.ESCUDO_ENTRADA then
		BaseService.ActivarEscudo(jugador, restanteNovato, "novato")
	else
		BaseService.ActivarEscudo(jugador, ConfigRobo.ESCUDO_ENTRADA, "entrada")
	end

	table.insert(
		estado.conexiones,
		mapa.promptCerrojo.Triggered:Connect(function(quien: Player)
			if quien == jugador then
				BaseService.ActivarCerrojo(jugador)
			end
		end)
	)
	table.insert(
		estado.conexiones,
		jugador.CharacterAdded:Connect(function()
			llevarABase(jugador)
		end)
	)

	BaseService.Recalcular(jugador)
	publicarBase(estado)
	llevarABase(jugador)
end

----------------------------------------------------------------------------- ciclo

local function expulsar(jugador: Player, destino: CFrame)
	local personaje = jugador.Character
	if personaje then
		personaje:PivotTo(destino)
		RedServidor.Notificar(jugador, "🔒 Esa base está cerrada", "error")
	end
end

local function revisar()
	local momento = ahora()
	local radio = ConfigBase.COBRO_RADIO
	for jugador, estado in estados do
		-- Cobro: el dueño pisa el botón de cobro de un pedestal.
		local raiz = raizDe(jugador)
		if raiz then
			for lugar, pedestal in estado.pedestales do
				if pedestal.tasa > 0 or pedestal.acumulado >= 1 then
					local boton = estado.mapa.pedestales[lugar].boton
					local relativo = boton.CFrame:PointToObjectSpace(raiz.Position)
					if
						math.abs(relativo.X) < radio
						and math.abs(relativo.Z) < radio
						and relativo.Y > -1
						and relativo.Y < 6
					then
						BaseService.Cobrar(jugador, lugar)
					end
				end
			end
		end

		-- Cerrojo: los intrusos (que no cargan un Crunchi robado) son sacados de la base.
		-- Un ladrón que carga un Crunchi queda atrapado adentro: ¡a defender!
		if estado.cerrojoHasta > momento then
			for _, otro in Players:GetPlayers() do
				if otro ~= jugador and otro:GetAttribute("Cargando") ~= true then
					local raizOtro = raizDe(otro)
					if raizOtro and MapaService.DentroDeBase(estado.mapa, raizOtro.Position) then
						expulsar(otro, estado.mapa.salida)
					end
				end
			end
		end
	end
end

function BaseService.Iniciar()
	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		BaseService.Asignar(jugador, datos)
	end)
	DatosService.JugadorSaliendo:Conectar(function(jugador: Player)
		BaseService.Liberar(jugador)
	end)
	EconomiaService.MultiplicadorCambio:Conectar(function(jugador: Player)
		BaseService.Recalcular(jugador)
	end)
	Reloj.Cada(ConfigBase.REVISION_SEGUNDOS, revisar)
end

return BaseService
