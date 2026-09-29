# Crunch Heist: documento de diseño

> Versión del documento: 0.1 (Fase 0)
> Estado: propuesta base. Los números son un punto de partida y se ajustarán con pruebas y datos de AnalyticsService.
> Regla de oro: todo número de este documento vivirá en un módulo `Config` dentro de `src/shared/Config/`. Cambiar el balance nunca debe requerir tocar la lógica.

---

## 0. Decisión de género (y por qué)

**Elegido: juego de robo entre bases con base tycoon y colección (estilo "Steal a ___"), más una capa PvE de agentes villanos.**

Por qué este género y no otro:

| Criterio | Robo entre bases + tycoon | Simulador de clics | Supervivencia PvE pura | Tycoon clásico |
|---|---|---|---|---|
| Retención D1/D7 comprobada en Roblox (2025–2026) | Muy alta: el formato más jugado de la plataforma en 2025 | Media | Media, depende del contenido | Media |
| Emoción variable (sorpresa) | Alta: rarezas en la cinta y robos | Baja | Media | Baja |
| Social (ver lo que otros tienen, interactuar) | Muy alta: las bases de todos están a la vista | Baja | Alta | Baja |
| Monetización natural sin pay-to-win | Alta: comodidad, x2, cosméticos | Alta | Media | Alta |
| Costo de contenido nuevo | Bajo: una manzana nueva es una fila en una tabla | Bajo | Alto: mapas y enemigos | Medio |
| Encaje con el tono del meme (caos, manzanas, explosiones) | Perfecto | Débil | Bueno | Débil |

El formato de robo tiene un riesgo real: que los jugadores nuevos o gratis se sientan víctimas. Por eso el diseño incluye **protecciones fuertes e iguales para todos** (sección 5), y **nada que se compre con Robux da ventaja para robar ni para evitar robos**.

La capa PvE de los **Agentes Escáner** permite que quien no disfruta del PvP se divierta "robando" a los villanos (el Almacén FrutaMax) y defendiendo la ciudad en eventos cooperativos.

---

## 1. Concepto y nombre

**Concepto en una frase:**
> Compra manzanas con caras ridículas en la cinta de la ciudad, llévalas a tu base para que te hagan ganar dinero y roba las más raras de las bases de los demás, mientras los Agentes Escáner de FrutaMax intentan ponerles precio a todas.

**Nombre propuesto:** **Crunch Heist** (subtítulo en español: *¡Roba las Manzanas!*).

- Corto, en inglés (Roblox es global), fácil de pronunciar en español y dice lo que es: *crunch* (manzana) y *heist* (golpe, robo).
- Roblox permite traducir el título y la descripción por idioma, así que en español se puede mostrar como "Crunch Heist: ¡Roba las Manzanas! 🍏".
- En `docs/LANZAMIENTO.md` hay alternativas para hacer pruebas A/B de nombre e ícono.

### Universo propio (sin copiar al creador original)

| Elemento | Nuestro diseño | Qué evitamos |
|---|---|---|
| Las manzanas | Los **Crunchis**: manzanas verdes low-poly con caras de **caricatura dibujada** (ojos enormes, dientes cuadrados, cejas exageradas). Cada uno tiene una personalidad y un accesorio (casco, mochila, cohete…). | Caras de personas reales, fotos, deepfakes y los nombres o frases del meme original |
| Los villanos | Los **Agentes Escáner** de **FrutaMax Corp.**: agentes de traje cuya cabeza es un **escáner de supermercado** con una línea láser roja. Quieren ponerle etiqueta de precio a cada Crunchi libre y venderlos en su MegaMercado. | Diseños de otros universos, como los "hombres cámara" de otras series. Nuestra cabeza es un escáner de caja registradora, con su propia silueta. |
| La ciudad | **Villa Crunch**: calles de caricatura, una gran cinta transportadora por la avenida central y el edificio gris de FrutaMax al fondo. | Mapas o modelos descargados de terceros sin licencia |
| El tono | Humor absurdo y caótico: gritos agudos al comprar un Crunchi, explosiones de confeti, cohetes que fallan, manzanas gigantes que caen del cielo en eventos. **Todo cartoon, sin sangre ni violencia realista.** | Humor ofensivo, sustos o contenido para mayores |

Cumplimiento: todo el contenido es apto para todo público y sigue las Community Standards de Roblox. El único "golpe" del juego es un **periódico enrollado** que empuja y hace soltar la manzana robada, sin daño.

---

## 2. Core loop

### Qué hace el jugador cada 30–90 segundos

```
     ┌──────────────────────────────────────────────────────────┐
     │                                                          │
     ▼                                                          │
 [1] Mira la CINTA ──► [2] Compra un Crunchi ──► [3] El Crunchi camina a tu base
     (aparecen al azar,     (mantener E / tocar)       y se sube a un pedestal
      algunos brillan)                                          │
                                                                ▼
 [6] Mejores Crunchis ◄── [5] Pisas el botón de cobro ◄── [4] El pedestal
     = más $/segundo          del pedestal: ¡monedas!         acumula $ por segundo
     │
     ├──► [A] ¿Ves un Legendario en otra base? ROBARLO (entrar, agarrar, huir)
     ├──► [B] ¿Suena la alarma de tu base? DEFENDER (periodicazo + cerrojo)
     └──► [C] ¿Te sobra dinero? ABRIR UNA CANASTA (rareza aleatoria con probabilidades visibles)
```

### Los tres niveles de loop

| Nivel | Duración | Qué persigue el jugador | Recompensa |
|---|---|---|---|
| **Corto** | 5–30 s | Comprar en la cinta, cobrar pedestales, un robo rápido, defender | Números que suben, monedas que saltan, sonido "crunch" |
| **Medio** (la sesión) | 15–45 min | Subir la base de tier (de Comunes a Épicos), conseguir el primer Legendario, completar las 3 misiones diarias, completar un set del Índice | Canasta gratis, % de ingreso permanente, título |
| **Largo** | días y semanas | Rebirths (multiplicador permanente), Índice al 100 %, mutaciones, pase de temporada, clasificaciones | Estatus visible, zonas nuevas, cosméticos |

---

## 3. Los primeros 60 segundos (sin tutorial largo)

No hay pantallas de texto. El tutorial son **flechas y globos de 3–5 palabras** que aparecen solo cuando hacen falta, y cada paso se registra en AnalyticsService (embudo de onboarding).

| Segundo | Qué pasa | Por qué engancha |
|---|---|---|
| 0 | Apareces **dentro de tu base**. Ya tienes un Crunchi gratis (Crunchito Bobo) en el pedestal 1, haciendo "+$1" cada segundo con números flotantes. Tienes $50. | Ya estás ganando antes de hacer nada |
| 2 | Una flecha brillante señala la cinta, a 15 studs: "¡Compra un Crunchi!" | Una sola instrucción, clara |
| 5–15 | Caminas a la cinta y mantienes pulsado sobre un Común de $20. Grito agudo + confeti, y el Crunchi sale corriendo con sus patitas hacia tu base. | Acción física y reacción graciosa inmediata |
| 20–30 | El botón de cobro de tu pedestal muestra "$18". Flecha: "¡Cobra!". Lo pisas: lluvia de monedas + sonido + el contador de dinero crece. | **Recompensa antes de los 30 segundos** |
| 30–50 | Compras 1–2 Comunes más. El ingreso pasa de $1/s a $6/s y la barra de "Siguiente meta" avanza. | Crecimiento visible y rápido |
| 45–60 | Pasa por la cinta un **Raro** con brillo azul y el anuncio "¡RARO en la cinta!". Cuesta $3,500 y no te alcanza. En la base vecina ves un Legendario dorado girando. | Deseo y meta a futuro: "quiero eso" |
| 2–3 min | Globo: "Puedes ROBAR Crunchis de otras bases 👀. Tu base tiene escudo por 3 min 🛡️". | Se revela el giro del juego cuando ya entiende lo básico |
| 3 min | Regalo: "¡Boost x2 de dinero GRATIS por 5 minutos!" | Prueba antes de comprar (sección 8) |

Pasos del embudo de onboarding (AnalyticsService):
1. Entró · 2. Compró su primer Crunchi · 3. Cobró por primera vez · 4. Tiene 3 Crunchis · 5. Abrió su primera canasta · 6. Intentó su primer robo o defendió uno · 7. Completó su primera misión diaria · 8. Hizo su primer Rebirth.

---

## 4. Los Crunchis (contenido inicial)

### Rarezas

| Rareza | Color | Probabilidad en la cinta principal | Pago aprox. (segundos para recuperar el precio) |
|---|---|---|---|
| Común | Gris | 55 % | ~20 s |
| Poco común | Verde | 28 % | ~40 s |
| Raro | Azul | 11.5 % | ~80 s |
| Épico | Morado | 4 % | ~150 s |
| Legendario | Dorado | 1.2 % | ~300 s |
| Mítico | Rojo/rosa | 0.25 % | ~600 s |
| Secreto | Arcoíris/negro | 0.05 % | ~1,200 s |

### Lista inicial: 21 Crunchis en 5 sets

| Crunchi | Rareza | $/s | Precio | Set | Idea visual |
|---|---|---|---|---|---|
| Crunchito Bobo | Común | 1 | $20 | Caras Locas | Sonrisa torcida y bizco |
| Mochilín | Común | 2 | $45 | Aventureros | Mochila diminuta |
| Pepito Pepita | Común | 3 | $75 | Huerto | Semillas como pecas |
| Manzana Sudada | Poco común | 8 | $300 | Caras Locas | Gotas de sudor, cara de pánico |
| Don Gusano | Poco común | 12 | $480 | Huerto | Un gusano que le sale como bigote |
| Taladrín | Poco común | 18 | $750 | Obreros | Un taladro en la cabeza |
| Casco Crunch | Raro | 45 | $3.5K | Obreros | Casco naranja de obra |
| Explorador Pip | Raro | 70 | $5.6K | Aventureros | Sombrero de pescador amarillo |
| Sonrisota | Raro | 100 | $8K | Caras Locas | Una sonrisa de 40 dientes |
| Catapultín | Épico | 250 | $37.5K | Obreros | Sentado en una catapulta de madera |
| Globo Crunch | Épico | 400 | $60K | Aventureros | Flota con una canasta de globo |
| Chispitas | Épico | 600 | $90K | Explosivos | Mecha encendida en vez de rabito |
| Manzana Cohete | Legendario | 1.5K | $450K | Explosivos | Montada en un cohete con fuego |
| Rey Semilla | Legendario | 2.5K | $750K | Huerto | Corona de hojas y capa |
| Gigantón | Legendario | 4K | $1.2M | Caras Locas | El triple de tamaño, cara de asombro |
| Ojos Láser | Mítico | 10K | $6M | Explosivos | Rayos verdes de los ojos |
| Mecha-Crunch | Mítico | 16K | $9.6M | Obreros | Armadura robótica |
| Ninja Verde | Mítico | 25K | $15M | Aventureros | Bandana y humo al moverse |
| Manzana Nuclear | Secreto | 75K | $90M | Explosivos | Brillo verde radiactivo, hongo de confeti |
| Corazón de Oro | Secreto | 120K | $150M | Huerto | Manzana mordida con un corazón dorado |
| Crunch Omega | Secreto | 200K | $250M | Caras Locas | Ojos en espiral, aura cósmica |

**Sets:** Caras Locas (5), Huerto (4), Obreros (4), Aventureros (4), Explosivos (4). Completar un set da **+3 % de ingreso permanente**, un título y un cosmético.

Agregar un Crunchi nuevo es **agregar una fila** en `Config/Crunchis.luau` (id, nombre, rareza, $/s, precio, set, modelo). Nada más.

### Mutaciones (variante aleatoria al aparecer)

| Mutación | Multiplicador de $/s y precio | Probabilidad |
|---|---|---|
| Normal | ×1 | resto |
| Dorado | ×2 | 4 % |
| Diamante | ×3 | 1 % |
| Arcoíris | ×5 | 0.2 % |
| Radiactivo (solo en eventos) | ×4 | según evento |

Las mutaciones son el objetivo del **mes**: hay un Índice separado por mutación ("Índice Dorado", "Índice Diamante"…).

---

## 5. Robos y defensa (con protección para todos)

### Cómo se roba
1. Entras a una base ajena (la puerta está abierta si el dueño no puso el cerrojo).
2. Mantienes pulsado sobre un Crunchi durante 1.5 s y lo cargas sobre la cabeza. Todos lo ven y suena una alarma en la base de la víctima.
3. Caminas más lento (80 % de velocidad) hasta **tu** base. Si llegas y tienes un pedestal libre, el Crunchi es tuyo.
4. Lo pierdes si el dueño te da un **periodicazo** (empujón cartoon, sin daño), si un Agente Escáner te atrapa, si mueres, si te desconectas o si pasan 60 s. En todos esos casos el Crunchi **vuelve a su dueño**.

### Cómo se defiende
- **Cerrojo:** un botón dentro de tu base cierra la puerta con un campo de fuerza por 60 s (+5 s por rebirth, máximo 120 s). Para volver a cerrarlo tienes que regresar a pulsarlo, lo que premia estar atento.
- **Periódico enrollado:** todos lo tienen gratis. Solo empuja a quien carga un Crunchi robado o a intrusos dentro de tu base, así que no sirve para molestar a cualquiera.

### Protecciones obligatorias (iguales para todos, no se compran)

| Protección | Regla | Para qué |
|---|---|---|
| Escudo de entrada | Base inrobable los primeros **3 min** de cada sesión | Nadie llega y lo pierde todo al instante |
| Protección de novato | Base inrobable durante los primeros **15 min** de tiempo total de juego | El nuevo aprende sin frustrarse |
| Límite por víctima | Máximo **2 robos cada 10 min** a una misma base; después, escudo automático de 5 min | Evita el "farmeo" de una víctima |
| Cooldown por par | Un mismo ladrón no puede robar a la misma víctima más de 1 vez cada 5 min | Reparte la presión |
| Protección por nivel | No puedes robar a alguien con **2 o más rebirths menos** que tú | Los veteranos no cazan novatos |
| Bóveda | 1 pedestal inrobable (+1 en Rebirth 3 y Rebirth 6) | Tu mejor Crunchi siempre está a salvo |
| Depósito | Los Crunchis guardados (no producen) no se pueden robar | Opción segura |
| Revancha | Tras un robo exitoso, el cerrojo del ladrón se recarga 45 s | La víctima tiene una ventana para recuperarlo |
| Base offline | Tu base solo existe mientras estás en el servidor | **Nunca pierdes nada estando desconectado** |

**Ningún producto de pago** aumenta la velocidad, el tiempo de cerrojo, el poder del periódico, las bóvedas ni la capacidad de robo.

---

## 6. Progresión

### Sistemas de progreso

| Sistema | Qué es | Loop |
|---|---|---|
| **Pedestales** | Empiezas con 8 y ganas +1 por rebirth (máximo 16 gratis). El pase "Piso Extra" da +4. | Medio |
| **Rebirth** | Reinicia el dinero y los Crunchis, pero da un **multiplicador permanente de +0.5×** y desbloquea zonas. Conservas 1 Crunchi a elección (tu "Mejor Amigo"). | Largo |
| **Índice** | Colección de 21 Crunchis con siluetas negras para los que faltan. Guarda la **primera vez** que tuviste cada uno. | Largo |
| **Sets** | Completar un set da +3 % de ingreso permanente, un título y un cosmético. | Medio/largo |
| **Hitos del Índice** | Al 25/50/75/100 %: aura, estela, título "Maestro Crunch" y skin dorada de Crunchito Bobo | Largo |
| **Mutaciones** | Índice separado por mutación | Mes |
| **Misiones diarias** | 3 al día (sacadas de un pool) + 1 cambio gratis. Completar las 3 da una Canasta gratis. | Medio |
| **Misiones semanales** | 3 más grandes | Semana |
| **Login** | Calendario de 7 días de conexión **no consecutivos** (no se reinicia nunca). El día 7 da una Canasta Épica, y se ve desde el día 1. | Día |
| **Racha suave** | +2 % de ingreso por día seguido (máximo +10 %). Perder un día **resta un paso**, no la borra. | Día |
| **Ganancias offline** | Al volver cobras el 20 % de tu ingreso base por el tiempo fuera, con tope de 3 h (VIP: 6 h) | Día |
| **Macetero** (Fase 2) | Plantas una semilla (de canastas o misiones) y crece en tiempo real, incluso offline, en 30 min–8 h, hasta dar un Crunchi con más probabilidad de mutación | Gancho para volver |
| **Pase Crunch** (temporada) | 30 niveles por temporada, con camino gratis y premium | Mes |
| **Zonas** | Cinta Dorada (Rebirth 3), Almacén FrutaMax (Rebirth 1), Cinta Celestial (Rebirth 6) | Largo |

### Tabla de rebirths (se define en `Config/Rebirths.luau`)

| Rebirth | Costo | Requisito (Crunchis en tu base) | Recompensa |
|---|---|---|---|
| 1 | $1M | 1 Legendario | +0.5×, +1 pedestal, desbloquea el Almacén FrutaMax |
| 2 | $5M | 2 Legendarios | +0.5×, +1 pedestal |
| 3 | $25M | 1 Mítico | +0.5×, +1 pedestal, **Cinta Dorada**, +1 bóveda |
| 4 | $100M | 2 Míticos | +0.5×, +1 pedestal |
| 5 | $400M | 3 Míticos | +0.5×, +1 pedestal, Canasta Celestial |
| 6 | $1.5B | 1 Secreto | +0.5×, +1 pedestal, **Cinta Celestial**, +1 bóveda |
| 7 | $6B | 2 Secretos | +0.5×, +1 pedestal |
| 8+ | ×4 del anterior | 3 Secretos | +0.5×, +1 pedestal (hasta 16) |

Los rebirths 8 en adelante son el "techo" temporal. Cada actualización agrega Crunchis, zonas y rebirths nuevos.

### Qué persigue el jugador

| Momento | Metas | Gancho para volver |
|---|---|---|
| **Primera hora** | Llenar la base con Raros y Épicos, primer Legendario (comprado, robado o de canasta), primer robo, primeras 3 misiones. Terminar **cerca del Rebirth 1** (barra al 80–95 %). | "Me falta poco para el Rebirth", más las ganancias offline |
| **Primer día** (2–3 sesiones) | Rebirth 1–2, primer set completo (Caras Locas o Huerto), ver un Mítico en la cinta, conocer el Almacén FrutaMax, calendario día 1 | Misiones nuevas mañana, macetero creciendo, recompensa del día 2 |
| **Primera semana** | Rebirth 3–5, Cinta Dorada, primer Mítico propio, 3–4 sets, Índice al 60 %, calendario día 7 (Canasta Épica), nivel 8–10 del pase | Primer Secreto, eventos de fin de semana |
| **Primer mes** | Rebirth 7+, Cinta Celestial, Índice al 100 %, empezar el Índice Dorado, completar el camino gratis del pase, entrar a la tabla de clasificación, Crunchis del evento | Nueva temporada, nuevos Crunchis cada semana |

---

## 7. Economía

**Una sola moneda: el dinero ($).** No hay moneda premium intermedia: lo que cuesta Robux se muestra en Robux, y lo que cuesta dinero, en dinero.

### Fórmula de ingreso

```
ingreso/s = Σ (ingreso base del Crunchi × multiplicador de mutación)          ← por cada pedestal
          × (1 + 0.5·rebirths + sets + racha + amigos + grupo 0.05 + Premium 0.10)  ← bonus aditivos
          × (2 si tiene el pase x2 Dinero)                                     ← multiplicadores
          × (2 si tiene un boost x2 temporal activo)
```

- Los bonus del segundo grupo **se suman** entre sí, para que no se disparen. Los del tercer grupo multiplican.
- Amigos en el servidor: +10 % por amigo, máximo +30 %. Estar en el grupo de Roblox del juego: +5 %.
- Las recompensas que se escalan "en minutos de ingreso" usan el **ingreso base sin boosts temporales**, para que no se pueda hacer trampa activando un x2 justo antes de cobrar.

### Fuentes de dinero (entradas)

| Fuente | Cantidad | Nota |
|---|---|---|
| Crunchis en pedestales | Principal (~85 %) | Se acumula en el pedestal hasta que lo cobras |
| Misiones diarias y semanales | 5 min de ingreso cada diaria; 30 min cada semanal | Escalado al jugador |
| Calendario de login | 2–10 min de ingreso + canastas | |
| Ganancias offline | 20 % del ingreso base, tope de 3 h | |
| Vender un Crunchi | 50 % de su precio | Salida de emergencia |
| Recompensas de set e Índice | Bonus porcentual, no dinero directo | No infla |
| Eventos cooperativos | Monedas que sueltan los agentes | Escalado al jugador |

### Gastos de dinero (salidas)

| Gasto | Nota |
|---|---|
| Comprar Crunchis en la cinta | Principal: precios exponenciales por rareza |
| Canastas | Madera $1K, Hierro $50K, Dorada $2M, Celestial $500M (valor esperado del 40–70 % del precio: pagas por la **oportunidad** de rareza) |
| Rebirth | El gran reinicio: lleva el dinero a 0 |
| Cosméticos con dinero | Auras y estelas básicas compradas con $, para que los jugadores gratis también tengan estatus |
| Cambios extra de misión | Precio escalado |

### Canastas (compradas con dinero del juego; las probabilidades siempre visibles)

| Canasta | Precio | Común | Poco común | Raro | Épico | Legendario | Mítico | Secreto |
|---|---|---|---|---|---|---|---|---|
| Madera | $1K | 70 % | 25 % | 5 % | – | – | – | – |
| Hierro | $50K | – | 50 % | 35 % | 13 % | 2 % | – | – |
| Dorada | $2M | – | – | 45 % | 38 % | 14 % | 2.8 % | 0.2 % |
| Celestial (R5) | $500M | – | – | – | 50 % | 35 % | 13 % | 2 % |

### Por qué no se rompe
1. **Precios exponenciales y pagos crecientes:** cada rareza cuesta unas 10–12 veces más pero solo produce 5–6 veces más, así que subir de tier siempre cuesta un poco más de tiempo.
2. **La rareza está limitada por la cinta,** no solo por el dinero: con 8 jugadores sale un Legendario cada 4 minutos en todo el servidor. Eso crea competencia, robos y valor.
3. **El rebirth es el gran sumidero:** devuelve el dinero a 0 cada cierto tiempo.
4. **Recompensas medidas en tiempo, no en cifras fijas:** nunca quedan obsoletas ni rompen el inicio del juego.
5. **No hay intercambio de dinero entre jugadores.** El robo transfiere un Crunchi, no crea valor. Límites para evitar que se usen cuentas alternativas para pasarse Crunchis.
6. Las ventas devuelven solo el 50 %.
7. AnalyticsService registra cada fuente y cada gasto para detectar inflación con datos reales.

---

## 8. Monetización

### Principio
Un jugador gratis puede llegar a **todo** el contenido del Índice, a todas las zonas y a todos los rebirths. Pagar **acelera, da comodidad, personaliza o da estatus**. Los jugadores gratis son el público que hace valiosos los cosméticos y generan Premium Payouts con su tiempo de juego.

### 8.1 Premium Payouts
- Beneficio pequeño para Premium: **+10 % de dinero** e ícono ⭐ junto al nombre.
- La retención es ingreso: cada minuto que juega un usuario Premium suma a los pagos. Todo lo de las secciones 3 y 6 es también monetización.

### 8.2 Game Passes (compra única)

| Pase | Precio | Qué da | Justificación |
|---|---|---|---|
| **VIP** | 199 R$ | Etiqueta [VIP] en el chat, nombre dorado, Terraza VIP (zona social con estatua de tu mejor Crunchi), aura exclusiva, +1 cambio de misión diario, tope offline de 6 h | Estatus y comodidad. Precio medio accesible. |
| **x2 Dinero** | 399 R$ | Ingreso ×2 permanente | El pase más vendido del género. Acelera sin bloquear nada. |
| **Auto-Cobro** | 149 R$ | El dinero de los pedestales va directo a tu saldo | Pura comodidad (sobre todo en celular) |
| **Piso Extra** | 299 R$ | +4 pedestales en un balcón | Más capacidad, que los gratis alcanzan con rebirths |
| **Depósito XL** | 99 R$ | Depósito de 10 → 40 espacios | Inventario, comodidad |
| **Apertura Triple** | 99 R$ | Abrir 3 canastas a la vez (pagando con $) | Ahorra tiempo |
| **Estela Arcoíris** | 99 R$ | Estela cosmética permanente | Estatus visible |
| **Aura Llama Verde** | 149 R$ | Aura cosmética permanente | Estatus visible |

### 8.3 Developer Products (compras repetibles)

**Paquetes de dinero** (con anclaje de precio). La UI muestra **la cifra exacta** en $ antes de comprar.

| Paquete | Precio | Cantidad | Valor por R$ | Etiqueta |
|---|---|---|---|---|
| Puñado | 29 R$ | 10 min de tu ingreso (mínimo $1K) | 1× | |
| Canasta | 99 R$ | 45 min de tu ingreso | 1.3× | |
| Carretilla | 299 R$ | 3 h de tu ingreso | 1.7× | "Más popular" |
| Camión | 799 R$ | 10 h de tu ingreso | 2.2× | **"Mejor valor"** |

**Bonus de primera compra:** la primera compra de dinero entrega **el doble**, una sola vez y avisado claramente.

**Otros productos:**

| Producto | Precio | Qué da |
|---|---|---|
| Boost x2 Dinero (30 min) | 49 R$ | Se suma al tiempo restante |
| Suerte del Servidor (15 min) | 79 R$ | Duplica la probabilidad de rarezas altas en la cinta **para todo el servidor**, con anuncio "¡Gracias, @jugador!". Social y positivo. |
| Duplicar ganancias offline | 25 R$ | Solo aparece en la pantalla de bienvenida, una vez por regreso |
| Canasta Sorpresa | 149 R$ | Épico o superior garantizado: Épico 70 % · Legendario 24 % · Mítico 5 % · Secreto 1 %. **Probabilidades visibles**. Se oculta a quien `PolicyService` restrinja (`ArePaidRandomItemsRestricted`). Todo lo que contiene se consigue gratis en la cinta. |
| Saltar nivel del pase | 29 R$ | +1 nivel del Pase Crunch |
| Pase Crunch Premium | 299 R$ | Camino premium de la temporada actual |
| **Pack Inicial** (una sola compra) | 99 R$ | 1 h de tu ingreso (mínimo $50K), una **Manzana Cohete (Legendario)**, boost x2 de 1 h y el título "Crunchero". Valor percibido de ~400 R$. |

**Pack Inicial:** se ofrece **una vez**, a los 7 minutos de juego, como tarjeta lateral pequeña que se cierra con un toque. Después queda en la tienda **sin límite de tiempo** (no hay "¡solo 24 h!").

**Servidores privados:** 99 R$ al mes (se configura en Studio).

**Opcional (Fase 3+):**
- **Regalos:** comprar VIP, x2 Dinero o un boost para un amigo que esté en el mismo servidor.
- **Suscripción "Club Crunch"** (si Roblox la tiene disponible para la cuenta): canasta diaria y cosmético mensual. Solo cosméticos y comodidad.

### 8.4 Cosméticos de estatus (visibles para otros)
Auras, estelas, títulos sobre la cabeza, skins de pedestal, efecto de llegada del Crunchi a tu base y "Crunchi Mascota" (tu mejor Crunchi te sigue en miniatura). Hay una mezcla de cosméticos **con dinero del juego** (para que los gratis tengan estatus) y con Robux.

### 8.5 Pase de temporada: "Pase Crunch"
- 30 niveles, temporadas de 4–5 semanas, 500 XP por nivel.
- XP: 100 por misión diaria (+100 por completar las 3), 500 por misión semanal y 50 por cada 10 min de juego (máximo 300 al día).
- **Camino gratis:** dinero, canastas, un Crunchi skin de la temporada y títulos. Un jugador que juega 4–5 días por semana lo completa.
- **Camino premium (299 R$):** auras, estelas, efectos de llegada, skins de Crunchis (mismas estadísticas, otro aspecto) y más canastas.
- **Ningún Crunchi del Índice es exclusivo de pago.** Los skins de pago son solo visuales.

### 8.6 Psicología de consumo que sí usamos (y cómo)

| Técnica | Implementación |
|---|---|
| Anclaje de precio | Los 4 paquetes lado a lado; "Mejor valor" en el grande y "Más popular" en el tercero |
| Bonus de primera compra | Dinero doble la primera vez, una sola vez |
| Probar antes de comprar | Boost x2 gratis de 5 min a los 3 minutos. Al terminar, el ícono del boost muestra "x2 para siempre", sin pop-up. |
| Prueba social | Auras, estelas y Crunchis raros se ven en las bases y encima de los jugadores. Anuncios de Míticos y Secretos. "Suerte del Servidor" agradece al comprador. |
| Momento correcto | Si intentas comprar un Crunchi y te falta menos del 30 %, el aviso "Te faltan $X" incluye un botón pequeño "Conseguir $". Nunca un pop-up. |
| Progreso de colección | Barras de sets e Índice siempre visibles, con siluetas |
| Recompensa satisfactoria | Toda compra con Robux tiene animación, sonido, confeti y un anuncio opcional |

### 8.7 Líneas rojas (implementadas en código, no solo prometidas)

| Regla | Cómo se garantiza |
|---|---|
| Probabilidades visibles | Toda canasta, con dinero o con Robux, muestra la tabla **antes** del botón de compra. La tabla se genera de la misma `Config` que usa el servidor, así que no pueden diferir. |
| Productos aleatorios de pago según país | `PolicyService:GetPolicyInfoForPlayerAsync` → se oculta la Canasta Sorpresa si `ArePaidRandomItemsRestricted` |
| Precios claros | Siempre en R$ con el ícono oficial. Los paquetes de dinero muestran la cifra exacta. |
| Sin escasez falsa | Un "limitado" tiene fecha de fin real guardada en `Config/Eventos.luau` y se cumple |
| Máximo 1 oferta automática por sesión | El servidor lleva la cuenta. Si se cierra, no vuelve a aparecer en esa sesión. |
| Nada de pop-ups que interrumpan | Las ofertas son tarjetas laterales o botones en la tienda, nunca modales durante un robo o una compra |
| No castigar para vender | La racha no se pierde entera, no hay "pierdes si no pagas", nada de pago cuando te roban |
| Robos justos | Sección 5: ninguna protección se compra |
| Datos y pagos | Nunca se piden datos personales ni se envía a pagos fuera de Roblox |
| Compras seguras | `ProcessReceipt` idempotente, con los recibos procesados guardados en el perfil del jugador |

### 8.8 Métricas de negocio a vigilar
Conversión (% de pagadores), ARPDAU, ARPPU, uso del primer paquete comprado, tiempo hasta la primera compra y retención D1/D7/D30 de pagadores frente a no pagadores (**si los gratis se van, algo está mal**).

---

## 9. Social

- **Bases a la vista:** tus Crunchis raros brillan y cualquiera puede verlos. Es la vitrina natural.
- **Anuncios del servidor:** "¡@Ana consiguió un SECRETO: Crunch Omega!".
- **Bonus por amigos:** +10 % de ingreso por amigo en el mismo servidor (máximo +30 %).
- **Clasificaciones:** en el servidor (leaderstats: Dinero/s y Rebirths) y globales (OrderedDataStore: mejor ingreso, robos exitosos, % del Índice), con tableros físicos en la plaza.
- **Terraza VIP y plaza central:** puntos de encuentro con emotes.
- **Eventos cooperativos:** la "Redada FrutaMax" se defiende entre todos, así que el servidor coopera.
- **Intercambio (post-lanzamiento):** con doble confirmación, control de `PolicyService` e historial. Se deja para después porque tiene alto riesgo de estafas.

---

## 10. Agentes Escáner, eventos y live-ops

| Elemento | Descripción | Fase |
|---|---|---|
| **Patrulla** | 3 agentes recorren la avenida. Si ven a alguien cargando un Crunchi robado, lo persiguen, y si lo tocan el Crunchi vuelve a su dueño. Disparan etiquetas pegajosas que frenan 2 s. | 2 |
| **Almacén FrutaMax** | PvE: entras al edificio de FrutaMax, esquivas láseres de escáner y sacas un Crunchi de su bodega (probabilidades visibles). Cooldown de 10 min. **Robar sin víctimas.** | 4 |
| **Redada FrutaMax** | Evento del servidor cada 20–25 min: 6 agentes etiquetan Crunchis (pausan su ingreso) y todos los golpean con el periódico para soltar monedas. | 4 |
| **Lluvia de Manzanas** | Manzanas gigantes caen del cielo y aumentan la probabilidad de mutación por 3 min | 4 |
| **Evento en vivo del creador** | Tú entras al juego a una hora **anunciada** y activas lluvias, suerte y Crunchis especiales para todos | Post-lanzamiento |

Todos los eventos se definen en `Config/Eventos.luau` (id, duración, frecuencia, efectos, fechas reales de inicio y fin). Un evento temporal nuevo es un bloque de configuración más.

---

## 11. Rendimiento (meta: 30+ FPS en Android de 2–3 GB de RAM)

| Área | Decisión |
|---|---|
| Servidor | 8 jugadores (8 bases) |
| Mundo | StreamingEnabled; bases con piezas simples; MeshParts low-poly |
| Crunchis | Una sola malla base para todos (≤ 500 triángulos) + decal de cara 256 px + accesorio ≤ 300 triángulos. Máximo 30 en la cinta a la vez (con pooling). |
| NPCs | Máximo 4 agentes (6 durante una redada), con un solo loop central de IA |
| Efectos | Solo en el cliente, con tope de partículas, y "Modo ahorro" en ajustes |
| UI | Mobile-first: botones de 56 px o más, UIScale, safe areas y sin depender del teclado |
| Red | Remotes con límite de frecuencia; solo se envían cambios; el dinero se replica 4 veces por segundo como máximo |
| Loops | Un loop central por sistema (Heartbeat con acumulador), sin `while wait()` sueltos |

---

## 12. Datos y analítica

- **AnalyticsService:** embudo de onboarding (sección 3), eventos de economía (cada fuente y gasto con su tipo), progresión (rebirths, sets, Índice) y eventos personalizados (robo intentado o exitoso, defensa, oferta vista, cerrada o comprada, en qué pantalla se va el jugador).
- Con estos datos se ajustan: precios, probabilidades, duración del escudo y momento de las ofertas.

---

## 13. Alcance por fase

| Fase | Contenido |
|---|---|
| **0** | Este documento, estructura de Rojo, guía de instalación y documentos de trabajo |
| **1 (MVP)** | Mapa placeholder generado por código, 8 bases, cinta con spawns por rareza, comprar, pedestales, cobro, robo con carga, periódico, cerrojo, escudos y límites, guardado con ProfileStore, HUD móvil y comandos de admin |
| **2** | Índice y sets, rebirth, mutaciones, misiones diarias y semanales, login con racha suave, ganancias offline, depósito, canastas con dinero, patrulla de Agentes Escáner, macetero |
| **3** | Tienda, Game Passes, Developer Products, ProcessReceipt idempotente, Pack Inicial, Pase Crunch, Premium, PolicyService, ofertas contextuales |
| **4** | Optimización (pooling y modo ahorro), pulido de sonidos y efectos, menú de ajustes completo, primer evento (Lluvia de Manzanas + Redada), Almacén FrutaMax |
