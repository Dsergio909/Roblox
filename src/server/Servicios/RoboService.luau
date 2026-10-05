--!strict
--[[
	RoboService
	Robar Crunchis de otras bases y defender la propia con el periódico enrollado.

	Flujo de un robo:
	  1. El ladrón mantiene "Robar" sobre un Crunchi ajeno → se validan TODAS las
	     protecciones (escudos, cerrojo, bóveda, nivel, límites...).
	  2. El ladrón carga el Crunchi sobre la cabeza, camina más lento y brilla en rojo.
	     El dueño recibe una alarma.
	  3a. Si llega a su base → el Crunchi pasa a ser suyo.
	  3b. Si recibe un periodicazo, muere, se desconecta, el dueño se va o se acaba el
	      tiempo → el Crunchi vuelve a su dueño.

	Mientras dura el robo, el Crunchi SIGUE en los datos del dueño. Solo se transfiere al
	completarse, así nunca se pierde ni se duplica si algo falla a mitad de camino.

	Ninguna protección se puede comprar (ver docs/GAME_DESIGN.md §5).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigRobo = require(Shared:WaitForChild("Config"):WaitForChild("Robo"))
local ConfigArmas = require(Shared:WaitForChild("Config"):WaitForChild("Armas"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local ModeloCrunchi = require(Shared:WaitForChild("ModeloCrunchi"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

type Robo = {
	ladron: Player,
	dueno: Player,
	uid: string,
	lugarDueno: number,
	lugarLadron: number,
	crunchiId: string,
	mutacion: string,
	modelo: Model?,
	inicio: number,
	origen: Vector3, -- dónde estaba el ladrón al agarrar el Crunchi (antitrampas)
	velocidadOriginal: number,
	resaltado: Highlight?,
	conexiones: { RBXScriptConnection },
}

local RoboService = {
	-- (ladron, dueno, crunchi: CrunchiGuardado)
	RoboCompletado = Senal.nueva(),
	-- (ladron, dueno, motivo: string, defensor: Player?)
	RoboFallido = Senal.nueva(),
	-- (ladron, dueno)
	RoboIniciado = Senal.nueva(),
	-- (golpeador, posicion: Vector3, frente: Vector3, arma: Arma) — alguien dio un golpe con
	-- su arma de defensa (los agentes de la Redada lo escuchan para saber si les pegaron)
	Periodicazo = Senal.nueva(),
}

local robos: { [Player]: Robo } = {} -- clave: el ladrón
local cooldownPar: { [string]: number } = {} -- "ladron:victima" → hasta cuándo
local ultimoGolpe: { [Player]: number } = {}
type Arma = ConfigArmas.Arma
local armaPorId: { [string]: Arma } = {}
for _, arma in ConfigArmas.LISTA do
	armaPorId[arma.id] = arma
end
local plantillas: { [string]: Tool } = {}
local ATRIBUTO_ARMA = "ArmaCrunch" -- marca las herramientas que son armas de defensa

----------------------------------------------------------------------------- utilidades

local function raizDe(jugador: Player): BasePart?
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		return raiz
	end
	return nil
end

local function humanoideDe(jugador: Player): Humanoid?
	local personaje = jugador.Character
	return personaje and personaje:FindFirstChildOfClass("Humanoid")
end

local function clavePar(ladron: Player, victima: Player): string
	return `{ladron.UserId}:{victima.UserId}`
end

function RoboService.EstaCargando(jugador: Player): boolean
	return robos[jugador] ~= nil
end

-- ¿Alguien le está robando a este jugador ahora mismo?
function RoboService.EstaSiendoRobado(dueno: Player): boolean
	for _, robo in robos do
		if robo.dueno == dueno then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------------- validación

-- Devuelve (true, lugarDueno, lugarLadron) o (false, motivo).
local function validar(ladron: Player, dueno: Player, uid: string): (boolean, any, number?)
	if ladron == dueno then
		return false, nil
	end
	local datosLadron = DatosService.Obtener(ladron)
	local datosDueno = DatosService.Obtener(dueno)
	if datosLadron == nil or datosDueno == nil then
		return false, nil
	end
	if robos[ladron] then
		return false, "¡Ya estás cargando un Crunchi!"
	end
	local humanoide = humanoideDe(ladron)
	if humanoide == nil or humanoide.Health <= 0 then
		return false, nil
	end

	local lugar = BaseService.LugarDe(dueno, uid)
	local estadoDueno = BaseService.Estado(dueno)
	if lugar == nil or estadoDueno == nil then
		return false, "Ese Crunchi ya no está ahí"
	end
	if estadoDueno.pedestales[lugar].enRobo then
		return false, "¡Alguien ya lo está robando!"
	end
	if BaseService.EsBoveda(dueno, lugar) then
		return false, "🔒 Ese Crunchi está en la bóveda: no se puede robar"
	end
	local escudo = BaseService.EscudoRestante(dueno)
	if escudo > 0 then
		return false, `🛡️ Esta base tiene escudo ({Formato.Tiempo(escudo)})`
	end
	if BaseService.CerrojoActivo(dueno) then
		return false, "🔒 Esta base está cerrada"
	end
	if datosLadron.rebirths - datosDueno.rebirths >= ConfigRobo.DIFERENCIA_REBIRTHS then
		return false, "Solo puedes robar a jugadores de tu nivel (por rebirths)"
	end
	local hasta = cooldownPar[clavePar(ladron, dueno)]
	if hasta and hasta > Reloj.Ahora() then
		return false, `Ya le robaste hace poco a {dueno.DisplayName}. Espera {Formato.Tiempo(hasta - Reloj.Ahora())}`
	end
	local lugarLadron = BaseService.LugarLibre(ladron)
	if lugarLadron == nil then
		return false, "¡Tu base está llena! Vende un Crunchi para poder robar"
	end

	local raiz = raizDe(ladron)
	local modelo = estadoDueno.pedestales[lugar].modelo
	if raiz == nil or modelo == nil then
		return false, nil
	end
	if (raiz.Position - modelo:GetPivot().Position).Magnitude > ConfigRobo.DISTANCIA_MAXIMA then
		return false, "Acércate más"
	end
	return true, lugar, lugarLadron
end

----------------------------------------------------------------------------- final del robo

local function limpiarLadron(robo: Robo)
	for _, conexion in robo.conexiones do
		conexion:Disconnect()
	end
	if robo.modelo then
		robo.modelo:Destroy()
		robo.modelo = nil
	end
	if robo.resaltado then
		robo.resaltado:Destroy()
	end
	local ladron = robo.ladron
	if ladron.Parent then
		local humanoide = humanoideDe(ladron)
		if humanoide then
			humanoide.WalkSpeed = robo.velocidadOriginal
		end
		ladron:SetAttribute("Cargando", false)
		ladron:SetAttribute("CargandoCrunchi", nil)
		ladron:SetAttribute("CargandoHasta", nil)
	end
	BaseService.Reservar(ladron, robo.lugarLadron, false)
end

local MENSAJES_FALLO: { [string]: string } = {
	golpe = "¡Te dieron un periodicazo y soltaste el Crunchi!",
	tiempo = "¡Se acabó el tiempo! El Crunchi volvió a su base",
	murio = "Soltaste el Crunchi",
	dueno_salio = "El dueño se fue: el Crunchi volvió con él",
	agente = "🔎 ¡Un Agente Escáner te atrapó! El Crunchi volvió a su dueño",
	ladron_salio = "",
	trampa = "El Crunchi volvió a su dueño",
}

function RoboService.Fallar(ladron: Player, motivo: string, defensor: Player?)
	local robo = robos[ladron]
	if robo == nil then
		return
	end
	robos[ladron] = nil
	limpiarLadron(robo)

	local dueno = robo.dueno
	local nombre = Catalogo.NombreCompleto(robo.crunchiId, robo.mutacion)
	if dueno.Parent then
		BaseService.DevolverCrunchi(dueno, robo.uid)
		RedServidor.Enviar("Alarma", dueno, false)
		if motivo == "golpe" or motivo == "tiempo" or motivo == "murio" or motivo == "agente" then
			RedServidor.Notificar(dueno, `¡Recuperaste a {nombre}!`, "exito")
		end
	end
	if ladron.Parent and MENSAJES_FALLO[motivo] and MENSAJES_FALLO[motivo] ~= "" then
		RedServidor.Notificar(ladron, MENSAJES_FALLO[motivo], "error")
	end
	if defensor and defensor.Parent then
		local datosDefensor = DatosService.Obtener(defensor)
		if datosDefensor then
			datosDefensor.stats.defensas += 1
		end
		if defensor ~= dueno then
			RedServidor.Notificar(defensor, `¡Detuviste a {ladron.DisplayName}! 🗞️`, "exito")
		end
		AnaliticaService.Onboarding(defensor, "PrimerRoboODefensa")
		AnaliticaService.Evento(defensor, "Defensa", 1, { robo.crunchiId })
	end
	if ladron.Parent then
		AnaliticaService.Evento(ladron, "RoboFallido", 1, { motivo, robo.crunchiId })
	end
	RoboService.RoboFallido:Disparar(ladron, dueno, motivo, defensor)
end

local function completar(robo: Robo)
	local ladron, dueno = robo.ladron, robo.dueno
	local datosLadron = DatosService.Obtener(ladron)
	local datosDueno = DatosService.Obtener(dueno)
	if datosLadron == nil or datosDueno == nil then
		RoboService.Fallar(ladron, "dueno_salio")
		return
	end

	-- Quitar de los datos del dueño
	local crunchi: Tipos.CrunchiGuardado? = nil
	for indice, guardado in datosDueno.crunchis do
		if guardado.uid == robo.uid then
			crunchi = table.remove(datosDueno.crunchis, indice)
			break
		end
	end
	if crunchi == nil then
		RoboService.Fallar(ladron, "dueno_salio")
		return
	end

	robos[ladron] = nil
	limpiarLadron(robo)
	BaseService.VaciarPedestal(dueno, robo.lugarDueno)

	-- Agregar a los datos del ladrón
	crunchi.lugar = robo.lugarLadron
	table.insert(datosLadron.crunchis, crunchi)
	DatosService.RegistrarIndice(ladron, crunchi.id, crunchi.mut)
	BaseService.Colocar(ladron, crunchi)

	datosLadron.stats.robosExitosos += 1
	datosDueno.stats.robosSufridos += 1
	cooldownPar[clavePar(ladron, dueno)] = Reloj.Ahora() + ConfigRobo.COOLDOWN_PAR
	BaseService.ActivarRevancha(ladron)
	BaseService.RegistrarRoboSufrido(dueno)

	-- Transferencia entre dos jugadores: guardamos ambos ya para reducir riesgos.
	DatosService.GuardarYa(ladron)
	DatosService.GuardarYa(dueno)

	local nombre = Catalogo.NombreCompleto(crunchi.id, crunchi.mut)
	RedServidor.Enviar("Alarma", dueno, false)
	RedServidor.Notificar(dueno, `😱 {ladron.DisplayName} te robó a {nombre}`, "alerta")
	RedServidor.Notificar(
		ladron,
		`¡Robaste a {nombre}! Tu cerrojo se recarga en {ConfigRobo.REVANCHA} s: ¡cuidado con la revancha!`,
		"exito"
	)
	RedServidor.Enviar("Efecto", ladron, "Robo", { crunchi = crunchi.id, mut = crunchi.mut })

	local rareza = Catalogo.RarezaDe(crunchi.id)
	if rareza and rareza.orden >= 5 then
		RedServidor.EnviarATodos(
			"Anuncio",
			`¡{ladron.DisplayName} le robó {nombre} a {dueno.DisplayName}!`,
			rareza.id
		)
	end
	AnaliticaService.Evento(ladron, "RoboExitoso", 1, { crunchi.id, crunchi.mut })
	RoboService.RoboCompletado:Disparar(ladron, dueno, crunchi)
end

----------------------------------------------------------------------------- inicio del robo

function RoboService.Intentar(ladron: Player, dueno: Player, uid: string)
	local ok, lugarOMotivo, lugarLadron = validar(ladron, dueno, uid)
	if not ok then
		if type(lugarOMotivo) == "string" then
			RedServidor.Notificar(ladron, lugarOMotivo, "error")
		end
		return
	end
	local lugar = lugarOMotivo :: number
	local lugarDestino = lugarLadron :: number
	local personaje = ladron.Character
	local cabeza = personaje and personaje:FindFirstChild("Head")
	local humanoide = humanoideDe(ladron)
	if not (cabeza and cabeza:IsA("BasePart")) or humanoide == nil then
		return
	end

	local estadoDueno = BaseService.Estado(dueno)
	if estadoDueno == nil then
		return
	end
	local pedestal = estadoDueno.pedestales[lugar]
	local crunchiId = pedestal.crunchiId :: string
	local mutacion = pedestal.mutacion or "normal"

	-- Robar mientras tienes escudo sería injusto: lo pierdes.
	if ConfigRobo.ROBAR_QUITA_ESCUDO and BaseService.EscudoRestante(ladron) > 0 then
		BaseService.QuitarEscudo(ladron)
		RedServidor.Notificar(ladron, "Perdiste tu escudo por robar", "alerta")
	end

	BaseService.Reservar(ladron, lugarDestino, true)
	local modelo = BaseService.TomarModelo(dueno, lugar)
	if modelo == nil then
		BaseService.Reservar(ladron, lugarDestino, false)
		return
	end

	-- Preparar el modelo para cargarlo sobre la cabeza (sin acciones, sin peso).
	for _, descendiente in modelo:GetDescendants() do
		if descendiente:IsA("ProximityPrompt") then
			descendiente:Destroy()
		elseif descendiente:IsA("BasePart") then
			descendiente.Massless = true
			descendiente.CanCollide = false
		end
	end
	local escala = ModeloCrunchi.Escala(crunchiId)
	local reduccion = math.min(1, 1.4 / escala) -- los gigantes se achican un poco al cargarlos
	if reduccion < 1 then
		modelo:ScaleTo(reduccion)
	end
	modelo:PivotTo(cabeza.CFrame * CFrame.new(0, cabeza.Size.Y / 2 + 0.2, 0))
	local cuerpo = modelo.PrimaryPart :: BasePart
	cuerpo.Anchored = false
	local soldadura = Instance.new("WeldConstraint")
	soldadura.Part0 = cabeza
	soldadura.Part1 = cuerpo
	soldadura.Parent = cuerpo
	modelo.Parent = personaje

	local resaltado = Instance.new("Highlight")
	resaltado.Name = "Ladron"
	resaltado.FillTransparency = 1
	resaltado.OutlineColor = Color3.fromRGB(255, 50, 50)
	resaltado.DepthMode = Enum.HighlightDepthMode.Occluded
	resaltado.Parent = personaje

	local raizLadron = raizDe(ladron)
	local robo: Robo = {
		ladron = ladron,
		dueno = dueno,
		uid = uid,
		lugarDueno = lugar,
		lugarLadron = lugarDestino,
		crunchiId = crunchiId,
		mutacion = mutacion,
		modelo = modelo,
		inicio = Reloj.Ahora(),
		origen = if raizLadron then raizLadron.Position else cabeza.Position,
		velocidadOriginal = humanoide.WalkSpeed,
		resaltado = resaltado,
		conexiones = {},
	}
	robos[ladron] = robo

	humanoide.WalkSpeed = robo.velocidadOriginal * ConfigRobo.VELOCIDAD_CARGANDO
	table.insert(
		robo.conexiones,
		humanoide.Died:Connect(function()
			RoboService.Fallar(ladron, "murio")
		end)
	)

	ladron:SetAttribute("Cargando", true)
	ladron:SetAttribute("CargandoCrunchi", crunchiId)
	ladron:SetAttribute("CargandoHasta", robo.inicio + ConfigRobo.TIEMPO_MAXIMO_CARGA)

	RedServidor.Enviar("Alarma", dueno, true, ladron.UserId)
	RedServidor.Notificar(ladron, `¡Llévalo a tu base! Tienes {ConfigRobo.TIEMPO_MAXIMO_CARGA} segundos`, "alerta")
	AnaliticaService.Onboarding(ladron, "PrimerRoboODefensa")
	AnaliticaService.Evento(ladron, "RoboIniciado", 1, { crunchiId })
	RoboService.RoboIniciado:Disparar(ladron, dueno)
end

----------------------------------------------------------------------------- armas de defensa

-- Herramienta de un arma: el modelo real (ReplicatedStorage > Modelos > Armas > <id>) o un
-- placeholder hecho con una parte. Lleva el atributo ATRIBUTO_ARMA con el id del arma.
local function crearHerramienta(arma: Arma): Tool
	local modelos = ReplicatedStorage:FindFirstChild("Modelos")
	local carpeta = modelos and modelos:FindFirstChild("Armas")
	local real = carpeta and carpeta:FindFirstChild(arma.id)
	if real and real:IsA("Tool") and real:FindFirstChild("Handle") then
		local copia = real:Clone()
		copia.Name = arma.nombre
		copia.CanBeDropped = false
		copia:SetAttribute(ATRIBUTO_ARMA, arma.id)
		return copia
	end

	local herramienta = Instance.new("Tool")
	herramienta.Name = arma.nombre
	herramienta.ToolTip = arma.descripcion
	herramienta.CanBeDropped = false
	herramienta.RequiresHandle = true
	herramienta.Grip = CFrame.new(0, 0, math.max(0, arma.tamano.Z / 2 - 0.4))
	herramienta:SetAttribute(ATRIBUTO_ARMA, arma.id)

	local mango = Instance.new("Part")
	mango.Name = "Handle"
	if arma.forma == "Ball" then
		mango.Shape = Enum.PartType.Ball
	end
	mango.Size = arma.tamano
	mango.Color = arma.color
	local ok, material = pcall(function()
		return (Enum.Material :: any)[arma.material]
	end)
	mango.Material = if ok and material then material else Enum.Material.SmoothPlastic
	mango.CanCollide = false
	mango.CanQuery = false
	mango.CanTouch = false
	mango.CastShadow = false
	mango.Massless = true
	mango.Parent = herramienta
	return herramienta
end

-- El arma equipada del jugador (la decide el servidor; si no hay datos, el periódico).
function RoboService.ArmaDe(jugador: Player): Arma
	local datos = DatosService.Obtener(jugador)
	local arma = if datos then armaPorId[datos.armaEquipada] else nil
	return arma or armaPorId[ConfigArmas.INICIAL]
end

local function golpear(golpeador: Player, herramienta: Tool)
	local arma = RoboService.ArmaDe(golpeador)
	-- Solo cuenta el arma que el servidor le dio y que tiene en la mano.
	if herramienta:GetAttribute(ATRIBUTO_ARMA) ~= arma.id or herramienta.Parent ~= golpeador.Character then
		return
	end
	local momento = os.clock()
	if (ultimoGolpe[golpeador] or 0) + arma.cooldown > momento then
		return
	end
	ultimoGolpe[golpeador] = momento
	local raiz = raizDe(golpeador)
	if raiz == nil then
		return
	end
	local frente = raiz.CFrame.LookVector
	RoboService.Periodicazo:Disparar(golpeador, raiz.Position, frente, arma)
	for _, otro in Players:GetPlayers() do
		if otro ~= golpeador then
			local raizOtro = raizDe(otro)
			if raizOtro then
				local diferencia = raizOtro.Position - raiz.Position
				local plano = Vector3.new(diferencia.X, 0, diferencia.Z)
				local distancia = plano.Magnitude
				local enFrente = distancia < 2.5 or (distancia > 0 and frente:Dot(plano.Unit) > arma.cono)
				if distancia <= arma.alcance and math.abs(diferencia.Y) < 6 and enFrente then
					-- Solo afecta a ladrones que cargan un Crunchi o a intrusos en tu base:
					-- las armas no sirven para molestar a cualquiera.
					local esLadron = robos[otro] ~= nil
					local esIntruso = BaseService.EstaEnBaseDe(otro, golpeador)
					if esLadron or esIntruso then
						if esLadron then
							RoboService.Fallar(otro, "golpe", golpeador)
						end
						local direccion = if distancia > 0 then plano.Unit else frente
						RedServidor.Enviar("Empujon", otro, direccion * arma.empuje, arma.empujeArriba)
						RedServidor.Enviar("Efecto", golpeador, "Golpe", { arma = arma.id })
						RedServidor.Enviar("Efecto", otro, "Golpe", { arma = arma.id })
					end
				end
			end
		end
	end
end

local function quitarArmas(jugador: Player, personaje: Model?)
	local contenedores: { Instance? } = { jugador:FindFirstChildOfClass("Backpack"), personaje }
	for _, contenedor in contenedores do
		if contenedor then
			for _, hijo in contenedor:GetChildren() do
				if hijo:IsA("Tool") and hijo:GetAttribute(ATRIBUTO_ARMA) ~= nil then
					hijo:Destroy()
				end
			end
		end
	end
end

-- Da (o cambia) el arma del jugador. Si tenía la anterior en la mano, equipa la nueva.
local function darArma(jugador: Player, personaje: Model)
	local mochila = jugador:WaitForChild("Backpack", 10)
	if mochila == nil or personaje.Parent == nil or jugador.Character ~= personaje then
		return
	end
	local arma = RoboService.ArmaDe(jugador)
	local plantilla: Tool? = plantillas[arma.id]
	if plantilla == nil then
		return
	end
	local enMano = personaje:FindFirstChildOfClass("Tool")
	local teniaEnMano = enMano ~= nil and enMano:GetAttribute(ATRIBUTO_ARMA) ~= nil
	quitarArmas(jugador, personaje)
	local herramienta = plantilla:Clone()
	herramienta.Activated:Connect(function()
		golpear(jugador, herramienta)
	end)
	herramienta.Parent = mochila
	local humanoide = personaje:FindFirstChildOfClass("Humanoid")
	if teniaEnMano and humanoide then
		humanoide:EquipTool(herramienta)
	end
end

-- Lo llama ArmaService al cambiar de arma.
function RoboService.ActualizarArma(jugador: Player)
	local personaje = jugador.Character
	if personaje then
		task.spawn(darArma, jugador, personaje)
	end
end

----------------------------------------------------------------------------- inicio

-- ¿Se alejó del punto del robo más rápido de lo que se puede caminar? (teletransporte o
-- "speed hack"). La velocidad la decide el servidor (lo que cambie el cliente no cuenta).
local function movimientoImposible(robo: Robo, momento: number): boolean
	local raiz = raizDe(robo.ladron)
	if raiz == nil then
		return false
	end
	local plano = (raiz.Position - robo.origen) * Vector3.new(1, 0, 1)
	local velocidad = robo.velocidadOriginal * ConfigRobo.VELOCIDAD_CARGANDO * ConfigRobo.ANTITRAMPA_MARGEN
	local maximo = (momento - robo.inicio + ConfigRobo.ANTITRAMPA_SEGUNDOS) * velocidad
	return plano.Magnitude > maximo
end

local function revisar()
	local momento = Reloj.Ahora()
	for ladron, robo in robos do
		if ladron.Parent == nil then
			RoboService.Fallar(ladron, "ladron_salio")
		elseif robo.dueno.Parent == nil then
			RoboService.Fallar(ladron, "dueno_salio")
		elseif momento - robo.inicio > ConfigRobo.TIEMPO_MAXIMO_CARGA then
			RoboService.Fallar(ladron, "tiempo")
		elseif movimientoImposible(robo, momento) then
			warn(`[Robo] Movimiento imposible de {ladron.Name} ({ladron.UserId}) cargando un Crunchi`)
			RoboService.Fallar(ladron, "trampa")
		elseif BaseService.DentroDeSuBase(ladron) then
			completar(robo)
		end
	end
	-- Limpiar cooldowns vencidos
	for clave, hasta in cooldownPar do
		if hasta <= momento then
			cooldownPar[clave] = nil
		end
	end
end

function RoboService.Iniciar()
	local carpetaArmas = Instance.new("Folder")
	carpetaArmas.Name = "ArmasDefensa"
	carpetaArmas.Parent = ServerStorage
	for _, arma in ConfigArmas.LISTA do
		local herramienta = crearHerramienta(arma)
		herramienta.Parent = carpetaArmas
		plantillas[arma.id] = herramienta
	end

	BaseService.IntentoRobo:Conectar(function(ladron: Player, dueno: Player, uid: string)
		RoboService.Intentar(ladron, dueno, uid)
	end)

	DatosService.JugadorSaliendo:Conectar(function(jugador: Player)
		if robos[jugador] then
			RoboService.Fallar(jugador, "ladron_salio")
		end
		for ladron, robo in robos do
			if robo.dueno == jugador then
				RoboService.Fallar(ladron, "dueno_salio")
			end
		end
	end)

	local function alEntrar(jugador: Player)
		jugador.CharacterAdded:Connect(function(personaje)
			darArma(jugador, personaje)
		end)
		if jugador.Character then
			task.spawn(darArma, jugador, jugador.Character)
		end
	end
	-- Cuando cargan los datos ya se sabe qué arma tiene equipada.
	DatosService.JugadorListo:Conectar(function(jugador: Player)
		RoboService.ActualizarArma(jugador)
	end)
	for _, jugador in Players:GetPlayers() do
		alEntrar(jugador)
	end
	Players.PlayerAdded:Connect(alEntrar)
	Players.PlayerRemoving:Connect(function(jugador)
		ultimoGolpe[jugador] = nil
	end)

	Reloj.Cada(0.2, revisar)
end

return RoboService
