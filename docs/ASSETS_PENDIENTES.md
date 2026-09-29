# Assets pendientes (modelos, imágenes y sonidos)

Todo lo que **tú** debes crear o subir en Roblox Studio o en el Creator Hub. El código funciona sin esto: en la Fase 1 todo se ve con **partes de colores (placeholders)**. Cuando subas un asset, pon su ID en el módulo `Config` que se indica y el juego lo usará sin cambiar la lógica.

**Estado actual (Fase 0):** nada es obligatorio todavía. La lista está ordenada por la fase en que conviene tenerlo.

---

## Dirección de arte (aplica a todo)

| Aspecto | Regla |
|---|---|
| Estilo | **Low-poly cartoon**, colores planos y saturados, formas redondeadas y exageradas. Como un juguete, no realista. |
| Caras | **Dibujadas a mano o vectoriales, estilo caricatura.** Ojos enormes, pupilas pequeñas, dientes cuadrados, cejas gruesas. **Nunca fotos ni caras de personas reales** (Roblox las rechaza). |
| Verde base de los Crunchis | `#7ED957` (cuerpo), `#4E9F2E` (sombra y hojas), `#8B5A2B` (rabito) |
| Colores de rareza | Común `#B0B0B0` · Poco común `#5BD15B` · Raro `#3FA9F5` · Épico `#A64DFF` · Legendario `#FFC933` · Mítico `#FF4D6D` · Secreto arcoíris/negro |
| FrutaMax (villanos) | Gris oficina `#6B7280`, negro traje `#1F2937` y rojo láser `#FF2A2A`. Serios en diseño, torpes en animación. |
| Originalidad | Nada copiado de otros juegos, series ni del meme original. Todos los modelos deben ser tuyos, de Roblox o de la Creator Store con licencia libre. |

### Presupuesto de rendimiento (celulares de gama baja)
- **Triángulos:** Crunchi completo ≤ 800 · Agente Escáner ≤ 1,500 · una base completa ≤ 3,000 · lo visible de la ciudad ≤ 25,000.
- **Texturas:** 256×256 para caras y detalles, 512×512 como máximo para atlas del entorno. Reutilizar siempre la misma textura en muchas piezas.
- **Materiales:** preferir `SmoothPlastic` y colores (casi gratis) en lugar de texturas. Pocas piezas `Neon`.
- **Sin** `SurfaceAppearance` pesadas, **sin** uniones (Union) complejas: usar MeshParts.
- Colisiones: `CollisionFidelity = Box` o `Hull` en todo lo decorativo; `CanCollide = false` en detalles pequeños.

---

## 1. Modelos 3D

| # | Asset | Especificación | Dónde va el ID | Fase |
|---|---|---|---|---|
| M1 | **Cuerpo de Crunchi** (malla base compartida) | Manzana redondeada ≤ 400 tris, pivote en la base, ~3 studs de alto. **Una sola malla para los 21 Crunchis.** Hoja y rabito aparte (≤ 60 tris). | `Config/Crunchis.luau` → `MALLA_BASE` | 2 |
| M2 | **Accesorios** (1 por Crunchi) | ≤ 300 tris cada uno, solo colores. Lista: mochila, semillas (decal), gotas de sudor, gusano, taladro, casco de obra, sombrero de pescador, catapulta, globo con canasta, mecha encendida, cohete, corona de hojas, (Gigantón: sin accesorio, escala 3×), visor láser, armadura robot, bandana ninja, brillo radiactivo, corazón dorado, aura en espiral | `Config/Crunchis.luau` → campo `accesorio` | 2–3 |
| M3 | **Agente Escáner** | Rig R6 con traje negro y corbata roja. Cabeza = **escáner de supermercado** (pistola lectora con ventana roja), ≤ 800 tris, + línea láser `Neon` roja. Total ≤ 1,500 tris. **No** debe parecerse a personajes con cabeza de cámara de otras series. | `Config/Agentes.luau` | 2 |
| M4 | **Kit de base** (modular) | Plataforma de piso, pedestal (≤ 200 tris), botón de cobro redondo, botón de cerrojo, puerta con campo de fuerza, cartel con nombre del dueño | Se reemplaza el placeholder en `Mapa/` | 3–4 |
| M5 | **Cinta transportadora** | Segmento recto repetible (≤ 150 tris) + textura de franjas 256×256 que se mueve | `Config/Mapa.luau` | 4 |
| M6 | **Periódico enrollado** (herramienta) | ≤ 150 tris, con textura de periódico 256×256 **inventada** (sin logos reales) | `Config/Robo.luau` | 4 |
| M7 | **Canastas** (4 tipos) | Madera, Hierro, Dorada y Celestial. ≤ 300 tris cada una. | `Config/Canastas.luau` | 3 |
| M8 | **Ciudad (Villa Crunch)** | Fachadas simples (cajas + atlas de ventanas 512×512), postes y árboles low-poly | Mapa en Studio | 4 |
| M9 | **Edificio FrutaMax / Almacén** | Edificio gris con logo **inventado** "FrutaMax" (manzana con etiqueta de precio) | Mapa en Studio | 4 |
| M10 | Props de evento | Manzana gigante que cae, cohete con humo, globo | `Config/Eventos.luau` | 4 |

**Cómo subir una malla:** en Blender exporta `.fbx` u `.obj` → en Studio usa `Home → Import 3D` → revisa triángulos y escala → guárdalo en `ReplicatedStorage/Modelos` (te daré la ruta exacta en su fase).

---

## 2. Imágenes

| # | Asset | Tamaño | Notas | Fase |
|---|---|---|---|---|
| I1 | **Caras de los 21 Crunchis** | 256×256 PNG, fondo transparente | Una por Crunchi (lista en `GAME_DESIGN.md` §4). Caricatura, expresiones exageradas. | 2 |
| I2 | **Íconos de UI** (hoja de sprites) | Un PNG de 1024×1024 con íconos de 128×128 | Dinero, tienda, índice, misiones, ajustes, rebirth, cerrojo, escudo, canasta, 7 gemas de rareza, x2, VIP. Una sola imagen = menos descargas en internet lento. | 3 |
| I3 | **Ícono del juego** | 512×512 PNG | Ver conceptos en `LANZAMIENTO.md`. Legible en tamaño pequeño, un solo personaje. | Antes del lanzamiento |
| I4 | **Miniaturas del juego** | 1920×1080 PNG/JPG, 3 a 5 imágenes | Ver `LANZAMIENTO.md`. Nada engañoso: debe mostrar lo que el juego tiene. | Antes del lanzamiento |
| I5 | **Íconos de Game Passes** (8) | 512×512 PNG | Roblox los recorta en círculo: deja el contenido centrado con margen. | 3 |
| I6 | **Íconos de Developer Products** (~10) | 512×512 PNG | Igual que I5 | 3 |
| I7 | **Íconos de badges** | 512×512 PNG, recorte circular | Primer Crunchi, primer robo, primer rebirth, set completo ×5, Índice 100 % | 2 |
| I8 | Textura de periódico, franjas de la cinta y ventanas | 256×256 / 512×512 | Inventadas, sin marcas reales | 4 |

---

## 3. Sonidos

Reglas de Roblox: solo puedes usar audio **subido por ti** (tuyo o con licencia) o de la **Creator Store con permiso de uso**, como la biblioteca de audio de Roblox. Formato `.mp3` u `.ogg`. Efectos cortos (≤ 3 s) y volumen normalizado entre sí.

| # | Sonido | Descripción | Fase |
|---|---|---|---|
| S1 | Compra | Grito agudo cartoon de alegría ("¡iiih!") **sin palabras** + "crunch" | 1–2 |
| S2 | Cobro normal y cobro grande | Monedas. El grande más largo y brillante. | 1–2 |
| S3 | Alarma de robo | Sirena cartoon corta, en loop mientras dure el robo | 1–2 |
| S4 | Cerrojo | "Zum" de campo de fuerza al cerrar y al abrir | 1–2 |
| S5 | Periodicazo | "¡Plaf!" de papel | 2 |
| S6 | Rareza en la cinta | 5 fanfarrias crecientes: Raro, Épico, Legendario, Mítico y Secreto (esta última muy épica) | 2 |
| S7 | Canasta | Redoble + revelación | 2 |
| S8 | Rebirth | Fanfarria larga (≤ 5 s) | 2 |
| S9 | Misión completa / nivel del pase | Campanita alegre | 2 |
| S10 | UI | Clic suave y error ("no alcanza") | 3 |
| S11 | Música principal | Loop de 90–120 s, funky y alegre, sin letra | 3 |
| S12 | Música de evento | Loop tenso pero gracioso, para la Redada FrutaMax | 4 |

Los IDs van en `Config/Sonidos.luau` (se crea en la Fase 1 con `0` como placeholder, que significa "sin sonido").

---

## 4. Configuración en el Creator Hub (no son archivos, pero también te tocan)

| Tarea | Fase |
|---|---|
| Crear los 8 Game Passes y copiar sus IDs a `Config/Productos.luau` | 3 |
| Crear los Developer Products y copiar sus IDs | 3 |
| Crear las badges | 2 |
| Activar servidores privados y ponerles precio | 3 |
| Tamaño de servidor: 8 jugadores | 1 |
| Cuestionario de madurez del contenido (Content Maturity) | Antes del lanzamiento |
