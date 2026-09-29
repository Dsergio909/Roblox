--!strict
--[[
	AgenteService
	Los Agentes Escáner de FrutaMax: NPCs de traje con cabeza de ESCÁNER de supermercado
	(línea láser roja). Patrullan la avenida y persiguen a quien cargue un Crunchi robado.
	Si lo alcanzan, el Crunchi vuelve a su dueño.

	Redada FrutaMax (evento, Fase 4): llegan agentes EXTRA (con sirena) que entran a las
	bases y etiquetan Crunchis (dejan de producir un rato). Se van de un periodicazo, y
	quien les pega gana monedas. Nunca entran a bases con escudo o cerrojo.

	Rendimiento: pocos agentes (Config/Agentes), modelos de pocas partes sin animaciones
	y UN solo ciclo de IA para todos. Se mueven con Humanoid:MoveTo (física del servidor,
	que Roblox interpola suave en los clientes).

	El modelo es un placeholder hecho con partes. Para usar un modelo real, ponlo en
	ReplicatedStorage > Modelos > AgenteEscaner (ver docs/ASSETS_PENDIENTES.md, M3).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigAgentes = require(Shared:WaitForChild("Config"):WaitForChild("Agentes"))
local ConfigEventos = require(Shared:WaitForChild("Config"):WaitForChild("Eventos"))
local ConfigRobo = require(Shared:WaitForChild("Config"):WaitForChild("Robo"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local RoboService = require(script.Parent:WaitForChild("RoboService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Agente = {
	modelo: Model,
	humanoide: Humanoid,
	raiz: BasePart,
	-- Patrulla: "patrulla" | "persecucion" | "aturdido"
	-- Redada:   "buscando" | "entrando" | "etiquetando" | "saliendo" | "fuera"
	estado: string,
	objetivo: Player?,
	desde: number,
	punto: number,
	lugar: number, -- Redada: pedestal elegido
}

local AgenteService = {}

local agentes: { Agente } = {}
local redada: { Agente } = {}
local recompensas: { [Player]: number } = {} -- cuántas monedas de redada ganó cada uno
local carpeta: Folder
local REDADA = ConfigEventos.REDADA
local TIEMPO_ATASCADO = 15 -- segundos en un mismo paso = está atascado: vuelve a empezar

local TRAJE = Color3.fromRGB(31, 41, 55)
local GRIS = Color3.fromRGB(107, 114, 128)
local ROJO = Color3.fromRGB(255, 42, 42)

----------------------------------------------------------------------------- modelo

local function parte(
	modelo: Model,
	raiz: BasePart?,
	nombre: string,
	tamano: Vector3,
	desplazamiento: Vector3,
	color: Color3,
	material: Enum.Material?
): BasePart
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if raiz then
		p.Massless = true
		p.CFrame = raiz.CFrame * CFrame.new(desplazamiento)
		local soldadura = Instance.new("WeldConstraint")
		soldadura.Part0 = raiz
		soldadura.Part1 = p
		soldadura.Parent = p
	end
	p.Parent = modelo
	return p
end

local function crearModeloPlaceholder(conSirena: boolean): Model
	local modelo = Instance.new("Model")
	local raiz = parte(modelo, nil, "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero, TRAJE)
	raiz.Transparency = 1
	raiz.CanCollide = true
	parte(modelo, raiz, "Torso", Vector3.new(2, 2, 1), Vector3.zero, TRAJE)
	parte(modelo, raiz, "Corbata", Vector3.new(0.3, 1.3, 0.1), Vector3.new(0, 0.2, -0.55), ROJO)
	parte(modelo, raiz, "BrazoIzquierdo", Vector3.new(0.8, 2, 0.8), Vector3.new(-1.4, 0, 0), TRAJE)
	parte(modelo, raiz, "BrazoDerecho", Vector3.new(0.8, 2, 0.8), Vector3.new(1.4, 0, 0), TRAJE)
	parte(modelo, raiz, "PiernaIzquierda", Vector3.new(0.9, 2, 0.9), Vector3.new(-0.5, -2, 0), TRAJE)
	parte(modelo, raiz, "PiernaDerecha", Vector3.new(0.9, 2, 0.9), Vector3.new(0.5, -2, 0), TRAJE)
	-- Cabeza: escáner de supermercado con su ventana roja y la línea láser.
	parte(modelo, raiz, "Head", Vector3.new(1.8, 1.3, 1.4), Vector3.new(0, 1.7, 0), GRIS)
	parte(modelo, raiz, "Mango", Vector3.new(0.6, 1, 0.6), Vector3.new(0, 1.25, 0.6), GRIS)
	parte(modelo, raiz, "Ventana", Vector3.new(1.4, 0.7, 0.1), Vector3.new(0, 1.7, -0.72), ROJO, Enum.Material.Neon)
	local laser =
		parte(modelo, raiz, "Laser", Vector3.new(0.08, 0.08, 6), Vector3.new(0, 1.7, -3.7), ROJO, Enum.Material.Neon)
	laser.Transparency = 0.4
	if conSirena then
		parte(modelo, raiz, "Sirena", Vector3.new(0.8, 0.5, 0.8), Vector3.new(0, 2.6, 0), ROJO, Enum.Material.Neon)
	end
	modelo.PrimaryPart = raiz
	return modelo
end

local function crearAgente(indice: number, deRedada: boolean): Agente
	local plantilla = ReplicatedStorage:FindFirstChild("Modelos")
		and (ReplicatedStorage :: any).Modelos:FindFirstChild("AgenteEscaner")
	local modelo: Model
	if plantilla and plantilla:IsA("Model") and plantilla:FindFirstChild("HumanoidRootPart") then
		modelo = plantilla:Clone()
	else
		modelo = crearModeloPlaceholder(deRedada)
	end
	modelo.Name = if deRedada then `AgenteRedada{indice}` else `AgenteEscaner{indice}`

	local humanoide = modelo:FindFirstChildOfClass("Humanoid")
	if humanoide == nil then
		local nuevo = Instance.new("Humanoid")
		nuevo.RigType = Enum.HumanoidRigType.R15
		nuevo.HipHeight = 2 -- piernas de 2 studs bajo el torso
		nuevo.Parent = modelo
		humanoide = nuevo
	end
	local h = humanoide :: Humanoid
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.WalkSpeed = if deRedada then REDADA.VELOCIDAD else ConfigAgentes.VELOCIDAD_PATRULLA
	h.BreakJointsOnDeath = false
	h.MaxHealth = math.huge
	h.Health = math.huge

	local raiz = modelo:FindFirstChild("HumanoidRootPart") :: BasePart
	local puntos = ConfigAgentes.PATRULLA
	local inicio = puntos[((indice - 1) * 3) % #puntos + 1]
	modelo:PivotTo(CFrame.new(inicio + Vector3.new(0, 2, 0)))
	modelo.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	modelo.Parent = carpeta
	pcall(function()
		raiz:SetNetworkOwner(nil) -- el servidor simula a los agentes (no un jugador)
	end)

	return {
		modelo = modelo,
		humanoide = h,
		raiz = raiz,
		estado = "patrulla",
		objetivo = nil,
		desde = os.clock(),
		punto = ((indice - 1) * 3) % #puntos + 1,
		lugar = 0,
	}
end

----------------------------------------------------------------------------- IA

local function raizDe(jugador: Player): BasePart?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function patrullar(agente: Agente)
	agente.estado = "patrulla"
	agente.objetivo = nil
	agente.humanoide.WalkSpeed = ConfigAgentes.VELOCIDAD_PATRULLA
end

local function buscarLadron(agente: Agente): Player?
	local mejor: Player? = nil
	local mejorDistancia = ConfigAgentes.RADIO_DETECCION
	for _, jugador in Players:GetPlayers() do
		if jugador:GetAttribute("Cargando") == true then
			local raiz = raizDe(jugador)
			if raiz then
				local distancia = (raiz.Position - agente.raiz.Position).Magnitude
				if distancia < mejorDistancia then
					mejor = jugador
					mejorDistancia = distancia
				end
			end
		end
	end
	return mejor
end

local function pensar(agente: Agente)
	if agente.modelo.Parent == nil then
		return
	end
	local ahora = os.clock()

	if agente.estado == "aturdido" then
		if ahora - agente.desde >= ConfigAgentes.DESCANSO_TRAS_ATRAPAR then
			patrullar(agente)
		end
		return
	end

	if agente.estado == "persecucion" then
		local objetivo = agente.objetivo
		local raizObjetivo = if objetivo then raizDe(objetivo) else nil
		if
			objetivo == nil
			or raizObjetivo == nil
			or objetivo:GetAttribute("Cargando") ~= true
			or ahora - agente.desde > ConfigAgentes.TIEMPO_MAXIMO_PERSECUCION
		then
			patrullar(agente)
			return
		end
		local distancia = ((raizObjetivo :: BasePart).Position - agente.raiz.Position).Magnitude
		if distancia > ConfigAgentes.DISTANCIA_ABANDONO then
			patrullar(agente)
			return
		end
		if distancia <= ConfigAgentes.RADIO_ATRAPAR then
			local jugador = objetivo :: Player
			RoboService.Fallar(jugador, "agente")
			local direccion = ((raizObjetivo :: BasePart).Position - agente.raiz.Position) * Vector3.new(1, 0, 1)
			if direccion.Magnitude > 0 then
				RedServidor.Enviar("Empujon", jugador, direccion.Unit * 40, 25)
			end
			agente.estado = "aturdido"
			agente.objetivo = nil
			agente.desde = ahora
			agente.humanoide:MoveTo(agente.raiz.Position)
			return
		end
		agente.humanoide:MoveTo((raizObjetivo :: BasePart).Position)
		return
	end

	-- Patrulla: ¿hay algún ladrón cerca?
	local ladron = buscarLadron(agente)
	if ladron then
		agente.estado = "persecucion"
		agente.objetivo = ladron
		agente.desde = ahora
		agente.humanoide.WalkSpeed = ConfigAgentes.VELOCIDAD_PERSECUCION
		RedServidor.Notificar(ladron, "🔎 ¡Un Agente Escáner te vio! ¡Corre!", "alerta")
		return
	end
	local puntos = ConfigAgentes.PATRULLA
	local destino = puntos[agente.punto]
	if (agente.raiz.Position - destino).Magnitude < 5 or ahora - agente.desde > 20 then
		agente.punto = agente.punto % #puntos + 1
		agente.desde = ahora
		destino = puntos[agente.punto]
	end
	agente.humanoide:MoveTo(destino)
end

----------------------------------------------------------------------------- redada

local function objetivoTomado(dueno: Player, lugar: number, excepto: Agente): boolean
	for _, otro in redada do
		if otro ~= excepto and otro.objetivo == dueno and otro.lugar == lugar and otro.estado ~= "fuera" then
			return true
		end
	end
	return false
end

-- Elige al azar un Crunchi que se pueda etiquetar (y que otro agente no haya elegido).
local function elegirObjetivo(agente: Agente): (Player?, number)
	local opciones: { { dueno: Player, lugar: number } } = {}
	for _, dueno in BaseService.Duenos() do
		local estado = BaseService.Estado(dueno)
		if estado then
			for lugar in estado.pedestales do
				if BaseService.PuedeEtiquetar(dueno, lugar) and not objetivoTomado(dueno, lugar, agente) then
					table.insert(opciones, { dueno = dueno, lugar = lugar })
				end
			end
		end
	end
	if #opciones == 0 then
		return nil, 0
	end
	local elegido = opciones[math.random(1, #opciones)]
	return elegido.dueno, elegido.lugar
end

local function puntoDeEntrada(): Vector3
	local puntos = ConfigAgentes.PATRULLA
	return puntos[math.random(1, #puntos)]
end

local function reubicar(agente: Agente, posicion: Vector3)
	agente.modelo:PivotTo(CFrame.new(posicion + Vector3.new(0, 2, 0)))
end

local function cambiar(agente: Agente, estado: string)
	agente.estado = estado
	agente.desde = os.clock()
end

local function pensarRedada(agente: Agente)
	local ahora = os.clock()
	local enPaso = ahora - agente.desde

	if agente.estado == "fuera" then
		if enPaso >= REDADA.REGRESO_SEGUNDOS then
			reubicar(agente, puntoDeEntrada())
			agente.modelo.Parent = carpeta
			pcall(function()
				agente.raiz:SetNetworkOwner(nil)
			end)
			cambiar(agente, "buscando")
		end
		return
	end

	if agente.estado == "buscando" then
		local dueno, lugar = elegirObjetivo(agente)
		if dueno then
			agente.objetivo = dueno
			agente.lugar = lugar
			cambiar(agente, "entrando")
		elseif enPaso > 4 then
			-- Nada que etiquetar: da una vuelta por la avenida.
			agente.humanoide:MoveTo(puntoDeEntrada())
			agente.desde = ahora
		end
		return
	end

	local dueno = agente.objetivo
	local estado = if dueno then BaseService.Estado(dueno) else nil
	if dueno == nil or estado == nil or enPaso > TIEMPO_ATASCADO then
		-- El dueño se fue o el agente se atascó: vuelve a empezar desde la avenida.
		if enPaso > TIEMPO_ATASCADO then
			reubicar(agente, puntoDeEntrada())
		end
		agente.objetivo = nil
		cambiar(agente, "buscando")
		return
	end
	local base = (estado :: BaseService.EstadoBase).mapa
	local salida = base.salida.Position

	if agente.estado == "saliendo" then
		if (agente.raiz.Position - salida).Magnitude < 5 then
			agente.objetivo = nil
			cambiar(agente, "buscando")
		else
			agente.humanoide:MoveTo(salida)
		end
		return
	end

	-- La base se protegió (cerrojo o escudo) o el Crunchi ya no se puede etiquetar.
	if not BaseService.PuedeEtiquetar(dueno :: Player, agente.lugar) then
		local adentro = MapaService.DentroDeBase(base, agente.raiz.Position)
		if adentro and BaseService.CerrojoActivo(dueno :: Player) then
			reubicar(agente, salida) -- el cerrojo lo saca, igual que a los jugadores
			adentro = false
		end
		if adentro then
			cambiar(agente, "saliendo")
		else
			agente.objetivo = nil
			cambiar(agente, "buscando")
		end
		return
	end

	if agente.estado == "entrando" then
		if (agente.raiz.Position - salida).Magnitude < 5 then
			cambiar(agente, "etiquetando")
		else
			agente.humanoide:MoveTo(salida)
		end
		return
	end

	if agente.estado == "etiquetando" then
		local destino = base.pedestales[agente.lugar].ancla.Position
		local plano = (destino - agente.raiz.Position) * Vector3.new(1, 0, 1)
		if plano.Magnitude < 5 then
			local crunchiId = (estado :: BaseService.EstadoBase).pedestales[agente.lugar].crunchiId
			if BaseService.Etiquetar(dueno :: Player, agente.lugar, REDADA.SEGUNDOS_ETIQUETA) then
				local def = if crunchiId then Catalogo.datos.crunchi[crunchiId] else nil
				RedServidor.Notificar(
					dueno :: Player,
					`🏷️ ¡Un Agente etiquetó a {if def then def.nombre else "tu Crunchi"}! Dale con el 🗞️ periódico`,
					"alerta"
				)
			end
			cambiar(agente, "saliendo")
		else
			agente.humanoide:MoveTo(destino)
		end
	end
end

-- Un periodicazo: ¿le dio a algún agente de la redada?
local function alPeriodicazo(golpeador: Player, posicion: Vector3, frente: Vector3)
	for _, agente in redada do
		if agente.estado == "fuera" or agente.modelo.Parent == nil then
			continue
		end
		local diferencia = agente.raiz.Position - posicion
		local plano = Vector3.new(diferencia.X, 0, diferencia.Z)
		local distancia = plano.Magnitude
		local enFrente = distancia < 3 or (distancia > 0 and frente:Dot(plano.Unit) > 0.2)
		if distancia <= ConfigRobo.PERIODICO_ALCANCE + 1 and math.abs(diferencia.Y) < 6 and enFrente then
			local lugarGolpe = agente.raiz.Position
			agente.modelo.Parent = nil -- se va corriendo (vuelve en unos segundos)
			agente.objetivo = nil
			cambiar(agente, "fuera")
			RedServidor.Enviar("Efecto", golpeador, "AgenteFuera", { posicion = lugarGolpe })

			local cuantas = recompensas[golpeador] or 0
			if cuantas < REDADA.MAX_RECOMPENSAS then
				recompensas[golpeador] = cuantas + 1
				local monto =
					EconomiaService.DineroPorMinutos(golpeador, REDADA.RECOMPENSA_MINUTOS, REDADA.RECOMPENSA_MINIMA)
				EconomiaService.Agregar(golpeador, monto, AnaliticaService.Tipo.Juego, "redada")
				RedServidor.Notificar(golpeador, `🗞️ ¡Agente fuera! +{Formato.Dinero(monto)}`, "exito")
			else
				RedServidor.Notificar(golpeador, "🗞️ ¡Agente fuera!", "exito")
			end
			AnaliticaService.Evento(golpeador, "AgenteRedada", 1)
		end
	end
end

function AgenteService.IniciarRedada()
	AgenteService.TerminarRedada()
	table.clear(recompensas)
	for indice = 1, REDADA.AGENTES do
		local agente = crearAgente(100 + indice, true)
		reubicar(agente, puntoDeEntrada())
		agente.estado = "buscando"
		table.insert(redada, agente)
	end
end

function AgenteService.TerminarRedada()
	for _, agente in redada do
		agente.modelo:Destroy()
	end
	table.clear(redada)
end

function AgenteService.Iniciar()
	local nueva = Instance.new("Folder")
	nueva.Name = "Agentes"
	nueva.Parent = workspace
	carpeta = nueva
	for indice = 1, ConfigAgentes.CANTIDAD do
		table.insert(agentes, crearAgente(indice, false))
	end
	Reloj.Cada(ConfigAgentes.CICLO_IA, function()
		for _, agente in agentes do
			local ok, err = pcall(pensar :: any, agente)
			if not ok then
				warn(`[Agentes] {err}`)
			end
		end
		for _, agente in redada do
			local ok, err = pcall(pensarRedada :: any, agente)
			if not ok then
				warn(`[Agentes] Redada: {err}`)
			end
		end
	end)
	RoboService.Periodicazo:Conectar(alPeriodicazo)
	Players.PlayerRemoving:Connect(function(jugador)
		recompensas[jugador] = nil
	end)
end

return AgenteService
