--!strict
--[[
	OfertaService
	Ofertas en el momento correcto, SIN interrumpir (ver docs/GAME_DESIGN.md §8.6 y §8.7):

	  - Prueba gratis: a los 3 minutos (una sola vez en la vida del jugador), un Boost x2 de
	    5 minutos de REGALO para que sienta la diferencia.
	  - Pack Inicial: a los 7 minutos de la sesión, una TARJETA LATERAL que se cierra con un
	    toque. Máximo una oferta automática por sesión y como mucho 3 veces en total. Nunca
	    durante un robo. Después sigue en la tienda, sin temporizador.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigProductos = require(Shared:WaitForChild("Config"):WaitForChild("Productos"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local CompraService = require(script.Parent:WaitForChild("CompraService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local OfertaService = {}

local inicioSesion: { [Player]: number } = {}
local ofertaEstaSesion: { [Player]: boolean } = {}

local function revisar()
	local ahora = os.clock()
	for _, jugador in Players:GetPlayers() do
		local datos = DatosService.Obtener(jugador)
		local inicio = inicioSesion[jugador]
		if datos and inicio then
			local minutos = (ahora - inicio) / 60

			-- Prueba gratis del Boost x2
			local prueba = ConfigProductos.PRUEBA_X2
			if not datos.compras.pruebaX2 and minutos >= prueba.A_LOS_MINUTOS then
				datos.compras.pruebaX2 = true
				CompraService.SumarBoostX2(jugador, prueba.DURACION_MINUTOS)
				RedServidor.Notificar(
					jugador,
					`🎁 ¡Regalo! Boost x2 GRATIS por {prueba.DURACION_MINUTOS} minutos. ¡Mira cómo sube tu dinero!`,
					"exito"
				)
				RedServidor.Enviar("Efecto", jugador, "Logro")
				AnaliticaService.Evento(jugador, "PruebaX2", 1)
			end

			-- Pack Inicial (tarjeta lateral, una vez por sesión como máximo)
			local pack = ConfigProductos.PACK_INICIAL
			if
				not ofertaEstaSesion[jugador]
				and not datos.compras.packInicial
				and datos.compras.vecesOfertaPack < pack.VECES_MAXIMAS_OFRECIDO
				and minutos >= pack.OFRECER_A_LOS_MINUTOS
				and jugador:GetAttribute("Cargando") ~= true
			then
				ofertaEstaSesion[jugador] = true
				datos.compras.vecesOfertaPack += 1
				RedServidor.Enviar("Oferta", jugador, "pack_inicial")
				AnaliticaService.Evento(jugador, "OfertaMostrada", 1, { "pack_inicial" })
			end
		end
	end
end

function OfertaService.Iniciar()
	DatosService.JugadorListo:Conectar(function(jugador: Player)
		inicioSesion[jugador] = os.clock()
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		inicioSesion[jugador] = nil
		ofertaEstaSesion[jugador] = nil
	end)
	-- El cliente avisa si la cerró (solo para Analytics: saber si la oferta molesta).
	Acciones.Registrar("oferta_cerrada", function(jugador: Player, id: any)
		if type(id) == "string" and #id < 40 then
			AnaliticaService.Evento(jugador, "OfertaCerrada", 1, { id })
		end
	end)
	Reloj.Cada(15, revisar)
end

return OfertaService
