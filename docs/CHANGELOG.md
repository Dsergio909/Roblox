# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versiones: `MAYOR.MENOR.PARCHE`.

## [0.1.0] - 2026-09-29 (Fase 1: MVP jugable)

### Agregado
- **Configuración editable** (`src/shared/Config/`): rarezas, 21 Crunchis en 5 sets (con su modelo placeholder descrito como datos), mutaciones, 3 cintas con probabilidades, economía, base, robo y protecciones, mapa, sonidos, admin y pasos de onboarding.
- **Catálogo validado:** si la configuración tiene un error (id repetido, rareza inexistente…), el juego lo avisa al arrancar.
- **Mapa placeholder** generado por código: avenida, 3 cintas y 8 bases con 20 pedestales, botones de cobro, cerrojo, puerta y letrero.
- **Cintas:** aparición por rareza y mutación con probabilidades configurables. El cliente dibuja y mueve los Crunchis (cero tráfico de red por movimiento) y el servidor valida cada compra (distancia, dinero, espacio, rebirth).
- **Bases:** pedestales que generan dinero (calculado sin bucles por segundo), cobro al pisar el botón, venta al 50 %, cerrojo, bóveda, escudo de entrada (3 min) y de novato (15 min de juego).
- **Robos:** cargar el Crunchi sobre la cabeza, llevarlo a tu base en 60 s, alarma y rayo hacia el ladrón, límite de 2 robos por base cada 10 min con escudo de alivio, cooldown por pareja, protección por nivel, revancha (el cerrojo del ladrón se recarga 45 s) y pérdida del escudo propio al robar.
- **Periódico enrollado:** empuja y hace soltar el Crunchi a los ladrones; solo afecta a ladrones o intrusos en tu base.
- **Datos:** ProfileStore con bloqueo de sesión, autoguardado, guardado al salir y al cerrar el servidor, versión de esquema y migraciones. El dinero sin cobrar se suma al salir.
- **HUD para celular:** dinero con contador animado, ingreso por segundo, estado de la base, barra de carga del robo, avisos, anuncios de rarezas y alarma.
- **Tutorial sin texto largo:** rayo guía a un Crunchi que puedes pagar y luego al botón de cobro; consejo sobre robos a los 2 minutos.
- **Analytics:** embudo de onboarding, eventos de economía (agrupados cuando son frecuentes) y eventos de robo y defensa.
- **Panel de admin 🛠️** (solo en Studio o para los UserIds de `Config/Admin`).
- Pruebas unitarias (31) de formato, azar, limitador, fórmulas, configuración y balance.

### Notas
- Todo se ve con partes de colores. Los modelos, imágenes y sonidos reales están en `ASSETS_PENDIENTES.md`.
- Sin Índice, rebirth, misiones ni tienda todavía (Fases 2 y 3).

## [0.0.1] - 2026-09-29 (Fase 0: fundamentos)

### Agregado
- `docs/GAME_DESIGN.md`: diseño completo de **Crunch Heist**. Incluye género (robo entre bases + tycoon + colección), core loop, primeros 60 segundos, 21 Crunchis en 5 sets, rarezas y mutaciones, protecciones anti-robo iguales para todos, progresión, economía, monetización sin pay-to-win y alcance por fase.
- Estructura de Rojo (`default.project.json`): `src/server`, `src/client` y `src/shared`, con StreamingEnabled activado.
- `rokit.toml` con versiones fijas de Rojo 7.7.0, Selene 0.31.0 y StyLua 2.5.2.
- Configuración de Selene (revisión de código) y StyLua (formato), y extensiones recomendadas de VS Code.
- Scripts de arranque de servidor y cliente que confirman que la sincronización funciona (etiqueta en pantalla apta para celular).
- `src/shared/Config/Juego.luau`: nombre y versión del juego.
- Documentos de trabajo: `SETUP.md`, `ARQUITECTURA.md`, `PRUEBAS.md`, `ASSETS_PENDIENTES.md` y `LANZAMIENTO.md`.
