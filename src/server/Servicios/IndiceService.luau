--!strict
--[[
	IndiceService
	El Índice (colección): sets, hitos por porcentaje y títulos.

	  - Completar un SET (tener cada Crunchi del set al menos una vez) da +3 % de ingreso
	    permanente (no se pierde con el rebirth) y un título.
	  - Los HITOS (25/50/75/100 % del Índice) dan un título, dinero y canastas.
	  - El jugador puede equipar un título: se ve sobre su cabeza (CabezaService).

	El registro de "tuvo este Crunchi" lo hace DatosService.RegistrarIndice; aquí solo se
	reacciona a la señal CrunchiObtenido.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigIndice = require(Config:WaitForChild("Indice"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Progresion = require(Shared:WaitForChild("Logica"):WaitForChild("Progresion"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RecompensaService = require(script.Parent:WaitForChild("RecompensaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

local IndiceService = {}

local idsBase: { string } = {}
for _, crunchi in Catalogo.datos.crunchis do
	table.insert(idsBase, crunchi.id)
end

local function contarClaves(datos: Tipos.Datos): number
	local cantidad = 0
	for _ in datos.indice do
		cantidad += 1
	end
	return cantidad
end
local clavesConocidas: { [Player]: number } = {}

local function aplicarTitulo(jugador: Player, datos: Tipos.Datos)
	jugador:SetAttribute("Titulo", datos.tituloEquipado)
end

local function revisarSets(jugador: Player, datos: Tipos.Datos)
	local huboCambios = false
	for _, set in Catalogo.datos.sets do
		if datos.setsCompletados[set.id] == nil then
			local completo = true
			for _, crunchi in Catalogo.datos.porSet[set.id] do
				if datos.indice[crunchi.id] == nil then
					completo = false
					break
				end
			end
			if completo then
				datos.setsCompletados[set.id] = os.time()
				datos.titulos[set.titulo] = true
				huboCambios = true
				RedServidor.Notificar(
					jugador,
					`🏆 ¡Set "{set.nombre}" completo! +{math.floor(set.bonus * 100)} % de ingreso para siempre y el título "{set.titulo}"`,
					"exito"
				)
				RedServidor.EnviarATodos(
					"Anuncio",
					`¡{jugador.DisplayName} completó el set {set.nombre}!`,
					"legendario"
				)
				RedServidor.Enviar("Efecto", jugador, "Logro")
				AnaliticaService.Evento(jugador, "SetCompletado", 1, { set.id })
			end
		end
	end
	if huboCambios then
		EconomiaService.AvisarCambio(jugador)
	end
end

local function revisarHitos(jugador: Player, datos: Tipos.Datos)
	local porcentaje = Progresion.PorcentajeIndice(datos.indice, idsBase)
	for _, hito in ConfigIndice.HITOS do
		local clave = tostring(hito.porcentaje)
		if porcentaje >= hito.porcentaje and not datos.hitosIndice[clave] then
			datos.hitosIndice[clave] = true
			datos.titulos[hito.titulo] = true
			local recompensas: { RecompensaService.Recompensa } = { { tipo = "dinero", minutos = hito.minutos } }
			if hito.canasta then
				table.insert(recompensas, { tipo = "canasta", id = hito.canasta, cantidad = 1 })
			end
			local texto = RecompensaService.DarVarias(jugador, recompensas, `hito_indice_{clave}`)
			RedServidor.Notificar(
				jugador,
				`📖 ¡Índice al {hito.porcentaje} %! Título "{hito.titulo}" · {texto}`,
				"exito"
			)
			RedServidor.Enviar("Efecto", jugador, "Logro")
			AnaliticaService.Progreso(jugador, "Indice", hito.porcentaje, hito.titulo)
		end
	end
end

function IndiceService.Iniciar()
	EconomiaService.RegistrarBonus("Sets", function(jugador)
		local datos = DatosService.Obtener(jugador)
		if datos == nil then
			return 0
		end
		local total = 0
		for setId in datos.setsCompletados do
			local set = Catalogo.datos.set[setId]
			if set then
				total += set.bonus
			end
		end
		return total
	end)

	DatosService.RegistrarEstado("indice", function(_jugador: Player, datos: Tipos.Datos)
		local claves = {}
		for clave in datos.indice do
			table.insert(claves, clave)
		end
		local sets = {}
		for setId in datos.setsCompletados do
			table.insert(sets, setId)
		end
		local titulos = {}
		for titulo in datos.titulos do
			table.insert(titulos, titulo)
		end
		table.sort(titulos)
		return { claves = claves, sets = sets, titulos = titulos, titulo = datos.tituloEquipado }
	end)

	DatosService.CrunchiObtenido:Conectar(function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		if datos == nil then
			return
		end
		local cantidad = contarClaves(datos)
		if cantidad ~= clavesConocidas[jugador] then
			clavesConocidas[jugador] = cantidad
			revisarSets(jugador, datos)
			revisarHitos(jugador, datos)
			DatosService.ActualizarEstado(jugador, { "indice" })
		end
	end)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		clavesConocidas[jugador] = contarClaves(datos)
		-- Por si se agregaron sets o hitos nuevos en una actualización:
		revisarSets(jugador, datos)
		revisarHitos(jugador, datos)
		aplicarTitulo(jugador, datos)
	end)
	DatosService.JugadorSaliendo:Conectar(function(jugador: Player)
		clavesConocidas[jugador] = nil
	end)

	Acciones.Registrar("titulo", function(jugador: Player, titulo: any)
		local datos = DatosService.Obtener(jugador)
		if datos == nil or type(titulo) ~= "string" then
			return
		end
		if titulo ~= "" and not datos.titulos[titulo] then
			return
		end
		datos.tituloEquipado = titulo
		aplicarTitulo(jugador, datos)
		DatosService.ActualizarEstado(jugador, { "indice" })
	end)
end

return IndiceService
