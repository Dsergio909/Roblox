# Guía de instalación: de GitHub a Roblox Studio

Esta guía se hace **una sola vez**. Al final hay un "flujo diario" de 4 pasos para cada vez que haya código nuevo.

**Tiempo estimado:** 30–45 minutos.
**Sistema:** Windows 10/11 (al final hay notas para Mac).

## Cómo funciona todo esto

```
 GitHub (la nube)             Tu PC                                 Roblox Studio
┌───────────────┐  Pull  ┌──────────────────────┐  rojo serve  ┌──────────────────────┐
│ dsergio909/   │ ─────► │ Carpeta del proyecto │ ───────────► │ Los scripts aparecen │
│ roblox        │        │ (archivos .luau)     │  (en vivo)   │ solos en el Explorer │
└───────────────┘        └──────────────────────┘              └──────────────────────┘
   Claude sube             GitHub Desktop                        Plugin de Rojo
   el código aquí          los descarga                          los recibe
```

- **Código** (scripts `.luau`): vive en GitHub. Rojo lo copia a Studio.
- **Todo lo demás** (modelos 3D, mapa, imágenes, sonidos): vive en tu lugar de Roblox (el archivo que guardas o publicas desde Studio).

> ⚠️ **Regla importante:** no edites los scripts sincronizados dentro de Studio. Rojo los sobrescribe con la versión de los archivos. Si quieres cambiar algo del código, dímelo o edita los archivos `.luau` en la carpeta del proyecto.

---

## Parte 1. Instalar los programas

### Paso 1. Roblox Studio
1. Entra a <https://create.roblox.com> e inicia sesión con tu cuenta de Roblox.
2. Pulsa **"Start Creating"** (o "Empezar a crear") y descarga Roblox Studio.
3. Instálalo y ábrelo una vez para que termine de configurarse. Luego ciérralo.

### Paso 2. GitHub Desktop
1. Descárgalo de <https://desktop.github.com> e instálalo.
2. Ábrelo e inicia sesión con tu cuenta de GitHub (**dsergio909**): `File → Options → Accounts → Sign in`.

### Paso 3. Descargar (clonar) el proyecto
1. En GitHub Desktop: `File → Clone repository…`
2. Pestaña **GitHub.com** → elige **dsergio909/roblox**.
3. En **Local path** deja algo como `C:\Users\TU_USUARIO\Documents\GitHub\roblox`. Anota esta ruta porque la usarás después.
4. Pulsa **Clone**.

### Paso 4. Cambiar a la rama de desarrollo
El código nuevo llega primero a una rama de trabajo.

1. Arriba en GitHub Desktop, pulsa **Current Branch**.
2. Elige **`claude/sleepy-cerf-7fxitm`**. Si no aparece, pulsa primero **Fetch origin** y búscala de nuevo.
3. Pulsa **Pull origin** si aparece el botón.

> Más adelante, cuando aceptes (merge) los cambios en `main`, trabajarás en la rama `main`. Te avisaré cuando toque.

### Paso 5. Instalar Rokit (instalador de herramientas)
Rokit instala **Rojo** y las demás herramientas en las versiones exactas que usa el proyecto (están en `rokit.toml`).

1. Pulsa la tecla Windows, escribe **PowerShell** y ábrelo (no hace falta como administrador).
2. Copia y pega este comando y pulsa Enter:
   ```powershell
   Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
   ```
3. Cuando termine, **cierra PowerShell y ábrelo de nuevo** (para que reconozca el comando nuevo).
4. Comprueba que funcionó:
   ```powershell
   rokit --version
   ```
   Debe mostrar algo como `rokit 1.x.x`.

> **Si el comando falla:** entra a <https://github.com/rojo-rbx/rokit/releases/latest>, descarga el `.zip` que dice `windows-x86_64`, descomprímelo y haz **doble clic en `rokit.exe`**. Si Windows muestra "Windows protegió su PC", pulsa "Más información → Ejecutar de todas formas" (solo si lo bajaste de esa página oficial).

### Paso 6. Instalar Rojo, Selene y StyLua (con Rokit)
1. En PowerShell, entra a la carpeta del proyecto (cambia la ruta si usaste otra en el paso 3):
   ```powershell
   cd "$HOME\Documents\GitHub\roblox"
   ```
   > Atajo: en GitHub Desktop, `Repository → Open in Command Prompt` abre una terminal ya ubicada en la carpeta. Para que sea PowerShell: `File → Options → Integrations → Shell → PowerShell`.
2. Instala las herramientas del proyecto:
   ```powershell
   rokit install
   ```
   La primera vez te preguntará si confías en cada herramienta (`rojo-rbx/rojo`, `Kampfkarren/selene`, `JohnnyMorganz/StyLua`). Responde **y** (sí) a cada una.
3. Comprueba:
   ```powershell
   rojo --version
   ```
   Debe decir `Rojo 7.7.0`.

### Paso 7. Instalar el plugin de Rojo en Studio
1. Con **Studio cerrado**, en la misma PowerShell:
   ```powershell
   rojo plugin install
   ```
2. Abre Roblox Studio. En la pestaña **Plugins** (en versiones nuevas de Studio puede estar en la barra superior o en el menú de plugins) debe aparecer **Rojo**.

> El plugin instalado así siempre coincide con la versión de Rojo del proyecto. No instales otro plugin de Rojo desde la tienda, porque las versiones distintas causan errores.

---

## Parte 2. Crear tu lugar (place) en Studio

### Paso 8. Nuevo lugar
1. En Studio: **New → Baseplate**.
2. Publícalo ya en Roblox (lo necesitaremos para guardar datos en la Fase 1):
   `File → Publish to Roblox` → **Create new experience** → nombre: **Crunch Heist** → **Create**.
   - Queda **privado** por defecto: nadie más puede entrar hasta que lo hagas público.

### Paso 9. Configuración inicial
En `Home → Game Settings` (el botón con engranaje):
1. **Security** → activa **Enable Studio Access to API Services**. Esto permite que el guardado de datos (DataStore) funcione mientras pruebas en Studio.
2. Pulsa **Save**.

En el **Explorer** (si no lo ves: pestaña `View → Explorer` y `View → Properties`):
1. Selecciona **Lighting** → en Properties busca **Technology** → elige **Voxel**. Es la iluminación más liviana para celulares de gama baja. Si tu versión de Studio ya no tiene esa opción, salta este paso.

> La cantidad de jugadores por servidor (8) la configuraremos en la Fase 1, cuando haya bases para 8.

---

## Parte 3. Conectar Rojo (lo que harás cada día)

### Paso 10. Iniciar el servidor de Rojo
En PowerShell, dentro de la carpeta del proyecto:
```powershell
rojo serve
```
Verás algo como:
```
Rojo server listening:
  Address: localhost
  Port:    34872
```
**Deja esa ventana abierta** mientras trabajas. Si la cierras, Studio deja de recibir el código.

### Paso 11. Conectar desde Studio
1. En Studio, abre el plugin **Rojo** y pulsa **Connect** (dirección `localhost`, puerto `34872`, que ya vienen puestos).
2. La primera vez puede mostrar una lista de cambios para confirmar: pulsa **Accept**.
3. En el **Explorer** ahora debes ver:
   - `ServerScriptService → Server` (un Script)
   - `ReplicatedStorage → Shared → Config → Juego` (un ModuleScript)
   - `StarterPlayer → StarterPlayerScripts → Client` (un LocalScript)
4. Selecciona **Workspace** y revisa en Properties que **StreamingEnabled** esté ✅ (lo activa Rojo automáticamente).

### Paso 12. Probar
1. Abre la ventana de salida: `View → Output`.
2. Pulsa **Play** (F5).
3. Debes ver:
   - En **Output**: `[Crunch Heist] Servidor v0.0.1 iniciado (Fase 0). Rojo sincroniza correctamente.` y `[Crunch Heist] Cliente v0.0.1 iniciado para TU_NOMBRE.`
   - En la **pantalla**: una etiqueta verde arriba que dice `✔ Rojo conectado · Crunch Heist v0.0.1 · Fase 0`, que desaparece a los 6 segundos.
4. Pulsa **Stop** (Shift+F5).

🎉 Si ves eso, **todo está listo**. Los pasos de prueba detallados están en `docs/PRUEBAS.md`.

---

## Flujo diario (cada vez que haya código nuevo)

1. **GitHub Desktop** → **Fetch origin** → **Pull origin**.
2. **PowerShell** en la carpeta del proyecto → `rojo serve` (déjala abierta).
3. **Studio** → abre tu lugar (`File → Open from Roblox` o desde recientes) → plugin **Rojo → Connect**.
4. **Prueba** con Play (F5) siguiendo `docs/PRUEBAS.md`. Si todo está bien, guarda: `File → Publish to Roblox` (Alt+P).

**Si algo falla:** copia las líneas rojas de la ventana **Output** y pégamelas. Con eso puedo encontrar el problema.

**Si haces modelos en Studio:** se guardan dentro de tu lugar, no en GitHub. Para tener respaldo, haz clic derecho en el modelo → **Save to File…** y guárdalo como `.rbxm` en la carpeta `assets/` del proyecto. Luego súbelo con GitHub Desktop (Commit + Push).

---

## Opcional: VS Code para leer y editar el código con comodidad

1. Instala VS Code: <https://code.visualstudio.com>
2. En GitHub Desktop: `Repository → Open in Visual Studio Code`.
3. VS Code te sugerirá instalar las extensiones recomendadas del proyecto (Luau LSP, StyLua, Selene, Rojo). Acepta.
4. Con eso tienes colores, autocompletado y formateo automático al guardar.

Herramientas de revisión (en PowerShell, dentro de la carpeta del proyecto):
```powershell
selene src          # busca errores comunes en el código
stylua --check src  # revisa el formato
```

---

## Problemas comunes

| Problema | Solución |
|---|---|
| `rokit` / `rojo` "no se reconoce como comando" | Cierra y abre PowerShell. Si sigue, reinicia la PC. |
| `rokit install` da error de descarga o de "rate limit" | Espera unos minutos y reintenta, o ejecuta `rokit authenticate github` y sigue las instrucciones |
| El plugin dice que la versión no coincide | Cierra Studio, ejecuta `rojo plugin install` y abre Studio de nuevo |
| **Connect** no hace nada o da error | Revisa que la ventana de `rojo serve` siga abierta y sin errores. Si Windows pregunta por el firewall, permite "redes privadas". |
| "Port 34872 is already in use" | Ya hay otro `rojo serve` abierto: ciérralo, o usa `rojo serve --port 34873` y cambia el puerto en el plugin |
| Cambié un script en Studio y se borró el cambio | Es lo esperado: Rojo manda. Edita los archivos `.luau` o pídemelo. |
| No sale la etiqueta verde | Mira **Output** por líneas rojas y revisa que exista `StarterPlayerScripts → Client` |
| El guardado de datos no funciona en Studio (Fase 1) | Revisa el Paso 9: *Enable Studio Access to API Services*, y que el lugar esté publicado |

---

## Notas para Mac
- Rokit se instala desde la Terminal con:
  ```sh
  curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
  ```
- Los demás pasos son iguales. En lugar de PowerShell usa la app **Terminal**, y para entrar a la carpeta: `cd ~/Documents/GitHub/roblox`.
