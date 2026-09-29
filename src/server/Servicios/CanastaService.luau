--!strict
--[[
	CanastaService
	Canastas sorpresa pagadas con DINERO DEL JUEGO (o con tickets gratis de recompensas).

	Las probabilidades salen de Config/Canastas, las MISMAS que la UI muestra antes de
	abrir. El resultado se decide aquí, en el servidor; el cliente solo muestra la animación.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CintaService = require(script.Parent:WaitForChild("CintaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local CanastaService = {
	-- (jugador, canastaId, crunchi: CrunchiGuardado)
	Abierta = Senal.nueva(),
}

local aleatorio = Random.new()
local function numeroAleatorio(): number
	return aleatorio:NextNumber()
end

local aperturasMultiples: { [string]: (Player) -> number } = {}

-- Game Pass "Apertura Triple" (Fase 3) registra aquí cuántas se pueden abrir a la vez.
function CanastaService.RegistrarAperturaMultiple(nombre: string, fn: (Player) -> number)
	aperturasMultiples[nombre] = fn
end

function CanastaService.MaximoPorVez(jugador: Player): number
	local maximo = 1
	for _, fn in aperturasMultiples do
		local ok, valor = pcall(fn, jugador)
		if ok and type(valor) == "number" then
			maximo = math.max(maximo, valor)
		end
	end
	return maximo
end

-- Sortea el contenido de una canasta (rareza → Crunchi → mutación).
function CanastaService.Sortear(pesos: Azar.Pesos, bonusMutacion: number?): (string?, string)
	local rarezaId = Azar.Ponderado(pesos, numeroAleatorio)
	local candidatos = if rarezaId then Catalogo.datos.porRareza[rarezaId] else nil
	local crunchi = if candidatos then Azar.Elegir(candidatos, numeroAleatorio) else nil
	if crunchi == nil then
		return nil, "normal"
	end
	local pesosMutacion = CintaService.PesosMutacion()
	if bonusMutacion and bonusMutacion ~= 1 then
		for clave, peso in pesosMutacion do
			if clave ~= "normal" then
				pesosMutacion[clave] = peso * bonusMutacion
			end
		end
	end
	local mutacion = Azar.Ponderado(pesosMutacion, numeroAleatorio) or "normal"
	return crunchi.id, mutacion
end

-- Abre UNA canasta. Devuelve el Crunchi o nil + motivo.
local function abrirUna(jugador: Player, datos: Tipos.Datos, canastaId: string, usarTicket: boolean): (any, string?)
	local canasta = Catalogo.canasta[canastaId]
	if canasta == nil then
		return nil, nil
	end
	if datos.rebirths < canasta.requisitoRebirths then
		return nil, `🔒 Necesitas Rebirth {canasta.requisitoRebirths}`
	end
	if BaseService.Destino(jugador) == nil then
		return nil, "¡Tu base y tu depósito están llenos!"
	end
	if usarTicket then
		if (datos.tickets[canastaId] or 0) < 1 then
			return nil, "No tienes canastas de ese tipo"
		end
		datos.tickets[canastaId] -= 1
		if datos.tickets[canastaId] <= 0 then
			datos.tickets[canastaId] = nil
		end
	else
		if canasta.soloTicket then
			return nil, nil
		end
		if not EconomiaService.Gastar(jugador, canasta.precio, AnaliticaService.Tipo.Tienda, `canasta_{canastaId}`) then
			return nil, `Te faltan {Formato.Dinero(canasta.precio - datos.dinero)}`
		end
	end

	local crunchiId, mutacion = CanastaService.Sortear(canasta.pesos)
	if crunchiId == nil then
		return nil, nil
	end
	local crunchi, esNuevo = BaseService.Otorgar(jugador, crunchiId, mutacion)
	if crunchi == nil then
		return nil, nil
	end
	AnaliticaService.Onboarding(jugador, "PrimeraCanasta")
	AnaliticaService.Evento(jugador, "CanastaAbierta", 1, { canastaId, crunchiId, mutacion })
	CanastaService.Abierta:Disparar(jugador, canastaId, crunchi)
	local rareza = Catalogo.RarezaDe(crunchiId)
	if rareza and rareza.anunciar then
		RedServidor.EnviarATodos(
			"Anuncio",
			`¡{jugador.DisplayName} sacó {Catalogo.NombreCompleto(crunchiId, mutacion)} de una {canasta.nombre}!`,
			rareza.id
		)
	end
	return { crunchi = crunchiId, mut = mutacion, nuevo = esNuevo, lugar = crunchi.lugar }, nil
end

local function alAbrir(jugador: Player, pedido: any)
	if type(pedido) ~= "table" or type(pedido.id) ~= "string" then
		return
	end
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	local cantidad = if type(pedido.cantidad) == "number" then math.floor(pedido.cantidad) else 1
	cantidad = math.clamp(cantidad, 1, CanastaService.MaximoPorVez(jugador))
	local resultados = {}
	for _ = 1, cantidad do
		local resultado, motivo = abrirUna(jugador, datos, pedido.id, pedido.ticket == true)
		if resultado == nil then
			if motivo then
				RedServidor.Notificar(jugador, motivo, "error")
			end
			break
		end
		table.insert(resultados, resultado)
	end
	if #resultados > 0 then
		RedServidor.Enviar("Efecto", jugador, "Canasta", { canasta = pedido.id, resultados = resultados })
		DatosService.ActualizarEstado(jugador, { "canastas" })
	end
end

function CanastaService.Iniciar()
	DatosService.RegistrarEstado("canastas", function(jugador: Player, datos: Tipos.Datos)
		return { tickets = table.clone(datos.tickets), maximoPorVez = CanastaService.MaximoPorVez(jugador) }
	end)
	Acciones.Registrar("canasta_abrir", alAbrir)
end

return CanastaService
