--!strict
--[[
	MascotasController
	Los Bichitos de la Huerta en el cliente:

	  - Ventana 🐾 con dos pestañas:
	      Mis Bichitos: equipar/quitar (toca la tarjeta), "Equipar mejores", liberar y la
	                    colección con siluetas "???" de los que faltan.
	      Huevos:       cada huevo con la probabilidad de CADA bichito visible antes de abrir.
	  - Animación al abrir un huevo.
	  - Los bichitos que siguen a cada jugador. Se dibujan SOLO en este dispositivo, para
	    jugadores cercanos y con tope. Con el Modo ahorro o la opción "Mascotas de otros"
	    apagada, solo se ven los tuyos.

	El servidor decide todo (MascotaService); aquí solo se pide y se muestra.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigMascotas = require(Shared:WaitForChild("Config"):WaitForChild("Mascotas"))
local Catalogo = require(Shared:WaitForChild("Catalogo"))
local Red = require(Shared:WaitForChild("Red"))
local Azar = require(Shared:WaitForChild("Util"):WaitForChild("Azar"))
local Formato = require(Shared:WaitForChild("Util"):WaitForChild("Formato"))
local Reloj = require(Shared:WaitForChild("Util"):WaitForChild("Reloj"))

local Interfaz = script.Parent.Parent:WaitForChild("Interfaz")
local UI = require(Interfaz:WaitForChild("UI"))
local Tema = require(Interfaz:WaitForChild("Tema"))
local Ventana = require(Interfaz:WaitForChild("Ventana"))
local Tarjetas = require(Interfaz:WaitForChild("Tarjetas"))
local EstadoCliente = require(script.Parent:WaitForChild("EstadoCliente"))
local HudController = require(script.Parent:WaitForChild("HudController"))
local SonidoController = require(script.Parent:WaitForChild("SonidoController"))
local EfectosController = require(script.Parent:WaitForChild("EfectosController"))
local NotificacionController = require(script.Parent:WaitForChild("NotificacionController"))

type Mascota = ConfigMascotas.Mascota
type Huevo = ConfigMascotas.Huevo

local MascotasController = {
	-- Lo cambia el menú ⚙️ (opción "Mascotas de otros").
	verOtros = true,
}

local jugador = Players.LocalPlayer
local porId: { [string]: Mascota } = {}
for _, mascota in ConfigMascotas.LISTA do
	porId[mascota.id] = mascota
end

local ventana: Ventana.Ventana? = nil
local lista: ScrollingFrame? = nil
local textoInfo: TextLabel? = nil
local botonesPestana: { [string]: TextButton } = {}
local pestanaActual = "mias"
local modoLiberar = false
local confirmarLiberar: string? = nil -- uid que hay que tocar otra vez para liberarlo
local revelacion: Frame? = nil

local function estado(): any
	local e = EstadoCliente.Obtener("mascotas")
	return if type(e) == "table" then e else nil
end

local function enviar(accion: string, datos: any)
	Red.Evento("AccionMenu"):FireServer(accion, datos)
end

local function ordenRareza(id: string): number
	local mascota = porId[id]
	local rareza = if mascota then Catalogo.datos.rareza[mascota.rareza] else nil
	return if rareza then rareza.orden else 0
end

----------------------------------------------------------------------------- pestaña: mis bichitos

local function seccion(padre: Instance, texto: string, orden: number)
	UI.Texto({
		texto = texto,
		tamano = UDim2.new(1, -8, 0, 22),
		tamanoLetra = 16,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.textoSuave,
		padre = padre,
	}).LayoutOrder =
		orden
end

local function pestanaMias(l: ScrollingFrame, e: any)
	local equipadas: { [string]: boolean } = {}
	for _, uid in e.equipadas do
		equipadas[uid] = true
	end

	-- Acciones
	local fila = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 44),
		LayoutOrder = 1,
		Parent = l,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		Parent = fila,
	})
	UI.Boton({
		texto = "⭐ Equipar mejores",
		color = Tema.COLORES.verde,
		tamano = UDim2.fromOffset(190, 42),
		tamanoLetra = 16,
		alPulsar = function()
			enviar("mascota_mejores", nil)
		end,
		padre = fila,
	})
	UI.Boton({
		texto = if modoLiberar then "✋ Terminar de liberar" else "🌿 Liberar bichitos",
		color = if modoLiberar then Tema.COLORES.rojo else Tema.COLORES.fondoClaro,
		tamano = UDim2.fromOffset(200, 42),
		tamanoLetra = 16,
		alPulsar = function()
			modoLiberar = not modoLiberar
			confirmarLiberar = nil
			MascotasController.Refrescar()
		end,
		padre = fila,
	})

	if #e.lista == 0 then
		seccion(l, "Todavía no tienes Bichitos. ¡Abre un 🥚 huevo!", 2)
	else
		seccion(
			l,
			if modoLiberar
				then "Toca un Bichito para liberarlo (te da algo de dinero)"
				else `Tus Bichitos ({#e.lista}/{ConfigMascotas.INVENTARIO_MAXIMO}) · toca para equipar o quitar`,
			2
		)
		-- Equipadas primero, después por rareza (de mayor a menor).
		local ordenadas = table.clone(e.lista)
		table.sort(ordenadas, function(a, b)
			local ea, eb = equipadas[a.uid] == true, equipadas[b.uid] == true
			if ea ~= eb then
				return ea
			end
			local ra, rb = ordenRareza(a.id), ordenRareza(b.id)
			if ra ~= rb then
				return ra > rb
			end
			return a.uid < b.uid
		end)
		local rejilla = Tarjetas.Rejilla(l, 3)
		for i, guardada in ordenadas do
			local mascota = porId[guardada.id]
			if mascota then
				local uid = guardada.uid
				local equipada = equipadas[uid] == true
				Tarjetas.Mascota(mascota, {
					orden = i,
					pie = if equipada then "✅ Equipada" else nil,
					alPulsar = function()
						if modoLiberar then
							if equipada then
								NotificacionController.Avisar("Primero quítalo de tus equipadas", "info")
								return
							end
							-- Épico o mejor: hay que tocarlo dos veces (no se libera por accidente).
							if ordenRareza(mascota.id) >= 4 and confirmarLiberar ~= uid then
								confirmarLiberar = uid
								NotificacionController.Avisar(
									`¿Seguro? Toca otra vez a {mascota.nombre} para liberarlo`,
									"alerta"
								)
								return
							end
							confirmarLiberar = nil
							enviar("mascota_liberar", uid)
						elseif equipada then
							enviar("mascota_quitar", uid)
						else
							enviar("mascota_equipar", uid)
						end
					end,
					padre = rejilla,
				})
			end
		end
	end

	-- Colección: todos los Bichitos, con silueta los que nunca tuviste.
	local vistas: { [string]: boolean } = {}
	for _, id in e.vistas do
		vistas[id] = true
	end
	local cuantas = 0
	for _ in vistas do
		cuantas += 1
	end
	seccion(l, `📖 Colección: {cuantas}/{#ConfigMascotas.LISTA}`, 4)
	local coleccion = Tarjetas.Rejilla(l, 5)
	for i, mascota in ConfigMascotas.LISTA do
		Tarjetas.Mascota(mascota, { orden = i, desconocido = not vistas[mascota.id], padre = coleccion })
	end
end

----------------------------------------------------------------------------- pestaña: huevos

local function textoProbabilidades(huevo: Huevo): string
	local probabilidades = Azar.Probabilidades(huevo.pesos)
	local ids = {}
	for id in huevo.pesos do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return (probabilidades[a] or 0) > (probabilidades[b] or 0)
	end)
	local partes = {}
	for _, id in ids do
		local mascota = porId[id]
		local p = probabilidades[id] or 0
		if mascota and p > 0 then
			local rareza = Catalogo.datos.rareza[mascota.rareza]
			local c = if rareza and rareza.id ~= "secreto" then rareza.color else Color3.fromRGB(255, 255, 255)
			local hex = string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
			table.insert(partes, `<font color="{hex}">{mascota.icono} {mascota.nombre} {Formato.Porcentaje(p)}</font>`)
		end
	end
	return table.concat(partes, "  ·  ")
end

local function pestanaHuevos(l: ScrollingFrame, e: any)
	local rebirths = jugador:GetAttribute("Rebirths")
	local nivel = if type(rebirths) == "number" then rebirths else 0
	local dinero = jugador:GetAttribute("Dinero")
	local saldo = if type(dinero) == "number" then dinero else 0
	seccion(l, "Se pagan con dinero del juego. Estas son las probabilidades REALES de cada huevo.", 0)
	for i, huevo in ConfigMascotas.HUEVOS do
		local marco = UI.Panel({
			Size = UDim2.new(1, -8, 0, 132),
			BackgroundColor3 = Tema.COLORES.fondoClaro,
			LayoutOrder = i,
			Parent = l,
		})
		UI.Borde(marco, huevo.color, 2.5)
		UI.Texto({
			texto = `{huevo.icono} {huevo.nombre} · {Formato.Dinero(huevo.precio)}`,
			tamano = UDim2.new(1, -20, 0, 24),
			posicion = UDim2.fromOffset(10, 4),
			tamanoLetra = 19,
			alineacion = Enum.TextXAlignment.Left,
			color = huevo.color,
			padre = marco,
		})
		local probabilidades = UI.Texto({
			texto = textoProbabilidades(huevo),
			tamano = UDim2.new(1, -20, 0, 50),
			posicion = UDim2.fromOffset(10, 30),
			tamanoLetra = 13,
			alineacion = Enum.TextXAlignment.Left,
			padre = marco,
		})
		probabilidades.RichText = true

		local botones = UI.Crear("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 1, -46),
			Size = UDim2.new(1, -20, 0, 42),
			Parent = marco,
		})
		UI.Crear("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			Parent = botones,
		})
		if nivel < huevo.requisitoRebirths then
			UI.Texto({
				texto = `🔒 Rebirth {huevo.requisitoRebirths}`,
				tamano = UDim2.fromOffset(180, 42),
				tamanoLetra = 17,
				color = Tema.COLORES.textoSuave,
				padre = botones,
			})
		else
			local id = huevo.id
			UI.Boton({
				texto = "Abrir ×1",
				color = if saldo >= huevo.precio then Tema.COLORES.verde else Tema.COLORES.fondo,
				tamano = UDim2.fromOffset(120, 40),
				tamanoLetra = 16,
				alPulsar = function()
					enviar("huevo_abrir", { id = id, cantidad = 1 })
				end,
				padre = botones,
			})
			if (e.maximoPorVez or 1) >= 3 then
				UI.Boton({
					texto = "Abrir ×3",
					color = if saldo >= huevo.precio * 3 then Tema.COLORES.verde else Tema.COLORES.fondo,
					tamano = UDim2.fromOffset(120, 40),
					tamanoLetra = 16,
					alPulsar = function()
						enviar("huevo_abrir", { id = id, cantidad = 3 })
					end,
					padre = botones,
				})
			end
		end
	end
end

----------------------------------------------------------------------------- ventana

function MascotasController.Refrescar()
	local v = ventana
	local l = lista
	local e = estado()
	if textoInfo and e then
		local equipadas = math.min(#e.equipadas, e.espacios)
		local bonus = math.floor((e.bonus or 0) * 100 + 0.5)
		local maximo = math.floor(ConfigMascotas.BONUS_MAXIMO * 100)
		textoInfo.Text = `Equipadas {equipadas}/{e.espacios} · Bonus de ingreso +{bonus} % (máx. +{maximo} %)`
	end
	for id, boton in botonesPestana do
		boton.BackgroundColor3 = if id == pestanaActual then Tema.COLORES.verde else Tema.COLORES.fondoClaro
	end
	if v == nil or l == nil or not v:EstaAbierta() or e == nil then
		return
	end
	UI.Vaciar(l)
	if pestanaActual == "mias" then
		pestanaMias(l, e)
	else
		pestanaHuevos(l, e)
	end
end

----------------------------------------------------------------------------- revelación de huevos

local function mostrarRevelacion(huevoId: string, resultados: { any })
	local marco = revelacion
	if marco == nil then
		return
	end
	local huevo = nil
	for _, h in ConfigMascotas.HUEVOS do
		if h.id == huevoId then
			huevo = h
		end
	end
	marco.Visible = true
	local premios = marco:FindFirstChild("Premios") :: Frame
	local titulo = marco:FindFirstChild("Titulo") :: TextLabel
	UI.Vaciar(premios)
	titulo.Text = if huevo then `{huevo.icono} Abriendo {huevo.nombre}…` else "Abriendo…"
	titulo.TextColor3 = Tema.COLORES.dinero

	-- Suspenso: el huevo "tiembla" mostrando bichitos al azar.
	local girador = UI.Texto({ texto = "", tamano = UDim2.new(1, 0, 0, 60), tamanoLetra = 48, padre = premios })
	for i = 1, 12 do
		local azar = ConfigMascotas.LISTA[math.random(1, #ConfigMascotas.LISTA)]
		girador.Text = azar.icono
		SonidoController.Reproducir("Clic")
		task.wait(0.05 + i * 0.008)
	end
	girador:Destroy()

	local mejor = 0
	for i, resultado in resultados do
		local mascota = porId[resultado.id]
		if mascota then
			Tarjetas.Mascota(mascota, {
				orden = i,
				pie = if resultado.nuevo then "📖 ¡NUEVO!" else nil,
				padre = premios,
			})
			mejor = math.max(mejor, ordenRareza(mascota.id))
		end
	end
	local primera = if resultados[1] then porId[resultados[1].id] else nil
	local rareza = if primera then Catalogo.datos.rareza[primera.rareza] else nil
	titulo.Text = if #resultados == 1 and primera then `¡{primera.nombre}!` else `¡{#resultados} Bichitos!`
	titulo.TextColor3 = if rareza and rareza.id ~= "secreto" then rareza.color else Tema.COLORES.dinero
	UI.Rebote(premios, 0.3)
	SonidoController.Reproducir(if mejor >= 4 then "RarezaAlta" else "Huevo")
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		EfectosController.Confeti(
			raiz.Position + Vector3.new(0, 3, 0),
			if rareza then rareza.color else nil,
			30 + mejor * 8
		)
	end
end

local function construirRevelacion()
	local pantalla = UI.Pantalla("RevelacionHuevo", 40)
	local marco = UI.Panel({
		Name = "RevelacionHuevo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 240),
		BackgroundTransparency = 0.05,
		Visible = false,
		Active = true,
		Parent = pantalla,
	})
	UI.Escalar(marco, 420, 240)
	UI.Borde(marco, Tema.COLORES.verde, 3)
	local titulo = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, -20, 0, 40),
		posicion = UDim2.fromOffset(10, 8),
		tamanoLetra = 26,
		padre = marco,
	})
	titulo.Name = "Titulo"
	local premios = UI.Crear("Frame", {
		Name = "Premios",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 52),
		Size = UDim2.new(1, -20, 0, 122),
		Parent = marco,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = premios,
	})
	UI.Boton({
		texto = "¡Genial!",
		color = Tema.COLORES.verde,
		tamano = UDim2.fromOffset(160, 48),
		posicion = UDim2.new(0.5, 0, 1, -10),
		ancla = Vector2.new(0.5, 1),
		alPulsar = function()
			marco.Visible = false
		end,
		padre = marco,
	})
	revelacion = marco
end

----------------------------------------------------------------------------- bichitos que te siguen

type Seguidor = { modelo: Model, id: string, fase: number }
local seguidores: { [Player]: { Seguidor } } = {}
local carpeta: Folder
local DISTANCIA = 90
local MAX_SEGUIDORES = 24

local function parte(modelo: Model, tamano: Vector3, color: Color3, cframe: CFrame, forma: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = tamano
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if forma then
		p.Shape = forma
	end
	p.CFrame = cframe
	p.Parent = modelo
	return p
end

-- Modelo placeholder según la forma (o el modelo real si existe).
local function crearModelo(mascota: Mascota): Model
	local modelos = ReplicatedStorage:FindFirstChild("Modelos")
	local carpetaReal = modelos and modelos:FindFirstChild("Mascotas")
	local real = carpetaReal and carpetaReal:FindFirstChild(mascota.id)
	if real and real:IsA("Model") and real.PrimaryPart then
		local copia = real:Clone()
		for _, d in copia:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		return copia
	end

	local modelo = Instance.new("Model")
	modelo.Name = mascota.id
	local bola = Enum.PartType.Ball
	local cuerpo = parte(modelo, Vector3.one * 1.2, mascota.color, CFrame.new(), bola)
	modelo.PrimaryPart = cuerpo
	if mascota.forma == "gusano" then
		parte(modelo, Vector3.one * 1, mascota.color2, CFrame.new(0, -0.1, 0.9), bola)
		parte(modelo, Vector3.one * 0.8, mascota.color, CFrame.new(0, -0.2, 1.6), bola)
	elseif mascota.forma == "volador" then
		for _, lado in { -1, 1 } do
			local ala = parte(
				modelo,
				Vector3.new(1.4, 0.1, 0.8),
				mascota.color2,
				CFrame.new(lado * 0.9, 0.2, 0.1) * CFrame.Angles(0, 0, math.rad(lado * 20))
			)
			ala.Transparency = 0.25
		end
	else -- bicho
		parte(modelo, Vector3.one * 0.8, mascota.color2, CFrame.new(0, 0.1, -0.8), bola)
		for _, lado in { -1, 1 } do
			parte(modelo, Vector3.new(0.08, 0.6, 0.08), mascota.color2, CFrame.new(lado * 0.25, 0.6, -0.9))
		end
	end
	-- Ojitos (en la parte de adelante: -Z)
	for _, lado in { -1, 1 } do
		parte(modelo, Vector3.one * 0.25, Color3.new(1, 1, 1), CFrame.new(lado * 0.25, 0.25, -0.55), bola)
	end
	if mascota.rareza == "mitico" or mascota.rareza == "secreto" then
		cuerpo.Material = Enum.Material.Neon
	end
	return modelo
end

local function quitarSeguidores(otro: Player)
	local lista_ = seguidores[otro]
	if lista_ then
		for _, seguidor in lista_ do
			seguidor.modelo:Destroy()
		end
		seguidores[otro] = nil
	end
end

local function idsDe(otro: Player): { string }
	local texto = otro:GetAttribute("Mascotas")
	local ids = {}
	if type(texto) == "string" and texto ~= "" then
		for _, id in string.split(texto, ",") do
			if porId[id] then
				table.insert(ids, id)
			end
		end
	end
	return ids
end

-- Cada segundo: quién debe tener bichitos dibujados y cuáles.
local function actualizarSeguidores()
	local camara = workspace.CurrentCamera
	local centro = if camara then camara.Focus.Position else Vector3.zero
	local total = 0
	local soloMios = not MascotasController.verOtros or EfectosController.calidad < 1
	for _, otro in Players:GetPlayers() do
		local personaje = otro.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		local esMio = otro == jugador
		local cerca = raiz ~= nil and raiz:IsA("BasePart") and (esMio or (raiz.Position - centro).Magnitude < DISTANCIA)
		local ids: { string } = if cerca and (esMio or not soloMios) then idsDe(otro) else {}
		if #ids == 0 or total + #ids > MAX_SEGUIDORES then
			quitarSeguidores(otro)
			continue
		end
		total += #ids
		local actuales = seguidores[otro]
		local iguales = actuales ~= nil and #actuales == #ids
		if iguales and actuales then
			for i, seguidor in actuales do
				if seguidor.id ~= ids[i] then
					iguales = false
				end
			end
		end
		if not iguales then
			quitarSeguidores(otro)
			local nuevos: { Seguidor } = {}
			for _, id in ids do
				local modelo = crearModelo(porId[id])
				modelo.Parent = carpeta
				table.insert(nuevos, { modelo = modelo, id = id, fase = math.random() * math.pi * 2 })
			end
			seguidores[otro] = nuevos
		end
	end
end

-- Cada frame: los bichitos flotan detrás de su dueño, en abanico.
local function moverSeguidores(dt: number)
	local t = os.clock()
	for otro, lista_ in seguidores do
		local personaje = otro.Character
		local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
		if raiz == nil or not raiz:IsA("BasePart") then
			continue
		end
		local n = #lista_
		for i, seguidor in lista_ do
			local mascota = porId[seguidor.id]
			local lado = (i - (n + 1) / 2) * 2.6
			local altura = if mascota and mascota.forma == "volador" then 1.6 else -1.8
			local rebote = math.sin(t * 3 + seguidor.fase) * 0.3
			local objetivo = raiz.CFrame * CFrame.new(lado, altura + rebote, 4 + math.abs(lado) * 0.3)
			local actual = seguidor.modelo:GetPivot()
			local alfa = math.clamp(dt * 8, 0, 1)
			local posicion = actual.Position:Lerp(objetivo.Position, alfa)
			-- Mira hacia donde mira su dueño.
			local destino = posicion + raiz.CFrame.LookVector
			if (actual.Position - objetivo.Position).Magnitude > 40 then
				posicion = objetivo.Position -- se quedó muy atrás (teletransporte): aparece junto a él
			end
			seguidor.modelo:PivotTo(CFrame.lookAt(posicion, destino))
		end
	end
end

----------------------------------------------------------------------------- inicio

function MascotasController.Iniciar()
	local v = Ventana.nueva("🐾 Bichitos", 610, 360, Tema.COLORES.verde)
	ventana = v
	v.alAbrir = function()
		task.defer(MascotasController.Refrescar)
	end
	local barra = UI.Crear("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = v.contenido,
	})
	UI.Crear("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = barra,
	})
	for _, pestana in { { id = "mias", texto = "🐾 Mis Bichitos" }, { id = "huevos", texto = "🥚 Huevos" } } do
		botonesPestana[pestana.id] = UI.Boton({
			texto = pestana.texto,
			color = Tema.COLORES.fondoClaro,
			tamano = UDim2.fromOffset(160, 38),
			tamanoLetra = 16,
			alPulsar = function()
				pestanaActual = pestana.id
				modoLiberar = false
				MascotasController.Refrescar()
			end,
			padre = barra,
		})
	end
	textoInfo = UI.Texto({
		texto = "",
		tamano = UDim2.new(1, 0, 0, 18),
		posicion = UDim2.fromOffset(0, 42),
		tamanoLetra = 14,
		alineacion = Enum.TextXAlignment.Left,
		color = Tema.COLORES.dinero,
		padre = v.contenido,
	})
	lista = UI.Lista({
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64),
		Parent = v.contenido,
	}, 6)
	construirRevelacion()

	HudController.AgregarBoton("🐾", Tema.COLORES.verde, 2, function()
		v:Alternar()
	end)

	EstadoCliente.Cambio:Conectar(function(parte_: string)
		if parte_ == "mascotas" then
			MascotasController.Refrescar()
		end
	end)
	jugador:GetAttributeChangedSignal("Dinero"):Connect(function()
		if pestanaActual == "huevos" then
			-- Los botones cambian de color si ya te alcanza (sin rehacer todo a cada rato).
			local actual = v:EstaAbierta()
			if actual then
				task.defer(MascotasController.Refrescar)
			end
		end
	end)
	Red.Evento("Efecto").OnClientEvent:Connect(function(nombre: any, datos: any)
		if nombre == "Huevo" and type(datos) == "table" and type(datos.resultados) == "table" then
			task.spawn(mostrarRevelacion, tostring(datos.huevo), datos.resultados)
		end
	end)

	carpeta = Instance.new("Folder")
	carpeta.Name = "MascotasLocales"
	carpeta.Parent = workspace
	Reloj.Cada(1, actualizarSeguidores)
	RunService.RenderStepped:Connect(moverSeguidores)
	Players.PlayerRemoving:Connect(quitarSeguidores)
end

return MascotasController
