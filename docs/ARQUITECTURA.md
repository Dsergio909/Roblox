# Arquitectura del código

Guía corta para entender dónde vive cada cosa. El detalle del diseño del juego está en `GAME_DESIGN.md`.

## Carpetas y a dónde van en Roblox

| Carpeta en GitHub | Dónde aparece en Studio | Qué contiene | Quién lo ejecuta |
|---|---|---|---|
| `src/server/` | `ServerScriptService → Server` | Lógica que decide todo: dinero, robos, compras, guardado | Solo el servidor (los jugadores no pueden verlo ni modificarlo) |
| `src/client/` | `StarterPlayer → StarterPlayerScripts → Client` | UI, efectos, sonidos, cámara | El dispositivo de cada jugador |
| `src/shared/` | `ReplicatedStorage → Shared` | Configuración (`Config/`), tipos y utilidades | Ambos |

Los archivos `init.server.luau` e `init.client.luau` son los **únicos puntos de entrada**. Todo lo demás son módulos (`.luau`) que esos puntos cargan en orden.

## Estructura planeada (se completa en la Fase 1 y siguientes)

```
src/
├── server/
│   ├── init.server.luau        ← arranque: carga los servicios en orden
│   ├── Servicios/
│   │   ├── DatosService         ← ProfileStore: cargar, autoguardar, guardar al salir, migraciones
│   │   ├── EconomiaService      ← único lugar que suma o resta dinero (con registro en Analytics)
│   │   ├── BaseService          ← asignar bases, pedestales, cobro, cerrojo, escudos
│   │   ├── CintaService         ← aparición de Crunchis por rareza (un solo loop)
│   │   ├── RoboService          ← robar, cargar, soltar, límites y protecciones
│   │   ├── CompraService        ← Game Passes, ProcessReceipt idempotente (Fase 3)
│   │   ├── AnaliticaService     ← envoltorio de AnalyticsService de Roblox
│   │   └── AdminService         ← comandos solo para los UserIds de Config.Admin
│   └── Mapa/                    ← genera el mapa placeholder con partes de colores
├── client/
│   ├── init.client.luau        ← arranque: carga los controladores
│   ├── Controladores/           ← HUD, tienda, índice, ajustes, efectos, sonidos
│   └── UI/                      ← componentes reutilizables (botón, tarjeta, barra)
└── shared/
    ├── Config/                  ← TODO el balance: Crunchis, Rarezas, Economía, Robo, Productos, Eventos…
    ├── Red/                     ← definición de todos los RemoteEvents (nombres y tipos)
    └── Util/                    ← formato de números ($1.5M), tablas, etc.
```

## Principios (no negociables)

1. **El servidor manda.** El cliente solo *pide* ("quiero comprar este Crunchi") y el servidor decide si se puede. El cliente nunca dice cuánto dinero tiene ni qué salió en una canasta.
2. **Todo Remote se valida:** tipos de los argumentos, distancia del jugador al objeto, cooldowns y límite de frecuencia. Si no cumple, se ignora (y se registra).
3. **Configuración separada de la lógica:** precios, probabilidades, IDs de productos y tiempos están en `src/shared/Config/`. Para balancear el juego se edita solo esa carpeta.
4. **Un loop por sistema:** nada de `while true do wait() end` sueltos. Cada servicio tiene un único ciclo central o reacciona a eventos.
5. **Datos seguros:** ProfileStore con bloqueo de sesión, autoguardado, guardado al salir y en `BindToClose`, y número de versión del esquema para migraciones.
6. **Compras idempotentes:** cada recibo de compra se guarda en el perfil del jugador. Si Roblox reintenta el mismo recibo, no se entrega dos veces.
7. **Efectos solo en el cliente:** el servidor envía "pasó X" y cada cliente decide cuántas partículas mostrar según su modo de calidad.
