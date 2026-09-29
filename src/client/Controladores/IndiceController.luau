--!strict
--[[
	IndiceController
	Menú 📖 Índice: la colección de Crunchis.

	  - Pestañas: Normal y cada mutación (Dorado, Diamante...) + Títulos.
	  - Agrupado por SET, con su progreso ("3/5") y su premio (+3 % para siempre).
	  - Los que te faltan se ven como silueta "???" con el color de su rareza.
	  - Barra general con el próximo hito (25/50/75/100 %).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local ConfigIndice = require(Config:WaitForChild("Indice"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local Tarjetas = require(Interfaz:WaitForChild("Tarjetas"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))

local IndiceController = {}

local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame
local textoProgreso: TextLabel
local fijarBarra: (number) -> ()
local pestanaActual = "normal"
local botonesPestana: { [string]: TextButton } = {}

local function estado(): any
	local e = EstadoCliente.Obtener("indice")
	return if type(e) == "table" then e else { claves = {}, sets = {}, titulos = {}, titulo = "" }
end

local function conjunto(listaClaves: { string }): { [string]: boolean }
	local resultado = {}
	for _, clave in listaClaves do
		resultado[clave] = true
	end
	return resultado
end

local function claveDe(crunchiId: string, pestana: string): string
	return if pestana == "normal" then crunchiId else `{crunchiId}:{pestana}`
end

local function refrescarProgreso(tiene: { [string]: boolean })
	local total = #Catalogo.datos.crunchis
	local cuenta = 0
	for _, crunchi in Catalogo.datos.crunchis do
		if tiene[claveDe(crunchi.id, pestanaActual)] then
			cuenta += 1
		end
	end
	local porcentaje = if total > 0 then cuenta / total * 100 else 0
	local texto = `{cuenta}/{total} ({math.floor(porcentaje)} %)`
	if pestanaActual == "normal" then
		for _, hito in ConfigIndice.HITOS do
			if porcentaje < hito.porcentaje then
				texto ..= `  ·  Próximo: {hito.porcentaje} % → "{hito.titulo}"`
				break
			end
		end
	end
	textoProgreso.Text = texto
	fijarBarra(porcentaje / 100)
end

local function refrescarTitulos()
	local e = estado()
	UI.Texto({
		texto = "Elige un título para mostrar sobre tu cabeza. Se consiguen completando sets e hitos del Índice.",
		tamano = UDim2.new(1, -8, 0, 40),
		tamanoLetra = 15,
		color = Tema.COLORES.textoSuave,
		padre = lista,
	}).LayoutOrder =
		0
	local function fila(titulo: string, orden: number)
		local marco = UI.Panel({
			Size = UDim2.new(1, -8, 0, 50),
			BackgroundColor3 = Tema.COLORES.fondoClaro,
			LayoutOrder = orden,
			Parent = lista,
		})
		local equipado = e.titulo == titulo
		UI.Texto({
			texto = if titulo == "" then "(Sin título)" else `« {titulo} »`,
			tamano = UDim2.new(1, -150, 1, 0),
			posicion = UDim2.fromOffset(10, 0),
			tamanoLetra = 18,
			alineacion = Enum.TextXAlignment.Left,
			color = if titulo == "" then Tema.COLORES.textoSuave else Tema.COLORES.dinero,
			padre = marco,
		})
		UI.Boton({
			texto = if equipado then "✔ Puesto" else "Usar",
			color = if equipado then Tema.COLORES.fondoClaro else Tema.COLORES.verde,
			tamano = UDim2.fromOffset(130, 42),
			posicion = UDim2.new(1, -6, 0.5, 0),
			ancla = Vector2.new(1, 0.5),
			tamanoLetra = 17,
			alPulsar = function()
				Red.Evento("AccionMenu"):FireServer("titulo", titulo)
			end,
			padre = marco,
		})
	end
	fila("", 1)
	for i, titulo in e.titulos do
		fila(titulo, i + 1)
	end
	if #e.titulos == 0 then
		UI.Texto({
			texto = "Todavía no tienes títulos. ¡Completa un set!",
			tamano = UDim2.new(1, -8, 0, 30),
			tamanoLetra = 16,
			padre = lista,
		}).LayoutOrder =
			99
	end
end

local function refrescar()
	local v = ventana
	if v == nil or not v:EstaAbierta() then
		return
	end
	UI.Vaciar(lista)
	for nombre, boton in botonesPestana do
		boton.BackgroundColor3 = if nombre == pestanaActual then Tema.COLORES.morado else Tema.COLORES.fondoClaro
	end
	if pestanaActual == "titulos" then
		textoProgreso.Text = ""
		fijarBarra(0)
		refrescarTitulos()
		return
	end

	local e = estado()
	local tiene = conjunto(e.claves)
	local setsCompletos = conjunto(e.sets)
	refrescarProgreso(tiene)

	local orden = 0
	for _, set in Catalogo.datos.sets do
		local crunchis = table.clone(Catalogo.datos.porSet[set.id])
		table.sort(crunchis, function(a, b)
			return Catalogo.OrdenDe(a.id) < Catalogo.OrdenDe(b.id)
		end)
		local cuenta = 0
		for _, crunchi in crunchis do
			if tiene[claveDe(crunchi.id, pestanaActual)] then
				cuenta += 1
			end
		end
		orden += 1
		local completo = setsCompletos[set.id] == true
		local premio = if pestanaActual == "normal"
			then `  ·  premio: +{math.floor(set.bonus * 100)} % y título "{set.titulo}"`
			else ""
		local encabezado = UI.Texto({
			texto = `{if completo and pestanaActual == "normal" then "✅ " else ""}{set.nombre}  {cuenta}/{#crunchis}{premio}`,
			tamano = UDim2.new(1, -8, 0, 26),
			tamanoLetra = 17,
			alineacion = Enum.TextXAlignment.Left,
			color = if completo then Tema.COLORES.verde else Tema.COLORES.texto,
			padre = lista,
		})
		encabezado.LayoutOrder = orden
		orden += 1
		local rejilla = Tarjetas.Rejilla(lista, orden)
		for i, crunchi in crunchis do
			Tarjetas.Crunchi(crunchi.id, if pestanaActual == "normal" then "normal" else pestanaActual, {
				desconocido = not tiene[claveDe(crunchi.id, pestanaActual)],
				orden = i,
				padre = rejilla,
			})
		end
	end
end

function IndiceController.Abrir()
	if ventana then
		ventana:Abrir()
	end
end

function IndiceController.Iniciar()
	local v = Ventana.nueva("📖 Índice", 580, 350, Tema.COLORES.morado)
	ventana = v
	v.alAbrir = function()
		task.defer(refrescar)
	end

	-- Pestañas
	local barraPestanas = UI.Crear("ScrollingFrame", {
		Name = "Pestanas",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
		Parent = v.contenido,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = barraPestanas,
	})
	local pestanas: { { id: string, texto: string } } = { { id = "normal", texto = "Normal" } }
	for _, mutacionId in ConfigIndice.MUTACIONES_INDICE do
		table.insert(pestanas, { id = mutacionId, texto = Catalogo.Mutacion(mutacionId).nombre })
	end
	table.insert(pestanas, { id = "titulos", texto = "🏷️ Títulos" })
	for i, pestana in pestanas do
		local boton = UI.Boton({
			texto = pestana.texto,
			color = Tema.COLORES.fondoClaro,
			tamano = UDim2.fromOffset(104, 36),
			tamanoLetra = 15,
			alPulsar = function()
				pestanaActual = pestana.id
				refrescar()
			end,
			padre = barraPestanas,
		})
		boton.LayoutOrder = i
		botonesPestana[pestana.id] = boton
	end

	textoProgreso = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, 0, 0, 20),
		posicion = UDim2.fromOffset(0, 44),
		tamanoLetra = 15,
		alineacion = Enum.TextXAlignment.Left,
		padre = v.contenido,
	})
	local _, fijar = UI.Barra(v.contenido, UDim2.new(1, 0, 0, 8), Tema.COLORES.morado, UDim2.fromOffset(0, 66))
	fijarBarra = fijar

	lista = UI.Lista({
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 1, -80),
		Parent = v.contenido,
	}, 6)

	HudController.AgregarBoton("📖", Tema.COLORES.morado, 3, function()
		v:Alternar()
	end)

	EstadoCliente.Cambio:Conectar(function(parte: string)
		if parte == "indice" then
			refrescar()
		end
	end)
end

return IndiceController
