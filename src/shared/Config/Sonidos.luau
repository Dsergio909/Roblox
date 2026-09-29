--!strict
--[[
	Config/Sonidos
	IDs de los sonidos del juego. 0 = sin sonido (el juego funciona igual).

	TODO (configuración de Roblox): sube tus sonidos o elige sonidos con licencia de la
	Creator Store y pega aquí su ID (solo el número). Ver docs/ASSETS_PENDIENTES.md §3.
]]

export type Sonido = { id: number, volumen: number }

local Sonidos: { [string]: Sonido } = {
	Compra = { id = 0, volumen = 0.6 }, -- S1
	Cobro = { id = 0, volumen = 0.5 }, -- S2
	CobroGrande = { id = 0, volumen = 0.6 }, -- S2
	Alarma = { id = 0, volumen = 0.5 }, -- S3
	Cerrojo = { id = 0, volumen = 0.5 }, -- S4
	Golpe = { id = 0, volumen = 0.6 }, -- S5
	RarezaAlta = { id = 0, volumen = 0.7 }, -- S6
	Robo = { id = 0, volumen = 0.6 },
	Error = { id = 0, volumen = 0.4 }, -- S10
	Clic = { id = 0, volumen = 0.3 }, -- S10
}

return Sonidos
