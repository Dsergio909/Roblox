--!strict
--[[
	CintaController
	Dibuja y mueve los Crunchis de las cintas EN EL DISPOSITIVO del jugador.

	El servidor solo avisa "apareció el Crunchi #57 en el segundo T"; aquí se crea el modelo
	y se mueve cada frame con la misma fórmula que usa el servidor. Resultado: movimiento
	suave y cero tráfico de red por el movimiento.

	Cada Crunchi tiene una acción "Comprar" (mantener pulsado). La compra la valida el servidor.
	El precio se ve en verde si te alcanza y en rojo si no.

	Reciclaje (object pooling): cuando un Crunchi sale de la cinta, su modelo no se destruye;
	se guarda y se reutiliza para el próximo Crunchi igual (misma especie y mutación). Crear
	modelos es lo más caro en celulares, y en la cinta se repiten mucho.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigMapa = require(Shared:WaitForChild("Config"):WaitForChild("Mapa"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local ModeloCrunchi = require(Shared:WaitForChild("ModeloCrunchi"))
local Red = require(Shared:WaitForChild("Red"))
local Tipos = require(Shared:WaitForChild("Tipos"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local CintaController = {}

type Reciclable = {
	clave: string,
	modelo: Model,
	cuerpo: BasePart,
	etiquetaPrecio: TextLabel?,
	prompt: ProximityPrompt,
}

type ItemLocal = {
	datos: Tipos.ItemCinta,
	reciclable: Reciclable,
	conexion: RBXScriptConnection,
	modelo: Model,
	cuerpo: BasePart,
	radio: number,
	precio: number,
	etiquetaPrecio: TextLabel?,
	prompt: ProximityPrompt,
	inicio: Vector3,
	direccion: Vector3,
	velocidad: number,
	largo: number,
	altura: number,
	fase: number,
}

local jugador = Players.LocalPlayer
local items: { [number]: ItemLocal } = {}
local carpeta: Folder

local reciclados: { [string]: { Reciclable } } = {}
local cantidadReciclados = 0
local MAX_RECICLADOS = 40
local MAX_RECICLADOS_POR_TIPO = 4

local VERDE = Color3.fromRGB(120, 255, 120)
local ROJO = Color3.fromRGB(255, 110, 110)

----------------------------------------------------------------------------- crear / quitar

-- Modelo + etiqueta + acción "Comprar" de un Crunchi (nuevo o reciclado).
local function obtenerReciclable(crunchiId: string, mutacionId: string): Reciclable
	local clave = `{crunchiId}:{mutacionId}`
	local lista = reciclados[clave]
	if lista and #lista > 0 then
		cantidadReciclados -= 1
		return table.remove(lista) :: Reciclable
	end

	local modelo = ModeloCrunchi.Crear(crunchiId, mutacionId)
	local cuerpo = modelo.PrimaryPart :: BasePart
	local ingreso, precio = Catalogo.Valor(crunchiId, mutacionId)
	local etiqueta = ModeloCrunchi.CrearEtiqueta(crunchiId, mutacionId, {
		precio = precio,
		ingresoPorSegundo = ingreso,
		distanciaMaxima = 70,
		formatoDinero = Formato.Dinero,
	})
	etiqueta.Parent = modelo
	local etiquetaPrecio = etiqueta:FindFirstChild("Precio")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Comprar"
	prompt.ActionText = `Comprar {Formato.Dinero(precio)}`
	prompt.ObjectText = Catalogo.NombreCompleto(crunchiId, mutacionId)
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = cuerpo
	return {
		clave = clave,
		modelo = modelo,
		cuerpo = cuerpo,
		etiquetaPrecio = if etiquetaPrecio and etiquetaPrecio:IsA("TextLabel") then etiquetaPrecio else nil,
		prompt = prompt,
	}
end

local function reciclar(reciclable: Reciclable)
	local lista = reciclados[reciclable.clave] or {}
	reciclados[reciclable.clave] = lista
	if cantidadReciclados >= MAX_RECICLADOS or #lista >= MAX_RECICLADOS_POR_TIPO then
		reciclable.modelo:Destroy()
		return
	end
	reciclable.modelo.Parent = nil
	table.insert(lista, reciclable)
	cantidadReciclados += 1
end

local function crear(datos: Tipos.ItemCinta)
	if items[datos.id] or Catalogo.datos.crunchi[datos.crunchi] == nil then
		return
	end
	local cinta = Catalogo.datos.cinta[datos.cinta]
	local mapa = ConfigMapa.CINTAS[datos.cinta]
	if cinta == nil or mapa == nil then
		return
	end
	local vector = mapa.fin - mapa.inicio
	local largo = vector.Magnitude
	if (Reloj.Ahora() - datos.t0) * cinta.velocidad >= largo then
		return -- ya llegó al final
	end

	local reciclable = obtenerReciclable(datos.crunchi, datos.mut)
	local _, precio = Catalogo.Valor(datos.crunchi, datos.mut)
	local id = datos.id
	local conexion = reciclable.prompt.Triggered:Connect(function()
		Red.Evento("ComprarCinta"):FireServer(id)
	end)

	local cuerpo = reciclable.cuerpo
	reciclable.modelo.Parent = carpeta
	items[datos.id] = {
		datos = datos,
		reciclable = reciclable,
		conexion = conexion,
		modelo = reciclable.modelo,
		cuerpo = cuerpo,
		radio = cuerpo.Size.Y / 2,
		precio = precio,
		etiquetaPrecio = reciclable.etiquetaPrecio,
		prompt = reciclable.prompt,
		inicio = mapa.inicio,
		direccion = vector.Unit,
		velocidad = cinta.velocidad,
		largo = largo,
		altura = ConfigMapa.ALTURA_CINTA,
		fase = math.random() * math.pi * 2,
	}
end

local function quitar(id: number)
	local item = items[id]
	if item then
		items[id] = nil
		item.conexion:Disconnect()
		reciclar(item.reciclable)
	end
end

----------------------------------------------------------------------------- movimiento

local function mover()
	local momento = Reloj.Ahora()
	local camara = workspace.CurrentCamera
	local posCamara = if camara then camara.CFrame.Position else Vector3.zero
	for id, item in items do
		local distancia = (momento - item.datos.t0) * item.velocidad
		if distancia >= item.largo then
			quitar(id)
			continue
		end
		-- Saltitos mientras avanza: se ve vivo y gracioso.
		local salto = math.abs(math.sin(momento * 7 + item.fase)) * 0.35
		local posicion = item.inicio + item.direccion * distancia + Vector3.new(0, item.altura + item.radio + salto, 0)
		-- Mira hacia la cámara (solo en horizontal) para que siempre veas su cara.
		local haciaCamara = Vector3.new(posCamara.X, posicion.Y, posCamara.Z)
		if (haciaCamara - posicion).Magnitude > 0.1 then
			item.cuerpo.CFrame = CFrame.lookAt(posicion, haciaCamara)
		else
			item.cuerpo.CFrame = CFrame.new(posicion)
		end
	end
end

-- Precio en verde si alcanza, en rojo si no; candado si falta rebirth.
local function actualizarPrecios()
	local dinero = jugador:GetAttribute("Dinero")
	local rebirths = jugador:GetAttribute("Rebirths")
	local saldo = if type(dinero) == "number" then dinero else 0
	local nivel = if type(rebirths) == "number" then rebirths else 0
	for _, item in items do
		local requisito = Catalogo.datos.cinta[item.datos.cinta].requisitoRebirths
		if nivel < requisito then
			item.prompt.ActionText = `🔒 Rebirth {requisito}`
			item.prompt.Enabled = false
			if item.etiquetaPrecio then
				item.etiquetaPrecio.TextColor3 = ROJO
			end
		else
			item.prompt.Enabled = true
			if item.etiquetaPrecio then
				item.etiquetaPrecio.TextColor3 = if saldo >= item.precio then VERDE else ROJO
			end
		end
	end
end

----------------------------------------------------------------------------- consultas

-- El Crunchi de la cinta más cercano que el jugador puede pagar (para el tutorial).
function CintaController.MasCercanoAsequible(posicion: Vector3): BasePart?
	local dinero = jugador:GetAttribute("Dinero")
	local saldo = if type(dinero) == "number" then dinero else 0
	local mejor: BasePart? = nil
	local mejorDistancia = math.huge
	for _, item in items do
		if item.precio <= saldo and item.prompt.Enabled then
			local distancia = (item.cuerpo.Position - posicion).Magnitude
			if distancia < mejorDistancia then
				mejor = item.cuerpo
				mejorDistancia = distancia
			end
		end
	end
	return mejor
end

----------------------------------------------------------------------------- inicio

function CintaController.Iniciar()
	carpeta = Instance.new("Folder")
	carpeta.Name = "CintaLocal"
	carpeta.Parent = workspace

	Red.Evento("CintaNuevo").OnClientEvent:Connect(function(datos: any)
		if type(datos) == "table" and type(datos.id) == "number" then
			crear(datos)
		end
	end)
	Red.Evento("CintaRemovido").OnClientEvent:Connect(function(id: any)
		if type(id) == "number" then
			quitar(id)
		end
	end)

	task.spawn(function()
		local ok, lista = pcall(function()
			return Red.Funcion("PedirCinta"):InvokeServer()
		end)
		if ok and type(lista) == "table" then
			for _, datos in lista do
				crear(datos)
			end
		end
	end)

	RunService.RenderStepped:Connect(mover)
	Reloj.Cada(0.5, actualizarPrecios)
end

return CintaController
