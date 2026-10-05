--!strict
--[[
	SonidoController
	Reproduce los sonidos del juego (IDs en Config/Sonidos). Si un sonido tiene id 0,
	simplemente no suena: el juego funciona igual sin sonidos.

	  SonidoController.Reproducir("Cobro")

	Música: suena en bucle "MusicaPrincipal", y durante los eventos "MusicaEvento" (si tiene
	id; si no, sigue la principal). Se apaga en ⚙️ Ajustes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigSonidos = require(Shared:WaitForChild("Config"):WaitForChild("Sonidos"))

local SonidoController = {
	activado = true, -- efectos de sonido (⚙️ Ajustes)
	musica = true, -- música de fondo (⚙️ Ajustes)
}

local cache: { [string]: Sound } = {}
local pistaDeseada = "MusicaPrincipal"
local pistaActual: Sound? = nil

local function obtener(nombre: string): Sound?
	local existente = cache[nombre]
	if existente then
		return existente
	end
	local definicion = ConfigSonidos[nombre]
	if definicion == nil or definicion.id == 0 then
		return nil
	end
	local sonido = Instance.new("Sound")
	sonido.Name = nombre
	sonido.SoundId = `rbxassetid://{definicion.id}`
	sonido.Volume = definicion.volumen
	sonido.Parent = SoundService
	cache[nombre] = sonido
	return sonido
end

function SonidoController.Reproducir(nombre: string)
	if not SonidoController.activado then
		return
	end
	local sonido = obtener(nombre)
	if sonido then
		SoundService:PlayLocalSound(sonido)
	end
end

-- Para sonidos en bucle (alarma): devuelve el Sound o nil.
function SonidoController.Bucle(nombre: string, activo: boolean)
	local sonido = obtener(nombre)
	if sonido == nil then
		return
	end
	sonido.Looped = true
	if activo and SonidoController.activado then
		if not sonido.IsPlaying then
			sonido:Play()
		end
	else
		sonido:Stop()
	end
end

local function aplicarMusica()
	local deseada: Sound? = nil
	if SonidoController.musica then
		deseada = obtener(pistaDeseada) or obtener("MusicaPrincipal")
	end
	local actual = pistaActual
	if actual and actual ~= deseada then
		actual:Stop()
	end
	if deseada then
		deseada.Looped = true
		if not deseada.IsPlaying then
			deseada:Play()
		end
	end
	pistaActual = deseada
end

-- Cambia la pista de fondo (p. ej. "MusicaEvento" durante un evento).
function SonidoController.Pista(nombre: string)
	pistaDeseada = nombre
	aplicarMusica()
end

function SonidoController.FijarMusica(activa: boolean)
	SonidoController.musica = activa
	aplicarMusica()
end

function SonidoController.Iniciar()
	aplicarMusica()
end

return SonidoController
