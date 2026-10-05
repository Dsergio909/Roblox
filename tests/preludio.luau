--[[
	Preludio de pruebas: versiones mínimas de tipos de Roblox (Color3, Vector3) para poder
	cargar los módulos de Config y de lógica pura fuera de Roblox Studio.

	Lo carga el intérprete `luau` de pruebas a través de la variable LUAU_PRELUDE
	(ver tests/README.md).
]]

Color3 = {
	fromRGB = function(r: number, g: number, b: number)
		return { R = r / 255, G = g / 255, B = b / 255 }
	end,
	new = function(r: number, g: number, b: number)
		return { R = r, G = g, B = b }
	end,
}

Vector3 = {
	new = function(x: number?, y: number?, z: number?)
		return { X = x or 0, Y = y or 0, Z = z or 0 }
	end,
}
