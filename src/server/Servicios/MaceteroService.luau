--!strict
--[[
	MaceteroService
	El macetero de tu base: plantas una semilla y crece EN TIEMPO REAL, incluso si te
	desconectas. Al cosechar sale un Crunchi al azar (con más probabilidad de mutación).
	Es el gancho para volver: "mi planta estará lista en 1 hora".

	Semillas y tiempos en Config/Semillas. La planta se ve en el macetero de cada base
	(la dibuja el cliente según los atributos "Semilla" y "ListaEn" del macetero).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CanastaService = require(script.Parent:WaitForChild("CanastaService"))
local MapaService = require(script.Parent:WaitForChild("MapaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local MaceteroService = {
	-- (jugador, crunchi: CrunchiGuardado)
	Cosechado = Senal.nueva(),
}

local function publicar(jugador: Player)
	local estado = BaseService.Estado(jugador)
	local datos = DatosService.Obtener(jugador)
	if estado == nil or datos == nil then
		return
	end
	estado.mapa.macetero:SetAttribute("Semilla", datos.macetero.semilla)
	estado.mapa.macetero:SetAttribute("ListaEn", datos.macetero.listaEn)
end

local function plantar(jugador: Player, semillaId: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(semillaId) ~= "string" then
		return
	end
	local semilla = Catalogo.semilla[semillaId]
	if semilla == nil then
		return
	end
	if datos.macetero.semilla ~= "" then
		RedServidor.Notificar(jugador, "Ya hay algo plantado", "error")
		return
	end
	if (datos.semillas[semillaId] or 0) < 1 then
		RedServidor.Notificar(jugador, "No tienes esa semilla", "error")
		return
	end
	datos.semillas[semillaId] -= 1
	if datos.semillas[semillaId] <= 0 then
		datos.semillas[semillaId] = nil
	end
	datos.macetero.semilla = semillaId
	datos.macetero.listaEn = os.time() + semilla.minutos * 60
	publicar(jugador)
	RedServidor.Notificar(
		jugador,
		`🌱 Plantaste una {semilla.nombre}. Estará lista en {Formato.Tiempo(semilla.minutos * 60)}`,
		"exito"
	)
	AnaliticaService.Evento(jugador, "Plantar", 1, { semillaId })
	DatosService.ActualizarEstado(jugador, { "macetero" })
end

local function cosechar(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or datos.macetero.semilla == "" then
		return
	end
	local semilla = Catalogo.semilla[datos.macetero.semilla]
	if semilla == nil then
		datos.macetero.semilla = ""
		datos.macetero.listaEn = 0
		publicar(jugador)
		return
	end
	local restante = datos.macetero.listaEn - os.time()
	if restante > 0 then
		RedServidor.Notificar(jugador, `Todavía le faltan {Formato.Tiempo(restante)}`, "info")
		return
	end
	if BaseService.Destino(jugador) == nil then
		RedServidor.Notificar(jugador, "¡Tu base y tu depósito están llenos!", "error")
		return
	end
	local crunchiId, mutacion = CanastaService.Sortear(semilla.pesos, semilla.bonusMutacion)
	if crunchiId == nil then
		return
	end
	local crunchi, esNuevo = BaseService.Otorgar(jugador, crunchiId, mutacion)
	if crunchi == nil then
		return
	end
	datos.macetero.semilla = ""
	datos.macetero.listaEn = 0
	publicar(jugador)
	RedServidor.Enviar(
		"Efecto",
		jugador,
		"Canasta",
		{ canasta = "macetero", resultados = { { crunchi = crunchiId, mut = mutacion, nuevo = esNuevo } } }
	)
	AnaliticaService.Evento(jugador, "Cosechar", 1, { semilla.id, crunchiId, mutacion })
	MaceteroService.Cosechado:Disparar(jugador, crunchi)
	DatosService.ActualizarEstado(jugador, { "macetero" })
end

-- Fertilizante (objeto): la planta crece de golpe; queda `fraccion` del tiempo que le
-- faltaba (0.5 = la mitad). Devuelve false si no hay nada creciendo.
function MaceteroService.Acelerar(jugador: Player, fraccion: number): boolean
	local datos = DatosService.Obtener(jugador)
	if datos == nil or datos.macetero.semilla == "" then
		return false
	end
	local restante = datos.macetero.listaEn - os.time()
	if restante <= 0 then
		return false
	end
	datos.macetero.listaEn = os.time() + math.floor(restante * math.clamp(fraccion, 0, 1))
	publicar(jugador)
	DatosService.ActualizarEstado(jugador, { "macetero" })
	return true
end

function MaceteroService.Iniciar()
	DatosService.RegistrarEstado("macetero", function(_jugador: Player, datos: Tipos.Datos)
		return {
			semilla = datos.macetero.semilla,
			listaEn = datos.macetero.listaEn,
			semillas = table.clone(datos.semillas),
		}
	end)
	BaseService.BaseAsignada:Conectar(function(jugador: Player)
		publicar(jugador)
	end)
	BaseService.BaseLiberada:Conectar(function(_jugador: Player, mapa: MapaService.BaseMapa)
		mapa.macetero:SetAttribute("Semilla", "")
		mapa.macetero:SetAttribute("ListaEn", 0)
	end)
	Acciones.Registrar("plantar", plantar)
	Acciones.Registrar("cosechar", function(jugador: Player)
		cosechar(jugador)
	end)
end

return MaceteroService
