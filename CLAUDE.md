# Guía para trabajar en este repositorio

Juego de Roblox "Crunch Heist" en Luau, sincronizado con Rojo. El dueño es principiante en Roblox y prueba todo en Studio. Quien programa no puede abrir Studio.

## Reglas del proyecto
- **Idioma:** comentarios, documentos, commits y textos del juego en **español**. Los nombres de módulos también (p. ej. `EconomiaService`, `Config/Crunchis`).
- **Diseño:** `docs/GAME_DESIGN.md` es la fuente de verdad. Si un cambio contradice el diseño, actualiza el documento en el mismo commit.
- **Datos, no código:** todo número de balance, ID de producto, sonido o probabilidad va en `src/shared/Config/`. Los IDs desconocidos van como `0` con un comentario `-- TODO`.
- **Servidor autoritativo:** el cliente solo pide. Todo Remote se valida (tipos, distancia, cooldown y frecuencia).
- `--!strict` en todos los archivos Luau que se pueda.
- **Contenido:** nada de caras de personas reales, nada del meme o creador original, todo apto para todo público.
- **Monetización:** respetar las líneas rojas de `GAME_DESIGN.md` §8.7 (probabilidades visibles, sin pop-ups repetidos, sin escasez falsa, protecciones de robo que no se compran).

## Al terminar cada fase o cambio relevante
Actualizar `docs/CHANGELOG.md`, `docs/PRUEBAS.md` (qué probar en Studio y cómo) y `docs/ASSETS_PENDIENTES.md`. Subir `VERSION` en `src/shared/Config/Juego.luau`.

## Verificación antes de hacer commit
```sh
rojo build -o /tmp/test.rbxlx   # el proyecto compila
stylua --check src              # formato
selene src                      # lint (necesita roblox.yml; ver abajo)
```
Si Selene no puede descargar la API de Roblox, genera `roblox.yml` con `selene generate-roblox-std`. Ese archivo está en `.gitignore`.
