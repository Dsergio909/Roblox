--!strict
--[[
	AlmacenService
	El Almacén FrutaMax: ROBAR SIN VÍCTIMAS (Config/Almacen).

	  1. En la puerta, "Entrar" (requiere Rebirth 1 y que haya pasado el tiempo de espera).
	  2. Te lleva al inicio de un pasillo con láseres que se deslizan de lado a lado.
	  3. Si tocas uno: alarma y sales (solo esperas unos segundos para reintentar).
	  4. Si llegas a la bodega, "Abrir la caja": un Crunchi al azar con las probabilidades
	     del cartel de la entrada.

	Los láseres NO existen en el servidor: el cliente los dibuja con la fórmula de
	Logica/Laseres y el reloj del servidor. El servidor usa la MISMA fórmula para saber si
	los tocaste, revisando el tramo entre dos posiciones (no solo el punto) y con una
	pequeña holgura a favor del jugador por la latencia.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigAlmacen = require(Shared:WaitForChild("Config"):WaitForChild("Almacen"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Laseres = require(Shared:WaitForChild("Logica"):WaitForChild("Laseres"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CanastaService = require(script.Parent:WaitForChild("CanastaService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))
local RoboService = require(script.Parent:WaitForChild("RoboService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Sesion = { inicio: number, t: number, avance: number, lado: number }

-- Tras el teletransporte, el dispositivo del jugador puede mandar un momento su posición
-- vieja (afuera). Durante este tiempo no se revisa nada para no sacarlo por error.
local GRACIA_SEGUNDOS = 1

local AlmacenService = {}

local sesiones: { [Player]: Sesion } = {}
local reintento: { [Player]: number } = {}

-- Marco del edificio: origen en el centro de la puerta (a nivel del piso) mirando hacia
-- adentro del pasillo (oeste). "Avance" = hacia adentro; "lado" = a lo ancho.
local ENTRADA = ConfigAlmacen.ENTRADA
local MARCO = CFrame.lookAt(ENTRADA, ENTRADA - Vector3.new(1, 0, 0))
local LARGO_TOTAL = ConfigAlmacen.LARGO_PASILLO + ConfigAlmacen.LARGO_BODEGA
local MEDIO_ANCHO = ConfigAlmacen.ANCHO_PASILLO / 2

local ROJO = Color3.fromRGB(230, 50, 50)
local GRIS = Color3.fromRGB(70, 74, 86)
local GRIS_CLARO = Color3.fromRGB(150, 155, 170)

local function aMundo(avance: number, lado: number, altura: number): CFrame
	return MARCO * CFrame.new(lado, altura, -avance)
end

local function aPasillo(posicion: Vector3): (number, number, number)
	local relativo = MARCO:PointToObjectSpace(posicion)
	return -relativo.Z, relativo.X, relativo.Y
end

local function raizDe(jugador: Player): BasePart?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

----------------------------------------------------------------------------- edificio

local function parte(
	modelo: Model,
	nombre: string,
	tamano: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = nombre
	p.Anchored = true
	p.Size = tamano
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.CanTouch = false
	p.Parent = modelo
	return p
end

local function cartel(padre: BasePart, texto: string, color: Color3, tamanoLetra: number?)
	local superficie = Instance.new("SurfaceGui")
	superficie.Face = Enum.NormalId.Back -- la cara que mira hacia la avenida
	superficie.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	superficie.PixelsPerStud = 30
	superficie.LightInfluence = 0
	superficie.Parent = padre
	local etiqueta = Instance.new("TextLabel")
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.Font = Enum.Font.FredokaOne
	etiqueta.TextColor3 = color
	etiqueta.RichText = true
	if tamanoLetra then
		etiqueta.TextSize = tamanoLetra
		etiqueta.TextWrapped = true
	else
		etiqueta.TextScaled = true
	end
	etiqueta.Text = texto
	etiqueta.Parent = superficie
end

-- Texto del cartel de probabilidades (las MISMAS que usa el sorteo).
local function textoProbabilidades(): string
	local pesos: { [string]: number } = ConfigAlmacen.PESOS :: any
	local total = 0
	for _, peso in pesos do
		total += peso
	end
	local lineas = { "<b>🎲 Probabilidades de la caja</b>" }
	for _, rareza in Catalogo.datos.rarezas do
		local peso = pesos[rareza.id]
		if peso and peso > 0 then
			local color = rareza.color:ToHex()
			table.insert(lineas, `<font color="#{color}">{rareza.nombre}</font>  {Formato.Porcentaje(peso / total)}`)
		end
	end
	table.insert(lineas, (string.gsub(Catalogo.TextoMutaciones(), " · ", "\n")))
	table.insert(lineas, "")
	table.insert(lineas, `Requisito: Rebirth {ConfigAlmacen.REQUISITO_REBIRTHS}`)
	table.insert(lineas, `Una caja cada {Formato.Duracion(ConfigAlmacen.COOLDOWN_SEGUNDOS)}`)
	return table.concat(lineas, "\n")
end

local function construir(): (BasePart, BasePart)
	local modelo = Instance.new("Model")
	modelo.Name = "AlmacenFrutaMax"
	local alto = ConfigAlmacen.ALTO

	-- Piso del pasillo y de la bodega
	parte(
		modelo,
		"Piso",
		Vector3.new(ConfigAlmacen.ANCHO_PASILLO + 2, 1.2, LARGO_TOTAL + 1),
		aMundo(LARGO_TOTAL / 2, 0, -0.6),
		Color3.fromRGB(215, 218, 225)
	)
	parte(
		modelo,
		"PisoBodega",
		Vector3.new(ConfigAlmacen.ANCHO_PASILLO, 0.1, ConfigAlmacen.LARGO_BODEGA),
		aMundo(ConfigAlmacen.LARGO_PASILLO + ConfigAlmacen.LARGO_BODEGA / 2, 0, 0.05),
		Color3.fromRGB(255, 215, 90)
	)
	-- Paredes (más altas que un salto: solo se entra por la puerta)
	for _, signo in { -1, 1 } do
		parte(
			modelo,
			"Pared",
			Vector3.new(1, alto, LARGO_TOTAL + 1),
			aMundo(LARGO_TOTAL / 2, signo * (MEDIO_ANCHO + 0.5), alto / 2),
			GRIS
		)
	end
	parte(
		modelo,
		"Fondo",
		Vector3.new(ConfigAlmacen.ANCHO_PASILLO + 2, alto, 1),
		aMundo(LARGO_TOTAL + 0.5, 0, alto / 2),
		GRIS
	)
	parte(modelo, "Frente", Vector3.new(ConfigAlmacen.ANCHO_PASILLO + 2, alto, 1), aMundo(-0.5, 0, alto / 2), GRIS)
	local puerta = parte(
		modelo,
		"Puerta",
		Vector3.new(5, 7, 0.4),
		aMundo(-1.2, 0, 3.5),
		Color3.fromRGB(40, 120, 200),
		Enum.Material.Metal
	)

	-- Letrero y cartel de probabilidades (hacia la avenida)
	local letrero = parte(
		modelo,
		"Letrero",
		Vector3.new(ConfigAlmacen.ANCHO_PASILLO, 2.4, 0.4),
		aMundo(-1.2, 0, alto - 1.6),
		Color3.fromRGB(25, 30, 45)
	)
	cartel(letrero, "🏭 ALMACÉN FRUTAMAX", Color3.fromRGB(255, 215, 90))
	local tablero = parte(
		modelo,
		"CartelProbabilidades",
		Vector3.new(8, 10, 0.4),
		aMundo(-2, MEDIO_ANCHO + 5.5, 5) * CFrame.Angles(0, math.rad(-20), 0),
		Color3.fromRGB(25, 30, 45)
	)
	cartel(tablero, textoProbabilidades(), Color3.new(1, 1, 1), 18)

	-- Emisores de láser en las paredes (decorado: los rayos los dibuja cada cliente)
	for _, laser in ConfigAlmacen.LASERES do
		for _, signo in { -1, 1 } do
			local emisor = parte(
				modelo,
				"Emisor",
				Vector3.new(0.4, alto - 1, 0.8),
				aMundo(laser.z, signo * (MEDIO_ANCHO - 0.1), (alto - 1) / 2),
				Color3.fromRGB(35, 35, 40),
				Enum.Material.Metal
			)
			emisor.CanCollide = false
		end
	end
	-- Línea de salida
	local linea = parte(
		modelo,
		"LineaSalida",
		Vector3.new(ConfigAlmacen.ANCHO_PASILLO, 0.1, 0.6),
		aMundo(3, 0, 0.05),
		Color3.fromRGB(90, 220, 90),
		Enum.Material.Neon
	)
	linea.CanCollide = false

	-- Caja fuerte al fondo de la bodega
	local caja = parte(
		modelo,
		"CajaFuerte",
		Vector3.new(5, 5, 4),
		aMundo(LARGO_TOTAL - 3, 0, 2.5),
		GRIS_CLARO,
		Enum.Material.DiamondPlate
	)
	local rueda = parte(
		modelo,
		"Rueda",
		Vector3.new(0.4, 2, 2),
		aMundo(LARGO_TOTAL - 5.1, 0, 2.5) * CFrame.Angles(0, math.rad(90), 0),
		ROJO
	)
	rueda.Shape = Enum.PartType.Cylinder

	modelo.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	modelo.Parent = MapaService.Carpeta or workspace
	return puerta, caja
end

----------------------------------------------------------------------------- sesiones

local function sacar(jugador: Player)
	local personaje = jugador.Character
	if personaje then
		local afuera = aMundo(-7, 0, 3).Position
		personaje:PivotTo(CFrame.lookAt(afuera, afuera + Vector3.new(1, 0, 0)))
	end
end

local function terminar(jugador: Player)
	sesiones[jugador] = nil
	if jugador.Parent then
		jugador:SetAttribute("AlmacenHasta", nil)
	end
end

local function fallar(jugador: Player, motivo: string)
	if sesiones[jugador] == nil then
		return
	end
	terminar(jugador)
	reintento[jugador] = Reloj.Ahora() + ConfigAlmacen.REINTENTO_SEGUNDOS
	if jugador.Parent == nil then
		return
	end
	sacar(jugador)
	if motivo == "laser" then
		RedServidor.Enviar("Efecto", jugador, "Laser")
		RedServidor.Notificar(
			jugador,
			`🚨 ¡Tocaste un láser! Vuelve a intentarlo en {ConfigAlmacen.REINTENTO_SEGUNDOS} s`,
			"alerta"
		)
	elseif motivo == "tiempo" then
		RedServidor.Notificar(jugador, "⏰ ¡Se acabó el tiempo! Vuelve a intentarlo", "alerta")
	end
	AnaliticaService.Evento(jugador, "AlmacenFallido", 1, { motivo })
end

local function entrar(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	local raiz = raizDe(jugador)
	if datos == nil or raiz == nil or sesiones[jugador] then
		return
	end
	local momento = Reloj.Ahora()
	if (raiz.Position - aMundo(-2, 0, 3).Position).Magnitude > 16 then
		return
	end
	if datos.rebirths < ConfigAlmacen.REQUISITO_REBIRTHS then
		RedServidor.Notificar(
			jugador,
			`🔒 El Almacén se abre con Rebirth {ConfigAlmacen.REQUISITO_REBIRTHS}`,
			"error"
		)
		return
	end
	if RoboService.EstaCargando(jugador) then
		RedServidor.Notificar(jugador, "¡Primero lleva tu Crunchi robado a tu base!", "error")
		return
	end
	if datos.almacen.proximo > momento then
		RedServidor.Notificar(
			jugador,
			`🏭 La próxima caja estará lista en {Formato.Duracion(datos.almacen.proximo - momento)}`,
			"info"
		)
		return
	end
	local espera = (reintento[jugador] or 0) - momento
	if espera > 0 then
		RedServidor.Notificar(jugador, `🚨 La alarma sigue sonando: espera {math.ceil(espera)} s`, "info")
		return
	end
	if BaseService.Destino(jugador) == nil then
		RedServidor.Notificar(jugador, "¡Tu base y tu depósito están llenos! Libera espacio primero", "error")
		return
	end

	local personaje = jugador.Character :: Model
	local inicio = aMundo(1.5, 0, 3).Position
	personaje:PivotTo(CFrame.lookAt(inicio, inicio + MARCO.LookVector))
	sesiones[jugador] = { inicio = momento, t = momento, avance = 1.5, lado = 0 }
	jugador:SetAttribute("AlmacenHasta", momento + ConfigAlmacen.TIEMPO_MAXIMO)
	RedServidor.Notificar(jugador, "🏭 ¡Esquiva los láseres rojos y llega a la caja fuerte!", "info")
	AnaliticaService.Evento(jugador, "AlmacenEntrada", 1)
end

local function abrirCaja(jugador: Player)
	local sesion = sesiones[jugador]
	local raiz = raizDe(jugador)
	local datos = DatosService.Obtener(jugador)
	if sesion == nil or raiz == nil or datos == nil then
		return
	end
	local momento = Reloj.Ahora()
	local avance = aPasillo(raiz.Position)
	if avance < ConfigAlmacen.LARGO_PASILLO or momento - sesion.inicio < ConfigAlmacen.TIEMPO_MINIMO then
		return
	end
	terminar(jugador)
	datos.almacen.proximo = momento + ConfigAlmacen.COOLDOWN_SEGUNDOS
	datos.almacen.veces += 1
	DatosService.ActualizarEstado(jugador, { "almacen" })

	local crunchiId, mutacion = CanastaService.Sortear(ConfigAlmacen.PESOS)
	local crunchi, esNuevo = nil, false
	if crunchiId then
		crunchi, esNuevo = BaseService.Otorgar(jugador, crunchiId, mutacion, true)
	end
	sacar(jugador)
	if crunchi == nil or crunchiId == nil then
		return
	end
	RedServidor.Enviar("Efecto", jugador, "Compra", { crunchi = crunchiId, mut = mutacion, nuevo = esNuevo })
	RedServidor.Notificar(
		jugador,
		`🏭 ¡Sacaste {Catalogo.NombreCompleto(crunchiId, mutacion)} del Almacén!`
			.. (if crunchi.lugar == 0 then " (está en tu depósito)" else ""),
		"exito"
	)
	local rareza = Catalogo.RarezaDe(crunchiId)
	if rareza and rareza.anunciar then
		RedServidor.EnviarATodos(
			"Anuncio",
			`¡{jugador.DisplayName} sacó {Catalogo.NombreCompleto(crunchiId, mutacion)} del Almacén FrutaMax!`,
			rareza.id
		)
	end
	AnaliticaService.Evento(jugador, "AlmacenExito", 1, { crunchiId, mutacion })
end

-- Cada frame, solo para quienes están adentro (pocos): ¿tocaron un láser?
local function vigilar()
	local momento = Reloj.Ahora()
	for jugador, sesion in sesiones do
		local raiz = raizDe(jugador)
		local personaje = jugador.Character
		local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
		if jugador.Parent == nil then
			terminar(jugador)
			continue
		end
		if raiz == nil or humanoide == nil or humanoide.Health <= 0 then
			fallar(jugador, "murio")
			continue
		end
		if momento - sesion.inicio > ConfigAlmacen.TIEMPO_MAXIMO then
			fallar(jugador, "tiempo")
			continue
		end
		local avance, lado = aPasillo((raiz :: BasePart).Position)
		if momento - sesion.inicio < GRACIA_SEGUNDOS then
			sesion.t = momento
			sesion.avance = math.max(avance, 0)
			sesion.lado = lado
			continue
		end
		if avance < -1 or math.abs(lado) > MEDIO_ANCHO + 2 or avance > LARGO_TOTAL + 2 then
			fallar(jugador, "salio")
			continue
		end
		-- La posición que ve el servidor llega con retraso: comparamos contra los láseres
		-- de ese momento (media latencia atrás).
		local retraso = math.clamp(jugador:GetNetworkPing() / 2, 0, 0.3)
		local tocado = Laseres.Tocado(
			ConfigAlmacen.LASERES,
			sesion.t - retraso,
			sesion.avance,
			sesion.lado,
			momento - retraso,
			avance,
			lado,
			ConfigAlmacen.ANCHO_LASER,
			ConfigAlmacen.HOLGURA
		)
		sesion.t = momento
		sesion.avance = avance
		sesion.lado = lado
		if tocado then
			fallar(jugador, "laser")
		end
	end
end

-- Nadie puede quedarse adentro sin una sesión (p. ej. si lo empujaron o reapareció ahí).
local function revisarIntrusos()
	for _, jugador in Players:GetPlayers() do
		if sesiones[jugador] == nil then
			local raiz = raizDe(jugador)
			if raiz then
				local avance, lado, altura = aPasillo(raiz.Position)
				if avance > 0 and avance < LARGO_TOTAL + 1 and math.abs(lado) < MEDIO_ANCHO + 1 and altura < 30 then
					sacar(jugador)
				end
			end
		end
	end
end

function AlmacenService.Iniciar()
	local puerta, caja = construir()

	local promptEntrar = Instance.new("ProximityPrompt")
	promptEntrar.Name = "Entrar"
	promptEntrar.ActionText = "Entrar"
	promptEntrar.ObjectText = "Almacén FrutaMax"
	promptEntrar.HoldDuration = 0.4
	promptEntrar.MaxActivationDistance = 10
	promptEntrar.RequiresLineOfSight = false
	promptEntrar.Parent = puerta
	promptEntrar.Triggered:Connect(entrar)

	local promptCaja = Instance.new("ProximityPrompt")
	promptCaja.Name = "AbrirCaja"
	promptCaja.ActionText = "Abrir la caja"
	promptCaja.ObjectText = "Caja fuerte"
	promptCaja.HoldDuration = 0.8
	promptCaja.MaxActivationDistance = 10
	promptCaja.RequiresLineOfSight = false
	promptCaja.Parent = caja
	promptCaja.Triggered:Connect(abrirCaja)

	RunService.Heartbeat:Connect(function()
		if next(sesiones) ~= nil then
			vigilar()
		end
	end)
	Reloj.Cada(0.5, revisarIntrusos)

	-- Estado privado: cuándo puede volver a entrar (para el HUD / el cartel).
	DatosService.RegistrarEstado("almacen", function(_, datos)
		return { proximo = datos.almacen.proximo }
	end)

	DatosService.JugadorSaliendo:Conectar(function(jugador: Player)
		terminar(jugador)
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		sesiones[jugador] = nil
		reintento[jugador] = nil
	end)

	AdminService.Registrar("almacen", function(jugador)
		local datos = DatosService.Obtener(jugador)
		if datos then
			datos.almacen.proximo = 0
			reintento[jugador] = nil
			RedServidor.Notificar(jugador, "🛠️ Almacén listo para entrar", "info")
		end
	end)
end

return AlmacenService
