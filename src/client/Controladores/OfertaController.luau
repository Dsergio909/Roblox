--!strict
--[[
	OfertaController
	Tarjeta LATERAL de oferta (no es un pop-up): aparece a un costado, no bloquea el juego,
	se cierra con un toque y no vuelve a aparecer en la sesión. El servidor decide cuándo
	(máximo una oferta automática por sesión; ver OfertaService).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigProductos = require(Shared:WaitForChild("Config"):WaitForChild("Productos"))
local Red = require(Shared:WaitForChild("Red"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local TiendaController = require(script.Parent:WaitForChild("TiendaController"))

local OfertaController = {}

local tarjeta: Frame? = nil

local function cerrar(id: string, avisar: boolean)
	local t = tarjeta
	if t == nil then
		return
	end
	tarjeta = nil
	if avisar then
		Red.Evento("AccionMenu"):FireServer("oferta_cerrada", id)
	end
	local tween = TweenService:Create(t, TweenInfo.new(0.25), { Position = UDim2.new(1, 400, 1, -90) })
	tween:Play()
	tween.Completed:Connect(function()
		t:Destroy()
	end)
end

local function mostrarPackInicial()
	if tarjeta then
		return
	end
	local tienda = EstadoCliente.Obtener("tienda")
	if type(tienda) == "table" and tienda.packInicial then
		return
	end
	local producto = ConfigProductos.PRODUCTOS.PACK_INICIAL
	local monto = if type(tienda) == "table" and tienda.montos then tienda.montos.PACK_INICIAL or 0 else 0
	local pantalla = UI.Pantalla("Oferta", 25)
	local t = UI.Panel({
		Name = "TarjetaOferta",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 400, 1, -90),
		Size = UDim2.fromOffset(300, 150),
		BackgroundTransparency = 0.05,
		Parent = pantalla,
	})
	UI.Escalar(t, 300, 150)
	UI.Borde(t, Tema.COLORES.dinero, 3)
	UI.Texto({
		texto = `{producto.icono} {producto.nombre}`,
		tamano = UDim2.new(1, -50, 0, 30),
		posicion = UDim2.fromOffset(10, 6),
		tamanoLetra = 22,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.dinero,
		padre = t,
	})
	UI.Texto({
		texto = `{Formato.Dinero(monto)} + Manzana Cohete (Legendario) + Boost x2 1 h + título. Una vez por cuenta.`,
		tamano = UDim2.new(1, -20, 0, 50),
		posicion = UDim2.fromOffset(10, 38),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		padre = t,
	})
	UI.Boton({
		texto = "✕",
		color = Tema.COLORES.fondoClaro,
		tamano = UDim2.fromOffset(40, 36),
		posicion = UDim2.new(1, -6, 0, 6),
		ancla = Vector2.new(1, 0),
		tamanoLetra = 18,
		alPulsar = function()
			cerrar("pack_inicial", true)
		end,
		padre = t,
	})
	UI.Boton({
		texto = "Ver en la tienda",
		color = Tema.COLORES.verde,
		tamano = UDim2.new(1, -20, 0, 44),
		posicion = UDim2.new(0, 10, 1, -8),
		ancla = Vector2.new(0, 1),
		tamanoLetra = 18,
		alPulsar = function()
			cerrar("pack_inicial", false)
			TiendaController.Abrir("pack")
		end,
		padre = t,
	})
	tarjeta = t
	TweenService:Create(t, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(1, -8, 1, -90) }):Play()
	-- Si el jugador no hace nada, se va sola (no se queda molestando).
	task.delay(20, function()
		if tarjeta == t then
			cerrar("pack_inicial", false)
		end
	end)
end

function OfertaController.Iniciar()
	Red.Evento("Oferta").OnClientEvent:Connect(function(id: any)
		if id == "pack_inicial" then
			mostrarPackInicial()
		end
	end)
end

return OfertaController
