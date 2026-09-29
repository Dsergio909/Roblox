--!strict
--[[
	AjustesController
	Menú ⚙️ Ajustes: música, sonidos y Modo ahorro. Se guardan con los datos del jugador
	(AjustesService), así valen en cualquier dispositivo.

	Modo ahorro (para celulares básicos):
	  - menos partículas (EfectosController.calidad) y auras más simples
	  - sin sombras (Lighting.GlobalShadows, solo en este dispositivo)
	  - menos manzanas en la Lluvia

	Si el juego va lento (pocos FPS por un rato), sugiere UNA vez por sesión activar el
	Modo ahorro. Es un aviso pequeño, no una ventana que bloquee.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local SonidoController = require(script.Parent:WaitForChild("SonidoController"))
local EfectosController = require(script.Parent:WaitForChild("EfectosController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

local AjustesController = {}

type Ajustes = { musica: boolean, efectos: boolean, ahorro: boolean }

local ajustes: Ajustes = { musica = true, efectos = true, ahorro = false }
local sombrasOriginales = Lighting.GlobalShadows
local botones: { [string]: TextButton } = {}
local textoFps: TextLabel? = nil
local fpsActual = 60

local OPCIONES = {
	{ clave = "musica", texto = "🎵 Música", ayuda = "Música de fondo" },
	{ clave = "efectos", texto = "🔊 Sonidos", ayuda = "Compras, cobros, alarmas..." },
	{ clave = "ahorro", texto = "🔋 Modo ahorro", ayuda = "Menos efectos y sin sombras: más fluido en celulares" },
}

local function valor(clave: string): boolean
	return (ajustes :: any)[clave] == true
end

local function pintarBotones()
	for clave, boton in botones do
		local activo = valor(clave)
		boton.Text = if activo then "SÍ" else "NO"
		boton.BackgroundColor3 = if activo then Tema.COLORES.verde else Tema.COLORES.fondoClaro
	end
end

-- Aplica los ajustes en este dispositivo.
local function aplicar()
	SonidoController.activado = ajustes.efectos
	SonidoController.FijarMusica(ajustes.musica)
	EfectosController.calidad = if ajustes.ahorro then 0.3 else 1
	Lighting.GlobalShadows = if ajustes.ahorro then false else sombrasOriginales
	pintarBotones()
end

-- Modo ahorro activo (para otros controladores: Lluvia, efectos...).
function AjustesController.Ahorro(): boolean
	return ajustes.ahorro
end

local function cambiar(clave: string)
	local nuevo = not valor(clave);
	(ajustes :: any)[clave] = nuevo
	aplicar() -- se aplica al instante; el servidor lo guarda
	Red.Evento("AccionMenu"):FireServer("ajustes", { clave = clave, valor = nuevo })
end

local function desdeServidor(valorServidor: any)
	if type(valorServidor) ~= "table" then
		return
	end
	for _, opcion in OPCIONES do
		local v = valorServidor[opcion.clave]
		if type(v) == "boolean" then
			(ajustes :: any)[opcion.clave] = v
		end
	end
	aplicar()
end

-- Mide los FPS y sugiere el Modo ahorro si el juego va lento un buen rato.
local function vigilarRendimiento()
	local cuadros = 0
	local desde = os.clock()
	local ventanasLentas = 0
	local sugerido = false
	local inicio = os.clock()
	RunService.Heartbeat:Connect(function()
		cuadros += 1
		local ahora = os.clock()
		if ahora - desde < 5 then
			return
		end
		fpsActual = cuadros / (ahora - desde)
		cuadros = 0
		desde = ahora
		local t = textoFps
		if t then
			t.Text = `Rendimiento: {math.floor(fpsActual + 0.5)} FPS`
		end
		if sugerido or ajustes.ahorro or ahora - inicio < 45 then
			return
		end
		ventanasLentas = if fpsActual < 25 then ventanasLentas + 1 else 0
		if ventanasLentas >= 3 then
			sugerido = true
			NotificacionController.Avisar("🐢 ¿Va lento? Activa el 🔋 Modo ahorro en ⚙️ Ajustes", "info")
		end
	end)
end

function AjustesController.Iniciar()
	local v = Ventana.nueva("⚙️ Ajustes", 380, 300, Tema.COLORES.azul)
	local lista = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -24),
		Parent = v.contenido,
	})
	UI.Crear("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = lista,
	})
	for orden, opcion in OPCIONES do
		local fila = UI.Crear("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 52),
			LayoutOrder = orden,
			Parent = lista,
		})
		UI.Texto({
			texto = opcion.texto,
			tamano = UDim2.new(1, -100, 0, 28),
			tamanoLetra = 20,
			alineacion = Enum.TextXAlignment.Left,
			padre = fila,
		})
		UI.Texto({
			texto = opcion.ayuda,
			tamano = UDim2.new(1, -100, 0, 20),
			posicion = UDim2.fromOffset(0, 28),
			tamanoLetra = 13,
			alineacion = Enum.TextXAlignment.Left,
			color = Tema.COLORES.textoSuave,
			padre = fila,
		})
		local clave = opcion.clave
		botones[clave] = UI.Boton({
			texto = "",
			tamano = UDim2.fromOffset(84, 44),
			posicion = UDim2.fromScale(1, 0.5),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 18,
			alPulsar = function()
				cambiar(clave)
			end,
			padre = fila,
		})
	end
	textoFps = UI.Texto({
		texto = "Rendimiento: …",
		tamano = UDim2.new(1, 0, 0, 20),
		posicion = UDim2.new(0, 0, 1, -20),
		tamanoLetra = 13,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = v.contenido,
	})

	HudController.AgregarBoton("⚙️", Tema.COLORES.fondoClaro, 90, function()
		v:Alternar()
	end, "izquierda")

	desdeServidor(EstadoCliente.Obtener("ajustes"))
	EstadoCliente.Cambio:Conectar(function(parte: string, valorNuevo: any)
		if parte == "ajustes" then
			desdeServidor(valorNuevo)
		end
	end)
	aplicar()
	vigilarRendimiento()
end

return AjustesController
