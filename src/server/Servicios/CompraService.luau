--!strict
--[[
	CompraService
	Todo lo que se paga con Robux:

	  GAME PASSES (compra única): se comprueban al entrar (UserOwnsGamePassAsync) y al
	  comprarlos en el juego (PromptGamePassPurchaseFinished). Sus efectos se registran en
	  los demás servicios (x2 dinero, pedestales extra, auto-cobro...).

	  DEVELOPER PRODUCTS (repetibles): MarketplaceService.ProcessReceipt IDEMPOTENTE:
	    1. Si el PurchaseId ya está en los recibos del jugador → no se entrega otra vez.
	    2. Se entrega y se anota el PurchaseId en el perfil.
	    3. Se espera a que ese recibo quede GUARDADO en DataStore antes de responder
	       "PurchaseGranted". Si el servidor se cae antes, Roblox reintenta la compra en
	       la próxima sesión y, gracias al paso 1, no se entrega dos veces.

	  POLICYSERVICE: a los jugadores de países que restringen objetos aleatorios de pago
	  se les oculta la Canasta Sorpresa (atributo "SinAleatoriosPagados").

	Para probar en Studio sin IDs: comando de admin `pase VIP` (activa un Game Pass solo
	en esa sesión) y `producto DINERO_CANASTA` (entrega un producto sin cobrar).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigProductos = require(Config:WaitForChild("Productos"))
local ConfigBase = require(Config:WaitForChild("Base"))
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CintaService = require(script.Parent:WaitForChild("CintaService"))
local CanastaService = require(script.Parent:WaitForChild("CanastaService"))
local OfflineService = require(script.Parent:WaitForChild("OfflineService"))
local MisionService = require(script.Parent:WaitForChild("MisionService"))
local PaseService = require(script.Parent:WaitForChild("PaseService"))
local CabezaService = require(script.Parent:WaitForChild("CabezaService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Producto = ConfigProductos.Producto

local CompraService = {
	-- (jugador, clave: string) — compró o se detectó un Game Pass
	PaseObtenido = Senal.nueva(),
	-- (jugador, clave: string, producto) — se entregó un Developer Product
	ProductoEntregado = Senal.nueva(),
}

local MAXIMO_RECIBOS = 100

local clavePorPase: { [number]: string } = {}
for clave, pase in ConfigProductos.PASES do
	if pase.id ~= 0 then
		clavePorPase[pase.id] = clave
	end
end
local clavePorProducto: { [number]: string } = {}
for clave, producto in ConfigProductos.PRODUCTOS do
	if producto.id ~= 0 then
		clavePorProducto[producto.id] = clave
	end
end

local pases: { [Player]: { [string]: boolean } } = {}
local boostActivo: { [Player]: boolean } = {}
local suerteHasta = 0
local suerteAnunciada = false

----------------------------------------------------------------------------- game passes

function CompraService.TienePase(jugador: Player, clave: string): boolean
	local lista = pases[jugador]
	return lista ~= nil and lista[clave] == true
end

local function publicarPases(jugador: Player)
	local claves = {}
	local lista: { [string]: boolean } = pases[jugador] or {}
	for clave in lista do
		table.insert(claves, clave)
	end
	table.sort(claves)
	jugador:SetAttribute("Pases", table.concat(claves, ","))
	jugador:SetAttribute("EtiquetasCambiaron", os.clock())
end

-- Aplica en el mundo lo que cambie al tener un pase nuevo.
local function aplicarPases(jugador: Player)
	publicarPases(jugador)
	EconomiaService.AvisarCambio(jugador)
	BaseService.ActualizarCapacidad(jugador)
	DatosService.ActualizarEstado(jugador, { "tienda", "canastas", "misiones", "offline", "cosmeticos" })
end

local function darPase(jugador: Player, clave: string, comprado: boolean)
	local lista = pases[jugador]
	if lista == nil then
		lista = {}
		pases[jugador] = lista
	end
	if lista[clave] then
		return
	end
	lista[clave] = true
	aplicarPases(jugador)
	CompraService.PaseObtenido:Disparar(jugador, clave)
	if comprado then
		local pase = ConfigProductos.PASES[clave]
		RedServidor.Enviar("Efecto", jugador, "CompraRobux", { nombre = pase.nombre })
		RedServidor.Notificar(jugador, `{pase.icono} ¡Gracias! Ya tienes {pase.nombre}`, "exito")
		AnaliticaService.Evento(jugador, "PaseComprado", pase.precio, { clave })
	end
end

local function cargarPases(jugador: Player)
	pases[jugador] = pases[jugador] or {}
	for clave, pase in ConfigProductos.PASES do
		if pase.id ~= 0 then
			local ok, tiene = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(jugador.UserId, pase.id)
			end)
			if ok and tiene then
				(pases[jugador] :: { [string]: boolean })[clave] = true
			end
		end
	end
	aplicarPases(jugador)
end

----------------------------------------------------------------------------- productos

local function sumarBoost(jugador: Player, datos: Tipos.Datos, minutos: number)
	datos.boosts.x2Hasta = math.max(os.time(), datos.boosts.x2Hasta) + minutos * 60
	jugador:SetAttribute("BoostX2Hasta", datos.boosts.x2Hasta)
	boostActivo[jugador] = true
	EconomiaService.AvisarCambio(jugador)
end

-- Suma un boost x2 (también lo usan la prueba gratis y el Pack Inicial).
function CompraService.SumarBoostX2(jugador: Player, minutos: number)
	local datos = DatosService.Obtener(jugador)
	if datos then
		sumarBoost(jugador, datos, minutos)
	end
end

-- Cuánto dinero da un paquete AHORA (lo mismo que muestra la tienda).
function CompraService.MontoDinero(jugador: Player, producto: Producto): number
	return EconomiaService.DineroPorMinutos(jugador, producto.minutos or 10, producto.minimo or 1000)
end

-- Entrega un producto. Puede fallar con error (entonces ProcessReceipt reintenta luego).
local function entregar(jugador: Player, clave: string, producto: Producto)
	local datos = DatosService.Obtener(jugador)
	assert(datos, "Sin datos")
	local tipo = producto.tipo

	if tipo == "dinero" then
		local cantidad = CompraService.MontoDinero(jugador, producto)
		if not datos.compras.primeraCompraDinero then
			datos.compras.primeraCompraDinero = true
			cantidad *= ConfigProductos.PRIMERA_COMPRA_MULTIPLICADOR
			RedServidor.Notificar(
				jugador,
				`🎉 ¡Bonus de primera compra: x{ConfigProductos.PRIMERA_COMPRA_MULTIPLICADOR}!`,
				"exito"
			)
		end
		EconomiaService.Agregar(jugador, cantidad, AnaliticaService.Tipo.Robux, clave)
		RedServidor.Notificar(jugador, `💰 +{Formato.Dinero(cantidad)}`, "exito")
	elseif tipo == "boost" then
		sumarBoost(jugador, datos, producto.minutos or 30)
		RedServidor.Notificar(jugador, `⚡ ¡Boost x2 activo! (+{producto.minutos} min)`, "exito")
	elseif tipo == "suerte" then
		suerteHasta = math.max(os.time(), suerteHasta) + (producto.minutos or 15) * 60
		suerteAnunciada = true
		workspace:SetAttribute("SuerteHasta", suerteHasta)
		workspace:SetAttribute("SuerteDe", jugador.DisplayName)
		RedServidor.EnviarATodos(
			"Anuncio",
			`🍀 ¡{jugador.DisplayName} activó SUERTE x2 para todo el servidor! ¡Gracias!`,
			"legendario"
		)
	elseif tipo == "offline_x2" then
		if not OfflineService.Duplicar(jugador) then
			-- No había ganancia offline pendiente: entregamos su equivalente en dinero.
			local cantidad = EconomiaService.DineroPorMinutos(jugador, 30, 1000)
			EconomiaService.Agregar(jugador, cantidad, AnaliticaService.Tipo.Robux, clave)
		end
	elseif tipo == "canasta" then
		local canastaId = producto.canasta or ""
		datos.tickets[canastaId] = (datos.tickets[canastaId] or 0) + 1
		-- Se abre sola (con animación). Si no hay espacio, queda guardada para después.
		task.defer(function()
			if CanastaService.Abrir(jugador, canastaId, true, 1) == 0 then
				RedServidor.Notificar(jugador, "Guardamos tu canasta: ábrela en 🧺 cuando tengas espacio", "info")
			end
		end)
	elseif tipo == "pase_nivel" then
		PaseService.SumarXp(jugador, PaseService.XpPorNivel(), true)
	elseif tipo == "pase_premium" then
		PaseService.ActivarPremium(jugador)
	elseif tipo == "pack_inicial" then
		if datos.compras.packInicial then
			-- Ya lo tenía (no debería poder comprarlo dos veces): entregamos su valor en dinero.
			EconomiaService.Agregar(
				jugador,
				CompraService.MontoDinero(jugador, producto),
				AnaliticaService.Tipo.Robux,
				clave
			)
		else
			datos.compras.packInicial = true
			local pack = ConfigProductos.PACK_INICIAL
			EconomiaService.Agregar(
				jugador,
				CompraService.MontoDinero(jugador, producto),
				AnaliticaService.Tipo.Robux,
				clave
			)
			BaseService.Otorgar(jugador, pack.CRUNCHI, "normal", true)
			sumarBoost(jugador, datos, pack.BOOST_MINUTOS)
			datos.titulos[pack.TITULO] = true
			RedServidor.Notificar(jugador, "🚀 ¡Pack Inicial entregado! Revisa tu base", "exito")
		end
	else
		error(`Tipo de producto desconocido: {tipo}`)
	end

	datos.compras.robuxGastados += producto.precio
	RedServidor.Enviar("Efecto", jugador, "CompraRobux", { nombre = producto.nombre })
	AnaliticaService.Evento(jugador, "ProductoComprado", producto.precio, { clave })
	CompraService.ProductoEntregado:Disparar(jugador, clave, producto)
	DatosService.ActualizarEstado(jugador, { "tienda" })
end

-- Espera a que el recibo quede guardado en DataStore (patrón oficial de ProfileStore).
local function esperarGuardado(perfil: any, purchaseId: string): Enum.ProductPurchaseDecision
	local function guardado(): boolean
		local ultimo = perfil.LastSavedData
		return ultimo ~= nil and ultimo.recibos ~= nil and table.find(ultimo.recibos, purchaseId) ~= nil
	end
	if guardado() then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	while perfil:IsActive() do
		local anterior = perfil.LastSavedData
		perfil:Save()
		if perfil.LastSavedData == anterior then
			perfil.OnAfterSave:Wait()
		end
		if guardado() then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if perfil:IsActive() then
			task.wait(10)
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function procesarRecibo(info: { [string]: any }): Enum.ProductPurchaseDecision
	local jugador = Players:GetPlayerByUserId(info.PlayerId)
	if jugador == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	DatosService.Esperar(jugador, 15)
	local perfil = DatosService.Perfil(jugador) :: any
	if perfil == nil or not perfil:IsActive() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local clave = clavePorProducto[info.ProductId]
	local producto = if clave then ConfigProductos.PRODUCTOS[clave] else nil
	if clave == nil or producto == nil then
		warn(`[Compras] Producto sin configurar: {info.ProductId}. Revisa Config/Productos.`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(info.PurchaseId)
	local recibos = perfil.Data.recibos
	if table.find(recibos, purchaseId) == nil then
		local ok, err = pcall(entregar :: any, jugador, clave, producto)
		if not ok then
			warn(`[Compras] No se pudo entregar {clave} a {jugador.Name}: {err}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		while #recibos >= MAXIMO_RECIBOS do
			table.remove(recibos, 1)
		end
		table.insert(recibos, purchaseId)
	end
	return esperarGuardado(perfil, purchaseId)
end

----------------------------------------------------------------------------- estado / ciclo

local function estado(jugador: Player, datos: Tipos.Datos)
	local montos: { [string]: number } = {}
	for clave, producto in ConfigProductos.PRODUCTOS do
		if producto.tipo == "dinero" or producto.tipo == "pack_inicial" then
			montos[clave] = CompraService.MontoDinero(jugador, producto)
		end
	end
	local lista = {}
	local propios: { [string]: boolean } = pases[jugador] or {}
	for clave in propios do
		table.insert(lista, clave)
	end
	return {
		montos = montos,
		primeraCompra = not datos.compras.primeraCompraDinero,
		packInicial = datos.compras.packInicial,
		pases = lista,
		boostX2Hasta = datos.boosts.x2Hasta,
		sinAleatorios = jugador:GetAttribute("SinAleatoriosPagados") == true,
	}
end

--[[
	Objetos aleatorios de pago. Roblox considera "de pago" también lo aleatorio que se compra
	con una moneda que se puede comprar con Robux. Por eso, donde está restringido, además
	de ocultar la Canasta Sorpresa se ocultan los paquetes de dinero y el Pack Inicial: así
	el dinero del juego (con el que se abren canastas y huevos) no se puede comprar con Robux.

	Hasta tener la respuesta de Roblox, el jugador se trata como restringido. Si la consulta
	falla en un servidor real, también (por prudencia). En Studio la consulta suele fallar:
	ahí se muestra todo para poder probar la tienda.
]]
local function revisarPolitica(jugador: Player)
	jugador:SetAttribute("SinAleatoriosPagados", true)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(jugador)
	end)
	local restringido
	if ok and type(info) == "table" then
		restringido = info.ArePaidRandomItemsRestricted == true
	else
		restringido = not RunService:IsStudio()
	end
	if jugador.Parent == nil then
		return
	end
	jugador:SetAttribute("SinAleatoriosPagados", restringido)
	DatosService.ActualizarEstado(jugador, { "tienda" })
end

local function registrarEfectos()
	EconomiaService.RegistrarMultiplicador("PaseX2", function(jugador)
		return if CompraService.TienePase(jugador, "X2_DINERO") then 2 else 1
	end)
	EconomiaService.RegistrarMultiplicador("BoostX2", function(jugador)
		local datos = DatosService.Obtener(jugador)
		return if datos and datos.boosts.x2Hasta > os.time() then 2 else 1
	end, true)
	BaseService.RegistrarPedestalesExtra("PisoExtra", function(jugador)
		return if CompraService.TienePase(jugador, "PISO_EXTRA") then ConfigBase.PEDESTALES_PASE else 0
	end)
	BaseService.RegistrarDepositoExtra("DepositoXL", function(jugador)
		return if CompraService.TienePase(jugador, "DEPOSITO_XL") then ConfigBase.DEPOSITO_PASE else 0
	end)
	BaseService.RegistrarAutoCobro("AutoCobro", function(jugador)
		return CompraService.TienePase(jugador, "AUTO_COBRO")
	end)
	CanastaService.RegistrarAperturaMultiple("AperturaTriple", function(jugador)
		return if CompraService.TienePase(jugador, "APERTURA_TRIPLE") then 3 else 1
	end)
	OfflineService.RegistrarHorasExtra("VIP", function(jugador)
		return if CompraService.TienePase(jugador, "VIP") then ConfigEconomia.OFFLINE.HORAS_MAXIMO_VIP else 0
	end)
	MisionService.RegistrarCambiosExtra("VIP", function(jugador)
		return if CompraService.TienePase(jugador, "VIP") then 1 else 0
	end)
	CabezaService.RegistrarEtiqueta("VIP", 1, function(jugador)
		if CompraService.TienePase(jugador, "VIP") then
			return "[VIP]", Color3.fromRGB(255, 200, 40)
		end
		return nil, nil
	end)
	CabezaService.RegistrarEtiqueta("Premium", 2, function(jugador)
		if jugador.MembershipType == Enum.MembershipType.Premium then
			return "⭐", nil
		end
		return nil, nil
	end)
	CintaService.RegistrarModificadorRareza("SuerteServidor", function()
		return if suerteHasta > os.time() then ConfigProductos.SUERTE else nil
	end)
end

function CompraService.Iniciar()
	registrarEfectos()
	MarketplaceService.ProcessReceipt = procesarRecibo
	DatosService.RegistrarEstado("tienda", estado)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(jugador: Player, paseId: number, comprado: boolean)
			local clave = clavePorPase[paseId]
			if comprado and clave then
				darPase(jugador, clave, true)
			end
		end
	)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		jugador:SetAttribute("BoostX2Hasta", datos.boosts.x2Hasta)
		boostActivo[jugador] = datos.boosts.x2Hasta > os.time()
		task.spawn(revisarPolitica, jugador)
		cargarPases(jugador)
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		pases[jugador] = nil
		boostActivo[jugador] = nil
	end)

	Reloj.Cada(2, function()
		local ahora = os.time()
		-- Fin de boosts: recalcular el ingreso cuando se acaban.
		for jugador, activo in boostActivo do
			local datos = DatosService.Obtener(jugador)
			local sigue = datos ~= nil and datos.boosts.x2Hasta > ahora
			if activo and not sigue then
				boostActivo[jugador] = false
				EconomiaService.AvisarCambio(jugador)
				RedServidor.Notificar(jugador, "⚡ Se terminó tu Boost x2", "info")
			end
		end
		if suerteAnunciada and suerteHasta <= ahora then
			suerteAnunciada = false
			RedServidor.EnviarATodos("Anuncio", "🍀 Se terminó la Suerte del Servidor", nil)
		end
		-- Terraza VIP: quien no es VIP es acompañado afuera.
		local terraza = MapaService.Terraza
		if terraza then
			for _, jugador in Players:GetPlayers() do
				local personaje = jugador.Character
				local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
				if
					raiz
					and raiz:IsA("BasePart")
					and not CompraService.TienePase(jugador, "VIP")
					and MapaService.DentroDeTerraza(raiz.Position)
				then
					(personaje :: Model):PivotTo(terraza.salida)
					RedServidor.Notificar(jugador, "👑 La Terraza es solo para VIP", "info")
				end
			end
		end
	end)
	-- La tienda muestra montos "en minutos de tu ingreso": se refrescan cada 30 s.
	Reloj.Cada(30, function()
		for _, jugador in Players:GetPlayers() do
			DatosService.ActualizarEstado(jugador, { "tienda" })
		end
	end)

	-- Herramientas de prueba (solo admins): activar pases y entregar productos sin pagar.
	AdminService.Registrar("pase", function(jugador: Player, argumentos: { string })
		local clave = string.upper(argumentos[1] or "")
		if ConfigProductos.PASES[clave] == nil then
			local claves = {}
			for k in ConfigProductos.PASES do
				table.insert(claves, k)
			end
			table.sort(claves)
			RedServidor.Notificar(jugador, `🛠️ Pases: {table.concat(claves, ", ")}`, "info")
			return
		end
		darPase(jugador, clave, true)
	end)
	AdminService.Registrar("producto", function(jugador: Player, argumentos: { string })
		local clave = string.upper(argumentos[1] or "")
		local producto = ConfigProductos.PRODUCTOS[clave]
		if producto == nil then
			local claves = {}
			for k in ConfigProductos.PRODUCTOS do
				table.insert(claves, k)
			end
			RedServidor.Notificar(jugador, `🛠️ Productos: {table.concat(claves, ", ")}`, "info")
			return
		end
		entregar(jugador, clave, producto)
	end)
end

return CompraService
