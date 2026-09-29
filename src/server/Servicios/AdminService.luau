--!strict
--[[
	AdminService
	Comandos de prueba SOLO para los UserIds de Config/Admin (y cualquiera en Studio si
	PERMITIR_EN_STUDIO = true). El cliente muestra un panel 🛠️ a quien tenga el atributo
	"EsAdmin"; el servidor vuelve a verificar CADA comando.

	Comandos (se escriben en el panel o se pulsan sus botones):
	  dinero <cantidad>        suma dinero (por defecto 1M)
	  reiniciar                borra tus datos y empiezas de cero
	  crunchi <id> [mutación]  te da un Crunchi en un pedestal libre
	  cinta <id> [mutación]    hace aparecer ese Crunchi en la cinta principal
	  secreto                  hace aparecer un Crunchi Secreto al azar en la cinta
	  sinescudo                quita el escudo de tu base (para probar robos)
	  novato                   suma 15 min de tiempo jugado (salta la protección de novato)
	  lista                    muestra los ids de todos los Crunchis
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigAdmin = require(Config:WaitForChild("Admin"))
local ConfigRobo = require(Config:WaitForChild("Robo"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))

local DatosService = require(script.Parent:WaitForChild("DatosService"))
local EconomiaService = require(script.Parent:WaitForChild("EconomiaService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local CintaService = require(script.Parent:WaitForChild("CintaService"))
local RedServidor = require(script.Parent.Parent:WaitForChild("Util"):WaitForChild("RedServidor"))

local AdminService = {}

type Comando = (jugador: Player, argumentos: { string }) -> ()
local comandos: { [string]: Comando } = {}

function AdminService.EsAdmin(jugador: Player): boolean
	if table.find(ConfigAdmin.USUARIOS, jugador.UserId) then
		return true
	end
	return ConfigAdmin.PERMITIR_EN_STUDIO and RunService:IsStudio()
end

-- Otros servicios pueden agregar sus propios comandos (p. ej. "rebirth" en la Fase 2).
function AdminService.Registrar(nombre: string, fn: Comando)
	comandos[nombre] = fn
end

local function responder(jugador: Player, texto: string)
	RedServidor.Notificar(jugador, `🛠️ {texto}`, "info")
end

local function mutacionValida(texto: string?): string
	if texto and Catalogo.datos.mutacion[texto] then
		return texto
	end
	return "normal"
end

local function registrarBasicos()
	AdminService.Registrar("dinero", function(jugador, args)
		local cantidad = tonumber(args[1]) or 1e6
		EconomiaService.Agregar(jugador, cantidad, "Admin", "admin")
		responder(jugador, `+{Formato.Dinero(cantidad)}`)
	end)

	AdminService.Registrar("reiniciar", function(jugador)
		DatosService.Reiniciar(jugador)
		responder(jugador, "Datos reiniciados")
	end)

	AdminService.Registrar("crunchi", function(jugador, args)
		local id = args[1]
		if id == nil or Catalogo.datos.crunchi[id] == nil then
			responder(jugador, "Crunchi desconocido. Usa: crunchi <id> [mutación] (escribe 'lista')")
			return
		end
		local crunchi = BaseService.Otorgar(jugador, id, mutacionValida(args[2]))
		if crunchi == nil then
			responder(jugador, "No tienes espacio (base y depósito llenos)")
			return
		end
		responder(jugador, `Te di {Catalogo.NombreCompleto(crunchi.id, crunchi.mut)}`)
	end)

	AdminService.Registrar("cinta", function(jugador, args)
		local id = args[1]
		if id == nil or Catalogo.datos.crunchi[id] == nil then
			responder(jugador, "Crunchi desconocido. Usa: cinta <id> [mutación]")
			return
		end
		CintaService.Aparecer("principal", id, mutacionValida(args[2]))
		responder(jugador, "Apareció en la cinta principal")
	end)

	AdminService.Registrar("secreto", function(jugador)
		local secreto = Azar.Elegir(Catalogo.datos.porRareza["secreto"] or {}, math.random)
		if secreto then
			CintaService.Aparecer("principal", secreto.id, "normal")
			responder(jugador, `Apareció {secreto.nombre} en la cinta`)
		end
	end)

	AdminService.Registrar("sinescudo", function(jugador)
		BaseService.QuitarEscudo(jugador)
		responder(jugador, "Tu base ya no tiene escudo")
	end)

	AdminService.Registrar("novato", function(jugador)
		local datos = DatosService.Obtener(jugador)
		if datos then
			datos.stats.tiempoJugado += ConfigRobo.NOVATO_SEGUNDOS
			responder(jugador, "Ya no eres novato (reinicia el escudo con 'sinescudo')")
		end
	end)

	AdminService.Registrar("lista", function(jugador)
		local ids = {}
		for _, crunchi in Catalogo.datos.crunchis do
			table.insert(ids, crunchi.id)
		end
		responder(jugador, table.concat(ids, ", "))
		print("[Admin] Crunchis: " .. table.concat(ids, ", "))
	end)
end

local function ejecutar(jugador: Player, texto: any)
	if type(texto) ~= "string" or #texto > 200 then
		return
	end
	if not AdminService.EsAdmin(jugador) then
		warn(`[Admin] {jugador.Name} ({jugador.UserId}) intentó usar un comando sin permiso`)
		return
	end
	local partes = string.split(string.lower(texto), " ")
	local nombre = table.remove(partes, 1)
	local comando = if nombre then comandos[nombre] else nil
	if comando == nil then
		responder(jugador, `Comando desconocido: {nombre or ""}`)
		return
	end
	local argumentos = {}
	for _, parte in partes do
		if parte ~= "" then
			table.insert(argumentos, parte)
		end
	end
	comando(jugador, argumentos)
end

function AdminService.Iniciar()
	registrarBasicos()
	RedServidor.Escuchar("AccionAdmin", 5, 10, ejecutar)
	DatosService.JugadorListo:Conectar(function(jugador: Player)
		if AdminService.EsAdmin(jugador) then
			jugador:SetAttribute("EsAdmin", true)
		end
	end)
end

return AdminService
