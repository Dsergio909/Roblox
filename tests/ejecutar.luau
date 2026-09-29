--[[
	Pruebas unitarias de la lógica pura y de la configuración.
	Se ejecutan fuera de Roblox Studio con el intérprete `luau` (ver tests/README.md).

	Solo prueban módulos que no dependen de Roblox (Util/, Logica/ y Config/).
]]

local Formato = require("../src/shared/Util/Formato")
local Azar = require("../src/shared/Util/Azar")
local Limitador = require("../src/shared/Util/Limitador")
local Ingreso = require("../src/shared/Logica/Ingreso")
local CatalogoPuro = require("../src/shared/Logica/CatalogoPuro")

local Rarezas = require("../src/shared/Config/Rarezas")
local Mutaciones = require("../src/shared/Config/Mutaciones")
local Sets = require("../src/shared/Config/Sets")
local Crunchis = require("../src/shared/Config/Crunchis")
local Cintas = require("../src/shared/Config/Cintas")
local Progresion = require("../src/shared/Logica/Progresion")
local ConfigRebirths = require("../src/shared/Config/Rebirths")
local ConfigCanastas = require("../src/shared/Config/Canastas")
local ConfigSemillas = require("../src/shared/Config/Semillas")
local ConfigMisiones = require("../src/shared/Config/Misiones")
local ConfigLogin = require("../src/shared/Config/Login")
local ConfigIndice = require("../src/shared/Config/Indice")
local ConfigProductos = require("../src/shared/Config/Productos")
local ConfigCosmeticos = require("../src/shared/Config/Cosmeticos")
local ConfigPase = require("../src/shared/Config/Pase")
local ConfigEventos = require("../src/shared/Config/Eventos")
local ConfigAlmacen = require("../src/shared/Config/Almacen")
local ConfigClasificacion = require("../src/shared/Config/Clasificacion")
local Laseres = require("../src/shared/Logica/Laseres")

----------------------------------------------------------------------------- mini framework
local pasadas, fallidas = 0, 0
local grupoActual = ""

local function grupo(nombre: string)
	grupoActual = nombre
end

local function prueba(nombre: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		pasadas += 1
	else
		fallidas += 1
		print(`❌ [{grupoActual}] {nombre}\n    {err}`)
	end
end

local function igual(obtenido: any, esperado: any, mensaje: string?)
	if obtenido ~= esperado then
		error(`{mensaje or ""} esperado {tostring(esperado)}, obtenido {tostring(obtenido)}`, 2)
	end
end

local function verdadero(condicion: boolean, mensaje: string)
	if not condicion then
		error(mensaje, 2)
	end
end

local function cerca(a: number, b: number, tolerancia: number, mensaje: string?)
	if math.abs(a - b) > tolerancia then
		error(`{mensaje or ""} esperado ~{b}, obtenido {a}`, 2)
	end
end

-- Generador pseudoaleatorio determinista (para pruebas reproducibles).
local function generador(semilla: number): () -> number
	local estado = semilla
	return function()
		estado = (estado * 1103515245 + 12345) % 2147483648
		return estado / 2147483648
	end
end

----------------------------------------------------------------------------- Formato
grupo("Formato")
prueba("Corto con números pequeños", function()
	igual(Formato.Corto(0), "0")
	igual(Formato.Corto(7.9), "7")
	igual(Formato.Corto(999), "999")
end)
prueba("Corto con sufijos", function()
	igual(Formato.Corto(1000), "1K")
	igual(Formato.Corto(1234), "1.23K")
	igual(Formato.Corto(1500), "1.5K")
	igual(Formato.Corto(12345), "12.3K")
	igual(Formato.Corto(123456), "123K")
	igual(Formato.Corto(999999), "999K")
	igual(Formato.Corto(1000000), "1M")
	igual(Formato.Corto(2.5e9), "2.5B")
	igual(Formato.Corto(1e12), "1T")
end)
prueba("Corto nunca redondea hacia arriba", function()
	igual(Formato.Corto(1999), "1.99K")
	igual(Formato.Corto(9999999), "9.99M")
end)
prueba("Corto con negativos, NaN e infinito", function()
	igual(Formato.Corto(-1500), "-1.5K")
	igual(Formato.Corto(0 / 0), "0")
	igual(Formato.Corto(math.huge), "∞")
end)
prueba("Dinero", function()
	igual(Formato.Dinero(20), "$20")
	igual(Formato.Dinero(450000), "$450K")
	igual(Formato.Dinero(-5), "-$5")
end)
prueba("Completo", function()
	igual(Formato.Completo(0), "0")
	igual(Formato.Completo(999), "999")
	igual(Formato.Completo(1000), "1,000")
	igual(Formato.Completo(1234567), "1,234,567")
	igual(Formato.Completo(-1234), "-1,234")
end)
prueba("Tiempo", function()
	igual(Formato.Tiempo(0), "0:00")
	igual(Formato.Tiempo(5), "0:05")
	igual(Formato.Tiempo(125), "2:05")
	igual(Formato.Tiempo(3661), "1:01:01")
	igual(Formato.Tiempo(-3), "0:00")
end)
prueba("Duración", function()
	igual(Formato.Duracion(45), "45s")
	igual(Formato.Duracion(725), "12m 5s")
	igual(Formato.Duracion(3 * 3600 + 120), "3h 2m")
	igual(Formato.Duracion(90000), "1d 1h")
	igual(Formato.Duracion(-10), "0s")
end)
prueba("Porcentaje", function()
	igual(Formato.Porcentaje(0.55), "55 %")
	igual(Formato.Porcentaje(0.115), "11.5 %")
	igual(Formato.Porcentaje(0.012), "1.2 %")
	igual(Formato.Porcentaje(0.0025), "0.25 %")
	igual(Formato.Porcentaje(0.0005), "0.05 %")
end)

----------------------------------------------------------------------------- Azar
grupo("Azar")
prueba("Ponderado respeta los pesos", function()
	local aleatorio = generador(42)
	local pesos = { a = 70, b = 20, c = 10 }
	local conteo = { a = 0, b = 0, c = 0 }
	local n = 20000
	for _ = 1, n do
		local clave = Azar.Ponderado(pesos, aleatorio) :: string
		conteo[clave] += 1
	end
	cerca(conteo.a / n, 0.7, 0.02, "a")
	cerca(conteo.b / n, 0.2, 0.02, "b")
	cerca(conteo.c / n, 0.1, 0.02, "c")
end)
prueba("Ponderado ignora pesos 0 y negativos", function()
	local aleatorio = generador(7)
	for _ = 1, 500 do
		igual(Azar.Ponderado({ a = 0, b = 5, c = -3 }, aleatorio), "b")
	end
	igual(Azar.Ponderado({ a = 0 }, aleatorio), nil)
end)
prueba("Ponderado en el borde superior", function()
	igual(
		Azar.Ponderado({ a = 1, b = 1 }, function()
			return 0.9999999999
		end),
		"b"
	)
	igual(
		Azar.Ponderado({ a = 1, b = 1 }, function()
			return 0
		end),
		"a"
	)
end)
prueba("Probabilidades suman 1", function()
	local p = Azar.Probabilidades({ x = 55, y = 28, z = 17 })
	cerca(p.x + p.y + p.z, 1, 1e-9)
	cerca(p.x, 0.55, 1e-9)
end)
prueba("Multiplicar", function()
	local p = Azar.Multiplicar({ a = 10, b = 1 }, { b = 2 })
	igual(p.a, 10)
	igual(p.b, 2)
end)
prueba("Elegir", function()
	igual(Azar.Elegir({}, math.random), nil)
	igual(Azar.Elegir({ "unico" }, math.random), "unico")
	igual(
		Azar.Elegir({ 1, 2, 3 }, function()
			return 0.99999
		end),
		3
	)
end)

----------------------------------------------------------------------------- Limitador
grupo("Limitador")
prueba("Permite ráfaga y luego bloquea", function()
	local l = Limitador.nuevo(2, 3)
	igual(l:Permitir("j", 0), true)
	igual(l:Permitir("j", 0), true)
	igual(l:Permitir("j", 0), true)
	igual(l:Permitir("j", 0), false)
end)
prueba("Recarga con el tiempo", function()
	local l = Limitador.nuevo(2, 2)
	l:Permitir("j", 0)
	l:Permitir("j", 0)
	igual(l:Permitir("j", 0.1), false)
	igual(l:Permitir("j", 0.6), true)
end)
prueba("Claves independientes y Olvidar", function()
	local l = Limitador.nuevo(1, 1)
	igual(l:Permitir("a", 0), true)
	igual(l:Permitir("b", 0), true)
	igual(l:Permitir("a", 0), false)
	l:Olvidar("a")
	igual(l:Permitir("a", 0), true)
end)

----------------------------------------------------------------------------- Ingreso
grupo("Ingreso")
prueba("Multiplicador: aditivos se suman, multiplicadores se multiplican", function()
	cerca(Ingreso.MultiplicadorTotal({}, {}), 1, 1e-9)
	cerca(Ingreso.MultiplicadorTotal({ 0.5, 0.1 }, {}), 1.6, 1e-9)
	cerca(Ingreso.MultiplicadorTotal({ 0.5 }, { 2, 2 }), 6, 1e-9)
end)
prueba("PorSegundo y precios", function()
	igual(Ingreso.PorSegundo(10, 2, 1.5), 30)
	igual(Ingreso.Precio(450000, 3), 1350000)
	igual(Ingreso.PrecioVenta(20, 1, 0.5), 10)
	igual(Ingreso.PrecioVenta(75, 1, 0.5), 37)
end)
prueba("BonusAmigos con tope", function()
	cerca(Ingreso.BonusAmigos(0, 0.1, 0.3), 0, 1e-9)
	cerca(Ingreso.BonusAmigos(2, 0.1, 0.3), 0.2, 1e-9)
	cerca(Ingreso.BonusAmigos(7, 0.1, 0.3), 0.3, 1e-9)
end)
prueba("Acumulado", function()
	igual(Ingreso.Acumulado(5, 2, 10, 15), 15)
	igual(Ingreso.Acumulado(5, 2, 10, 8), 5) -- tiempo negativo no resta
end)

----------------------------------------------------------------------------- Catálogo y balance
grupo("Catálogo")
local catalogo, errores = CatalogoPuro.Construir(Rarezas, Mutaciones, Sets, Crunchis, Cintas)

prueba("La configuración no tiene errores", function()
	if #errores > 0 then
		error(table.concat(errores, "\n    "))
	end
end)
prueba("21 Crunchis, 3 por rareza", function()
	igual(#catalogo.crunchis, 21)
	for _, rareza in catalogo.rarezas do
		igual(#catalogo.porRareza[rareza.id], 3, rareza.id)
	end
end)
prueba("Rarezas ordenadas", function()
	igual(catalogo.rarezas[1].id, "comun")
	igual(catalogo.rarezas[#catalogo.rarezas].id, "secreto")
end)
prueba("Valor con mutación", function()
	local ingreso, precio = CatalogoPuro.Valor(catalogo, "crunchito_bobo", "dorado")
	igual(ingreso, 2)
	igual(precio, 40)
	igual(CatalogoPuro.OrdenDe(catalogo, "crunch_omega"), 7)
	igual(CatalogoPuro.OrdenDe(catalogo, "no_existe"), 0)
end)
prueba("Detecta errores de configuración", function()
	local malos = table.clone(Crunchis)
	table.insert(malos, {
		id = "Mal ID",
		nombre = "x",
		rareza = "ultra",
		ingreso = 0,
		precio = 1,
		set = "nada",
		descripcion = "",
	})
	table.insert(malos, Crunchis[1]) -- id repetido
	local _, errs = CatalogoPuro.Construir(Rarezas, Mutaciones, Sets, malos, Cintas)
	verdadero(#errs >= 5, `se esperaban >= 5 errores, hubo {#errs}`)
end)

grupo("Balance")
prueba("Cada rareza tarda más en pagarse que la anterior", function()
	local anterior = 0
	for _, rareza in catalogo.rarezas do
		local lista = catalogo.porRareza[rareza.id]
		local suma = 0
		for _, c in lista do
			suma += c.precio / c.ingreso
		end
		local promedio = suma / #lista
		verdadero(promedio > anterior, `{rareza.id}: recuperación {promedio}s no es mayor que {anterior}s`)
		anterior = promedio
	end
end)
prueba("Cada rareza produce más que la anterior", function()
	for i = 2, #catalogo.rarezas do
		local menor = catalogo.porRareza[catalogo.rarezas[i].id][1]
		local mayorAnterior = catalogo.porRareza[catalogo.rarezas[i - 1].id][3]
		verdadero(
			menor.ingreso > mayorAnterior.ingreso,
			`{menor.id} ({menor.ingreso}/s) debería producir más que {mayorAnterior.id} ({mayorAnterior.ingreso}/s)`
		)
	end
end)
prueba("Probabilidades de la cinta principal como en el diseño", function()
	local p = Azar.Probabilidades(catalogo.cinta.principal.pesos)
	cerca(p.comun, 0.55, 1e-6)
	cerca(p.legendario, 0.012, 1e-6)
	cerca(p.secreto, 0.0005, 1e-6)
end)
prueba("Mutaciones: Dorado 4 %, Diamante 1 %, Arcoíris 0.2 %", function()
	local p = Azar.Probabilidades(catalogo.pesosMutacion)
	cerca(p.dorado, 0.04, 1e-6)
	cerca(p.diamante, 0.01, 1e-6)
	cerca(p.arcoiris, 0.002, 1e-6)
	igual(p.radiactivo, nil) -- solo en eventos
end)
prueba("Simulación: en 10.000 apariciones las rarezas salen en proporción", function()
	local aleatorio = generador(123)
	local conteo: { [string]: number } = {}
	local n = 10000
	for _ = 1, n do
		local r = Azar.Ponderado(catalogo.cinta.principal.pesos, aleatorio) :: string
		conteo[r] = (conteo[r] or 0) + 1
	end
	cerca((conteo.comun or 0) / n, 0.55, 0.02)
	cerca((conteo.raro or 0) / n, 0.115, 0.015)
end)

----------------------------------------------------------------------------- Progresión
grupo("Progresión")
local ordenRareza: { [string]: number } = {}
for _, r in catalogo.rarezas do
	ordenRareza[r.id] = r.orden
end

prueba("Niveles de rebirth: tabla y fórmula", function()
	igual(Progresion.NivelRebirth(1, ConfigRebirths).costo, 1e6)
	local ultimo = ConfigRebirths.NIVELES[#ConfigRebirths.NIVELES]
	local siguiente = Progresion.NivelRebirth(#ConfigRebirths.NIVELES + 1, ConfigRebirths)
	igual(siguiente.costo, ultimo.costo * ConfigRebirths.FACTOR_COSTO)
	igual(siguiente.requisitos[1].rareza, ConfigRebirths.REQUISITO_DESPUES.rareza)
end)
prueba("Rebirths cada vez más caros", function()
	local anterior = 0
	for n = 1, 12 do
		local costo = Progresion.NivelRebirth(n, ConfigRebirths).costo
		verdadero(costo > anterior, `rebirth {n} no es más caro que el anterior`)
		anterior = costo
	end
end)
prueba("Requisitos: una rareza mayor cuenta para una menor", function()
	local ok = Progresion.CumpleRequisitos({ 6 }, { { rareza = "legendario", cantidad = 1 } }, ordenRareza)
	igual(ok, true)
	local ok2 = Progresion.CumpleRequisitos({ 4, 4 }, { { rareza = "legendario", cantidad = 1 } }, ordenRareza)
	igual(ok2, false)
end)
prueba("Requisitos: cada Crunchi cuenta una sola vez", function()
	local req = { { rareza = "legendario", cantidad = 1 }, { rareza = "mitico", cantidad = 1 } }
	igual((Progresion.CumpleRequisitos({ 6 }, req, ordenRareza)), false)
	igual((Progresion.CumpleRequisitos({ 6, 5 }, req, ordenRareza)), true)
	local _, detalle = Progresion.CumpleRequisitos({ 5 }, { { rareza = "legendario", cantidad = 2 } }, ordenRareza)
	igual(detalle[1].tiene, 1)
	igual(detalle[1].cumple, false)
end)
prueba("Día y semana (semanas desde el lunes)", function()
	igual(Progresion.Dia(0), 0)
	igual(Progresion.Dia(86399), 0)
	igual(Progresion.Dia(86400), 1)
	-- 1970-01-05 fue lunes (día 4) y 1970-01-04 domingo (día 3)
	igual(Progresion.Semana(3), 0)
	igual(Progresion.Semana(4), 1)
	igual(Progresion.Semana(10), 1)
	igual(Progresion.Semana(11), 2)
end)
prueba("Racha suave", function()
	igual(Progresion.ActualizarRacha(0, 0, 100, 5), 1) -- primera vez
	igual(Progresion.ActualizarRacha(3, 100, 100, 5), 3) -- mismo día
	igual(Progresion.ActualizarRacha(3, 99, 100, 5), 4) -- día seguido
	igual(Progresion.ActualizarRacha(5, 99, 100, 5), 5) -- tope
	igual(Progresion.ActualizarRacha(4, 97, 100, 5), 3) -- faltó 2 días: -2 +1
	igual(Progresion.ActualizarRacha(1, 90, 100, 5), 1) -- nunca baja de 0 antes de sumar hoy
end)
prueba("Dinero por minutos y offline", function()
	igual(Progresion.DineroPorMinutos(10, 5, 100), 3000)
	igual(Progresion.DineroPorMinutos(0.1, 5, 100), 100)
	igual(Progresion.GananciaOffline(100, 3600, 0.2, 3), 72000)
	igual(Progresion.GananciaOffline(100, 36000, 0.2, 3), 216000) -- tope de 3 h
	igual(Progresion.GananciaOffline(100, -5, 0.2, 3), 0)
end)
prueba("Porcentaje del Índice", function()
	igual(Progresion.PorcentajeIndice({ a = 1, b = 1 }, { "a", "b", "c", "d" }), 50)
	igual(Progresion.PorcentajeIndice({}, {}), 0)
end)
prueba("Elegir misiones sin repetir", function()
	local aleatorio = generador(9)
	local pool = { "a", "b", "c", "d", "e" }
	for _ = 1, 50 do
		local elegidas = Progresion.ElegirMisiones(pool, 3, aleatorio, { "a" })
		igual(#elegidas, 3)
		verdadero(table.find(elegidas, "a") == nil, "no debe elegir excluidas")
		verdadero(elegidas[1] ~= elegidas[2] and elegidas[2] ~= elegidas[3] and elegidas[1] ~= elegidas[3], "repetidas")
	end
	igual(#Progresion.ElegirMisiones({ "x" }, 3, aleatorio, nil), 1)
end)

grupo("Config Fase 2")
local canastaPorId: { [string]: any } = {}
for _, c in ConfigCanastas do
	canastaPorId[c.id] = c
end
local semillaPorId: { [string]: any } = {}
for _, s in ConfigSemillas do
	semillaPorId[s.id] = s
end
prueba("Canastas y semillas usan rarezas existentes con Crunchis", function()
	local function revisar(nombre: string, pesos: { [string]: number })
		for rareza, peso in pesos do
			verdadero(ordenRareza[rareza] ~= nil, `{nombre}: rareza desconocida {rareza}`)
			if peso > 0 then
				verdadero(#catalogo.porRareza[rareza] > 0, `{nombre}: no hay Crunchis {rareza}`)
			end
		end
	end
	for _, c in ConfigCanastas do
		revisar(c.id, c.pesos)
	end
	for _, s in ConfigSemillas do
		revisar(s.id, s.pesos)
	end
end)
prueba("Canastas: valor esperado menor que el precio", function()
	for _, c in ConfigCanastas do
		if c.precio > 0 then
			local p = Azar.Probabilidades(c.pesos)
			local esperado = 0
			for rareza, prob in p do
				local lista = catalogo.porRareza[rareza]
				local suma = 0
				for _, cr in lista do
					suma += cr.precio
				end
				esperado += prob * suma / #lista
			end
			verdadero(esperado < c.precio, `{c.id}: valor esperado {esperado} >= precio {c.precio}`)
		end
	end
end)
prueba("Misiones: ids únicos y tipos conocidos", function()
	local tipos = {
		comprar = true,
		cobrar = true,
		robar_o_defender = true,
		abrir_canasta = true,
		conseguir_rareza = true,
		jugar_minutos = true,
		cerrar_base = true,
		cosechar = true,
		completar_diarias = true,
	}
	local vistos = {}
	for _, lista in { ConfigMisiones.DIARIAS, ConfigMisiones.SEMANALES } do
		for _, m in lista do
			verdadero(vistos[m.id] == nil, `id repetido {m.id}`)
			vistos[m.id] = true
			verdadero(tipos[m.tipo] == true, `tipo desconocido {m.tipo}`)
			if m.tipo == "conseguir_rareza" then
				verdadero(ordenRareza[m.parametro or ""] ~= nil, `{m.id}: parámetro de rareza inválido`)
			end
		end
	end
	verdadero(#ConfigMisiones.DIARIAS >= ConfigMisiones.DIARIAS_POR_DIA, "pocas diarias")
	verdadero(#ConfigMisiones.SEMANALES >= ConfigMisiones.SEMANALES_POR_SEMANA, "pocas semanales")
	verdadero(canastaPorId[ConfigMisiones.BONUS_DIARIO.canasta] ~= nil, "bonus diario: canasta desconocida")
end)
prueba("Login: recompensas válidas", function()
	igual(#ConfigLogin.CALENDARIO, 7)
	for i, r in ConfigLogin.CALENDARIO do
		if r.tipo == "canasta" then
			verdadero(canastaPorId[r.id or ""] ~= nil, `día {i}: canasta desconocida`)
		elseif r.tipo == "semilla" then
			verdadero(semillaPorId[r.id or ""] ~= nil, `día {i}: semilla desconocida`)
		else
			igual(r.tipo, "dinero", `día {i}`)
		end
	end
end)
prueba("Hitos del Índice ordenados y con canastas válidas", function()
	local anterior = 0
	for _, h in ConfigIndice.HITOS do
		verdadero(h.porcentaje > anterior, "hitos desordenados")
		anterior = h.porcentaje
		if h.canasta then
			verdadero(canastaPorId[h.canasta] ~= nil, `hito {h.porcentaje}: canasta desconocida`)
		end
	end
end)

grupo("Config Fase 3")
local cosmeticoPorId: { [string]: any } = {}
for _, c in ConfigCosmeticos do
	cosmeticoPorId[c.id] = c
end
prueba("Cosméticos: ids únicos y fuentes válidas", function()
	local vistos = {}
	for _, c in ConfigCosmeticos do
		verdadero(vistos[c.id] == nil, `id repetido {c.id}`)
		vistos[c.id] = true
		verdadero(c.tipo == "aura" or c.tipo == "estela", `{c.id}: tipo inválido`)
		if c.fuente == "dinero" then
			verdadero((c.precioDinero or 0) > 0, `{c.id}: falta precioDinero`)
		elseif string.sub(c.fuente, 1, 5) == "pase:" then
			local pase = string.sub(c.fuente, 6)
			verdadero(ConfigProductos.PASES[pase] ~= nil, `{c.id}: Game Pass desconocido {pase}`)
		else
			igual(c.fuente, "premio", c.id)
		end
	end
	for _, h in ConfigIndice.HITOS do
		if h.cosmetico then
			verdadero(cosmeticoPorId[h.cosmetico] ~= nil, `hito {h.porcentaje}: cosmético desconocido`)
		end
	end
end)
prueba("Productos: tipos y referencias válidas", function()
	local tipos = {
		dinero = true,
		boost = true,
		suerte = true,
		offline_x2 = true,
		canasta = true,
		pase_nivel = true,
		pase_premium = true,
		pack_inicial = true,
	}
	for clave, p in ConfigProductos.PRODUCTOS do
		verdadero(tipos[p.tipo] == true, `{clave}: tipo desconocido {p.tipo}`)
		if p.tipo == "canasta" then
			verdadero(canastaPorId[p.canasta or ""] ~= nil, `{clave}: canasta desconocida`)
		end
		if p.tipo == "dinero" or p.tipo == "boost" or p.tipo == "suerte" then
			verdadero((p.minutos or 0) > 0, `{clave}: faltan minutos`)
		end
	end
	verdadero(catalogo.crunchi[ConfigProductos.PACK_INICIAL.CRUNCHI] ~= nil, "Pack Inicial: Crunchi desconocido")
end)
prueba("Paquetes de dinero: más grande = mejor valor por Robux (anclaje)", function()
	local paquetes = {}
	for _, p in ConfigProductos.PRODUCTOS do
		if p.tipo == "dinero" then
			table.insert(paquetes, p)
		end
	end
	table.sort(paquetes, function(a, b)
		return a.precio < b.precio
	end)
	verdadero(#paquetes >= 3, "se esperan al menos 3 paquetes de dinero")
	local anterior = 0
	for _, p in paquetes do
		local valor = (p.minutos :: number) / p.precio
		verdadero(valor > anterior, `{p.nombre}: da menos minutos por Robux que el anterior`)
		anterior = valor
	end
end)
prueba("Pase: 30 niveles con premios válidos", function()
	igual(#ConfigPase.NIVELES, 30)
	verdadero(ConfigPase.TEMPORADA.fin > ConfigPase.TEMPORADA.inicio, "fechas de temporada invertidas")
	local function revisar(n: number, premio: any)
		if premio.tipo == "canasta" then
			verdadero(canastaPorId[premio.id] ~= nil, `nivel {n}: canasta desconocida`)
		elseif premio.tipo == "semilla" then
			verdadero(semillaPorId[premio.id] ~= nil, `nivel {n}: semilla desconocida`)
		elseif premio.tipo == "cosmetico" then
			verdadero(cosmeticoPorId[premio.id] ~= nil, `nivel {n}: cosmético desconocido`)
		elseif premio.tipo == "dinero" then
			verdadero((premio.minutos or 0) > 0, `nivel {n}: dinero sin minutos`)
		else
			igual(premio.tipo, "titulo", `nivel {n}`)
		end
	end
	for n, nivel in ConfigPase.NIVELES do
		revisar(n, nivel.gratis)
		revisar(n, nivel.premium)
	end
end)
prueba("Canasta Sorpresa (Robux): solo rarezas altas y probabilidades que suman 100 %", function()
	local sorpresa = canastaPorId["sorpresa"]
	verdadero(sorpresa ~= nil and sorpresa.soloTicket, "debe existir y ser solo por ticket")
	local p = Azar.Probabilidades(sorpresa.pesos)
	local suma = 0
	for rareza, prob in p do
		verdadero(ordenRareza[rareza] >= 4, `rareza {rareza} por debajo de Épico`)
		suma += prob
	end
	cerca(suma, 1, 1e-9)
end)

----------------------------------------------------------------------------- Fase 4
grupo("Config Fase 4")
prueba("Eventos: ids únicos, duraciones y mutaciones/rarezas que existen", function()
	local vistos = {}
	local todos = table.clone(ConfigEventos.ROTACION)
	for _, e in ConfigEventos.TEMPORADA do
		table.insert(todos, e)
		verdadero(e.inicio ~= nil and e.fin ~= nil and e.fin > e.inicio, `{e.id}: temporada sin fechas reales`)
	end
	verdadero(#ConfigEventos.ROTACION >= 1, "la rotación está vacía")
	for _, e in todos do
		verdadero(not vistos[e.id], `evento repetido: {e.id}`)
		vistos[e.id] = true
		verdadero(e.duracion > 0 and e.duracion <= 15, `{e.id}: duración fuera de rango`)
		verdadero(e.tipo == "lluvia" or e.tipo == "redada" or e.tipo == "hora", `{e.id}: tipo desconocido "{e.tipo}"`)
		for mutacion, factor in e.mutaciones or {} do
			verdadero(catalogo.mutacion[mutacion] ~= nil, `{e.id}: mutación desconocida {mutacion}`)
			verdadero(factor > 0, `{e.id}: factor de mutación inválido`)
		end
		for rareza, factor in e.rarezas or {} do
			verdadero(ordenRareza[rareza] ~= nil, `{e.id}: rareza desconocida {rareza}`)
			verdadero(factor > 0, `{e.id}: factor de rareza inválido`)
		end
		verdadero((e.multIngreso or 1) >= 1 and (e.multIngreso or 1) <= 3, `{e.id}: multIngreso fuera de rango`)
	end
	verdadero(ConfigEventos.INTERVALO_MINUTOS >= 3, "eventos demasiado seguidos")
	local r = ConfigEventos.REDADA
	verdadero(r.AGENTES >= 1 and r.AGENTES <= 8, "Redada: cantidad de agentes (rendimiento)")
	verdadero(r.SEGUNDOS_ETIQUETA <= 60, "Redada: una etiqueta no debería castigar más de 1 minuto")
	verdadero(r.MAX_RECOMPENSAS >= 1, "Redada: sin recompensas")
end)
prueba("Almacén: probabilidades válidas y solo rarezas con Crunchis", function()
	local p = Azar.Probabilidades(ConfigAlmacen.PESOS)
	local suma = 0
	for rareza, prob in p do
		verdadero(ordenRareza[rareza] ~= nil, `rareza desconocida {rareza}`)
		verdadero(#(catalogo.porRareza[rareza] or {}) > 0, `rareza {rareza} sin Crunchis`)
		suma += prob
	end
	cerca(suma, 1, 1e-9)
	verdadero(ConfigAlmacen.TIEMPO_MINIMO < ConfigAlmacen.TIEMPO_MAXIMO, "tiempos invertidos")
	verdadero(ConfigAlmacen.REINTENTO_SEGUNDOS <= 60, "fallar no debería castigar con mucha espera")
end)
prueba("Almacén: láseres dentro del pasillo y siempre con hueco para pasar", function()
	local anterior = 0
	for i, laser in ConfigAlmacen.LASERES do
		verdadero(laser.z > anterior + 2, `láser {i}: muy pegado al anterior (o desordenado)`)
		verdadero(laser.z < ConfigAlmacen.LARGO_PASILLO, `láser {i}: fuera del pasillo`)
		verdadero(laser.velocidad > 0 and laser.velocidad <= 1.2, `láser {i}: velocidad imposible`)
		verdadero(
			Laseres.DejaHueco(laser, ConfigAlmacen.ANCHO_PASILLO, ConfigAlmacen.ANCHO_LASER),
			`láser {i}: tapa todo el pasillo`
		)
		verdadero(
			laser.amplitud + ConfigAlmacen.ANCHO_LASER / 2 <= ConfigAlmacen.ANCHO_PASILLO / 2 + 0.01,
			`láser {i}: se sale por las paredes`
		)
		anterior = laser.z
	end
end)
prueba("Clasificación: tablas conocidas", function()
	for _, tabla in ConfigClasificacion.TABLAS do
		verdadero(
			tabla.id == "rebirths" or tabla.id == "robos" or tabla.id == "indice",
			`tabla sin puntaje: {tabla.id}`
		)
	end
	verdadero(ConfigClasificacion.SUBIR_CADA >= 60, "subir puntajes muy seguido gasta el límite de DataStore")
end)

prueba("Mutaciones fijas de canastas: el bonus solo multiplica mutaciones", function()
	local base = CatalogoPuro.PesosMutacionFijos(catalogo)
	local conBonus = CatalogoPuro.PesosMutacionFijos(catalogo, 2)
	for clave, peso in base do
		if clave == "normal" then
			igual(conBonus[clave], peso)
		else
			cerca(conBonus[clave], peso * 2, 1e-9)
		end
	end
	verdadero(base ~= catalogo.pesosMutacion, "debe devolver una copia")
	igual(catalogo.pesosMutacion.dorado, base.dorado)
end)

grupo("Láseres")
local laserPrueba = { z = 10, amplitud = 3, velocidad = 0.5, fase = 0 }
prueba("Lado: empieza en el centro y es periódico", function()
	cerca(Laseres.Lado(laserPrueba, 0), 0, 1e-9)
	cerca(Laseres.Lado(laserPrueba, 0.5), 3, 1e-9) -- un cuarto de vuelta: extremo
	cerca(Laseres.Lado(laserPrueba, 2), Laseres.Lado(laserPrueba, 0), 1e-9)
end)
prueba("Toca: solo cerca en avance y en lado", function()
	verdadero(Laseres.Toca(laserPrueba, 0, 10, 0, 4, 0), "en el centro debería tocar")
	verdadero(not Laseres.Toca(laserPrueba, 0, 12, 0, 4, 0), "2 studs antes no toca")
	verdadero(not Laseres.Toca(laserPrueba, 0, 10, 6, 4, 0), "al costado no toca")
	verdadero(Laseres.Toca(laserPrueba, 0, 10, 2.9, 4, 0), "rozando el borde sí toca")
	verdadero(not Laseres.Toca(laserPrueba, 0, 10, 2.9, 4, 0.5), "con holgura, rozar no cuenta")
end)
prueba("Cruza: detecta a quien pasa corriendo entre dos muestras", function()
	-- De avance 8 a 12 en 0.25 s (16 studs/s) por el centro, con el láser en el centro.
	verdadero(Laseres.Cruza(laserPrueba, 0, 8, 0, 0.01, 12, 0, 4, 0), "debería detectar el cruce")
	-- Mismo tramo pero por el costado libre.
	verdadero(not Laseres.Cruza(laserPrueba, 0, 8, -6, 0.01, 12, -6, 4, 0), "por el costado no toca")
	-- Tramo que no llega a la cortina.
	verdadero(not Laseres.Cruza(laserPrueba, 0, 2, 0, 0.1, 5, 0, 4, 0), "lejos de la cortina")
	-- Quieto sobre la cortina.
	verdadero(Laseres.Cruza(laserPrueba, 0, 10, 0, 0.1, 10, 0, 4, 0), "quieto encima")
	igual(Laseres.Tocado({ laserPrueba }, 0, 8, 0, 0.01, 12, 0, 4, 0), 1)
end)

----------------------------------------------------------------------------- resumen
print(`\n{pasadas} pruebas pasaron, {fallidas} fallaron.`)
if fallidas > 0 then
	error("Hay pruebas fallidas")
end
