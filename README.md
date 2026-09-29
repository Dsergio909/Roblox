# Crunch Heist 🍏

Juego de Roblox: compra manzanas con caras ridículas (los **Crunchis**), ponlas en tu base para ganar dinero y roba las más raras de las bases de los demás, mientras los Agentes Escáner de FrutaMax intentan ponerles precio.

El código está en Luau y se sincroniza con Roblox Studio usando [Rojo](https://rojo.space).

## Empezar
1. **Instalación (una vez):** [`docs/SETUP.md`](docs/SETUP.md)
2. **Qué probar:** [`docs/PRUEBAS.md`](docs/PRUEBAS.md)

## Documentos
| Documento | Contenido |
|---|---|
| [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) | Diseño del juego: loops, progresión, economía y monetización |
| [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) | Cómo está organizado el código |
| [`docs/ASSETS_PENDIENTES.md`](docs/ASSETS_PENDIENTES.md) | Modelos, imágenes y sonidos por crear |
| [`docs/LANZAMIENTO.md`](docs/LANZAMIENTO.md) | Nombre, descripción, miniaturas y plan de eventos |
| [`docs/CHANGELOG.md`](docs/CHANGELOG.md) | Historial de versiones |

## Estructura
```
src/server  → ServerScriptService.Server          (lógica autoritativa)
src/client  → StarterPlayerScripts.Client         (UI y efectos)
src/shared  → ReplicatedStorage.Shared            (Config y utilidades)
```

## Comandos útiles
```sh
rokit install        # instala Rojo, Selene y StyLua en las versiones del proyecto
rojo serve           # sincroniza en vivo con Studio
selene src           # revisa errores comunes
stylua src           # formatea el código
```
