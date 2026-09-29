--!strict
--[[
	TiendaController
	Menú 🛒 Tienda. Pestañas: Dinero · Pases · Boosts · Sorpresa · Cosméticos · Pack Inicial.

	Reglas que cumple (docs/GAME_DESIGN.md §8.7):
	  - Precios SIEMPRE en Robux, leídos de Roblox (el precio real que pusiste en el Creator
	    Dashboard). Si Roblox no responde, se muestra el de Config/Productos.
	  - Los paquetes de dinero muestran la cantidad EXACTA que darían ahora.
	  - La Canasta Sorpresa muestra sus probabilidades y se oculta donde la ley lo restringe.
	  - La tienda solo se abre cuando el jugador la abre (o desde un botón discreto).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigProductos = require(Config:WaitForChild("Productos"))
local ConfigCosmeticos = require(Config:WaitForChild("Cosmeticos"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local TiendaController = {}

type Pase = ConfigProductos.Pase
type Producto = ConfigProductos.Producto

local jugador = Players.LocalPlayer
local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local pestanaActual = "dinero"
local botonesPestana: { [string]: TextButton } = {}
local precios: { [number]: number } = {} -- id → precio real en Robux
local consultando: { [number]: boolean } = {}

----------------------------------------------------------------------------- precios reales

local function precioDe(id: number, tipo: Enum.InfoType, respaldo: number): number
	if id == 0 then
		return respaldo
	end
	local conocido = precios[id]
	if conocido then
		return conocido
	end
	if not consultando[id] then
		consultando[id] = true
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfoAsync(id, tipo)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				precios[id] = info.PriceInRobux
				TiendaController.Refrescar()
			end
		end)
	end
	return respaldo
end

local function textoPrecio(robux: number): string
	return `R$ {robux}`
end

----------------------------------------------------------------------------- compras

local function comprarProducto(producto: Producto)
	if producto.id == 0 then
		NotificacionController.Avisar(
			"Este producto aún no está configurado (falta su ID en Config/Productos).",
			"error"
		)
		return
	end
	MarketplaceService:PromptProductPurchase(jugador, producto.id)
end

local function comprarPase(pase: Pase)
	if pase.id == 0 then
		NotificacionController.Avisar("Este pase aún no está configurado (falta su ID en Config/Productos).", "error")
		return
	end
	MarketplaceService:PromptGamePassPurchase(jugador, pase.id)
end

local function estado(): any
	local e = EstadoCliente.Obtener("tienda")
	return if type(e) == "table" then e else { montos = {}, pases = {}, primeraCompra = true, sinAleatorios = true }
end

----------------------------------------------------------------------------- tarjetas

type OpcionesTarjeta = {
	icono: string,
	titulo: string,
	detalle: string,
	etiqueta: string?,
	textoBoton: string,
	colorBoton: Color3?,
	alPulsar: (() -> ())?,
	orden: number,
	alto: number?,
	colorBorde: Color3?,
}

local function tarjeta(padre: Instance, o: OpcionesTarjeta): Frame
	local alto = o.alto or 76
	local marco = UI.Panel({
		Size = UDim2.new(1, -8, 0, alto),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		LayoutOrder = o.orden,
		Parent = padre,
	})
	if o.colorBorde then
		UI.Borde(marco, o.colorBorde, 2.5)
	end
	UI.Texto({
		texto = o.icono,
		tamano = UDim2.fromOffset(56, alto),
		tamanoLetra = 34,
		padre = marco,
	})
	UI.Texto({
		texto = o.titulo .. (if o.etiqueta then `   <font color="#FFD34D">★ {o.etiqueta}</font>` else ""),
		tamano = UDim2.new(1, -230, 0, 26),
		posicion = UDim2.fromOffset(60, 6),
		tamanoLetra = 18,
		alineacion = Enum.TextXAlignment.Left,
		padre = marco,
	}).RichText =
		true
	local detalle = UI.Texto({
		texto = o.detalle,
		tamano = UDim2.new(1, -230, 0, alto - 36),
		posicion = UDim2.fromOffset(60, 32),
		tamanoLetra = 13,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = marco,
	})
	detalle.RichText = true
	detalle.TextYAlignment = Enum.TextYAlignment.Top
	if o.alPulsar then
		UI.Boton({
			texto = o.textoBoton,
			color = o.colorBoton or Tema.COLORES.verde,
			tamano = UDim2.fromOffset(160, 48),
			posicion = UDim2.new(1, -8, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 18,
			alPulsar = o.alPulsar,
			padre = marco,
		})
	else
		UI.Texto({
			texto = o.textoBoton,
			tamano = UDim2.fromOffset(160, 48),
			posicion = UDim2.new(1, -8, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 18,
			color = Tema.COLORES.verde,
			padre = marco,
		})
	end
	return marco
end

----------------------------------------------------------------------------- pestañas

local function pestanaDinero(l: ScrollingFrame, e: any)
	local paquetes: { { clave: string, p: Producto } } = {}
	for clave, producto in ConfigProductos.PRODUCTOS do
		if producto.tipo == "dinero" then
			table.insert(paquetes, { clave = clave, p = producto })
		end
	end
	table.sort(paquetes, function(a, b)
		return a.p.precio < b.p.precio
	end)
	if e.primeraCompra then
		UI.Texto({
			texto = `🎉 Tu PRIMERA compra de dinero vale x{ConfigProductos.PRIMERA_COMPRA_MULTIPLICADOR} (una sola vez)`,
			tamano = UDim2.new(1, -8, 0, 24),
			tamanoLetra = 16,
			color = Tema.COLORES.dinero,
			padre = l,
		}).LayoutOrder =
			0
	end
	for i, paquete in paquetes do
		local producto = paquete.p
		local monto = e.montos[paquete.clave] or 0
		tarjeta(l, {
			icono = producto.icono,
			titulo = `{producto.nombre}: {Formato.Dinero(monto)}`,
			detalle = `{producto.descripcion} (calculado con tu ingreso actual)`,
			etiqueta = producto.etiqueta,
			textoBoton = textoPrecio(precioDe(producto.id, Enum.InfoType.Product, producto.precio)),
			alPulsar = function()
				comprarProducto(producto)
			end,
			orden = i,
			colorBorde = if producto.etiqueta then Tema.COLORES.dinero else nil,
		})
	end
end

local function pestanaPases(l: ScrollingFrame, e: any)
	local tiene: { [string]: boolean } = {}
	for _, clave in e.pases do
		tiene[clave] = true
	end
	local claves = {}
	for clave in ConfigProductos.PASES do
		table.insert(claves, clave)
	end
	table.sort(claves, function(a, b)
		return ConfigProductos.PASES[a].precio > ConfigProductos.PASES[b].precio
	end)
	UI.Texto({
		texto = "Compra única, para siempre. Ningún pase da ventaja para robar ni para evitar robos.",
		tamano = UDim2.new(1, -8, 0, 22),
		tamanoLetra = 14,
		color = Tema.COLORES.textoSuave,
		padre = l,
	}).LayoutOrder =
		0
	for i, clave in claves do
		local pase = ConfigProductos.PASES[clave]
		tarjeta(l, {
			icono = pase.icono,
			titulo = pase.nombre,
			detalle = pase.descripcion,
			textoBoton = if tiene[clave]
				then "✔ Lo tienes"
				else textoPrecio(precioDe(pase.id, Enum.InfoType.GamePass, pase.precio)),
			alPulsar = if tiene[clave]
				then nil
				else function()
					comprarPase(pase)
				end,
			orden = i,
			alto = 86,
		})
	end
end

local function pestanaBoosts(l: ScrollingFrame, _e: any)
	local orden = 0
	for _, clave in { "BOOST_X2", "SUERTE_SERVIDOR", "OFFLINE_X2" } do
		local producto = ConfigProductos.PRODUCTOS[clave]
		local mostrar = true
		if clave == "OFFLINE_X2" then
			local offline = EstadoCliente.Obtener("offline")
			mostrar = type(offline) == "table" and (offline.pendiente or 0) > 0
		end
		if mostrar then
			orden += 1
			tarjeta(l, {
				icono = producto.icono,
				titulo = producto.nombre,
				detalle = producto.descripcion,
				textoBoton = textoPrecio(precioDe(producto.id, Enum.InfoType.Product, producto.precio)),
				alPulsar = function()
					comprarProducto(producto)
				end,
				orden = orden,
			})
		end
	end
end

local function pestanaSorpresa(l: ScrollingFrame, e: any)
	if e.sinAleatorios then
		UI.Texto({
			texto = "Este producto no está disponible en tu región.",
			tamano = UDim2.new(1, -8, 0, 40),
			tamanoLetra = 16,
			padre = l,
		}).LayoutOrder =
			1
		return
	end
	local producto = ConfigProductos.PRODUCTOS.CANASTA_SORPRESA
	local canasta = Catalogo.canasta[producto.canasta or ""]
	if canasta == nil then
		return
	end
	-- Probabilidades SIEMPRE visibles antes de comprar.
	local probabilidades = Azar.Probabilidades(canasta.pesos)
	local lineas = {}
	for i = #Catalogo.datos.rarezas, 1, -1 do
		local rareza = Catalogo.datos.rarezas[i]
		local p = probabilidades[rareza.id]
		if p then
			local c = if rareza.id == "secreto" then Color3.fromRGB(255, 255, 255) else rareza.color
			local hex = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
			table.insert(lineas, `<font color="{hex}">{rareza.nombre}: {Formato.Porcentaje(p)}</font>`)
		end
	end
	tarjeta(l, {
		icono = producto.icono,
		titulo = producto.nombre,
		detalle = `Probabilidades: {table.concat(lineas, " · ")}\nTodos estos Crunchis también se consiguen GRATIS en las cintas.`,
		textoBoton = textoPrecio(precioDe(producto.id, Enum.InfoType.Product, producto.precio)),
		alPulsar = function()
			comprarProducto(producto)
		end,
		orden = 1,
		alto = 100,
		colorBorde = canasta.color,
	})
end

local function pestanaCosmeticos(l: ScrollingFrame, _e: any)
	local estadoCosmeticos = EstadoCliente.Obtener("cosmeticos")
	local tiene: { [string]: boolean } = {}
	local aura, estela = "", ""
	if type(estadoCosmeticos) == "table" then
		for _, id in estadoCosmeticos.tiene do
			tiene[id] = true
		end
		aura, estela = estadoCosmeticos.aura, estadoCosmeticos.estela
	end
	for i, cosmetico in ConfigCosmeticos do
		local propio = tiene[cosmetico.id] == true
		local equipado = cosmetico.id == aura or cosmetico.id == estela
		local textoBoton: string
		local accion: (() -> ())? = nil
		local color: Color3? = nil
		if propio then
			textoBoton = if equipado then "Quitar" else "Usar"
			color = if equipado then Tema.COLORES.fondo else Tema.COLORES.verde
			accion = function()
				Red.Evento("AccionMenu")
					:FireServer(
						"cosmetico_equipar",
						{ tipo = cosmetico.tipo, id = if equipado then "" else cosmetico.id }
					)
			end
		elseif cosmetico.fuente == "dinero" then
			textoBoton = Formato.Dinero(cosmetico.precioDinero or 0)
			color = Tema.COLORES.naranja
			accion = function()
				Red.Evento("AccionMenu"):FireServer("cosmetico_comprar", cosmetico.id)
			end
		elseif string.sub(cosmetico.fuente, 1, 5) == "pase:" then
			local pase = ConfigProductos.PASES[string.sub(cosmetico.fuente, 6)]
			textoBoton = if pase then `{pase.icono} Pase` else "Pase"
			color = Tema.COLORES.azul
			accion = function()
				pestanaActual = "pases"
				TiendaController.Refrescar()
			end
		else
			textoBoton = "🏆 Premio"
			accion = nil
		end
		tarjeta(l, {
			icono = if cosmetico.tipo == "aura" then "✨" else "💫",
			titulo = cosmetico.nombre,
			detalle = if cosmetico.tipo == "aura" then "Aura a tu alrededor" else "Estela al moverte",
			textoBoton = textoBoton,
			colorBoton = color,
			alPulsar = accion,
			orden = i,
			alto = 64,
			colorBorde = if equipado then Tema.COLORES.verde else nil,
		})
	end
end

local function pestanaPack(l: ScrollingFrame, e: any)
	local producto = ConfigProductos.PRODUCTOS.PACK_INICIAL
	if e.packInicial then
		UI.Texto({
			texto = "✔ Ya tienes el Pack Inicial. ¡Gracias!",
			tamano = UDim2.new(1, -8, 0, 40),
			tamanoLetra = 18,
			padre = l,
		}).LayoutOrder =
			1
		return
	end
	tarjeta(l, {
		icono = producto.icono,
		titulo = producto.nombre,
		detalle = `{Formato.Dinero(e.montos.PACK_INICIAL or 0)} + {producto.descripcion}. Una sola vez por cuenta.`,
		etiqueta = "Mejor valor",
		textoBoton = textoPrecio(precioDe(producto.id, Enum.InfoType.Product, producto.precio)),
		alPulsar = function()
			comprarProducto(producto)
		end,
		orden = 1,
		alto = 100,
		colorBorde = Tema.COLORES.dinero,
	})
end

local PESTANAS: { { id: string, texto: string, fn: (ScrollingFrame, any) -> () } } = {
	{ id = "pack", texto = "🚀 Pack", fn = pestanaPack },
	{ id = "dinero", texto = "💰 Dinero", fn = pestanaDinero },
	{ id = "pases", texto = "⭐ Pases", fn = pestanaPases },
	{ id = "boosts", texto = "⚡ Boosts", fn = pestanaBoosts },
	{ id = "sorpresa", texto = "🎁 Sorpresa", fn = pestanaSorpresa },
	{ id = "cosmeticos", texto = "✨ Cosméticos", fn = pestanaCosmeticos },
}

function TiendaController.Refrescar()
	local v = ventana
	local l = lista
	if v == nil or l == nil or not v:EstaAbierta() then
		return
	end
	local e = estado()
	for id, boton in botonesPestana do
		boton.BackgroundColor3 = if id == pestanaActual then Tema.COLORES.naranja else Tema.COLORES.fondoClaro
		if id == "sorpresa" then
			boton.Visible = not e.sinAleatorios
		elseif id == "pack" then
			boton.Visible = not e.packInicial
		end
	end
	UI.Vaciar(l)
	for _, pestana in PESTANAS do
		if pestana.id == pestanaActual then
			pestana.fn(l, e)
		end
	end
end

-- Abre la tienda en una pestaña concreta ("dinero", "pases", "boosts"...).
function TiendaController.Abrir(pestana: string?)
	if pestana then
		pestanaActual = pestana
	end
	if ventana then
		ventana:Abrir()
	end
end

function TiendaController.Iniciar()
	local v = Ventana.nueva("🛒 Tienda", 600, 350, Tema.COLORES.naranja)
	ventana = v
	v.alAbrir = function()
		task.defer(TiendaController.Refrescar)
	end

	local barra = UI.Crear("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
		Parent = v.contenido,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = barra,
	})
	for i, pestana in PESTANAS do
		local boton = UI.Boton({
			texto = pestana.texto,
			color = Tema.COLORES.fondoClaro,
			tamano = UDim2.fromOffset(122, 38),
			tamanoLetra = 15,
			alPulsar = function()
				pestanaActual = pestana.id
				TiendaController.Refrescar()
			end,
			padre = barra,
		})
		boton.LayoutOrder = i
		botonesPestana[pestana.id] = boton
	end
	lista = UI.Lista({
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		Parent = v.contenido,
	}, 6)

	HudController.AgregarBoton("🛒", Tema.COLORES.naranja, 0, function()
		v:Alternar()
	end)

	-- "Te faltan $X" → botón discreto "Conseguir $" dentro del aviso (nunca un pop-up).
	NotificacionController.AlPedirDinero = function()
		TiendaController.Abrir("dinero")
	end
	HudController.AlPedirX2 = function()
		TiendaController.Abrir("pases")
	end

	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "tienda" or parte == "cosmeticos" then
			TiendaController.Refrescar()
		end
	end)
end

return TiendaController
