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
- [ ] Output: `[Crunch Heist] Servidor v0.1.0 iniciado (Fase 1).` y `[Crunch Heist] Cliente v0.1.0 listo.`, sin líneas rojas.
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
- [ ] Acércate a un Crunchi tuyo: aparece **"Vender $X"** (tecla **F**, mantener). Al venderlo recibes el 50 % de su precio y el pedestal queda vacío.
- [ ] Llena los 8 pedestales y trata de comprar otro: aviso "¡Tu base está llena!".
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
