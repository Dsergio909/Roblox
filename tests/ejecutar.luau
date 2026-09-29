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

----------------------------------------------------------------------------- resumen
print(`\n{pasadas} pruebas pasaron, {fallidas} fallaron.`)
if fallidas > 0 then
	error("Hay pruebas fallidas")
end
