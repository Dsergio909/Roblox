--!strict
--[[
	Punto de entrada del CLIENTE (se ejecuta en el dispositivo de cada jugador).

	Rojo convierte esta carpeta (src/client) en un LocalScript llamado "Client" dentro
	de StarterPlayer > StarterPlayerScripts. Igual que en el servidor, un solo punto
	de entrada cargará los "controladores" (UI, efectos, sonidos) en la Fase 1.

	Por ahora solo muestra un aviso temporal para comprobar que Rojo funciona
	y que la UI se ve bien en celular (respeta el notch y las áreas seguras).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- En el cliente usamos WaitForChild: las cosas de ReplicatedStorage pueden tardar
-- un instante en llegar desde el servidor.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Juego = require(Shared:WaitForChild("Config"):WaitForChild("Juego"))

local SEGUNDOS_VISIBLE = 6

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")

local pantalla = Instance.new("ScreenGui")
pantalla.Name = "AvisoRojo"
pantalla.ResetOnSpawn = false
-- DeviceSafeInsets: nada queda tapado por el notch ni por las esquinas redondeadas del celular.
pantalla.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

local etiqueta = Instance.new("TextLabel")
etiqueta.Name = "Mensaje"
-- Tamaños en escala (porcentaje de la pantalla), no en píxeles fijos: se adapta a cualquier dispositivo.
etiqueta.AnchorPoint = Vector2.new(0.5, 0)
etiqueta.Position = UDim2.fromScale(0.5, 0.03)
etiqueta.Size = UDim2.fromScale(0.8, 0.08)
etiqueta.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
etiqueta.BackgroundTransparency = 0.2
etiqueta.TextColor3 = Color3.fromRGB(140, 230, 90)
etiqueta.Font = Enum.Font.FredokaOne
etiqueta.TextScaled = true
etiqueta.Text = `✔ Rojo conectado · {Juego.NOMBRE} v{Juego.VERSION} · Fase {Juego.FASE}`
etiqueta.Parent = pantalla

local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0.3, 0)
esquinas.Parent = etiqueta

-- Límite de tamaño de letra: legible en un celular de 5" sin verse gigante en un monitor.
local limiteTexto = Instance.new("UITextSizeConstraint")
limiteTexto.MinTextSize = 14
limiteTexto.MaxTextSize = 32
limiteTexto.Parent = etiqueta

local margen = Instance.new("UIPadding")
margen.PaddingLeft = UDim.new(0.03, 0)
margen.PaddingRight = UDim.new(0.03, 0)
margen.PaddingTop = UDim.new(0.15, 0)
margen.PaddingBottom = UDim.new(0.15, 0)
margen.Parent = etiqueta

pantalla.Parent = playerGui

print(`[{Juego.NOMBRE}] Cliente v{Juego.VERSION} iniciado para {jugador.Name}.`)

task.delay(SEGUNDOS_VISIBLE, function()
	pantalla:Destroy()
end)
