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
