--!strict
--[[
	Config/Admin
	Quién puede usar el panel de administración (dar dinero, reiniciar datos, etc.).

	TODO (configuración de Roblox): pon tu UserId. Lo ves en la dirección de tu perfil:
	  https://www.roblox.com/users/123456789/profile  →  tu UserId es 123456789
]]

local Admin = {
	USUARIOS = {
		-- 123456789, -- ← tu UserId aquí
	} :: { number },

	-- En Roblox Studio cualquiera que pruebe el juego es admin (para que puedas probar
	-- aunque todavía no hayas puesto tu UserId). En el juego publicado NO aplica.
	PERMITIR_EN_STUDIO = true,
}

return table.freeze(Admin)
