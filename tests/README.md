# Pruebas unitarias

Prueban la lógica que no depende de Roblox (`src/shared/Util`, `src/shared/Logica`) y que la
configuración (`src/shared/Config`) sea válida y esté balanceada. No se sincronizan con Studio.

## Cómo ejecutarlas

Necesitas el intérprete `luau` (https://github.com/luau-lang/luau/releases) con soporte para
un "preludio" (definición de `Color3` y `Vector3` falsos antes de cargar los módulos). El
intérprete oficial no tiene esa opción; los agentes que trabajan en este repo usan una copia
con un pequeño parche que lee el archivo indicado en la variable `LUAU_PRELUDE`:

```sh
LUAU_PRELUDE=tests/preludio.luau luau tests/ejecutar.luau
```

Resultado esperado: `N pruebas pasaron, 0 fallaron.`

## Qué agregar

Cada vez que agregues lógica pura (fórmulas, sorteos, cálculos de recompensas), agrega sus
pruebas en `tests/ejecutar.luau`. Si cambias números de balance, las pruebas de la sección
"Balance" avisan si rompiste la progresión (p. ej. un Épico que se paga más rápido que un Raro).
