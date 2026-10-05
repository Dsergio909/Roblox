# Pruebas en Roblox Studio

Qué probar después de cada fase y cómo. Marca cada casilla y, si algo falla, copia el texto rojo de la ventana **Output** y pégamelo.

**Antes de cualquier prueba:**
1. GitHub Desktop → **Pull origin** (estar en la rama indicada en `SETUP.md`).
2. PowerShell en la carpeta del proyecto → `rojo serve`.
3. Studio → plugin **Rojo → Connect**.
4. Abrir `View → Output`.

**Cómo probar en celular sin tener uno:** en Studio, pestaña **Test** → selector de dispositivo (**Device**) → elige un teléfono pequeño (por ejemplo un iPhone SE o un Android de pantalla chica) y también uno con notch. Prueba en vertical y en horizontal.

**Cómo probar con varios jugadores:** pestaña **Test** → **Clients and Servers** → elige 2 o 3 jugadores → **Start**. Se abren varias ventanas: una del servidor y una por jugador.

---

## Fase 0: conexión de Rojo

### P0.1 Sincronización
- [ ] Al conectar Rojo, en el **Explorer** aparecen:
  - [ ] `ServerScriptService → Server` (ícono de Script)
  - [ ] `ReplicatedStorage → Shared → Config → Juego` (ícono de ModuleScript)
  - [ ] `StarterPlayer → StarterPlayerScripts → Client` (ícono de LocalScript)
- [ ] `Workspace` → Properties → **StreamingEnabled** está marcado.

### P0.2 Ejecución
- [ ] Pulsa **Play** (F5).
- [ ] En **Output** aparece: `[Crunch Heist] Servidor v0.0.1 iniciado (Fase 0). Rojo sincroniza correctamente.`
- [ ] En **Output** aparece: `[Crunch Heist] Cliente v0.0.1 iniciado para <tu nombre>.`
- [ ] En pantalla, arriba al centro, aparece la etiqueta verde `✔ Rojo conectado · Crunch Heist v0.0.1 · Fase 0`.
- [ ] La etiqueta desaparece sola a los ~6 segundos.
- [ ] No hay líneas rojas (errores) en Output.

### P0.3 Celular
- [ ] Con el emulador de un teléfono pequeño, la etiqueta se lee bien (letra no diminuta) y no se sale de la pantalla.
- [ ] Con un teléfono con notch en horizontal, la etiqueta **no** queda tapada por el notch.

### P0.4 Sincronización en vivo
- [ ] Con Rojo conectado (sin darle Play), abre en el Bloc de notas `src/shared/Config/Juego.luau` de la carpeta del proyecto y cambia `VERSION = "0.0.1"` por `VERSION = "0.0.1-prueba"`. Guarda.
- [ ] En Studio, abre `ReplicatedStorage → Shared → Config → Juego`: el cambio aparece solo, en 1–2 segundos.
- [ ] Deja el archivo como estaba (`"0.0.1"`) y guarda. En GitHub Desktop no debe quedar ningún cambio pendiente. Si queda uno, pulsa clic derecho → **Discard changes**.

---

## Fase 1: MVP jugable

**Qué hay:** mapa de prueba generado con partes de colores, 3 cintas, 8 bases, comprar, cobrar, vender, cerrojo, escudos, robos, periódico, guardado de datos, HUD para celular, tutorial con flecha y panel de admin.

**Qué NO hay todavía:** modelos 3D reales, sonidos (los IDs están en `0`), Índice, rebirth, misiones ni tienda (Fases 2 y 3).

> 💡 **Panel de admin:** en Studio eres admin automáticamente. Busca el botón 🛠️ naranja a la derecha de la pantalla. Tiene botones para darte dinero, hacer aparecer un Secreto, quitar tu escudo, etc. Si escribes `lista` en el cuadro, ves los ids de todos los Crunchis.

### P1.1 Arranque (1 jugador, botón Play)
- [ ] Output: `[Crunch Heist] Servidor vX.Y.Z iniciado (Fase N).` y `[Crunch Heist] Cliente vX.Y.Z listo.` (con la versión actual), sin líneas rojas.
- [ ] Aparece el mapa: pasto verde, avenida gris, 3 cintas (gris, dorada y azul) y 8 bases de colores.
- [ ] Apareces **dentro de tu base**, mirando hacia tus pedestales. El letrero sobre la puerta dice `Base de <tu nombre>`.
- [ ] En el pedestal dorado (bóveda, fondo a la izquierda) está tu **Crunchito Bobo** (bizco, boca torcida).
- [ ] HUD arriba: `$50` y `+$1/s`. Arriba a la izquierda: `🛡️ Escudo de novato 14:xx`.
- [ ] En la tabla de jugadores (arriba a la derecha) aparecen `Dinero` y `Rebirths`.

### P1.2 Tutorial (primeros 60 segundos)
- [ ] Hay un rayo amarillo desde tu personaje hasta un Crunchi de la cinta que puedes pagar, y un globo: "¡Compra un Crunchi en la cinta! 🛒".
- [ ] Los Crunchis de la cinta avanzan dando saltitos y miran hacia la cámara.
- [ ] Encima de cada uno: rareza (con color), nombre, `$X/s` y precio (**verde** si te alcanza, **rojo** si no).

### P1.3 Comprar
- [ ] Acércate a un Crunchi barato y mantén **E** (o toca el botón en celular). Tu dinero baja, sale confeti y el Crunchi aparece "inflándose" en un pedestal libre de tu base.
- [ ] Aviso: "📖 ¡Nuevo en tu Índice: …!" (la primera vez de cada tipo).
- [ ] Intenta comprar uno caro: aviso rojo "Te faltan $X".
- [ ] En las cintas dorada y azul el botón dice `🔒 Rebirth 3` / `🔒 Rebirth 6` y no deja comprar.

### P1.4 Cobrar
- [ ] Sobre los botones verdes delante de cada pedestal aparece un contador `$X` que sube solo.
- [ ] El tutorial ahora apunta al botón con más dinero: "¡Pisa el botón verde para cobrar! 💰".
- [ ] Al pisarlo sale `+$X` flotando y el dinero del HUD "cuenta" hacia arriba. El tutorial desaparece.
- [ ] Con el admin: `+$1M` → compra varios Crunchis y verifica que `+$/s` sube.

### P1.5 Vender y base llena
- [ ] Acércate a un Crunchi tuyo: aparece **"Opciones"** (tecla **F**) → "Vender $X". Al venderlo recibes el 50 % de su precio y el pedestal queda vacío. (Desde la Fase 2; ver P2.1.)
- [ ] Llena los 8 pedestales y compra otro: desde la Fase 2 va al depósito 📦. Con base y depósito llenos: aviso "¡Tu base y tu depósito están llenos!".
- [ ] Los pedestales 9 a 20 se ven casi transparentes (se desbloquean con rebirths en la Fase 2).

### P1.6 Cerrojo
- [ ] Junto a la puerta, adentro, hay un pilar rojo: "Cerrar base". Al usarlo, la puerta muestra un campo de fuerza y el HUD dice `🔒 Cerrada 0:59`. Tú puedes salir y entrar.
- [ ] Cuando termina, puedes volver a cerrarla.

### P1.7 Robos (2 jugadores)
Pestaña **Test → Clients and Servers → 2 jugadores → Start**. Se abren una ventana del servidor y dos de jugadores (Player1 y Player2).

Preparación (en la ventana de **Player2**, con su panel 🛠️): `No soy novato` → `Quitar mi escudo` → escribe `crunchi casco_crunch` y pulsa Ejecutar.

- [ ] **Player1** va a la base de Player2: sobre el Casco Crunch ve **"Robar"**; sobre el Crunchito Bobo de la bóveda **no** (está protegido).
- [ ] Player1 mantiene **E** 1.5 s: el Crunchi va sobre su cabeza, Player1 brilla en rojo, camina más lento y ve abajo "¡Lleva a … a tu base! 60 s" con una barra.
- [ ] **Player2** ve el borde rojo parpadeante, "🚨 ¡Player1 TE ESTÁ ROBANDO!" y un rayo rojo que apunta al ladrón.
- [ ] Si Player1 llega a su base: el Crunchi pasa a su pedestal. Player1: "¡Robaste a …!". Player2: "😱 Player1 te robó a …".
- [ ] El HUD de Player1 dice `⚠️ Cerrojo en 0:45` (revancha: no puede cerrar su base por 45 s).
- [ ] Player1 intenta robarle a Player2 otra vez enseguida: "Ya le robaste hace poco a Player2. Espera 4:5x".

### P1.8 Defensa con el periódico
- [ ] Repite el robo, pero esta vez Player2 equipa el **Periódico** (tecla 1 o su botón en la barra) y hace clic junto al ladrón.
- [ ] Player1 sale volando (empujón), suelta el Crunchi y este vuelve a la base de Player2. Player2: "¡Recuperaste a …!".
- [ ] Golpear a un jugador que NO roba y que NO está dentro de tu base no hace nada.
- [ ] Si el ladrón no llega en 60 s: "¡Se acabó el tiempo!" y el Crunchi vuelve.

### P1.9 Protecciones
- [ ] Con el escudo activo (sin usar "Quitar mi escudo"), el otro jugador **no** ve "Robar" y el letrero de la base muestra `🛡️ m:ss`.
- [ ] Con la base cerrada con cerrojo, el otro jugador no puede entrar (choca con la puerta) y, si ya estaba adentro sin cargar nada, es sacado afuera.
- [ ] Tras 2 robos a la misma base en 10 min, esa base recibe un escudo de alivio de 5 min.
- [ ] Si el ladrón tenía escudo, al robar lo pierde (aviso "Perdiste tu escudo por robar").

### P1.10 Guardado de datos
Requiere el lugar publicado y **Enable Studio Access to API Services** activado (ver `SETUP.md`, Paso 9).
- [ ] Juega, gana dinero y compra Crunchis. Pulsa Stop y luego Play otra vez: conservas el dinero y los Crunchis en los mismos pedestales.
- [ ] El dinero que quedó sin cobrar en los botones se sumó a tu saldo al salir.
- [ ] Sin acceso a API: Output dice `Roblox API services unavailable - data will not be saved`. Es normal y el juego funciona igual (solo no guarda).
- [ ] Panel 🛠️ → `Reiniciar datos`: empiezas de cero con $50 y un Crunchito Bobo.

### P1.11 Celular
Pestaña **Test → Device**: elige un teléfono pequeño y uno con notch, en horizontal.
- [ ] El dinero, el estado de la base y los avisos se leen bien y nada queda tapado por el notch.
- [ ] Los botones de acción (Comprar/Robar/Vender) se pueden tocar.
- [ ] El botón 🛠️ tiene tamaño cómodo para un dedo.

### P1.12 Rendimiento (orientativo)
- [ ] Con 3 jugadores de prueba, `View → Stats` (o Shift+F5 en el cliente) muestra FPS estables (en Studio, 60).
- [ ] Output no muestra advertencias repetidas.

**Si algo falla:** copia las líneas rojas de Output (de la ventana del servidor y de la del jugador) y pégamelas.

---

## Fase 2: progresión

**Qué hay:** Índice con sets e hitos, títulos sobre la cabeza, rebirth con Mejor Amigo, mutaciones en el Índice, misiones diarias y semanales, calendario de 7 días con racha suave, ganancias offline, depósito y opciones de cada Crunchi, canastas con dinero del juego (con probabilidades visibles), macetero con semillas que crecen en tiempo real, Agentes Escáner que persiguen ladrones y bonus por amigos.

**Botones nuevos:** a la derecha 🧺 Canastas · 📋 Misiones · 📖 Índice · 🔁 Rebirth. A la izquierda 🎁 Recompensas · 📦 Mis Crunchis · 🛠️ Admin.

**Comandos de admin nuevos:** escribe `rebirth` en el cuadro del panel 🛠️ para hacer un rebirth gratis (sin requisitos).

### P2.1 Opciones y depósito
- [ ] Acércate a un Crunchi tuyo: ahora dice **"Opciones"** (tecla **F**). Se abre un panel con Vender, Guardar en depósito, A la bóveda y Mejor Amigo.
- [ ] "Guardar en depósito": el Crunchi desaparece del pedestal y aparece en 📦 → Depósito. Deja de sumar al `+$/s`.
- [ ] En 📦 toca un Crunchi del depósito → "Colocar en la base": vuelve a un pedestal libre.
- [ ] "A la bóveda": pasa al pedestal dorado (si estaba ocupado, intercambian lugares).
- [ ] Vender un Épico o mejor pide confirmación ("¿Seguro? Toca otra vez").
- [ ] Con la base llena, comprar en la cinta lo manda al depósito (aviso 📦).

### P2.2 Canastas 🧺
- [ ] Cada canasta muestra sus **probabilidades por rareza** antes del botón de abrir.
- [ ] "Abrir $1K" (Canasta de Madera) cobra el dinero y muestra la animación: nombres que giran y se detienen en el premio.
- [ ] El Crunchi aparece en tu base (o en el depósito si está llena).
- [ ] Sin dinero suficiente: aviso rojo y no se cobra nada.
- [ ] La Canasta Celestial dice `🔒 Rebirth 5` si no tienes 5 rebirths.

### P2.3 Índice 📖 y sets
- [ ] Los Crunchis que tuviste se ven con su nombre; los demás, como silueta "???" con el color de su rareza.
- [ ] Pestañas Dorado, Diamante… muestran solo las mutaciones que tuviste.
- [ ] Completa un set (con admin: `crunchi pepito_pepita`, `crunchi don_gusano`, `crunchi rey_semilla`, `crunchi corazon_oro` → set Huerto): aviso 🏆, anuncio a todos, `+$/s` sube un 3 % y el título aparece en la pestaña 🏷️ Títulos.
- [ ] Al equipar un título, se ve sobre tu cabeza (y tu nombre con 🔁 si tienes rebirths).
- [ ] Al llegar al 25 % del Índice (6 Crunchis distintos): recompensa de hito.

### P2.4 Rebirth 🔁
- [ ] El menú muestra costo y requisitos con ✓/✗, lo que ganas y lo que pierdes.
- [ ] Con admin: `+$1M` y `crunchi manzana_cohete` → el botón 🔁 muestra "!" y el requisito queda ✓.
- [ ] "Cambiar Mejor Amigo" → elige uno. "HACER REBIRTH" pide confirmación.
- [ ] Tras el rebirth: dinero $50, solo queda tu Mejor Amigo, ingreso x1.5, un pedestal más (9) y apareces en la misma base. Tu nombre muestra 🔁1.
- [ ] Tras `rebirth` ×3 (admin): la Cinta Dorada ya deja comprar y tienes 2 bóvedas.

### P2.5 Misiones 📋
- [ ] Hay 3 diarias y 3 semanales con barra de progreso y recompensa (💰, ⭐ XP, 🌱).
- [ ] Compra Crunchis / cobra: la barra avanza. Al completarla, aviso ✅ y el botón 📋 muestra un globito.
- [ ] "¡Reclamar!" da la recompensa. Completar las 3 diarias da una Canasta de Madera extra.
- [ ] "🔄 Cambiar" cambia una diaria (1 vez por día).
- [ ] Los contadores "nuevas en…" / "terminan en…" bajan cada segundo.

### P2.6 Recompensas 🎁 (calendario, racha y offline)
- [ ] En tu **primera** sesión la ventana NO se abre sola; el botón 🎁 tiene un globito.
- [ ] Reclamar el día 1 da dinero. El calendario marca ✅ los días reclamados.
- [ ] Con datos guardados: sal, espera 2+ minutos y vuelve. La ventana se abre sola con "Mientras no estabas… tus Crunchis ganaron $X" y un botón Cobrar.
- [ ] La racha y su bonus se muestran en la ventana.

### P2.7 Macetero 🌱
- [ ] En tu base, frente al cerrojo (esquina opuesta), hay una maceta café. Al tocarla (**E**) se abre el panel.
- [ ] Tienes 1 Semilla Común de regalo → "Plantar". Aparece un brote que crece con un contador `🌱 29:59`.
- [ ] (Para no esperar 30 min: cambia `minutos` de "comun" a `1` en `Config/Semillas.luau` mientras pruebas.)
- [ ] Cuando dice "✨ ¡Lista!", abre el panel → "Cosechar": animación de revelación y el Crunchi va a tu base.
- [ ] Otros jugadores ven tu planta crecer.

### P2.8 Agentes Escáner (2 jugadores)
- [ ] Hay 3 agentes (traje negro, cabeza gris con ventana roja y un láser) caminando por la avenida.
- [ ] Roba un Crunchi y pasa cerca de un agente: aviso "🔎 ¡Un Agente Escáner te vio! ¡Corre!" y te persigue.
- [ ] Si te alcanza, sales empujado y el Crunchi vuelve a su dueño. Si te alejas o llegas a tu base, se rinde.

### P2.9 Amigos
- [ ] (Con una cuenta amiga real en un servidor publicado) el `+$/s` sube un 10 % por amigo en el servidor.

---

## Fase 3: monetización

**Qué hay:** tienda 🛒 (Pack Inicial, dinero, pases, boosts, Canasta Sorpresa, cosméticos), Pase Crunch ⭐ (30 niveles, gratis y premium), auras y estelas visibles para todos, Terraza VIP, etiqueta [VIP] en el chat y sobre la cabeza, boost x2 de prueba gratis, oferta lateral del Pack Inicial, Suerte del Servidor, Auto-Cobro, Piso Extra, Depósito XL, Apertura Triple y compras seguras (ProcessReceipt idempotente).

**Botones:** derecha 🛒 · 🧺 · 📋 · 📖 · ⭐ — izquierda 🎁 · 📦 · 🔁 · 🛠️.

> ⚠️ **Los IDs de los productos todavía están en 0** (se configuran al final, ver `CONFIGURACION_ROBLOX.md`). Mientras tanto, los botones de compra avisan "aún no está configurado". Para probar los EFECTOS sin pagar, usa el panel 🛠️:
> - `pase VIP` (o `X2_DINERO`, `AUTO_COBRO`, `PISO_EXTRA`, `DEPOSITO_XL`, `APERTURA_TRIPLE`, `ESTELA_ARCOIRIS`, `AURA_LLAMA`): activa ese Game Pass solo por esta sesión.
> - `producto DINERO_CANASTA` (o `BOOST_X2`, `SUERTE_SERVIDOR`, `CANASTA_SORPRESA`, `PACK_INICIAL`, `PASE_PREMIUM`, `PASE_NIVEL`, `OFFLINE_X2`): entrega ese producto sin cobrar.
> - `pasexp 5000`: suma XP al pase. `pasepremium`: activa el premium.

### P3.1 Tienda 🛒
- [ ] Pestaña 💰 Dinero: 4 paquetes con la cantidad EXACTA en $ que darían ahora, el precio en R$ y las etiquetas "Más popular" y "Mejor valor". Arriba: "Tu PRIMERA compra de dinero vale x2".
- [ ] `producto DINERO_PUNADO` dos veces: la primera da el doble (aviso de bonus) y la segunda no.
- [ ] Pestaña ⭐ Pases: 8 pases con descripción; los que tienes dicen "✔ Lo tienes".
- [ ] Pestaña 🎁 Sorpresa: muestra las probabilidades por rareza (Épico 70 %, Legendario 24 %, Mítico 5 %, Secreto 1 %) y por mutación (Dorado 4 %, Diamante 1 %, Arcoíris 0.2 %). En Studio se ve todo (ahí Roblox no siempre responde la consulta de región, y el juego lo permite solo en Studio para que puedas probar). En el juego publicado, en los países que restringen objetos aleatorios de pago, desaparecen la pestaña 🎁 Sorpresa, 💰 Dinero y 🚀 Pack (el dinero sirve para abrir canastas y huevos), y el botón "Conseguir $".
- [ ] Pestaña ✨ Cosméticos: comprar el "Aura Brillante" con dinero del juego ($25K) la equipa y se ve alrededor de tu personaje. "Quitar" / "Usar" funcionan.
- [ ] Botón de compra con ID 0: aviso "aún no está configurado" (no se rompe nada).

### P3.2 Game Passes (con `pase …`)
- [ ] `pase X2_DINERO`: el `+$/s` se duplica.
- [ ] `pase PISO_EXTRA`: 4 pedestales más se desbloquean en tu base.
- [ ] `pase AUTO_COBRO`: cada 2 s aparece "+$X" junto al dinero sin pisar los botones.
- [ ] `pase DEPOSITO_XL`: 📦 muestra capacidad 40.
- [ ] `pase APERTURA_TRIPLE`: en 🧺 aparece "Abrir x3".
- [ ] `pase VIP`: aparece `[VIP]` sobre tu cabeza y en tus mensajes de chat, el Aura Dorada se equipa sola, puedes entrar a la **Terraza VIP** (al final de la avenida, lado este). Sin VIP la puerta es sólida y, si entras de otra forma, te sacan.
- [ ] `pase ESTELA_ARCOIRIS` / `pase AURA_LLAMA`: se equipan solos y se ven.

### P3.3 Productos (con `producto …`)
- [ ] `BOOST_X2`: bajo el dinero aparece `⚡ x2 29:59` y el ingreso se duplica. Al terminar: aviso y botón pequeño "⚡ x2 para siempre" (abre la pestaña Pases).
- [ ] `SUERTE_SERVIDOR`: anuncio a todo el servidor con tu nombre y `🍀 Suerte x2` bajo el dinero de TODOS.
- [ ] `CANASTA_SORPRESA`: se abre sola con la animación y da un Épico o mejor.
- [ ] `PACK_INICIAL`: dinero + Manzana Cohete + boost 1 h + título "Crunchero". La pestaña 🚀 Pack desaparece.
- [ ] `OFFLINE_X2`: con ganancia offline pendiente, la duplica (ver 🎁).

### P3.4 Pase Crunch ⭐
- [ ] Muestra temporada, nivel, barra de XP y "termina en…". (Si la fecha actual está fuera de la temporada, dice "temporada terminada" y no suma XP: ajusta las fechas en `Config/Pase.luau`.)
- [ ] Reclamar misiones suma XP al pase. `pasexp 5000` sube 10 niveles.
- [ ] Los premios gratis de niveles alcanzados tienen "Reclamar". Los premium muestran 🔒 hasta `pasepremium`.
- [ ] El botón ⭐ muestra un globito con los premios por reclamar.

### P3.5 Ofertas (sin interrumpir)
- [ ] A los 3 minutos de juego (una sola vez por cuenta): aviso "🎁 ¡Regalo! Boost x2 GRATIS por 5 minutos".
- [ ] A los 7 minutos: aparece a la DERECHA una tarjeta pequeña del Pack Inicial que se cierra con ✕ y se va sola a los 20 s. No vuelve a aparecer en la sesión.
- [ ] Al intentar comprar en la cinta sin dinero, el aviso rojo trae un botón pequeño "💰 Conseguir $" que abre la tienda.

### P3.6 Compras reales (cuando configures los IDs)
- [ ] Compra un producto en un servidor publicado: se entrega una sola vez, aunque salgas enseguida.
- [ ] Si el servidor se cierra justo al comprar, al volver a entrar se entrega (una vez).

---

## Fase 4: eventos, Almacén y optimización

**Qué hay:** eventos automáticos (🌧️ Lluvia de Manzanas, 🚨 Redada FrutaMax, ✨ Hora Dorada, ☢️ Noche Nuclear), el Almacén FrutaMax 🏭 con láseres, el Salón de la Fama (tablas globales), el menú ⚙️ Ajustes con Modo ahorro, música, Crunchis Arcoíris que cambian de color y reciclaje de modelos en las cintas.

**Botones:** izquierda 🎁 · 📦 · 🔁 · ⚙️ · 🛠️.

> Para no esperar: en el panel 🛠️ están los botones **🌧️ Lluvia, 🚨 Redada, ✨ Hora Dorada, ☢️ Noche Nuclear, Terminar evento** y **🏭 Almacén listo**. Sin tocar nada, el primer evento empieza a los 5 minutos y luego uno cada 8 minutos.

### P4.1 Eventos
- [ ] Al empezar un evento: anuncio grande, cartel arriba a la izquierda (debajo del estado de la base) con el nombre y "termina en 2:59", y un tono de color suave en la pantalla. Al terminar, el cartel desaparece.
- [ ] 🌧️ Lluvia: caen manzanas rojas (y alguna dorada) alrededor de ti. No chocan con nada. Salen más Crunchis Dorados, Diamante y Arcoíris en las cintas.
- [ ] ✨ Hora Dorada: tu `+$/s` sube x1.5 al empezar y vuelve a la normalidad al terminar.
- [ ] ☢️ Noche Nuclear: aparecen Crunchis **Radiactivos** (verdes brillantes) en las cintas. Fuera del evento no salen nunca.
- [ ] Con la ventana del servidor: en Output no aparecen errores rojos durante los eventos.

### P4.2 Redada FrutaMax (mejor con 2 jugadores)
- [ ] Botón 🚨 Redada: aparecen 5 agentes con una **sirena roja** en la cabeza. Van a una base, entran por la puerta y se acercan a un Crunchi.
- [ ] Al llegar, el Crunchi muestra "🏷️ ¡ETIQUETADO!", su contador deja de subir unos 25 s y al dueño le llega un aviso.
- [ ] Golpea a un agente con el 🗞️ periódico: desaparece con confeti y ganas monedas ("🗞️ ¡Agente fuera! +$X"). Vuelve a aparecer a los 6 s. Después de 6 recompensas ya no da monedas (pero se sigue yendo).
- [ ] Con el **escudo** activo (los primeros minutos) o con el **cerrojo** puesto, los agentes no etiquetan tu base. Si pones el cerrojo con un agente adentro, lo saca.
- [ ] Los agentes de la redada no atrapan ladrones (eso lo hacen solo los 3 agentes normales).
- [ ] Al terminar el evento, los agentes con sirena desaparecen.

### P4.3 Almacén FrutaMax 🏭
- [ ] Al oeste de la avenida (pasando el final de las cintas) está el edificio con el letrero "ALMACÉN FRUTAMAX" y un cartel con las probabilidades por rareza y mutación.
- [ ] Sin rebirths, la puerta dice "🔒 Rebirth 1" y no deja entrar. Con `rebirth` (o al llegar a Rebirth 1) aparece el aviso "¡Se abrió el Almacén FrutaMax!".
- [ ] "Entrar" te lleva al inicio del pasillo y abajo aparece "🏭 ¡Esquiva los láseres y abre la caja! 90 s".
- [ ] Los láseres rojos se deslizan de lado a lado. Si tocas uno: alarma, te saca afuera y dice que esperes 15 s.
- [ ] Llegar a la caja fuerte (zona amarilla) → "Abrir la caja" → recibes un Crunchi Raro o mejor (en un pedestal o en el depósito). La puerta pasa a decir "⏳ 9:59".
- [ ] Salir y volver a entrar al juego no reinicia la espera. El botón 🏭 Almacén listo (admin) la quita.
- [ ] Con 2 jugadores: el otro ve los mismos láseres en las mismas posiciones.
- [ ] Nadie puede quedarse adentro sin haber entrado por la puerta (si reapareces adentro, te saca).

### P4.4 Salón de la Fama
- [ ] Junto al Almacén (lado norte) hay 3 carteles: 🔁 Top Rebirths, 🦹 Top Robos, 📖 Top Coleccionistas.
- [ ] En Studio sin "Enable Studio Access to API Services" dicen "Sin conexión con Roblox". Con el acceso activado y tras unos minutos de juego, aparece tu nombre.

### P4.5 Ajustes ⚙️ y rendimiento
- [ ] ⚙️ abre la ventana con 🎵 Música, 🔊 Sonidos y 🔋 Modo ahorro (SÍ/NO). Abajo se ven los FPS.
- [ ] Modo ahorro SÍ: el confeti es mucho menor, las sombras desaparecen y en la Lluvia caen menos manzanas. Sale del juego y vuelve: el ajuste se mantiene.
- [ ] Sonidos NO: no suena nada al comprar o cobrar. Música NO: se apaga la música (cuando tenga ID).
- [ ] Crunchi Arcoíris (`crunchi crunchito_bobo arcoiris`): su cuerpo cambia de color continuamente.
- [ ] Con el emulador de un celular pequeño: la ventana ⚙️ y el cartel del evento se ven completos.
- [ ] Rendimiento (orientativo): con la cinta llena, en `View → Stats` o con Ctrl+Shift+F5 los FPS se mantienen estables. En el Explorer, `Workspace → CintaLocal` no crece sin parar (los modelos se reciclan).

### P4.6 Insignias (cuando tengan ID, en el juego publicado)
- [ ] Con los IDs puestos en `Config/Insignias.luau` y el juego publicado: comprar tu primer Crunchi da la insignia "¡Mi primer Crunchi!" (aparece el aviso de Roblox). Salir y volver no la vuelve a pedir.

---

## Fase 5: Bichitos, armas y objetos

**Qué hay:** 7 armas de defensa que se desbloquean jugando, mascotas (🐾 Bichitos) con huevos, objetos de un solo uso (🎒 Mochila), opciones nuevas y antitrampas.

**Botones:** derecha 🛒 · 🧺 · 🐾 · 📋 · 📖 · ⭐ — izquierda 🎁 · 📦 · 🎒 · 🔁 · ⚙️ · 🛠️.

> Atajos en el panel 🛠️ (escríbelos en el cuadro): `arma chancla` (equipa sin requisito), `mascota fenix`, `objeto jugo_turbo 5`, `dinero 1000000000` y `rebirth`.

### P5.1 Armas
- [ ] 🎒 → 🗞️ Armas: el Periódico dice "✅ Equipada"; las demás muestran 🔒, qué falta y una barrita.
- [ ] `arma matamoscas`: en tu barra de herramientas aparece el Matamoscas (rojo, más largo). Con 2 jugadores, golpear a un ladrón lo detiene desde más lejos que el periódico, pero tarda más en volver a golpear.
- [ ] Haz `rebirth` una vez: a los pocos segundos llega "🔓 ¡Nueva arma: Matamoscas!" y en Armas ya se puede **Equipar**.
- [ ] Al morir y reaparecer, sigues teniendo el arma equipada (no vuelve el periódico).
- [ ] Durante una 🚨 Redada, cada agente golpeado suma para el ☂️ Paraguas (10 agentes).

### P5.2 Bichitos 🐾
- [ ] 🐾 → 🥚 Huevos: cada huevo muestra la probabilidad de **cada** bichito (deben sumar 100 %). Sin rebirths, el Dorado y el Celestial dicen 🔒.
- [ ] Con dinero, "Abrir ×1" en el Huevo de Huerta: animación, tarjeta del bichito con "📖 ¡NUEVO!", y el bichito aparece **flotando detrás de ti**.
- [ ] En "Mis Bichitos", arriba dice "Equipadas 1/2 · Bonus de ingreso +2 %" y tu `+$/s` subió.
- [ ] Toca una tarjeta para quitarla o equiparla. "⭐ Equipar mejores" elige las de más bonus.
- [ ] "🌿 Liberar": un común se libera al tocarlo (te da algo de dinero). Uno épico o mejor pide tocarlo dos veces. Uno equipado pide quitarlo primero.
- [ ] Colección: los que nunca tuviste salen como "???".
- [ ] `mascota fenix` (Secreto): anuncio a todo el servidor y el bichito brilla.
- [ ] `pase MASCOTAS_EXTRA`: los espacios suben en 2.
- [ ] Con 2 jugadores: ves los bichitos del otro. En ⚙️, "🐾 Mascotas de otros: NO" los oculta (los tuyos siguen).

### P5.3 Objetos 🎒
- [ ] 🎒 → 🧃 Objetos: cada objeto con su precio (cambia según tu ingreso) y "Comprar".
- [ ] Compra y usa un 🧃 Jugo Turbo: bajo el dinero aparece "🧃 9:59" y tu `+$/s` sube x1.5. Al acabarse: aviso y vuelve a la normalidad.
- [ ] 🧲 Imán: el dinero se cobra solo (aparece "+$X" junto al dinero) mientras dure.
- [ ] 🧪 Fertilizante sin nada plantado: dice que no hay nada creciendo y **no se gasta**. Con una semilla plantada: el tiempo baja a la mitad.
- [ ] ⏱️ Reloj del Almacén después de sacar una caja: la puerta vuelve a decir "Entrar".
- [ ] 🎉 Confeti: explosión de confeti que también ve el otro jugador si está cerca.
- [ ] Misiones: aparecen a veces "Abre 3 huevos" y "Usa 2 objetos"; al reclamarlas dan su objeto.

### P5.4 Opciones y seguridad
- [ ] ⚙️ tiene 5 opciones y se puede desplazar en un celular chico. "📢 Anuncios: NO" oculta los avisos de lo que consiguen los demás (los eventos se siguen anunciando).
- [ ] Antitrampas (no hace falta probarlo con trampas): robar y caminar normal a tu base sigue funcionando igual, aunque tengas lag.
- [ ] En Output no aparecen errores rojos al usar todo lo anterior.

