# Robot camarero en un restaurante

**Mapa · A\* · EKF · Control de puntos · Control reactivo**

Trabajo de **Guiado y Navegación de Robots**
Máster en Automática y Robótica · ETSII-UPM

<!-- TODO: imagen de portada (p. ej. trayectoria del demostrador sobre el mapa) -->

Robot móvil simulado en Apolo que hace de camarero en un restaurante de 18 × 14 m. Planifica con A\* sobre una rejilla de ocupación, se localiza con un filtro de Kalman extendido (odometría + balizas láser) y sigue el camino con un controlador de puntos. Si aparece un obstáculo que no está en el mapa, replanifica o lo bordea con control reactivo.

---

## Índice

- [Contenido de la carpeta](#contenido-de-la-carpeta)
- [Ejecución](#ejecución)
- [Mapa](#mapa)
- [Planificación](#planificación)
- [Localización con EKF](#localización-con-ekf)
- [Control](#control)
- [Demostrador](#demostrador)
- [Experimentos](#experimentos)
- [Resultados](#resultados)

---

## Contenido de la carpeta

```
robot-camarero-restaurante/
├── README.md
├── demostrador.m       Misión completa
├── restaurante.xml     Mundo de Apolo
├── mapa/               Definición del entorno y generación del XML
├── planificacion/      Rejilla de ocupación, búsqueda de caminos y replanificación
├── localizacion/       EKF (odometría + balizas láser)
├── control/            Controlador de puntos, control reactivo y bucle de navegación
└── experimentos/       Calibraciones y experimentos de la memoria
    └── resultados/     Datos .mat de las calibraciones y experimentos
```

## Ejecución

**Entorno:** MATLAB y el simulador Apolo.
<!-- TODO: versiones de MATLAB y Apolo -->

1. Abrir Apolo y cargar `restaurante.xml`.
2. En MATLAB, añadir al path la carpeta `Apolo/Matlab` (funciones `apolo*`).
3. Ejecutar:

```matlab
demostrador
```

El script añade al path las subcarpetas del trabajo. Los scripts de `experimentos/` también lo hacen, así que se pueden ejecutar directamente.

La misión se cambia en la variable `mision` al principio de `demostrador.m`. Lugares disponibles: `'Cocina (pase)'`, `'Barra'`, `'Recepcion'`, `'Base de carga'` y `'M1'` a `'M10'`.

> `restaurante.xml` usa matrículas de ejemplo (11111, 22222, 33333). Las matrículas fijan el ruido de los sensores, así que los resultados numéricos no coinciden con los de la memoria.

## Mapa

| Archivo | Descripción |
|---|---|
| `mapaRestaurante.m` | Define el entorno: paredes, muebles, imprevistos, puntos de interés, balizas y sensores |
| `generarXMLApolo.m` | Genera `restaurante.xml` a partir del mapa |
| `dibujarMapa.m` | Dibuja el plano en MATLAB |

- **Restaurante de 18 × 14 m:** comedor con 10 mesas y 2 columnas; arriba, cocina, barra y aseos.
- **3 imprevistos** que el planificador no conoce: un camarero de pie, una silla desplazada y un carrito de servicio.
- **24 balizas** en paredes, columnas y barra, a la altura del láser.
- **Sensores del robot (Marvin):** láser LMS100 en un mástil a 1,2 m, que ve por encima de mesas y sillas, y 5 ultrasonidos a 0,3 m (frontal, dos diagonales y dos laterales).

## Planificación

| Archivo | Descripción |
|---|---|
| `rejillaOcupacion.m`, `actualizarRejilla.m` | Rejilla de ocupación con inflado y coste por celda |
| `buscarCamino.m` | Anchura, profundidad, primero el mejor, Dijkstra y A\*, con 8 vecinos |
| `simplificarCamino.m` | Reduce el camino a puntos de giro |
| `planificar.m` | Camino entre dos puntos en metros |
| `lecturaEsperada.m`, `marcarObstaculos.m` | Detección de imprevistos y marcado en la rejilla |
| `irA.m` | Ir a un destino replanificando ante imprevistos |
| `posicionDe.m` | Coordenadas de un lugar por su nombre |

- La rejilla solo incluye obstáculos conocidos (paredes y muebles). El inflado permite tratar el robot como un punto.
- El coste por celda sube cerca de los obstáculos, para que A\* vaya por el centro de pasillos y puertas.
- `buscarCamino.m` es una traducción a MATLAB del código C++ del [laberinto](../../../04-matematicas-para-automatica-y-robotica/trabajos/laberinto/), con diagonales.
- **Imprevistos:** se comparan los ultrasonidos con la lectura esperada según el mapa. Si un sensor mide bastante menos, el robot se para, marca el obstáculo en la rejilla y replanifica. Si no queda camino, olvida las marcas y bordea el obstáculo con el control reactivo.

## Localización con EKF

| Archivo | Descripción |
|---|---|
| `ekfIniciar.m`, `ekfPaso.m` | EKF: predicción con odometría y corrección con balizas láser |
| `ekfApoloFun.m` | EKF sobre una ruta fija, con parámetros (para los experimentos) |
| `ekfTeleop.m` | EKF con teleoperación por teclado; puede repetir el último recorrido |

- **Estado:** pose `[x y θ]`.
- **Predicción:** odometría. `Q` crece con la distancia y el ángulo recorridos.
- **Corrección:** distancia y ángulo a cada baliza vista. Si la distancia no es válida, solo usa el ángulo.
- **Validación:** cada baliza se valida con la distancia de Mahalanobis.
- **Recuperación:** si se rechazan todas las balizas durante 2 s seguidos, se infla `P`.
- `Q` y `R` salen de las calibraciones de odometría y láser.

## Control

| Archivo | Descripción |
|---|---|
| `controladorPunto.m` | Controlador de puntos |
| `controladorReactivo.m` | Bordeo de obstáculos con los ultrasonidos |
| `navegar.m` | Bucle de navegación: controlador + reactivo + EKF |

- **Controlador de puntos:** `v = Kv·ρ·cos(α)`, `w = Kα·α`, con saturación. Si el error de orientación es grande, gira sobre el sitio antes de avanzar.
- **Control reactivo:** tres modos. `IR` sigue al controlador de puntos. `GIRAR` gira hacia el lado más libre. `SEGUIR` bordea el obstáculo a una distancia fija. Vuelve a `IR` cuando el objetivo está libre y el robot está más cerca que al empezar a rodear, como en los algoritmos Bug.
- **`navegar.m`** acaba cada tramo en `llega`, `choque`, `bloqueado` o `tiempo`.

## Demostrador

`demostrador.m` ejecuta la misión por defecto:

1. Sale de la base de carga y recoge en la cocina.
2. Sirve en la mesa M1.
3. Vuelve a la base de carga.
4. Acude a la barra.

En los tres primeros tramos replanifica ante imprevistos. En el último los bordea con el control reactivo. Al terminar guarda `resultadoDemostrador.mat`.

## Experimentos

Los scripts de `experimentos/` generan las tablas y figuras de la memoria.

| Script | Qué estudia |
|---|---|
| `CalibrarOdometria.m` | Calibración de la odometría (`Q`) |
| `CalibrarLaser.m` | Calibración del láser (`R`) |
| `calibrarUltrasonidos.m` | Ruido de los ultrasonidos y apertura del cono |
| `experimentosEKF.m` | Influencia de `P(0\|0)`, `Q`, `R`, la validación y el número de balizas |
| `experimentosReactivo.m` | Ajuste del control reactivo |
| `compararPlanificadores.m` | Comparación de algoritmos e influencia del inflado |
| `experimentoCoste.m` | Influencia del coste por celda |

`experimentos/resultados/` contiene los `.mat` de las calibraciones y los experimentos. Permiten rehacer las figuras sin volver a simular. Los scripts guardan los `.mat` en la carpeta actual de MATLAB.

## Resultados

<!-- TODO: resultados numéricos de la memoria (calibración, EKF, planificadores, reactivo, demostrador) -->

---

*Gonzalo · Máster en Automática y Robótica, ETSII-UPM*
