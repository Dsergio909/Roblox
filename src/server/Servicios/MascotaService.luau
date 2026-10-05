--!strict
--[[
	MascotaService
	Los Bichitos de la Huerta (Config/Mascotas): huevos, equipar, liberar y su bonus.

	  - Los huevos se pagan con DINERO DEL JUEGO; el sorteo lo hace el servidor con los
	    mismos pesos que la UI muestra antes de comprar.
	  - Las mascotas equipadas suman un bonus de INGRESO (con tope). No tocan los robos.
	  - El cliente dibuja las mascotas a partir del atributo "Mascotas" del jugador (ids).
	  - El Game Pass "Apertura Triple" también sirve para abrir 3 huevos a la vez.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigMascotas = require(Shared:WaitForChild("Config"):WaitForChild("Mascotas"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Senal = require(Shared:WaitForChild("Util"):WaitForChild("Senal"))
local LogicaMascotas = require(Shared:WaitForChild("Logica"):WaitForChild("Mascotas"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local AnaliticaService = require(script.Parent:WaitForChild("AnaliticaService"))
local RecompensaService = require(script.Parent:WaitForChild("RecompensaService"))
local CanastaService = require(script.Parent:WaitForChild("CanastaService"))
local MisionService = require(script.Parent:WaitForChild("MisionService"))
local RebirthService = require(script.Parent:WaitForChild("RebirthService"))
local CompraService = require(script.Parent:WaitForChild("CompraService"))
local AdminService = require(script.Parent:WaitForChild("AdminService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))
local Acciones = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("Acciones"))

type Mascota = ConfigMascotas.Mascota
type Huevo = ConfigMascotas.Huevo
type Guardada = Tipos.MascotaGuardada

local MascotaService = {
	-- (jugador, huevoId, mascotaId)
	HuevoAbierto = Senal.nueva(),
}

local porId: { [string]: Mascota } = {}
for _, mascota in ConfigMascotas.LISTA do
	porId[mascota.id] = mascota
end
local huevoPorId: { [string]: Huevo } = {}
for _, huevo in ConfigMascotas.HUEVOS do
	huevoPorId[huevo.id] = huevo
end

local aleatorio = Random.new()
local function numeroAleatorio(): number
	return aleatorio:NextNumber()
end

----------------------------------------------------------------------------- consultas

function MascotaService.Espacios(jugador: Player, datos: Tipos.Datos): number
	return LogicaMascotas.Espacios(datos.rebirths, CompraService.TienePase(jugador, "MASCOTAS_EXTRA"), ConfigMascotas)
end

local function buscar(datos: Tipos.Datos, uid: string): (Guardada?, number?)
	for indice, guardada in datos.mascotas do
		if guardada.uid == uid then
			return guardada, indice
		end
	end
	return nil, nil
end

-- Las equipadas que cuentan: solo hasta la cantidad de espacios. (No se desequipa nada si
-- faltan espacios: el Game Pass se carga unos segundos después de entrar, y así no se
-- pierde lo que el jugador había elegido.)
local function activas(jugador: Player, datos: Tipos.Datos): { Mascota }
	local espacios = MascotaService.Espacios(jugador, datos)
	local resultado: { Mascota } = {}
	for _, uid in datos.mascotasEquipadas do
		if #resultado >= espacios then
			break
		end
		local guardada = buscar(datos, uid)
		local mascota = if guardada then porId[guardada.id] else nil
		if mascota then
			table.insert(resultado, mascota)
		end
	end
	return resultado
end

function MascotaService.Bonus(jugador: Player, datos: Tipos.Datos): number
	local bonus = {}
	for _, mascota in activas(jugador, datos) do
		table.insert(bonus, mascota.bonus)
	end
	return LogicaMascotas.Bonus(bonus, ConfigMascotas.BONUS_MAXIMO)
end

----------------------------------------------------------------------------- publicar

-- Quita de las equipadas lo que ya no existe (liberadas, ids viejos) y los repetidos.
local function limpiar(datos: Tipos.Datos)
	local validas: { string } = {}
	local vistas: { [string]: boolean } = {}
	for _, uid in datos.mascotasEquipadas do
		local guardada = buscar(datos, uid)
		if guardada and porId[guardada.id] and not vistas[uid] then
			vistas[uid] = true
			table.insert(validas, uid)
		end
	end
	datos.mascotasEquipadas = validas
end

local function publicar(jugador: Player, datos: Tipos.Datos)
	local ids = {}
	for _, mascota in activas(jugador, datos) do
		table.insert(ids, mascota.id)
	end
	jugador:SetAttribute("Mascotas", table.concat(ids, ","))
end

-- Algo cambió: atributo para los demás, multiplicador de ingreso y la ventana 🐾.
local function cambio(jugador: Player, datos: Tipos.Datos)
	limpiar(datos)
	publicar(jugador, datos)
	EconomiaService.AvisarCambio(jugador)
	DatosService.ActualizarEstado(jugador, { "mascotas" })
end

----------------------------------------------------------------------------- entregar

-- Agrega una mascota. Si hay espacio libre, se equipa sola. Devuelve (guardada, esNueva).
function MascotaService.Otorgar(jugador: Player, mascotaId: string, forzar: boolean?): (Guardada?, boolean)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or porId[mascotaId] == nil then
		return nil, false
	end
	if #datos.mascotas >= ConfigMascotas.INVENTARIO_MAXIMO and not forzar then
		return nil, false
	end
	local guardada: Guardada = { uid = DatosService.NuevoUid(jugador), id = mascotaId }
	table.insert(datos.mascotas, guardada)
	local esNueva = not datos.mascotasVistas[mascotaId]
	datos.mascotasVistas[mascotaId] = true
	if #datos.mascotasEquipadas < MascotaService.Espacios(jugador, datos) then
		table.insert(datos.mascotasEquipadas, guardada.uid)
	end
	return guardada, esNueva
end

----------------------------------------------------------------------------- acciones

local function abrirHuevo(jugador: Player, pedido: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(pedido) ~= "table" or type(pedido.id) ~= "string" then
		return
	end
	local huevo = huevoPorId[pedido.id]
	if huevo == nil then
		return
	end
	if datos.rebirths < huevo.requisitoRebirths then
		RedServidor.Notificar(jugador, `🔒 Necesitas Rebirth {huevo.requisitoRebirths}`, "error")
		return
	end
	local pedidos = if type(pedido.cantidad) == "number" then pedido.cantidad else 1
	local veces = math.clamp(math.floor(pedidos), 1, CanastaService.MaximoPorVez(jugador))
	if veces ~= veces then -- NaN
		return
	end

	local resultados = {}
	for _ = 1, veces do
		if #datos.mascotas >= ConfigMascotas.INVENTARIO_MAXIMO then
			RedServidor.Notificar(jugador, "🐾 ¡No te caben más Bichitos! Libera alguno", "error")
			break
		end
		if not EconomiaService.Gastar(jugador, huevo.precio, AnaliticaService.Tipo.Tienda, `huevo_{huevo.id}`) then
			RedServidor.Notificar(jugador, `Te faltan {Formato.Dinero(huevo.precio - datos.dinero)}`, "sinDinero")
			break
		end
		local mascotaId = Azar.Ponderado(huevo.pesos, numeroAleatorio)
		if mascotaId == nil then
			break
		end
		local guardada, esNueva = MascotaService.Otorgar(jugador, mascotaId)
		if guardada == nil then
			break
		end
		table.insert(resultados, { id = mascotaId, nuevo = esNueva })
		MascotaService.HuevoAbierto:Disparar(jugador, huevo.id, mascotaId)
		MisionService.Sumar(jugador, "abrir_huevo", 1)
		AnaliticaService.Evento(jugador, "HuevoAbierto", 1, { huevo.id, mascotaId })
		local mascota = porId[mascotaId]
		local rareza = Catalogo.datos.rareza[mascota.rareza]
		if rareza and rareza.orden >= ConfigMascotas.ANUNCIAR_DESDE then
			RedServidor.EnviarATodos(
				"Anuncio",
				`🐾 ¡{jugador.DisplayName} sacó {mascota.nombre} de un {huevo.nombre}!`,
				rareza.id
			)
		end
	end
	if #resultados > 0 then
		RedServidor.Enviar("Efecto", jugador, "Huevo", { huevo = huevo.id, resultados = resultados })
		cambio(jugador, datos)
	end
end

local function equipar(jugador: Player, uid: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(uid) ~= "string" or buscar(datos, uid) == nil then
		return
	end
	if table.find(datos.mascotasEquipadas, uid) then
		return
	end
	limpiar(datos)
	if #datos.mascotasEquipadas >= MascotaService.Espacios(jugador, datos) then
		RedServidor.Notificar(jugador, "No tienes más espacios: quita una mascota primero", "error")
		return
	end
	table.insert(datos.mascotasEquipadas, uid)
	cambio(jugador, datos)
end

local function quitar(jugador: Player, uid: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(uid) ~= "string" then
		return
	end
	local indice = table.find(datos.mascotasEquipadas, uid)
	if indice then
		table.remove(datos.mascotasEquipadas, indice)
		cambio(jugador, datos)
	end
end

local function equiparMejores(jugador: Player)
	local datos = DatosService.Obtener(jugador)
	if datos == nil then
		return
	end
	local lista = {}
	for _, guardada in datos.mascotas do
		local mascota = porId[guardada.id]
		if mascota then
			table.insert(lista, { uid = guardada.uid, bonus = mascota.bonus })
		end
	end
	datos.mascotasEquipadas = LogicaMascotas.Mejores(lista, MascotaService.Espacios(jugador, datos))
	cambio(jugador, datos)
end

local function liberar(jugador: Player, uid: any)
	local datos = DatosService.Obtener(jugador)
	if datos == nil or type(uid) ~= "string" then
		return
	end
	local guardada, indice = buscar(datos, uid)
	if guardada == nil or indice == nil then
		return
	end
	local mascota = porId[guardada.id]
	table.remove(datos.mascotas, indice)
	local equipada = table.find(datos.mascotasEquipadas, uid)
	if equipada then
		table.remove(datos.mascotasEquipadas, equipada)
	end
	local pago = if mascota then ConfigMascotas.LIBERAR[mascota.rareza] or 0 else 0
	if pago > 0 then
		EconomiaService.Agregar(jugador, pago, AnaliticaService.Tipo.Juego, "liberar_mascota")
	end
	RedServidor.Notificar(
		jugador,
		`🌿 Liberaste a {if mascota then mascota.nombre else "tu bichito"}. +{Formato.Dinero(pago)}`,
		"info"
	)
	cambio(jugador, datos)
end

----------------------------------------------------------------------------- estado

local function estado(jugador: Player, datos: Tipos.Datos)
	local lista = {}
	for _, guardada in datos.mascotas do
		table.insert(lista, { uid = guardada.uid, id = guardada.id })
	end
	local vistas = {}
	for id in datos.mascotasVistas do
		table.insert(vistas, id)
	end
	return {
		lista = lista,
		equipadas = table.clone(datos.mascotasEquipadas),
		espacios = MascotaService.Espacios(jugador, datos),
		bonus = MascotaService.Bonus(jugador, datos),
		vistas = vistas,
		maximoPorVez = CanastaService.MaximoPorVez(jugador),
	}
end

----------------------------------------------------------------------------- inicio

function MascotaService.Iniciar()
	DatosService.RegistrarEstado("mascotas", estado)

	EconomiaService.RegistrarBonus("Mascotas", function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		return if datos then MascotaService.Bonus(jugador, datos) else 0
	end)

	RecompensaService.RegistrarTipo("mascota", function(jugador: Player, recompensa)
		local id = recompensa.id or ""
		local guardada = MascotaService.Otorgar(jugador, id, true)
		local datos = DatosService.Obtener(jugador)
		if guardada == nil or datos == nil then
			return ""
		end
		cambio(jugador, datos)
		return `🐾 {porId[id].nombre}`
	end)

	DatosService.JugadorListo:Conectar(function(jugador: Player, datos: Tipos.Datos)
		-- Mascotas de un id que ya no existe (quitado en una actualización) se conservan
		-- guardadas pero no se equipan ni dan bonus.
		cambio(jugador, datos)
	end)
	-- Más espacios al hacer rebirth o comprar el pase.
	RebirthService.RebirthHecho:Conectar(function(jugador: Player)
		local datos = DatosService.Obtener(jugador)
		if datos then
			cambio(jugador, datos)
		end
	end)
	CompraService.PaseObtenido:Conectar(function(jugador: Player, clave: string)
		local datos = DatosService.Obtener(jugador)
		if datos and clave == "MASCOTAS_EXTRA" then
			cambio(jugador, datos)
		end
	end)
	Players.PlayerRemoving:Connect(function(jugador)
		jugador:SetAttribute("Mascotas", nil)
	end)

	Acciones.Registrar("huevo_abrir", abrirHuevo)
	Acciones.Registrar("mascota_equipar", equipar)
	Acciones.Registrar("mascota_quitar", quitar)
	Acciones.Registrar("mascota_mejores", equiparMejores)
	Acciones.Registrar("mascota_liberar", liberar)

	AdminService.Registrar("mascota", function(jugador, args)
		local id = args[1] or ""
		if porId[id] == nil then
			local ids = {}
			for _, mascota in ConfigMascotas.LISTA do
				table.insert(ids, mascota.id)
			end
			RedServidor.Notificar(jugador, `🛠️ Mascotas: {table.concat(ids, ", ")}`, "info")
			return
		end
		RecompensaService.Dar(jugador, { tipo = "mascota", id = id }, "admin")
		RedServidor.Notificar(jugador, `🛠️ +{porId[id].nombre}`, "info")
	end)
end

return MascotaService
