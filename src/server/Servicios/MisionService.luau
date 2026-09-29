--!strict
--[[
	MisionService
	Misiones diarias (se renuevan a las 00:00 UTC) y semanales (cada lunes).

	  - El progreso se cuenta escuchando señales de otros servicios (comprar, cobrar,
	    robar/defender, abrir canastas...). Ver los TIPOS en Config/Misiones.
	  - Reclamar da dinero (en minutos de ingreso, así siempre vale la pena), XP del pase
	    y a veces semillas.
	  - Completar las 3 diarias da un premio extra.
	  - Se puede cambiar una misión diaria gratis por día (VIP: una más, Fase 3).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigMisiones = require(Shared:WaitForChild("Config"):WaitForChild("Misiones"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RecompensaService = require(script.Parent:WaitForChild("RecompensaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CintaService = require(script.Parent:WaitForChild("CintaService"))
local RoboService = require(script.Parent:WaitForChild("RoboService"))
local CanastaService = require(script.Parent:WaitForChild("CanastaService"))
local MaceteroService = require(script.Parent:WaitForChild("MaceteroService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

type Mision = ConfigMisiones.Mision

local MisionService = {}

local definiciones: { [string]: Mision } = {}
local idsDiarias: { string } = {}
local idsSemanales: { string } = {}
for _, mision in ConfigMisiones.DIARIAS do
	definiciones[mision.id] = mision
	table.insert(idsDiarias, mision.id)
end
for _, mision in ConfigMisiones.SEMANALES do
	definiciones[mision.id] = mision
	table.insert(idsSemanales, mision.id)
end

local aleatorio = Random.new()
local function numeroAleatorio(): number
	return aleatorio:NextNumber()
end

local cambiosExtra: { [string]: (Player) -> number } = {}
local pendientes: { [Player]: boolean } = {}

-- Otros servicios pueden dar cambios extra (Game Pass VIP en la Fase 3).
function MisionService.RegistrarCambiosExtra(nombre: string, fn: (Player) -> number)
	cambiosExtra[nombre] = fn
end

local function cambiosDisponibles(jugador: Player, datos: Tipos.Datos): number
	local total = ConfigMisiones.CAMBIOS_GRATIS_POR_DIA
	for _, fn in cambiosExtra do
		local ok, valor = pcall(fn, jugador)
		if ok and type(valor) == "number" then
			total += valor
		end
	end
	return math.max(0, total - datos.misiones.cambiosUsados)
end

local function nuevas(ids: { string }): { Tipos.MisionGuardada }
	local lista = {}
	for _, id in ids do
		table.insert(lista, { id = id, progreso = 0, reclamada = false })
	end
	return lista
end

local function idsDe(lista: { Tipos.MisionGuardada }): { string }
	local ids = {}
	for _, mision in lista do
		table.insert(ids, mision.id)
	end
	return ids
end

-- Renueva las misiones si cambió el día o la semana. Devuelve true si cambió algo.
local function asegurar(datos: Tipos.Datos): boolean
	local misiones = datos.misiones
	local hoy = Progresion.Dia(os.time())
	local semana = Progresion.Semana(hoy)
	local cambio = false
	if misiones.dia ~= hoy then
		local anteriores = idsDe(misiones.diarias)
		misiones.diarias =
			nuevas(Progresion.ElegirMisiones(idsDiarias, ConfigMisiones.DIARIAS_POR_DIA, numeroAleatorio, anteriores))
		misiones.dia = hoy
		misiones.cambiosUsados = 0
		misiones.bonusDiario = false
		cambio = true
	end
	if misiones.semana ~= semana then
		misiones.semanales =
			nuevas(Progresion.ElegirMisiones(idsSemanales, ConfigMisiones.SEMANALES_POR_SEMANA, numeroAleatorio, nil))
		misiones.semana = semana
		cambio = true
	end
	return cambio
end

local function textoDe(mision: Mision): string
	return (string.gsub(mision.texto, "{meta}", tostring(mision.meta)))
end

----------------------------------------------------------------------------- progreso

--[[
	Suma progreso a las misiones del tipo indicado.
	Para "conseguir_rareza", `crunchiId` es el Crunchi conseguido (se compara su rareza).
]]
function MisionService.Sumar(jugador: Player, tipo: string, cantidad: number, crunchiId: string?)
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	asegurar(datos)
	for _, lista in { datos.misiones.diarias, datos.misiones.semanales } do
		for _, guardada in lista do
			local mision = definiciones[guardada.id]
			if mision and mision.tipo == tipo and not guardada.reclamada and guardada.progreso < mision.meta then
				local cuenta = true
				if tipo == "conseguir_rareza" then
					local rareza = Catalogo.datos.rareza[mision.parametro or ""]
					cuenta = crunchiId ~= nil and rareza ~= nil and Catalogo.OrdenDe(crunchiId) >= rareza.orden
				end
				if cuenta then
					guardada.progreso = math.min(mision.meta, guardada.progreso + cantidad)
					pendientes[jugador] = true
					if guardada.progreso >= mision.meta then
						RedServidor.Notificar(
							jugador,
							`✅ ¡Misión lista! {textoDe(mision)} — reclámala en 📋`,
							"exito"
						)
					end
				end
			end
		end
	end
end

----------------------------------------------------------------------------- acciones

local function buscar(datos: Tipos.Datos, id: string): (Tipos.MisionGuardada?, boolean)
	for _, guardada in datos.misiones.diarias do
		if guardada.id == id then
			return guardada, true
		end
	end
	for _, guardada in datos.misiones.semanales do
		if guardada.id == id then
			return guardada, false
		end
	end
	return nil, false
end

local function recompensasDe(mision: Mision): { RecompensaService.Recompensa }
	local lista: { RecompensaService.Recompensa } = {
		{ tipo = "dinero", minutos = mision.minutos, minimo = ConfigMisiones.DINERO_MINIMO },
		{ tipo = "xp", cantidad = mision.xp },
	}
	if mision.semillas then
		table.insert(lista, { tipo = "semilla", id = "comun", cantidad = mision.semillas })
	end
	return lista
end

local function reclamar(jugador: Player, id: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(id) ~= "string" then
		return
	end
	asegurar(datos)
	local guardada, esDiaria = buscar(datos, id)
	local mision = definiciones[id]
	if guardada == nil or mision == nil or guardada.reclamada or guardada.progreso < mision.meta then
		return
	end
	guardada.reclamada = true
	local texto = RecompensaService.DarVarias(jugador, recompensasDe(mision), `mision_{id}`)
	RedServidor.Notificar(jugador, `🎉 {texto}`, "exito")
	RedServidor.Enviar("Efecto", jugador, "Logro")
	AnaliticaService.Onboarding(jugador, "PrimeraMision")
	AnaliticaService.Evento(jugador, "MisionReclamada", 1, { id })

	if esDiaria then
		MisionService.Sumar(jugador, "completar_diarias", 1)
		-- ¿Completó las 3 diarias? Premio extra.
		local todas = true
		for _, otra in datos.misiones.diarias do
			if not otra.reclamada then
				todas = false
				break
			end
		end
		if todas and not datos.misiones.bonusDiario then
			datos.misiones.bonusDiario = true
			local bonus = ConfigMisiones.BONUS_DIARIO
			local textoBonus = RecompensaService.DarVarias(jugador, {
				{ tipo = "canasta", id = bonus.canasta, cantidad = bonus.cantidad },
				{ tipo = "xp", cantidad = bonus.xp },
			}, "bonus_diarias")
			RedServidor.Notificar(jugador, `🏅 ¡Completaste todas las diarias! {textoBonus}`, "exito")
		end
	end
	pendientes[jugador] = true
end

local function cambiar(jugador: Player, id: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(id) ~= "string" then
		return
	end
	asegurar(datos)
	local guardada, esDiaria = buscar(datos, id)
	local mision = definiciones[id]
	if guardada == nil or mision == nil or not esDiaria or guardada.reclamada or guardada.progreso >= mision.meta then
		return
	end
	if cambiosDisponibles(jugador, datos) <= 0 then
		RedServidor.Notificar(jugador, "Ya no te quedan cambios hoy", "error")
		return
	end
	local nueva = Progresion.ElegirMisiones(idsDiarias, 1, numeroAleatorio, idsDe(datos.misiones.diarias))[1]
	if nueva == nil or nueva == id then
		return
	end
	guardada.id = nueva
	guardada.progreso = 0
	datos.misiones.cambiosUsados += 1
	pendientes[jugador] = true
end

----------------------------------------------------------------------------- estado

local function lista(jugador: Player, guardadas: { Tipos.MisionGuardada })
	local resultado = {}
	for _, guardada in guardadas do
		local mision = definiciones[guardada.id]
		if mision then
			table.insert(resultado, {
				id = guardada.id,
				texto = textoDe(mision),
				meta = mision.meta,
				progreso = guardada.progreso,
				reclamada = guardada.reclamada,
				dinero = EconomiaService.DineroPorMinutos(jugador, mision.minutos, ConfigMisiones.DINERO_MINIMO),
				xp = mision.xp,
				semillas = mision.semillas or 0,
			})
		end
	end
	return resultado
end

local function estado(jugador: Player, datos: Tipos.Datos)
	asegurar(datos)
	local hoy = Progresion.Dia(os.time())
	local semana = Progresion.Semana(hoy)
	return {
		diarias = lista(jugador, datos.misiones.diarias),
		semanales = lista(jugador, datos.misiones.semanales),
		cambios = cambiosDisponibles(jugador, datos),
		bonusDiario = datos.misiones.bonusDiario,
		finDia = (hoy + 1) * 86400,
		-- La semana `semana` empieza el día semana*7 - 3 (lunes); termina 7 días después.
		finSemana = ((semana + 1) * 7 - 3) * 86400,
	}
end

----------------------------------------------------------------------------- inicio

function MisionService.Iniciar()
	DatosService.RegistrarEstado("misiones", estado)

	DatosService.JugadorListo:Conectar(function(_jugador: Player, datos: Tipos.Datos)
		asegurar(datos)
	end)

	-- Qué cuenta para cada tipo de misión.
	CintaService.Comprado:Conectar(function(jugador: Player)
		MisionService.Sumar(jugador, "comprar", 1)
	end)
	BaseService.Cobrado:Conectar(function(jugador: Player)
		MisionService.Sumar(jugador, "cobrar", 1)
	end)
	BaseService.CerrojoActivado:Conectar(function(jugador: Player)
		MisionService.Sumar(jugador, "cerrar_base", 1)
	end)
	RoboService.RoboCompletado:Conectar(function(ladron: Player)
		MisionService.Sumar(ladron, "robar_o_defender", 1)
	end)
	RoboService.RoboFallido:Conectar(function(_ladron: Player, _dueno: Player, _motivo: string, defensor: Player?)
		if defensor then
			MisionService.Sumar(defensor, "robar_o_defender", 1)
		end
	end)
	DatosService.CrunchiObtenido:Conectar(function(jugador: Player, crunchiId: string)
		MisionService.Sumar(jugador, "conseguir_rareza", 1, crunchiId)
	end)
	CanastaService.Abierta:Conectar(function(jugador: Player)
		MisionService.Sumar(jugador, "abrir_canasta", 1)
	end)
	MaceteroService.Cosechado:Conectar(function(jugador: Player)
		MisionService.Sumar(jugador, "cosechar", 1)
	end)

	Acciones.Registrar("mision_reclamar", reclamar)
	Acciones.Registrar("mision_cambiar", cambiar)

	-- Cada minuto: minutos jugados y cambio de día mientras se juega.
	Reloj.Cada(60, function()
		for _, jugador in Players:GetPlayers() do
			local datos = DatosService.Obtener(jugador)
			if datos then
				if asegurar(datos) then
					RedServidor.Notificar(jugador, "📋 ¡Misiones nuevas disponibles!", "info")
				end
				MisionService.Sumar(jugador, "jugar_minutos", 1)
				pendientes[jugador] = true
			end
		end
	end)

	-- El estado se envía como mucho una vez por segundo (cobrar suma progreso muy seguido).
	Reloj.Cada(1, function()
		for jugador in pendientes do
			pendientes[jugador] = nil
			if jugador.Parent then
				DatosService.ActualizarEstado(jugador, { "misiones" })
			end
		end
	end)
end

return MisionService
