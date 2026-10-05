--!strict
--[[
	Interfaz/Tarjetas
	Tarjeta visual de un Crunchi para los menús (Índice, depósito, canastas, rebirth...).

	Sin imágenes todavía: un círculo con el color de la mutación y un 🍏, el nombre y la
	rareza con su color. Los Crunchis que aún no tienes se muestran como SILUETA negra con
	"???" (pero se ve de qué rareza son: da ganas de conseguirlos).

	Cuando existan imágenes de las caras (docs/ASSETS_PENDIENTES.md, I1), se agregarán aquí.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalogo = require(Shared:WaitForChild("Catalogo"))

local Interfaz = script.Parent
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))

local Tarjetas = {}

local VERDE = Color3.fromRGB(126, 217, 87)

export type Opciones = {
	desconocido: boolean?, -- silueta "???"
	pie: string?, -- texto extra abajo (precio, "x2", "⭐ Mejor Amigo"...)
	alPulsar: (() -> ())?,
	orden: number?,
	padre: Instance?,
	tamano: UDim2?,
}

function Tarjetas.Crunchi(crunchiId: string, mutacionId: string, opciones: Opciones): GuiObject
	local def = Catalogo.datos.crunchi[crunchiId]
	local rareza = Catalogo.RarezaDe(crunchiId)
	local mutacion = Catalogo.Mutacion(mutacionId)
	local desconocido = opciones.desconocido == true
	local colorRareza = if rareza then rareza.color else Tema.COLORES.textoSuave
	if rareza and rareza.id == "secreto" then
		colorRareza = Color3.fromRGB(230, 230, 230)
	end

	local tarjeta: GuiObject
	if opciones.alPulsar then
		local boton = UI.Crear("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = Tema.COLORES.fondoClaro,
		}) :: TextButton
		local fn = opciones.alPulsar
		boton.Activated:Connect(function()
			fn()
		end)
		tarjeta = boton
	else
		tarjeta = UI.Crear("Frame", { BackgroundColor3 = Tema.COLORES.fondoClaro }) :: Frame
	end
	tarjeta.Name = crunchiId
	tarjeta.Size = opciones.tamano or UDim2.fromOffset(96, 118)
	tarjeta.LayoutOrder = opciones.orden or 0
	tarjeta.BorderSizePixel = 0
	UI.Esquinas(tarjeta)
	UI.Borde(tarjeta, if desconocido then Color3.fromRGB(70, 70, 80) else colorRareza, 2.5)

	-- "Foto": círculo con el color del Crunchi (o negro si es desconocido)
	local foto = UI.Crear("Frame", {
		Name = "Foto",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = if desconocido then Color3.fromRGB(15, 15, 18) else (mutacion.color or VERDE),
		Parent = tarjeta,
	})
	UI.Esquinas(foto, UDim.new(1, 0))
	UI.Texto({
		texto = if desconocido then "?" else "🍏",
		tamano = UDim2.fromScale(1, 1),
		tamanoLetra = if desconocido then 30 else 30,
		color = if desconocido then Color3.fromRGB(90, 90, 100) else Tema.COLORES.texto,
		padre = foto,
	})

	UI.Texto({
		texto = if desconocido then "???" else (if def then def.nombre else crunchiId),
		tamano = UDim2.new(1, -6, 0, 30),
		posicion = UDim2.fromOffset(3, 60),
		tamanoLetra = 14,
		padre = tarjeta,
	})
	local textoRareza = if rareza then rareza.nombre else ""
	if not desconocido and mutacion.id ~= "normal" then
		textoRareza = `{mutacion.nombre}`
	end
	UI.Texto({
		texto = textoRareza,
		tamano = UDim2.new(1, -6, 0, 14),
		posicion = UDim2.fromOffset(3, 89),
		tamanoLetra = 12,
		color = colorRareza,
		padre = tarjeta,
	})
	if opciones.pie then
		UI.Texto({
			texto = opciones.pie,
			tamano = UDim2.new(1, -6, 0, 14),
			posicion = UDim2.fromOffset(3, 102),
			tamanoLetra = 12,
			color = Tema.COLORES.dinero,
			padre = tarjeta,
		})
	end
	if opciones.padre then
		tarjeta.Parent = opciones.padre
	end
	return tarjeta
end

-- Tarjeta de un Bichito (mascota): color, ícono, nombre, rareza y bonus. Silueta "???" si
-- todavía no lo tienes (para la colección).
export type DatosMascota = {
	id: string,
	nombre: string,
	icono: string,
	rareza: string,
	bonus: number,
	color: Color3,
}

function Tarjetas.Mascota(mascota: DatosMascota, opciones: Opciones): GuiObject
	local rareza = Catalogo.datos.rareza[mascota.rareza]
	local desconocido = opciones.desconocido == true
	local colorRareza = if rareza then rareza.color else Tema.COLORES.textoSuave
	if rareza and rareza.id == "secreto" then
		colorRareza = Color3.fromRGB(230, 230, 230)
	end

	local tarjeta: GuiObject
	if opciones.alPulsar then
		local boton = UI.Crear("TextButton", {
			Text = "",
			AutoButtonColor = true,
			BackgroundColor3 = Tema.COLORES.fondoClaro,
		}) :: TextButton
		local fn = opciones.alPulsar
		boton.Activated:Connect(function()
			fn()
		end)
		tarjeta = boton
	else
		tarjeta = UI.Crear("Frame", { BackgroundColor3 = Tema.COLORES.fondoClaro }) :: Frame
	end
	tarjeta.Name = mascota.id
	tarjeta.Size = opciones.tamano or UDim2.fromOffset(96, 118)
	tarjeta.LayoutOrder = opciones.orden or 0
	tarjeta.BorderSizePixel = 0
	UI.Esquinas(tarjeta)
	UI.Borde(tarjeta, if desconocido then Color3.fromRGB(70, 70, 80) else colorRareza, 2.5)

	local foto = UI.Crear("Frame", {
		Name = "Foto",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = if desconocido then Color3.fromRGB(15, 15, 18) else mascota.color,
		Parent = tarjeta,
	})
	UI.Esquinas(foto, UDim.new(1, 0))
	UI.Texto({
		texto = if desconocido then "?" else mascota.icono,
		tamano = UDim2.fromScale(1, 1),
		tamanoLetra = 30,
		color = if desconocido then Color3.fromRGB(90, 90, 100) else Tema.COLORES.texto,
		padre = foto,
	})
	UI.Texto({
		texto = if desconocido then "???" else mascota.nombre,
		tamano = UDim2.new(1, -6, 0, 30),
		posicion = UDim2.fromOffset(3, 60),
		tamanoLetra = 13,
		padre = tarjeta,
	})
	UI.Texto({
		texto = if rareza then `{rareza.nombre} · +{math.floor(mascota.bonus * 100 + 0.5)} %` else "",
		tamano = UDim2.new(1, -6, 0, 14),
		posicion = UDim2.fromOffset(3, 89),
		tamanoLetra = 12,
		color = colorRareza,
		padre = tarjeta,
	})
	if opciones.pie then
		UI.Texto({
			texto = opciones.pie,
			tamano = UDim2.new(1, -6, 0, 14),
			posicion = UDim2.fromOffset(3, 102),
			tamanoLetra = 12,
			color = Tema.COLORES.dinero,
			padre = tarjeta,
		})
	end
	if opciones.padre then
		tarjeta.Parent = opciones.padre
	end
	return tarjeta
end

-- Rejilla (grid) para tarjetas, que crece hacia abajo según el contenido.
function Tarjetas.Rejilla(padre: Instance, orden: number?): Frame
	local marco = UI.Crear("Frame", {
		Name = "Rejilla",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = orden or 0,
		Parent = padre,
	}) :: Frame
	UI.Crear("UIGridLayout", {
		CellSize = UDim2.fromOffset(96, 118),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = marco,
	})
	return marco
end

return Tarjetas
