# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versiones: `MAYOR.MENOR.PARCHE`.

## [0.0.1] - 2026-09-29 (Fase 0: fundamentos)

### Agregado
- `docs/GAME_DESIGN.md`: diseño completo de **Crunch Heist**. Incluye género (robo entre bases + tycoon + colección), core loop, primeros 60 segundos, 21 Crunchis en 5 sets, rarezas y mutaciones, protecciones anti-robo iguales para todos, progresión, economía, monetización sin pay-to-win y alcance por fase.
- Estructura de Rojo (`default.project.json`): `src/server`, `src/client` y `src/shared`, con StreamingEnabled activado.
- `rokit.toml` con versiones fijas de Rojo 7.7.0, Selene 0.31.0 y StyLua 2.5.2.
- Configuración de Selene (revisión de código) y StyLua (formato), y extensiones recomendadas de VS Code.
- Scripts de arranque de servidor y cliente que confirman que la sincronización funciona (etiqueta en pantalla apta para celular).
- `src/shared/Config/Juego.luau`: nombre y versión del juego.
- Documentos de trabajo: `SETUP.md`, `ARQUITECTURA.md`, `PRUEBAS.md`, `ASSETS_PENDIENTES.md` y `LANZAMIENTO.md`.
