--!strict
--[[
	Config/Login
	Recompensa por conectarse y racha suave. Ver docs/GAME_DESIGN.md §6.

	CALENDARIO: 7 recompensas por DÍAS DE CONEXIÓN (no hace falta que sean seguidos: el
	calendario NUNCA se reinicia; si faltas, sigues donde quedaste). Tras el día 7 vuelve
	a empezar.

	RACHA: +2 % de ingreso por cada día seguido (máximo +10 %). Si faltas, la racha baja
	UN paso por cada día que faltaste (no se borra toda).

	Tipos de recompensa:
	  { tipo = "dinero", minutos = N }       N minutos de tu ingreso actual (mínimo DINERO_MINIMO)
	  { tipo = "canasta", id = "...", cantidad = N }
	  { tipo = "semilla", id = "...", cantidad = N }
]]

export type Recompensa = { tipo: string, minutos: number?, id: string?, cantidad: number?, texto: string }

local function R(recompensa: Recompensa): Recompensa
	return recompensa
end

local Login = {
	CALENDARIO = {
		R({ tipo = "dinero", minutos = 5, texto = "Dinero" }),
		R({ tipo = "canasta", id = "madera", cantidad = 1, texto = "Canasta de Madera" }),
		R({ tipo = "dinero", minutos = 10, texto = "Dinero" }),
		R({ tipo = "semilla", id = "comun", cantidad = 2, texto = "2 Semillas" }),
		R({ tipo = "canasta", id = "hierro", cantidad = 1, texto = "Canasta de Hierro" }),
		R({ tipo = "dinero", minutos = 20, texto = "Mucho dinero" }),
		R({ tipo = "canasta", id = "epica", cantidad = 1, texto = "¡Canasta Épica!" }),
	},
	DINERO_MINIMO = 200,

	RACHA_BONUS_POR_DIA = 0.02,
	RACHA_MAXIMA = 5, -- 5 días × 2 % = +10 %
}

return table.freeze(Login)
