# Suspensión activa regenerativa — cuarto de vehículo eléctrico

Requisitos: MATLAB R2021a o posterior. Sin Simulink. Sin toolboxes obligatorios
(`lqr` se usa si tienen Control System Toolbox; si no, `diseno_lqr.m` resuelve
Riccati por su cuenta).

## Cómo ejecutar

1. Abrir MATLAB y cambiar la carpeta actual (*Current Folder*) a esta carpeta,
   para que encuentre todas las funciones. No hace falta `addpath`.
2. Abrir `main_suspension.m`.
3. Correr el script completo con **F5** (botón *Run*), o sección por sección con
   **Ctrl+Enter**. Si se corre por secciones, hay que hacerlo en orden empezando
   por la primera: cada sección usa variables de las anteriores (`p`, `cam`,
   `sys`, `res`, `ds`), y la primera hace `clear` y `close all`.
4. Resultado:
   - En la ventana de comandos: el balance energético de 4 ruedas (sección 5) y
     la tabla de desempeño en confort y seguridad (sección 6).
   - 6 figuras como pestañas en una sola ventana de Figuras: la validación del
     modelo (desde `modelo_cuarto_vehiculo.m`) y las 5 de la sección 7.

Orden de las secciones de `main_suspension.m`:

| Sección | Módulo | Qué produce |
|---|---|---|
| 0 | Todos | `p` (parámetros) |
| 1 | Ciencia de Datos | `cam` (camino de 1 km) |
| 2 | Mecánica | `sys` (modelo) + figura de validación |
| 3 | Mecatrónica | `ctrl` (LQR) y `res(1:3)` (pasivo, activo, regenerativo) |
| 4 | Ciencia de Datos | `ds` (clasificación del terreno) |
| 5 | Desarrollo Sustentable | `en` y balance energético impreso |
| 6 | Integrador | Tabla `T` de confort y seguridad |
| 7 | Integrador | Gráficas para la presentación |

Notas:
- **Reproducibilidad:** el camino depende de `p.semilla` en `parametros.m`. Con
  la misma semilla todos obtienen los mismos resultados; para probar otro
  camino, cambiarla ahí.
- **Figuras acopladas:** el script activa
  `set(0, 'DefaultFigureWindowStyle', 'docked')`, que dura toda la sesión de
  MATLAB. Para volver a ventanas separadas:
  `set(0, 'DefaultFigureWindowStyle', 'normal')`.
- **Exportar figuras a PNG:** descomentar las líneas de `exportgraphics` al final
  de la sección 7. Las imágenes salen del tamaño de la pestaña, así que conviene
  agrandar la ventana de Figuras antes de exportar.

| Archivo | Responsable | Qué hace |
|---|---|---|
| `parametros.m` | Todos | Único lugar con números físicos |
| `modelo_cuarto_vehiculo.m` | Mecánica | Matrices A, B, E, C, D; discretización con `expm`; frecuencias naturales |
| `diseno_lqr.m` | Mecatrónica | Pesos → Q, R, N → ganancia K; polos de lazo cerrado |
| `simular.m` | Mecatrónica | Lazo de simulación: pasivo / activo / regenerativo (clipped LQR) |
| `generar_camino.m`, `perfil_iso8608.m` | Ciencia de Datos | Camino ISO 8608 de 1 km con 3 tipos de superficie + bache + tope |
| `clasificar_terreno.m` | Ciencia de Datos | Features por ventana + centroide más cercano + matriz de confusión |
| `analisis_energia.m` | Desarrollo Sustentable | Energía generada/consumida, Wh/km, % del consumo del VE, CO2e |
| `main_suspension.m` | Integrador | Une todo, tabla de desempeño y 5 figuras (más la de validación del modelo) |

Contrato entre módulos (no cambiarlo sin avisar):
- `cam.w` (velocidad del camino, columna, un valor por `p.dt`) → entra a `simular`
- `res(k)` con campos `acc_s, acc_u, carr, llan, u, vrel, Pmec` → lo usan todos
- `ds.pred_t` (clase predicha por muestra) → lo usa `analisis_energia`

Órdenes de magnitud esperados (varían un poco con la semilla):
- Frecuencias naturales ≈ 1.1 Hz (carrocería) y ≈ 11 Hz (rueda)
- Aceleración RMS: pasivo ≈ 0.65 m/s², activo ≈ 0.40 (≈ -40 %), regenerativo ≈ 0.53 (≈ -20 %)
- Clasificación ≈ 90–95 % (los errores caen en cambios de tramo, bache y tope)
- Energía, 4 ruedas: activo consume ≈ 0.4 Wh/km neto; regenerativo genera ≈ 0.3 Wh/km;
  potencial teórico del amortiguador ≈ 1.2 Wh/km (≈ 50 W medios) a 40 km/h
