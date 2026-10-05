# Configuración directa de Roblox

Todo lo que **solo tú puedes hacer** porque se hace en tu cuenta de Roblox: crear los productos, poner los IDs, las insignias, el tamaño del servidor, los sonidos, etc. El código ya está listo y espera estos datos. Mientras un ID esté en `0`, el juego funciona igual y el botón correspondiente avisa "aún no está configurado".

> ⚠️ Roblox cambia de vez en cuando los nombres y la ubicación de sus menús. Si un botón no está donde dice esta guía, busca el nombre en inglés que va entre paréntesis, o usa el buscador del Creator Dashboard.

**Dónde se hace cada cosa:**
- **Creator Dashboard:** https://create.roblox.com/dashboard/creations → clic en tu experiencia **Crunch Heist**. Aquí se crean pases, productos e insignias, y se ven las estadísticas.
- **Roblox Studio:** para publicar y probar.
- **Los archivos de `src/shared/Config/`:** aquí pegas los IDs. Ábrelos con VS Code (o el Bloc de notas) desde la carpeta del proyecto.

---

## 0. Orden recomendado (lista para marcar)

- [ ] 1. Publicar y ajustes básicos (API Services, 8 jugadores)
- [ ] 2. Tu UserId de administrador
- [ ] 3. Los 9 Game Passes
- [ ] 4. Los 11 Developer Products
- [ ] 5. Las 8 insignias (badges)
- [ ] 6. Sonidos y música
- [ ] 7. Fechas reales de la temporada del Pase
- [ ] 8. Grupo (comunidad) de Roblox (opcional)
- [ ] 9. Servidores privados
- [ ] 10. Chat, madurez, género, dispositivos, ícono y miniaturas
- [ ] 11. Publicar la versión final y hacerla pública

---

## Cómo guardar un cambio de configuración (se repite en cada sección)

1. Edita el archivo de `src/shared/Config/...` y guárdalo.
2. Con `rojo serve` corriendo y Studio conectado, el cambio llega solo a Studio. Prueba con **Play**.
3. Para que llegue al juego **publicado**: en Studio, `File → Publish to Roblox`. (Rojo solo cambia Studio; los jugadores ven la última versión que publicaste.)
4. En GitHub Desktop: escribe un resumen (por ejemplo "IDs de los Game Passes"), **Commit** y **Push origin**, para no perder el cambio.

> Un ID es solo el número. Por ejemplo, de `https://www.roblox.com/game-pass/123456789/VIP` el ID es `123456789`. Se pega sin comillas: `id = 123456789,`

---

## 1. Publicar y ajustes básicos

Si ya seguiste `SETUP.md` (Pasos 8 y 9), la experiencia ya está publicada y con el acceso a la API activado. Solo revisa:

1. **Studio → Home → Game Settings → Security → Enable Studio Access to API Services: activado.** Sin esto no se guardan los datos en Studio y el Salón de la Fama dice "Sin conexión".
2. **Tamaño del servidor = 8 jugadores** (el mapa tiene 8 bases). En el Creator Dashboard: tu experiencia → **Places** → **Crunch Heist** → sección de acceso (**Access**) → **Server Size** (Max Players) = **8** → **Save**.
   - El código también lo sabe en `Config/Juego.luau` → `MAX_JUGADORES = 8`. Si algún día cambias uno, cambia el otro (y agrega bases en `Config/Mapa.luau`).
3. **No cambies nunca** después de lanzar (borraría el progreso de todos):
   - `Config/Juego.luau` → `NOMBRE_DATASTORE`
   - `Config/Clasificacion.luau` → `PREFIJO_DATASTORE`
   - los `id` de Crunchis, mutaciones, canastas, semillas y las `clave` de las insignias

---

## 2. Tu UserId de administrador

El panel 🛠️ (dar dinero, eventos, reiniciar...) solo aparece para los admins. En Studio aparece para cualquiera (para que puedas probar); en el juego publicado, **solo** para los UserId de la lista.

1. Abre tu perfil de Roblox en el navegador. La dirección es como `https://www.roblox.com/users/123456789/profile`.
2. El número (`123456789`) es tu **UserId**.
3. En `src/shared/Config/Admin.luau`:
   ```lua
   USUARIOS = {
       123456789, -- yo
   } :: { number },
   ```
4. Guarda, publica y comprueba en el juego publicado que ves el botón 🛠️. Nadie más debería verlo.

---

## 3. Los 9 Game Passes

**Dónde:** Creator Dashboard → tu experiencia → **Monetization → Passes** → **Create a Pass**.

Para cada pase:
1. Sube su imagen (512×512, ver `ASSETS_PENDIENTES.md` I5; mientras tanto puedes usar una imagen simple).
2. Nombre y descripción (de la tabla de abajo) → **Create Pass**.
3. Abre el pase → **Sales** (o **Pricing**) → activa **Item for Sale** → pon el precio → **Save**.
4. Copia el ID (está en la dirección del pase o con el botón **Copy Asset ID**).
5. Pégalo en `src/shared/Config/Productos.luau`, dentro de `PASES`, en el `id` de la clave correspondiente.

| Clave en `Config/Productos` | Nombre | Precio sugerido | Descripción sugerida |
|---|---|---|---|
| `VIP` | VIP | 199 R$ | Etiqueta [VIP] en el chat y sobre tu cabeza, Aura Dorada, Terraza VIP, +1 cambio de misión diario y ganancias offline de hasta 6 h. |
| `X2_DINERO` | x2 Dinero | 399 R$ | Ganas el doble de dinero, para siempre. |
| `AUTO_COBRO` | Auto-Cobro | 149 R$ | El dinero de tus pedestales va directo a tu saldo. |
| `PISO_EXTRA` | Piso Extra | 299 R$ | +4 pedestales en tu base. |
| `DEPOSITO_XL` | Depósito XL | 99 R$ | Tu depósito pasa de 10 a 40 lugares. |
| `APERTURA_TRIPLE` | Apertura Triple | 99 R$ | Abre 3 canastas a la vez (se pagan con dinero del juego). |
| `ESTELA_ARCOIRIS` | Estela Arcoíris | 99 R$ | Una estela arcoíris que te sigue. |
| `AURA_LLAMA` | Aura Llama Verde | 149 R$ | Un aura de llamas verdes. |
| `MASCOTAS_EXTRA` | Mascotas Extra | 149 R$ | Lleva 2 Bichitos más equipados a la vez (solo suben tu ingreso). |

- El precio que ven los jugadores se **lee de Roblox**: el `precio` del archivo es solo un respaldo. Aun así, déjalos iguales para que no haya confusión.
- **Cómo probar:** en el juego publicado, compra un pase con tu cuenta (Roblox cobra de verdad). Para probar gratis, en Studio las compras son de prueba (no cobran) y funcionan igual; también puedes usar el comando `pase X2_DINERO` del panel 🛠️.
- Ningún pase da ventaja para robar ni para evitar robos. Si agregas pases nuevos, respeta esa regla (`GAME_DESIGN.md` §8.7).

---

## 4. Los 11 Developer Products

**Dónde:** Creator Dashboard → tu experiencia → **Monetization → Developer Products** → **Create a Developer Product**.

Para cada uno: imagen (512×512, I6), nombre, descripción y precio → **Create** → copia el ID → pégalo en `src/shared/Config/Productos.luau`, dentro de `PRODUCTOS`.

| Clave en `Config/Productos` | Nombre | Precio sugerido | Descripción sugerida |
|---|---|---|---|
| `DINERO_PUNADO` | Puñado de dinero | 29 R$ | 10 minutos de tu ingreso (¡x2 en tu primera compra!). |
| `DINERO_CANASTA` | Canasta de dinero | 99 R$ | 45 minutos de tu ingreso. |
| `DINERO_CARRETILLA` | Carretilla de dinero | 299 R$ | 3 horas de tu ingreso. |
| `DINERO_CAMION` | Camión de dinero | 799 R$ | 10 horas de tu ingreso. |
| `BOOST_X2` | Boost x2 (30 min) | 49 R$ | Ganas el doble durante 30 minutos. |
| `SUERTE_SERVIDOR` | Suerte del Servidor (15 min) | 79 R$ | Más Crunchis raros en las cintas para TODOS durante 15 minutos. |
| `OFFLINE_X2` | Duplicar ganancias offline | 25 R$ | Duplica lo que ganaste mientras no estabas. |
| `CANASTA_SORPRESA` | Canasta Sorpresa | 149 R$ | Un Crunchi Épico o mejor. Épico 70 % · Legendario 24 % · Mítico 5 % · Secreto 1 %. Mutación: Dorado 4 % · Diamante 1 % · Arcoíris 0.2 %. |
| `PASE_NIVEL` | Saltar nivel del Pase | 29 R$ | Sube 1 nivel del Pase Crunch. |
| `PASE_PREMIUM` | Pase Crunch Premium | 299 R$ | Desbloquea los premios premium de la temporada actual. |
| `PACK_INICIAL` | Pack Inicial | 99 R$ | Dinero + Manzana Cohete (Legendario) + Boost x2 1 h + título. Una vez por cuenta. |

- **Canasta Sorpresa:** pon las probabilidades también en la descripción del producto (como en la tabla). El juego ya las muestra antes de comprar y la oculta en los países donde Roblox restringe los objetos aleatorios de pago.
- Si cambias las probabilidades en `Config/Canastas.luau`, actualiza también esta descripción.
- Las compras se entregan una sola vez aunque Roblox reintente (recibos guardados). Para probar sin pagar usa `producto DINERO_CANASTA` (o cualquier clave) en el panel 🛠️.

---

## 5. Las 8 insignias (badges)

**Dónde:** Creator Dashboard → tu experiencia → **Engagement → Badges** (a veces en **Associated Items → Badges**) → **Create a Badge**.

Imagen 512×512 (se recorta en círculo, ver I7), nombre y descripción → **Create** → copia el ID → pégalo en `src/shared/Config/Insignias.luau`, en el `id` de la insignia correspondiente.

| Clave | Nombre | Cuándo se entrega |
|---|---|---|
| `primer_crunchi` | ¡Mi primer Crunchi! | Primer Crunchi comprado en la cinta |
| `primer_robo` | Manos rápidas | Primer robo exitoso |
| `primera_defensa` | ¡Periodicazo! | Primer ladrón detenido con el periódico |
| `primer_rebirth` | Renacer Crujiente | Primer rebirth |
| `rebirth_5` | Veterano de Villa Crunch | Rebirth 5 |
| `primer_set` | Coleccionista | Primer set del Índice completo |
| `indice_100` | Índice Completo | Los 21 Crunchis al menos una vez |
| `almacen` | Golpe al Almacén | Primera caja del Almacén FrutaMax |

- Roblox deja crear algunas insignias gratis por día; si te pide Robux, puedes esperar al día siguiente para crear las demás.
- Pruébalas en el **juego publicado** (en Studio puede que no se entreguen). Quien ya cumplía la condición la recibe al entrar.

---

## 6. Sonidos y música

Solo puedes usar audio que **subiste tú** (y tienes derecho a usar) o audio de la **Creator Store** con permiso de uso (por ejemplo, la biblioteca de audio de Roblox).

1. **Buscar:** en Studio → **View → Toolbox** → pestaña **Audio**, o en https://create.roblox.com/store/audio. Escucha, elige y copia su ID.
2. **O subir el tuyo:** Creator Dashboard → **Development Items → Audio** → **Upload Asset** (`.mp3` u `.ogg`). Roblox lo revisa antes de que funcione.
3. Pega cada ID en `src/shared/Config/Sonidos.luau` (solo el número). `0` = sin sonido.

| Nombre en `Config/Sonidos` | Qué es (ver `ASSETS_PENDIENTES.md` §3) |
|---|---|
| `Compra` | S1: grito cartoon al comprar |
| `Cobro`, `CobroGrande` | S2: monedas |
| `Alarma` | S3: sirena de robo (se repite mientras dura) |
| `Cerrojo` | S4: campo de fuerza |
| `Golpe` | S5: periodicazo |
| `RarezaAlta` | S6: fanfarria de rareza |
| `Rebirth` | S8: fanfarria larga |
| `Logro` | S9: campanita (misión, set, compra) |
| `Error`, `Clic` | S10: interfaz |
| `MusicaPrincipal` | S11: música de fondo (en bucle) |
| `MusicaEvento` | S12: música de los eventos |
| `Laser` | S13: alarma del Almacén |
| `Evento` | S14: empieza un evento |
| `Chancla`, `Chillido`, `Splash` | S15–S17: golpes de la chancla, el pez de goma y el globo de agua |
| `Huevo` | S18: abrir un huevo de Bichito |
| `Objeto` | S19: usar un objeto de la Mochila |
| `Robo` | Robo exitoso |

4. Si un audio no suena en el juego publicado, revisa en el Creator Dashboard que tu experiencia tenga **permiso** para usarlo (en la página del audio → **Permissions**).
5. Ajusta el `volumen` (de 0 a 1) si alguno se oye muy fuerte. La música ya tiene volumen bajo.

---

## 7. Fechas reales de la temporada del Pase

El Pase Crunch ⭐ tiene fecha de inicio y de fin **reales** (nada de escasez falsa). Hoy están de ejemplo: del 1 de octubre al 6 de noviembre de 2026.

1. Elige la fecha de lanzamiento y la de fin (unas 5 semanas después).
2. Convierte cada fecha a "tiempo Unix": en Studio, **View → Command Bar**, pega y pulsa Enter:
   ```lua
   print(DateTime.fromUniversalTime(2026, 10, 15, 0, 0, 0).UnixTimestamp)
   ```
   (año, mes, día, hora, minuto, segundo, en hora UTC). En Output aparece el número.
3. En `src/shared/Config/Pase.luau` → `TEMPORADA`, pon `inicio` y `fin` con esos números y actualiza el comentario con la fecha legible.
4. **Temporada nueva:** cambia `id` (por ejemplo `"t2"`), `nombre`, `inicio`, `fin` y, si quieres, los premios de `NIVELES`. Cada jugador empieza la temporada nueva en el nivel 0 automáticamente.

**Eventos de temporada** (Halloween, Navidad...): en `src/shared/Config/Eventos.luau` hay un ejemplo comentado en `TEMPORADA`. Se agregan igual, con `inicio` y `fin` reales, y solo aparecen en la rotación entre esas fechas.

---

## 8. Grupo (comunidad) de Roblox (opcional)

Da **+5 % de ingreso** a quien sea miembro del grupo del juego, y sirve para tener una comunidad.

1. Crea el grupo en Roblox (**Communities → Create**; Roblox cobra unos Robux por crearlo).
2. Su ID está en la dirección: `https://www.roblox.com/communities/12345678/...` → `12345678`.
3. En `src/shared/Config/Economia.luau` → `ID_GRUPO = 12345678,`.
4. (Opcional, más adelante) puedes transferir la experiencia al grupo para compartir ingresos con tu equipo.

---

## 9. Servidores privados

1. Creator Dashboard → tu experiencia → **Monetization → Private Servers** (o en Studio: **Game Settings → Monetization**).
2. Actívalos y ponles precio: **99 R$ al mes** (sugerido en `GAME_DESIGN.md`).
3. No hace falta tocar código: el juego funciona igual en servidores privados.

---

## 10. Chat, madurez, género, dispositivos, ícono y miniaturas

1. **Chat:** en Studio, Explorer → **TextChatService** → propiedad **ChatVersion** = **TextChatService** (es lo normal en lugares nuevos). La etiqueta [VIP] del chat lo necesita.
2. **Cuestionario de madurez (Content Maturity / Experience Questionnaire):** Creator Dashboard → tu experiencia → **Audience** (o **Maturity & Compliance**) → responde con honestidad. Guía: tono cartoon, sin sangre; el periodicazo es "violencia cartoon leve"; hay compras con Robux y una canasta aleatoria de pago (con probabilidades visibles). No hay chat de voz ni contenido para mayores.
3. **Género y dispositivos:** en los ajustes de la experiencia (**Configure → Basic Info**): género de simulación/tycoon; dispositivos: teléfono, tablet y computadora.
4. **Nombre, descripción, ícono y miniaturas:** textos listos en `LANZAMIENTO.md` (§1 a §4). Nada engañoso: las miniaturas deben mostrar lo que hay en el juego.
5. **Idiomas (opcional):** **Localization** → agrega inglés con la descripción en inglés de `LANZAMIENTO.md`.

---

## 11. Publicar la versión final y hacerla pública

1. Revisa que en `src/shared/Config/Juego.luau` esté `DATOS_DE_PRUEBA_EN_STUDIO = false` (así los datos de las pruebas en Studio se guardan de verdad; es lo que está ahora).
2. Studio → `File → Publish to Roblox`.
3. Prueba el juego publicado con 5–10 amigos (lista en `LANZAMIENTO.md` §5), con la experiencia todavía privada o compartida solo con ellos.
4. Cuando todo esté bien: Creator Dashboard → tu experiencia → **Access** (o **Configure → Permissions**) → **Public** → **Save**.
5. Durante las primeras semanas mira **Analytics** en el Creator Dashboard: embudo de los primeros minutos, economía y retención. No hay que configurar nada: los eventos ya los envía el juego (solo desde el juego publicado, no desde Studio).

---

## Resumen: qué archivo tiene cada dato

| Dato | Archivo | Campo |
|---|---|---|
| Tu UserId (admin) | `Config/Admin.luau` | `USUARIOS` |
| IDs de Game Passes | `Config/Productos.luau` | `PASES.<CLAVE>.id` |
| IDs de Developer Products | `Config/Productos.luau` | `PRODUCTOS.<CLAVE>.id` |
| IDs de insignias | `Config/Insignias.luau` | `id` de cada una |
| IDs de sonidos y música | `Config/Sonidos.luau` | `id` de cada nombre |
| Fechas de la temporada | `Config/Pase.luau` | `TEMPORADA.inicio` / `fin` |
| Eventos con fecha | `Config/Eventos.luau` | `TEMPORADA` |
| ID del grupo | `Config/Economia.luau` | `ID_GRUPO` |
| Jugadores por servidor | Creator Dashboard (+ `Config/Juego.luau` → `MAX_JUGADORES`) | Server Size = 8 |

Si algo no funciona, copia el texto rojo de **Output** (en Studio) o de la **Developer Console** (en el juego publicado: F9 en computadora) y pégamelo.
