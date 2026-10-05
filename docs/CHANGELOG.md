# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versiones: `MAYOR.MENOR.PARCHE`.

## [0.5.0] - 2026-10-05 (Fase 5: Bichitos, armas y objetos)

### Agregado
- **7 armas de defensa** (🎒 Mochila → Armas): Periódico, Chancla Voladora, Matamoscas Gigante, Pez de Goma Chillón, Baguette Dura, Globo de Agua y Paraguas Rebotón. Se desbloquean jugando (detener ladrones, rebirths, Índice, Almacén, Redadas), nunca se compran, y están equilibradas (más alcance = golpe más lento). Aviso al desbloquear una y barrita de progreso en las bloqueadas.
- **Bichitos de la Huerta 🐾:** 12 mascotas originales que te siguen y suben tu ingreso (tope +60 %). Tres huevos con dinero del juego, con la probabilidad de cada bichito a la vista. Equipar, "Equipar mejores", liberar (con confirmación para los raros) y colección con siluetas. Los de los demás se ven si están cerca.
- **Objetos de la Mochila 🎒:** Jugo Turbo, Imán de Monedas, Fertilizante Mágico, Reloj del Almacén y Bomba de Confeti. Si un objeto no sirve en ese momento, no se gasta. Sus tiempos se ven bajo el dinero.
- Game Pass **Mascotas Extra** (+2 espacios; ID pendiente en `Config/Productos`).
- Misiones nuevas: abrir huevos y usar objetos (con objetos de premio). Objetos y bichitos en el Pase Crunch (niveles 7, 12, 18 y 22).
- **Ajustes:** 🐾 Mascotas de otros y 📢 Anuncios.
- Comandos de admin: `arma <id>`, `mascota <id>`, `objeto <id> [n]`.
- Recompensas extensibles (`RecompensaService.RegistrarTipo`): "consumible" y "mascota".
- Pruebas: armas (equilibrio y desbloqueo), huevos (probabilidades y que todo se pueda conseguir), espacios y bonus de mascotas, objetos (67 en total).

### Cambiado
- El periódico ahora es un arma más de `Config/Armas` (los valores salieron de `Config/Robo`).
- Botones del HUD un poco más chicos para que entren 🐾 y 🎒; nuevo orden. El cartel de eventos pasó arriba al centro, debajo del dinero.
- El menú ⚙️ se desplaza si no entra en la pantalla.

### Seguridad y correcciones
- **Antitrampas de robo:** quien carga un Crunchi no puede alejarse del punto del robo más rápido de lo que camina (teletransporte o "speed hack" → el Crunchi vuelve a su dueño). Sin falsos positivos por lag.
- **Antitrampas del Almacén:** avanzar más rápido que lo posible termina el intento.
- **Región (objetos aleatorios de pago):** donde Roblox los restringe, también se ocultan los paquetes de dinero, el Pack Inicial y "Conseguir $"; antes la respuesta de Roblox podía llegar tarde y no aplicarse. En Studio se muestra todo para poder probar.
- Fuga de memoria del Auto-Cobro al salir; `oferta_cerrada` solo acepta ids conocidos; el comando `almacen` actualiza la puerta al instante.

## [0.4.0] - 2026-09-29 (Fase 4: eventos, Almacén y optimización)

### Agregado
- **Eventos automáticos** (`Config/Eventos.luau`): cada 8 minutos empieza el siguiente de la rotación, con un cartel y la cuenta regresiva real, anuncio, música de evento y un tono de color suave.
  - 🌧️ **Lluvia de Manzanas:** manzanas gigantes caen del cielo (solo visuales, recicladas) y hay más mutaciones en las cintas.
  - 🚨 **Redada FrutaMax:** 5 agentes con sirena entran a las bases y etiquetan Crunchis (no producen durante 25 s). De un periodicazo se van y quien les pega gana monedas (máximo 6 recompensas por redada). Nunca entran a bases con escudo o cerrojo.
  - ✨ **Hora Dorada:** ingreso x1.5 para todos y muchos Dorados.
  - ☢️ **Noche Nuclear:** la mutación Radiactiva (x4) solo sale en este evento.
  - Eventos de temporada con fechas reales de inicio y fin (solo aparecen entre esas fechas).
- **Almacén FrutaMax 🏭** (Rebirth 1): robar sin víctimas. Cruzas un pasillo de láseres que se deslizan y abres la caja fuerte: un Crunchi Raro o mejor, con las probabilidades en un cartel en la entrada. Una caja cada 10 minutos (se guarda); si tocas un láser solo esperas 15 s para reintentar.
- **Salón de la Fama:** tablas de clasificación globales (Top Rebirths, Top Robos y Top Coleccionistas) junto al Almacén.
- **Menú ⚙️ Ajustes:** música, sonidos y **Modo ahorro** (menos partículas, sin sombras y menos manzanas). Se guardan con tus datos. Si el juego va lento, sugiere el Modo ahorro una vez por sesión. Muestra los FPS.
- **Música de fondo** y música de evento (`Config/Sonidos`: `MusicaPrincipal`, `MusicaEvento`), y sonidos nuevos `Laser` y `Evento`.
- Los **Crunchis Arcoíris** cambian de color de verdad (un solo ciclo para todos y solo los cercanos).
- **Insignias (badges):** 8 insignias (`Config/Insignias.luau`) que se entregan solas según los datos del jugador; cada una se pide a Roblox una sola vez.
- **`docs/CONFIGURACION_ROBLOX.md`:** guía paso a paso de todo lo que se configura en Roblox (UserId de admin, Game Passes, Developer Products, insignias, sonidos, fechas del pase, grupo, servidores privados, madurez y publicación).
- Comandos de admin: `evento <id>` / `evento fin` y `almacen` (con botones rápidos en el panel 🛠️).
- Pruebas: configuración de eventos, Almacén, clasificación e insignias, fórmula de los láseres y mutaciones fijas (60 en total).

### Cambiado
- **Reciclaje de modelos (object pooling)** en las cintas: los Crunchis que salen de la cinta se reutilizan en vez de crearse de nuevo (menos tirones en celulares).
- Las canastas, semillas, la Canasta Sorpresa y el Almacén muestran también la **probabilidad de cada mutación**, y esas probabilidades son fijas (los eventos solo cambian las cintas). Así lo que se ve antes de abrir es siempre lo real.
- El suelo del mapa es más ancho para que entren el Almacén (oeste) y la Terraza VIP (este).

## [0.3.0] - 2026-09-29 (Fase 3: monetización)

### Agregado
- **Tienda 🛒** con pestañas: Pack Inicial, Dinero (4 paquetes con monto exacto, "Más popular" y "Mejor valor"), Pases, Boosts, Canasta Sorpresa y Cosméticos. Los precios se leen de Roblox (los reales del Creator Dashboard).
- **8 Game Passes** con sus efectos: VIP, x2 Dinero, Auto-Cobro, Piso Extra, Depósito XL, Apertura Triple, Estela Arcoíris y Aura Llama Verde. Ninguno ayuda a robar ni a evitar robos.
- **Developer Products:** paquetes de dinero (bonus x2 en la primera compra), Boost x2, Suerte del Servidor (beneficia a todos y agradece al comprador), Duplicar ganancias offline, Canasta Sorpresa, Saltar nivel, Pase Premium y Pack Inicial (una vez por cuenta).
- **Compras seguras:** `ProcessReceipt` idempotente con recibos guardados en el perfil y espera del guardado antes de confirmar (patrón oficial de ProfileStore).
- **PolicyService:** la Canasta Sorpresa se oculta donde se restringen objetos aleatorios de pago (y ante la duda, también).
- **Pase Crunch ⭐:** temporada con fechas reales, 30 niveles, camino gratis y premium, XP por misiones y por jugar (con tope diario).
- **Cosméticos:** auras y estelas (con dinero del juego, por pase o como premio) que cada cliente dibuja solo para jugadores cercanos.
- **VIP:** etiqueta [VIP] sobre la cabeza y en el chat, Aura Dorada, Terraza VIP, +1 cambio de misión y ganancias offline de hasta 6 h. ⭐ junto al nombre de los usuarios Premium.
- **Ofertas que no interrumpen:** boost x2 gratis de 5 min a los 3 minutos (una vez), tarjeta lateral del Pack Inicial a los 7 minutos (máx. una por sesión y 3 en total) y botón "Conseguir $" dentro del aviso "Te faltan $X".
- Indicadores de boost y suerte bajo el dinero, y "+$X" único para el Auto-Cobro.
- Comandos de admin: `pase <CLAVE>`, `producto <CLAVE>`, `pasexp <n>`, `pasepremium`.
- Pruebas: anclaje de precios de los paquetes, referencias del pase y cosméticos (51 en total).

### Cambiado
- El botón 🔁 Rebirth pasó a la columna izquierda para dejar lugar a 🛒 y ⭐.
- "Reiniciar datos" (admin) conserva todo lo pagado (recibos, compras, pase y cosméticos).

## [0.2.0] - 2026-09-29 (Fase 2: progresión)

### Agregado
- **Índice 📖:** colección por set con siluetas "???" para los que faltan, pestañas por mutación (Dorado, Diamante, Arcoíris, Radiactivo) y progreso general.
- **Sets:** completar un set da +3 % de ingreso permanente (no se pierde con el rebirth), un título y un anuncio a todo el servidor.
- **Hitos del Índice** (25/50/75/100 %): títulos, dinero y canastas.
- **Títulos sobre la cabeza:** nombre, título equipado y rebirths visibles para todos (el nombre por defecto de Roblox se oculta).
- **Rebirth 🔁:** requisitos de dinero y de Crunchis ("rareza o mejor"), multiplicador +0.5× permanente, +1 pedestal, más cerrojo, más bóvedas y zonas (Cinta Dorada en R3, Canasta Celestial en R5, Cinta Celestial en R6). Conservas un "Mejor Amigo" y apareces en la misma base. Doble confirmación.
- **Misiones 📋:** 3 diarias (00:00 UTC) y 3 semanales (lunes), progreso por señales (comprar, cobrar, robar o defender, canastas, rarezas, minutos, cerrojo, cosechar), recompensas en minutos de ingreso + XP + semillas, 1 cambio gratis por día y premio por completar las 3 diarias.
- **Recompensas 🎁:** calendario de 7 días de conexión que nunca se reinicia y racha suave (+2 %/día, máx. +10 %, faltar un día resta un paso). La ventana se abre sola una vez por sesión, nunca en la primera.
- **Ganancias offline:** 20 % del ingreso base por el tiempo fuera (tope 3 h), para cobrar al volver.
- **Mis Crunchis 📦 y panel de Opciones:** vender (con confirmación para Épico+), depósito (10 lugares, no produce pero no se puede robar), colocar, mover a la bóveda y elegir Mejor Amigo. Comprar con la base llena manda el Crunchi al depósito.
- **Canastas 🧺** con dinero del juego o tickets de recompensa (Madera, Hierro, Dorada, Celestial y Épica solo por recompensa), con probabilidades visibles y animación de revelación.
- **Macetero 🌱:** semillas (Común 30 min, Dorada 2 h, Estelar 8 h) que crecen en tiempo real incluso desconectado; cosechar da un Crunchi con más probabilidad de mutación. La planta se ve crecer en cada base.
- **Agentes Escáner:** 3 NPCs de FrutaMax patrullan la avenida y persiguen a quien carga un Crunchi robado; si lo alcanzan, el Crunchi vuelve a su dueño.
- **Bonus por amigos:** +10 % por amigo en el servidor (máx. +30 %).
- Sistema de ventanas para celular (una abierta a la vez, se ajustan a pantallas verticales y horizontales) y tarjetas de Crunchi.
- Comando de admin `rebirth`. Pruebas unitarias nuevas (46 en total).

### Cambiado
- La acción "Vender" sobre tus Crunchis ahora es "Opciones" (abre el panel).
- Escalado de la interfaz: cada panel se escala desde su punto de anclaje y nunca se sale de la pantalla.
- Los bordes de las cintas ya no tienen colisión (nadie se traba al cruzar).

### Corregido
- La semilla de regalo ya no se vuelve a regalar en cada sesión (ProfileStore rellenaba la plantilla de forma recursiva).

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
