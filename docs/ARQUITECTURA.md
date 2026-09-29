# Arquitectura del código

Guía corta para entender dónde vive cada cosa. El detalle del diseño del juego está en `GAME_DESIGN.md`.

## Carpetas y a dónde van en Roblox

| Carpeta en GitHub | Dónde aparece en Studio | Qué contiene | Quién lo ejecuta |
|---|---|---|---|
| `src/server/` | `ServerScriptService → Server` | Lógica que decide todo: dinero, robos, compras, guardado | Solo el servidor (los jugadores no pueden verlo ni modificarlo) |
| `src/client/` | `StarterPlayer → StarterPlayerScripts → Client` | UI, efectos, sonidos, cámara | El dispositivo de cada jugador |
| `src/shared/` | `ReplicatedStorage → Shared` | Configuración (`Config/`), tipos y utilidades | Ambos |

Los archivos `init.server.luau` e `init.client.luau` son los **únicos puntos de entrada**. Todo lo demás son módulos (`.luau`) que esos puntos cargan en orden.

## Estructura actual

```
src/
├── server/                              (solo el servidor)
│   ├── init.server.luau                 ← arranque: crea los remotos e inicia los servicios en orden
│   ├── Servicios/
│   │   ├── DatosService                 ← ProfileStore: cargar, autoguardar, guardar al salir, migraciones
│   │   ├── AnaliticaService             ← envoltorio de AnalyticsService (embudo, economía, eventos)
│   │   ├── EconomiaService              ← único lugar que suma o resta dinero; bonus y multiplicadores
│   │   ├── MapaService                  ← genera el mapa placeholder (bases, cintas, suelo)
│   │   ├── BaseService                  ← bases: pedestales, cobro, venta, cerrojo, escudos
│   │   ├── CintaService                 ← aparición de Crunchis por rareza y compra validada
│   │   ├── RoboService                  ← robos, protecciones y periódico
│   │   ├── TutorialService              ← pasos del onboarding y estado del tutorial
│   │   └── AdminService                 ← comandos de prueba (solo admins)
│   ├── Util/RedServidor                 ← escuchar remotos con límite de frecuencia y pcall
│   └── Paquetes/ProfileStore            ← librería de terceros (Apache 2.0), sin modificar
├── client/                              (en el dispositivo de cada jugador)
│   ├── init.client.luau                 ← arranque: inicia los controladores en orden
│   ├── Interfaz/Tema, Interfaz/UI       ← colores, medidas y constructores de UI (escala automática)
│   └── Controladores/
│       ├── EstadoCliente                ← estado privado que manda el servidor
│       ├── HudController                ← dinero, ingreso, estado de la base, barra de robo, botones
│       ├── NotificacionController       ← avisos, anuncios, alarma de robo
│       ├── CintaController              ← dibuja y mueve los Crunchis de la cinta; botón Comprar
│       ├── BaseController               ← contadores de cobro, puertas, qué acciones ves en cada Crunchi
│       ├── EfectosController            ← confeti y efectos (con límite)
│       ├── RoboController               ← rayo hacia el ladrón y empujón
│       ├── TutorialController           ← rayo guía y globo de los primeros minutos
│       ├── SonidoController             ← sonidos (IDs en Config/Sonidos)
│       └── AdminController              ← panel 🛠️
└── shared/                              (servidor y cliente)
    ├── Config/                          ← TODO el balance y los datos editables
    ├── Catalogo                         ← la Config indexada y validada
    ├── Red                              ← lista de RemoteEvents y RemoteFunctions
    ├── Tipos                            ← forma de los datos guardados
    ├── ModeloCrunchi                    ← modelo real o placeholder de un Crunchi y su etiqueta
    ├── Logica/                          ← fórmulas puras (probadas fuera de Studio)
    └── Util/                            ← Formato, Azar, Limitador, Senal, Reloj

tests/                                   ← pruebas unitarias (no se sincronizan con Studio)
```

### Cómo se comunican los servicios
- **Señales** (`Util/Senal`): p. ej. `DatosService.JugadorListo`, `CintaService.Comprado`, `RoboService.RoboCompletado`. Un servicio avisa y otros reaccionan, sin depender unos de otros.
- **Registro de bonus:** `EconomiaService.RegistrarBonus(...)`. Rebirths, Premium, grupo, pases y boosts aportan su parte sin que Economía los conozca.
- **Estado privado:** `DatosService.RegistrarEstado("tutorial", fn)`. Cada servicio arma la parte del estado que el cliente necesita.

## Principios (no negociables)

1. **El servidor manda.** El cliente solo *pide* ("quiero comprar este Crunchi") y el servidor decide si se puede. El cliente nunca dice cuánto dinero tiene ni qué salió en una canasta.
2. **Todo Remote se valida:** tipos de los argumentos, distancia del jugador al objeto, cooldowns y límite de frecuencia. Si no cumple, se ignora (y se registra).
3. **Configuración separada de la lógica:** precios, probabilidades, IDs de productos y tiempos están en `src/shared/Config/`. Para balancear el juego se edita solo esa carpeta.
4. **Un loop por sistema:** nada de `while true do wait() end` sueltos. Cada servicio tiene un único ciclo central o reacciona a eventos.
5. **Datos seguros:** ProfileStore con bloqueo de sesión, autoguardado, guardado al salir y en `BindToClose`, y número de versión del esquema para migraciones.
6. **Compras idempotentes:** cada recibo de compra se guarda en el perfil del jugador. Si Roblox reintenta el mismo recibo, no se entrega dos veces.
7. **Efectos solo en el cliente:** el servidor envía "pasó X" y cada cliente decide cuántas partículas mostrar según su modo de calidad.
