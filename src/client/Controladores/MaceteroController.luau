--!strict
--[[
	MaceteroController
	  - Dibuja la planta en el macetero de CADA base (se ve crecer; los demás también la ven).
	  - Panel 🌱 al tocar tu macetero: plantar una semilla, ver cuánto falta o cosechar.

	La planta es un placeholder (tallo + bulbo del color de la semilla) que crece según el
	progreso. Solo existe en el cliente (cero costo en el servidor).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local BaseController = require(script.Parent:WaitForChild("BaseController"))

local MaceteroController = {}

local ventana: Ventana.Ventana? = nil
local plantas: { [BasePart]: { tallo: Part, bulbo: Part, texto: TextLabel } } = {}

----------------------------------------------------------------------------- planta visible

local function crearPlanta(macetero: BasePart)
	local tallo = Instance.new("Part")
	tallo.Name = "Tallo"
	tallo.Anchored = true
	tallo.CanCollide = false
	tallo.CanQuery = false
	tallo.CanTouch = false
	tallo.CastShadow = false
	tallo.Color = Color3.fromRGB(80, 170, 60)
	tallo.Material = Enum.Material.SmoothPlastic
	local bulbo = tallo:Clone()
	bulbo.Name = "Bulbo"
	bulbo.Shape = Enum.PartType.Ball
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.fromOffset(150, 30)
	cartel.StudsOffset = Vector3.new(0, 4.5, 0)
	cartel.MaxDistance = 50
	cartel.LightInfluence = 0
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.Font = Enum.Font.FredokaOne
	texto.TextScaled = true
	texto.TextColor3 = Color3.fromRGB(200, 255, 170)
	texto.TextStrokeTransparency = 0.2
	texto.Parent = cartel
	cartel.Parent = macetero
	tallo.Parent = macetero
	bulbo.Parent = macetero
	plantas[macetero] = { tallo = tallo, bulbo = bulbo, texto = texto }
end

local function actualizarPlanta(macetero: BasePart, ahora: number)
	local semillaId = macetero:GetAttribute("Semilla")
	local listaEn = macetero:GetAttribute("ListaEn")
	local planta = plantas[macetero]
	if type(semillaId) ~= "string" or semillaId == "" or type(listaEn) ~= "number" then
		if planta then
			planta.tallo.Transparency = 1
			planta.bulbo.Transparency = 1
			planta.texto.Text = ""
		end
		return
	end
	if planta == nil then
		crearPlanta(macetero)
		planta = plantas[macetero]
	end
	local p = planta :: { tallo: Part, bulbo: Part, texto: TextLabel }
	local semilla = Catalogo.semilla[semillaId]
	local duracion = if semilla then semilla.minutos * 60 else 1
	local restante = listaEn - ahora
	local progreso = math.clamp(1 - restante / duracion, 0.05, 1)
	local base = macetero.Position + Vector3.new(0, macetero.Size.X / 2, 0)
	local alto = 0.4 + 2.4 * progreso
	p.tallo.Transparency = 0
	p.tallo.Size = Vector3.new(0.3, alto, 0.3)
	p.tallo.CFrame = CFrame.new(base + Vector3.new(0, alto / 2, 0))
	p.bulbo.Transparency = 0
	p.bulbo.Size = Vector3.one * (0.4 + 1.4 * progreso)
	p.bulbo.CFrame = CFrame.new(base + Vector3.new(0, alto, 0))
	p.bulbo.Color = if semilla then semilla.color else Color3.fromRGB(140, 200, 90)
	p.bulbo.Material = if restante <= 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.texto.Text = if restante <= 0 then "✨ ¡Lista!" else `🌱 {Formato.Tiempo(restante)}`
end

----------------------------------------------------------------------------- panel

local function textoProbabilidades(pesos: { [string]: number }): string
	local probabilidades = Azar.Probabilidades(pesos)
	local partes = {}
	for i = #Catalogo.datos.rarezas, 1, -1 do
		local rareza = Catalogo.datos.rarezas[i]
		local p = probabilidades[rareza.id]
		if p then
			table.insert(partes, `{rareza.nombre} {Formato.Porcentaje(p)}`)
		end
	end
	return table.concat(partes, " · ")
end

local function refrescar()
	local v = ventana
	if v == nil or not v:EstaAbierta() then
		return
	end
	UI.Vaciar(v.contenido)
	local e = EstadoCliente.Obtener("macetero")
	if type(e) ~= "table" then
		return
	end
	local lista = UI.Lista({ Size = UDim2.fromScale(1, 1), Parent = v.contenido }, 6)

	if e.semilla ~= "" then
		local semilla = Catalogo.semilla[e.semilla]
		local restante = e.listaEn - Reloj.Ahora()
		UI.Texto({
			texto = `Plantaste: {if semilla then semilla.nombre else e.semilla}`,
			tamano = UDim2.new(1, -8, 0, 26),
			tamanoLetra = 20,
			padre = lista,
		}).LayoutOrder =
			1
		if restante > 0 then
			UI.Texto({
				texto = `Estará lista en {Formato.Duracion(restante)}. ¡Sigue creciendo aunque te desconectes!`,
				tamano = UDim2.new(1, -8, 0, 44),
				tamanoLetra = 16,
				color = Tema.COLORES.textoSuave,
				padre = lista,
			}).LayoutOrder =
				2
		else
			UI.Boton({
				texto = "✨ ¡Cosechar!",
				color = Tema.COLORES.verde,
				tamano = UDim2.new(1, -8, 0, 56),
				tamanoLetra = 22,
				alPulsar = function()
					Red.Evento("AccionMenu"):FireServer("cosechar")
					v:Cerrar()
				end,
				padre = lista,
			}).LayoutOrder =
				2
		end
		return
	end

	UI.Texto({
		texto = "Elige una semilla para plantar. Crece en tiempo real y al cosechar sale un Crunchi al azar (¡con más probabilidad de mutación!).",
		tamano = UDim2.new(1, -8, 0, 40),
		tamanoLetra = 14,
		color = Tema.COLORES.textoSuave,
		padre = lista,
	}).LayoutOrder =
		0
	local alguna = false
	for i, semilla in Catalogo.semillas do
		local cantidad = e.semillas[semilla.id] or 0
		if cantidad > 0 then
			alguna = true
			local marco = UI.Panel({
				Size = UDim2.new(1, -8, 0, 70),
				BackgroundColor3 = Tema.COLORES.fondoClaro,
				LayoutOrder = i,
				Parent = lista,
			})
			UI.Borde(marco, semilla.color, 2)
			UI.Texto({
				texto = `🌱 {semilla.nombre} ×{cantidad} · {Formato.Duracion(semilla.minutos * 60)}`,
				tamano = UDim2.new(1, -140, 0, 24),
				posicion = UDim2.fromOffset(10, 4),
				tamanoLetra = 17,
				alineacion = Enum.TextXAlignment.Left,
				padre = marco,
			})
			UI.Texto({
				texto = textoProbabilidades(semilla.pesos),
				tamano = UDim2.new(1, -140, 0, 36),
				posicion = UDim2.fromOffset(10, 28),
				tamanoLetra = 12,
				alineacion = Enum.TextXAlignment.Left,
				color = Tema.COLORES.textoSuave,
				padre = marco,
			})
			UI.Boton({
				texto = "Plantar",
				color = Tema.COLORES.verde,
				tamano = UDim2.fromOffset(120, 46),
				posicion = UDim2.new(1, -8, 0.5, 0),
				ancla = Vector2.new(1, 0.5),
				alPulsar = function()
					Red.Evento("AccionMenu"):FireServer("plantar", semilla.id)
				end,
				padre = marco,
			})
		end
	end
	if not alguna then
		UI.Texto({
			texto = "No tienes semillas. Consíguelas en las misiones y en el calendario diario 🎁",
			tamano = UDim2.new(1, -8, 0, 40),
			tamanoLetra = 16,
			padre = lista,
		}).LayoutOrder =
			99
	end
end

function MaceteroController.Iniciar()
	local v = Ventana.nueva("🌱 Macetero", 480, 300, Tema.COLORES.verde)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end
	BaseController.MaceteroPedido:Conectar(function()
		v:Abrir()
	end)
	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "macetero" then
			refrescar()
		end
	end)

	-- Plantas de todas las bases visibles: se actualizan una vez por segundo.
	Reloj.Cada(1, function()
		local carpeta = BaseController.Carpeta()
		if carpeta == nil then
			return
		end
		local ahora = Reloj.Ahora()
		for _, base in carpeta:GetChildren() do
			local macetero = base:FindFirstChild("Macetero")
			if macetero and macetero:IsA("BasePart") then
				actualizarPlanta(macetero, ahora)
			end
		end
		for macetero in plantas do
			if macetero.Parent == nil then
				plantas[macetero] = nil
			end
		end
	end)
end

return MaceteroController
