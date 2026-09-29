--!strict
--[[
	AdminController
	Panel de pruebas 🛠️ (solo aparece si el servidor te marca como admin; el servidor
	vuelve a verificar cada comando). Botones rápidos + un cuadro para escribir comandos.
	La lista de comandos está en server/Servicios/AdminService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Red = require(Shared:WaitForChild("Red"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local HudController = require(script.Parent:WaitForChild("HudController"))

local AdminController = {}

local jugador = Players.LocalPlayer
local panel: Frame? = nil

-- Botones rápidos: texto → comando. Otras fases agregan más con AdminController.Agregar.
local rapidos: { { texto: string, comando: string } } = {
	{ texto = "+$1M", comando = "dinero 1000000" },
	{ texto = "+$1B", comando = "dinero 1000000000" },
	{ texto = "Secreto en cinta", comando = "secreto" },
	{ texto = "Quitar mi escudo", comando = "sinescudo" },
	{ texto = "No soy novato", comando = "novato" },
	{ texto = "Reiniciar datos", comando = "reiniciar" },
}

local function enviar(comando: string)
	Red.Evento("AccionAdmin"):FireServer(comando)
end

function AdminController.Agregar(texto: string, comando: string)
	table.insert(rapidos, { texto = texto, comando = comando })
end

local function construirPanel(): Frame
	local pantalla = UI.Pantalla("Admin", 50)
	local nuevo = UI.Panel({
		Name = "PanelAdmin",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 300),
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = pantalla,
	})
	UI.Borde(nuevo, Tema.COLORES.naranja, 3)
	UI.Margen(nuevo, 10)
	UI.Texto({
		texto = "🛠️ Admin (solo pruebas)",
		tamano = UDim2.new(1, -50, 0, 28),
		tamanoLetra = 22,
		padre = nuevo,
	})
	UI.Boton({
		texto = "X",
		color = Tema.COLORES.rojo,
		tamano = UDim2.fromOffset(40, 40),
		posicion = UDim2.new(1, 0, 0, -4),
		ancla = Vector2.new(1, 0),
		alPulsar = function()
			nuevo.Visible = false
		end,
		padre = nuevo,
	})

	local rejilla = UI.Crear("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -100),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = nuevo,
	})
	UI.Crear("UIGridLayout", {
		CellSize = UDim2.fromOffset(128, 48),
		CellPadding = UDim2.fromOffset(6, 6),
		Parent = rejilla,
	})
	for _, rapido in rapidos do
		UI.Boton({
			texto = rapido.texto,
			color = Tema.COLORES.fondoClaro,
			tamanoLetra = 16,
			alPulsar = function()
				enviar(rapido.comando)
			end,
			padre = rejilla,
		})
	end

	local cuadro = UI.Crear("TextBox", {
		Position = UDim2.new(0, 0, 1, -50),
		Size = UDim2.new(1, -110, 0, 48),
		BackgroundColor3 = Tema.COLORES.fondoClaro,
		Font = Tema.FUENTE,
		TextSize = 18,
		TextColor3 = Tema.COLORES.texto,
		PlaceholderText = "crunchi crunch_omega arcoiris",
		Text = "",
		ClearTextOnFocus = false,
		Parent = nuevo,
	}) :: TextBox
	UI.Esquinas(cuadro)
	UI.Boton({
		texto = "Ejecutar",
		color = Tema.COLORES.verde,
		tamano = UDim2.fromOffset(100, 48),
		posicion = UDim2.new(1, 0, 1, -50),
		ancla = Vector2.new(1, 0),
		tamanoLetra = 18,
		alPulsar = function()
			if cuadro.Text ~= "" then
				enviar(cuadro.Text)
			end
		end,
		padre = nuevo,
	})
	return nuevo
end

local function activar()
	if panel then
		return
	end
	local nuevo = construirPanel()
	panel = nuevo
	HudController.AgregarBoton("🛠️", Tema.COLORES.naranja, 100, function()
		nuevo.Visible = not nuevo.Visible
	end)
end

function AdminController.Iniciar()
	if jugador:GetAttribute("EsAdmin") == true then
		activar()
	end
	jugador:GetAttributeChangedSignal("EsAdmin"):Connect(function()
		if jugador:GetAttribute("EsAdmin") == true then
			activar()
		end
	end)
end

return AdminController
