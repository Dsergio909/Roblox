--!strict
--[[
	Config/Rebirths
	El rebirth reinicia tu dinero y tus Crunchis a cambio de un multiplicador PERMANENTE
	(+0.5× por rebirth, ver Config/Economia), un pedestal más y zonas nuevas.

	Conservas: el Índice, los sets, los títulos, las semillas, el calendario y UN Crunchi
	a elección (tu "Mejor Amigo").

	Requisitos: "rareza" es la rareza MÍNIMA (un Mítico cuenta para un requisito de
	Legendario). Los Crunchis pueden estar en la base o en el depósito.
]]

export type Requisito = { rareza: string, cantidad: number }
export type Nivel = { costo: number, requisitos: { Requisito }, desbloquea: string? }

local Rebirths = {
	NIVELES = {
		{ costo = 1e6, requisitos = { { rareza = "legendario", cantidad = 1 } }, desbloquea = "Almacén FrutaMax" },
		{ costo = 5e6, requisitos = { { rareza = "legendario", cantidad = 2 } } },
		{
			costo = 25e6,
			requisitos = { { rareza = "mitico", cantidad = 1 } },
			desbloquea = "Cinta Dorada y una bóveda más",
		},
		{ costo = 100e6, requisitos = { { rareza = "mitico", cantidad = 2 } } },
		{ costo = 400e6, requisitos = { { rareza = "mitico", cantidad = 3 } }, desbloquea = "Canasta Celestial" },
		{
			costo = 1.5e9,
			requisitos = { { rareza = "secreto", cantidad = 1 } },
			desbloquea = "Cinta Celestial y una bóveda más",
		},
		{ costo = 6e9, requisitos = { { rareza = "secreto", cantidad = 2 } } },
	} :: { Nivel },

	-- Después del último nivel de la tabla: cada rebirth cuesta FACTOR_COSTO veces el anterior.
	FACTOR_COSTO = 4,
	REQUISITO_DESPUES = { rareza = "secreto", cantidad = 3 } :: Requisito,

	-- Conservar un Crunchi a elección al hacer rebirth.
	CONSERVA_MEJOR_AMIGO = true,
}

return table.freeze(Rebirths)
