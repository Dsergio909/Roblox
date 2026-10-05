--!strict
--[[
	RebirthService
	Hacer rebirth: pagar el costo y tener los Crunchis requeridos → se reinicia el dinero
	y los Crunchis (menos tu "Mejor Amigo") a cambio de:
	  +0.5× de ingreso permanente, +1 pedestal, más tiempo de cerrojo y zonas nuevas.

	Se conserva: Índice, sets, títulos, misiones, calendario, semillas, tickets y el
	Crunchi Mejor Amigo. Ver Config/Rebirths.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigRebirths = require(Config:WaitForChild("Rebirths"))
local ConfigEconomia = require(Config:WaitForChild("Economia"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RoboService = require(script.Parent:WaitForChild("RoboService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local RebirthService = {
	-- (jugador, nuevoNivel)
	RebirthHecho = Senal.nueva(),
}

local ordenRareza: { [string]: number } = {}
for _, rareza in Catalogo.datos.rarezas do
	ordenRareza[rareza.id] = rareza.orden
end

local function ordenesDe(datos: Tipos.Datos): { number }
	local ordenes = {}
	for _, crunchi in datos.crunchis do
		table.insert(ordenes, Catalogo.OrdenDe(crunchi.id))
	end
	return ordenes
end

-- El Crunchi que se conserva: el elegido o, si no hay, el de mayor valor.
local function elegirMejorAmigo(datos: Tipos.Datos): Tipos.CrunchiGuardado?
	for _, crunchi in datos.crunchis do
		if crunchi.uid == datos.mejorAmigo then
			return crunchi
		end
	end
	local mejor: Tipos.CrunchiGuardado? = nil
	local mejorPrecio = -1
	for _, crunchi in datos.crunchis do
		local _, precio = Catalogo.Valor(crunchi.id, crunchi.mut)
		if precio > mejorPrecio then
			mejor = crunchi
			mejorPrecio = precio
		end
	end
	return mejor
end

-- Resumen para la UI: costo, requisitos (con cuántos tiene) y qué desbloquea.
local function estado(_jugador: Player, datos: Tipos.Datos)
	local siguiente = datos.rebirths + 1
	local nivel = Progresion.NivelRebirth(siguiente, ConfigRebirths)
	local cumple, detalle = Progresion.CumpleRequisitos(ordenesDe(datos), nivel.requisitos, ordenRareza)
	local amigo = elegirMejorAmigo(datos)
	return {
		actual = datos.rebirths,
		siguiente = siguiente,
		costo = nivel.costo,
		requisitos = detalle,
		cumpleRequisitos = cumple,
		desbloquea = nivel.desbloquea or "",
		mejorAmigo = if amigo then amigo.uid else "",
	}
end

function RebirthService.Hacer(jugador: Player, ignorarRequisitos: boolean?): (boolean, string?)
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return false, nil
	end
	if RoboService.EstaCargando(jugador) or RoboService.EstaSiendoRobado(jugador) then
		return false, "No puedes hacer rebirth durante un robo"
	end
	local siguiente = datos.rebirths + 1
	local nivel = Progresion.NivelRebirth(siguiente, ConfigRebirths)
	if not ignorarRequisitos then
		local cumple = Progresion.CumpleRequisitos(ordenesDe(datos), nivel.requisitos, ordenRareza)
		if not cumple then
			return false, "Todavía no tienes los Crunchis requeridos"
		end
		if datos.dinero < nivel.costo then
			return false, `Te faltan {Formato.Dinero(nivel.costo - datos.dinero)}`
		end
	end

	-- 1. Reiniciar los datos: solo queda el Mejor Amigo, en el pedestal 1.
	local amigo = if ConfigRebirths.CONSERVA_MEJOR_AMIGO then elegirMejorAmigo(datos) else nil
	datos.crunchis = {}
	if amigo then
		amigo.lugar = 1
		table.insert(datos.crunchis, amigo)
		datos.mejorAmigo = amigo.uid
	else
		datos.mejorAmigo = ""
	end
	datos.rebirths = siguiente

	-- 2. Volver a armar la base (misma base, con la nueva capacidad y multiplicador).
	--    El dinero pendiente en los botones se suma al saldo, pero el saldo se reinicia.
	BaseService.Reconstruir(jugador)
	EconomiaService.Fijar(jugador, ConfigEconomia.DINERO_INICIAL)
	EconomiaService.ActualizarRebirths(jugador, datos.rebirths)
	EconomiaService.AvisarCambio(jugador)
	DatosService.GuardarYa(jugador)

	RedServidor.Enviar("Efecto", jugador, "Rebirth", { nivel = siguiente })
	RedServidor.Notificar(
		jugador,
		`🔁 ¡Rebirth {siguiente}! Ahora ganas x{1 + siguiente * ConfigEconomia.BONUS.POR_REBIRTH} para siempre`,
		"exito"
	)
	if nivel.desbloquea then
		RedServidor.Notificar(jugador, `🔓 Desbloqueaste: {nivel.desbloquea}`, "exito")
	end
	RedServidor.EnviarATodos("Anuncio", `¡{jugador.DisplayName} hizo REBIRTH {siguiente}!`, "mitico")
	AnaliticaService.Progreso(jugador, "Rebirth", siguiente)
	AnaliticaService.Onboarding(jugador, "PrimerRebirth")
	RebirthService.RebirthHecho:Disparar(jugador, siguiente)
	DatosService.ActualizarEstado(jugador, { "rebirth", "crunchis" })
	return true, nil
end

function RebirthService.Iniciar()
	DatosService.RegistrarEstado("rebirth", estado)

	-- Los requisitos dependen de qué Crunchis tienes: se actualiza cuando cambian.
	BaseService.CrunchisCambiaron:Conectar(function(jugador: Player)
		DatosService.ActualizarEstado(jugador, { "rebirth" })
	end)

	Acciones.Registrar("rebirth", function(jugador: Player)
		local ok, motivo = RebirthService.Hacer(jugador)
		if not ok and motivo then
			RedServidor.Notificar(jugador, motivo, "error")
		end
	end)

	AdminService.Registrar("rebirth", function(jugador: Player)
		local ok, motivo = RebirthService.Hacer(jugador, true)
		if not ok then
			RedServidor.Notificar(jugador, `🛠️ {motivo or "No se pudo"}`, "error")
		end
	end)
end

return RebirthService
