# Plan de lanzamiento y descubrimiento

El algoritmo de Roblox recomienda experiencias según su **retención** (D1, D7), el **tiempo de juego por sesión**, el **porcentaje de clics en la miniatura** y la **participación** (volver, invitar a amigos). Todo el diseño apunta a eso. Este documento cubre lo que ve el jugador **antes** de entrar.

---

## 1. Nombre

**Principal:** **Crunch Heist**

Alternativas para pruebas A/B o si el nombre ya existe (búscalo en Roblox antes de publicar):

| Nombre | Por qué |
|---|---|
| Crunch Heist | Corto, marca propia, fácil de recordar |
| Steal the Crunchis | Usa el patrón "Steal a…" que la gente busca en el género |
| Crunchi Robbers | Directo; "robbers" se entiende en muchos idiomas |
| Apple Heist Mayhem | Más descriptivo en inglés |
| Roba un Crunchi | Para el mercado hispano, como título traducido |

**Formato del título en la página del juego** (Roblox permite traducir el título por idioma):
- Inglés: `Crunch Heist 🍏`
- Español: `Crunch Heist: ¡Roba las Manzanas! 🍏`
- En cada actualización se agrega una etiqueta al inicio y se quita a los pocos días: `[🚀 UPDATE] Crunch Heist 🍏`, `[🌧️ EVENTO] …`

> No uses palabras que no correspondan ("FREE ROBUX", "ADMIN") ni nombres de otros juegos o marcas. Roblox lo castiga y confunde a los jugadores.

---

## 2. Descripción

### Español
```
🍏 ¡Compra, colecciona y ROBA manzanas con caras ridículas!

🛒 Compra Crunchis en la cinta de Villa Crunch
💰 Ponlos en tu base y gana dinero cada segundo
🦹 Entra a otras bases y roba sus Crunchis más raros
🛡️ Defiende tu base con el cerrojo y el periódico
🔎 ¡Cuidado con los Agentes Escáner de FrutaMax!
📖 Completa el Índice: de Común a SECRETO
🔁 Haz Rebirth para multiplicar tus ganancias

🎁 Recompensas diarias · Misiones · Eventos cada semana
👥 ¡Juega con amigos y gana +10 % por cada uno!

👍 ¡Dale like y ⭐ favorito para enterarte de las actualizaciones!
```

### English
```
🍏 Buy, collect and STEAL apples with ridiculous faces!

🛒 Buy Crunchis from the Crunch Town conveyor
💰 Put them in your base to earn cash every second
🦹 Sneak into other bases and steal their rarest Crunchis
🛡️ Defend your base with the lock and a rolled-up newspaper
🔎 Watch out for the FrutaMax Scanner Agents!
📖 Complete the Index: from Common to SECRET
🔁 Rebirth to multiply your earnings

🎁 Daily rewards · Quests · Weekly events
👥 Play with friends for +10% cash each!

👍 Like and ⭐ favorite to get notified about updates!
```

---

## 3. Ícono del juego (512×512)

Reglas: **un solo personaje grande**, contraste alto y **nada de texto** (o una sola palabra). Tiene que entenderse en tamaño miniatura (unos 150 px en celular).

| Concepto | Descripción |
|---|---|
| **A. "¡Atrapado!"** (recomendado) | Primer plano de un Crunchi con **ojos gigantes de pánico** abrazando una bolsa de dinero "$". Fondo verde brillante con rayos. Una línea láser roja del escáner le cruza la cara. |
| B. "El Secreto" | Crunch Omega con ojos en espiral y aura arcoíris sobre fondo negro. Transmite "hay algo rarísimo que conseguir". |
| C. "Ladrón" | Crunchi con antifaz de ladrón (dibujado) y sonrisa pícara, cargando otro Crunchi dorado |

Haz 2 versiones y usa las **pruebas A/B de ícono y miniaturas** del Creator Dashboard (si están disponibles para tu experiencia) durante 1–2 semanas. Quédate con la que tenga más clics **y** más tiempo de juego.

---

## 4. Miniaturas (1920×1080, 3 a 5)

Deben mostrar **cosas reales del juego** (Roblox castiga las miniaturas engañosas).

| # | Concepto | Texto sobre la imagen |
|---|---|---|
| 1 | **Robo en acción:** un jugador corre con un Crunchi Legendario brillante sobre la cabeza, el dueño lo persigue con el periódico y un Agente Escáner apunta su láser. Explosión de confeti de fondo. | "¡ROBA MANZANAS!" |
| 2 | **Escalera de rarezas:** 7 Crunchis en fila de Común a Secreto, el último como silueta con "?" | "¿CONSEGUIRÁS EL SECRETO?" |
| 3 | **Base épica:** una base llena de Crunchis dorados y arcoíris con números "$1.2M/s" flotando | "HAZTE MILLONARIO" |
| 4 | **Evento:** manzanas gigantes cayendo sobre la ciudad | "¡EVENTO!" (se cambia en cada evento) |
| 5 | **Amigos:** 4 jugadores defendiendo una base juntos | "JUEGA CON AMIGOS" |

Tips: personajes grandes, poco texto (3–4 palabras en letras gruesas) y colores saturados. Revisa cómo se ve en tamaño celular antes de subir.

---

## 5. Antes de publicar (checklist)

- [ ] Probado con 5–10 amigos en un servidor real (no solo en Studio)
- [ ] Cuestionario de **Content Maturity** llenado con honestidad (tono cartoon; el periodicazo es "violencia cartoon leve")
- [ ] Género de la experiencia configurado, y dispositivos: teléfono, tablet y computadora (consola más adelante)
- [ ] Título y descripción traducidos (ES/EN) en Localization
- [ ] Ícono, 3+ miniaturas, badges, Game Passes y productos creados y probados
- [ ] Servidores privados activados
- [ ] Tamaño de servidor: 8
- [ ] Grupo de Roblox creado para la comunidad (el juego se puede publicar bajo el grupo para compartir ingresos más adelante)
- [ ] Revisado el **Creator Dashboard → Analytics** para ver que llegan los eventos

---

## 6. Metas para el lanzamiento suave (primeras 2 semanas)

Son referencias aproximadas del género, para saber si vamos bien:

| Métrica | Meta mínima | Buena |
|---|---|---|
| Retención D1 | 20 % | 30 %+ |
| Retención D7 | 6 % | 10 %+ |
| Sesión promedio | 12 min | 20 min+ |
| Onboarding: compró su primer Crunchi | 90 % | 97 %+ |
| Conversión a pagador | 1 % | 3 %+ |

Si el D1 es bajo, primero se revisan el embudo de onboarding y los primeros 5 minutos, no la tienda.

---

## 7. Plan de actualizaciones y eventos (primeras semanas)

**Ritmo:** una actualización **cada semana, el sábado temprano** (los fines de semana hay más jugadores) y un evento pequeño a mitad de semana. Cada actualización = nuevas filas en `Config/`, no reprogramar.

| Semana | Actualización | Evento |
|---|---|---|
| **0** (prueba cerrada) | v0.9: correcciones con amigos | – |
| **1** (lanzamiento) | v1.0: juego base (Fases 1–4) | **Lluvia de Manzanas** el fin de semana: más probabilidad de mutación Dorada |
| **2** | +3 Crunchis (nuevo set **"Deportistas"**: Crunchi Portero, Balón Crunch, Campeón Dorado) y tablas de clasificación con premios cosméticos semanales | **Hora Dorada** miércoles |
| **3** | **Almacén FrutaMax** mejorado (2.º piso más difícil) y mutación **Radiactiva** | **Noche Nuclear**: solo en ese evento aparece la mutación Radiactiva, con fechas reales |
| **4** | Fin de la Temporada 1 del Pase Crunch → **Temporada 2** con cosméticos nuevos, Rebirths 9–10 | **Redada FrutaMax Gigante** (jefe cooperativo) |
| **5** | Intercambio seguro entre jugadores (si las métricas lo justifican) o Macetero 2.0 | Evento en vivo del creador (hora anunciada con 3 días de anticipación) |
| **6** | +4 Crunchis de temporada según el calendario real (Halloween, Navidad…) | Evento de temporada |

**Eventos de temporada** (con fechas reales, nada de "limitado" falso): Halloween (Crunchis Zombi, calabazas), Navidad (Crunchis con gorro y nieve), Año Nuevo, San Valentín, Pascua (canastas de huevo) y vacaciones de verano. Los Crunchis de evento van en un **Índice de eventos aparte**, así el Índice principal siempre se puede completar.

**Evento en vivo del creador:** anuncias la hora en el grupo de Roblox y en tus redes. Entras al juego y, con los comandos de admin, activas lluvias, suerte x3 y un Crunchi especial para todos los presentes. Genera picos de jugadores y mucho contenido para videos.

---

## 8. Promoción

- **Videos cortos** (YouTube Shorts, TikTok): momentos caóticos reales del juego, como robos fallidos en el último segundo, un Secreto apareciendo o una redada. Ya tienes experiencia con este tipo de videos.
- **Anuncios de Roblox** (Sponsored Experiences / Ads Manager): empieza con presupuesto pequeño después de validar retención. Anunciar un juego que no retiene es tirar Robux.
- **Grupo de Roblox:** anuncios de actualizaciones y bonus por unirse al grupo (+5 % de dinero, verificado con `IsInGroup`).
- **Redes externas:** solo las que Roblox permite enlazar en la página de la experiencia, y respetando sus reglas por edad.
