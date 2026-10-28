# Suspensión activa regenerativa — cuarto de vehículo eléctrico

Requisitos: MATLAB R2021a o posterior. Sin Simulink. Sin toolboxes obligatorios
(`lqr` se usa si tienen Control System Toolbox; si no, `diseno_lqr.m` resuelve
Riccati por su cuenta).

Ejecutar: abrir `main_suspension.m` y correr sección por sección (Ctrl+Enter).

| Archivo | Responsable | Qué hace |
|---|---|---|
| `parametros.m` | Todos | Único lugar con números físicos |
| `modelo_cuarto_vehiculo.m` | Mecánica | Matrices A, B, E, C, D; discretización con `expm`; frecuencias naturales |
| `diseno_lqr.m` | Mecatrónica | Pesos → Q, R, N → ganancia K; polos de lazo cerrado |
| `simular.m` | Mecatrónica | Lazo de simulación: pasivo / activo / regenerativo (clipped LQR) |
| `generar_camino.m`, `perfil_iso8608.m` | Ciencia de Datos | Camino ISO 8608 de 1 km con 3 tipos de superficie + bache + tope |
| `clasificar_terreno.m` | Ciencia de Datos | Features por ventana + centroide más cercano + matriz de confusión |
| `analisis_energia.m` | Desarrollo Sustentable | Energía generada/consumida, Wh/km, % del consumo del VE, CO2e |
| `main_suspension.m` | Integrador | Une todo, tabla de desempeño y 5 figuras |

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
