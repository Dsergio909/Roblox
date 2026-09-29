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
stylua src tests                # formato (stylua --check para solo revisar)
selene src                      # lint (necesita roblox.yml; ver abajo)
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json \
  --definitions=@roblox=<globalTypes.d.luau de luau-lsp> --ignore="**/Paquetes/**" src   # tipos
LUAU_PRELUDE=tests/preludio.luau luau tests/ejecutar.luau                              # pruebas
```
- Si Selene no puede descargar la API de Roblox, genera `roblox.yml` con `selene generate-roblox-std`. Ese archivo está en `.gitignore`.
- `luau-lsp` y `luau` se pueden compilar desde su código fuente (GitHub: JohnnyMorganz/luau-lsp, que incluye Luau como submódulo). Las definiciones de tipos de Roblox están en `scripts/globalTypes.d.luau` de ese repo.
- Las pruebas necesitan un `luau` con soporte de preludio (ver `tests/README.md`).

## Particularidades de Luau estricto encontradas
- Listas de tablas con campos opcionales: envolver cada elemento en una función tipada (ver `P()` en `Config/Crunchis`).
- `pcall(fn)` con una función que no devuelve nada: usar `pcall(fn :: any, ...)`.
- Iterar `x or {}`: asignarlo antes a una variable tipada.
