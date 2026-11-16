TRABAJO DE GUIADO Y NAVEGACIÓN DE ROBOTS - ROBOT CAMARERO EN UN RESTAURANTE
===========================================================================

CÓMO EJECUTAR EL DEMOSTRADOR
1. Abrir Apolo y cargar restaurante.xml.
2. En MATLAB, añadir al path la carpeta Apolo/Matlab (las funciones apolo*).
3. Ejecutar:  demostrador
   (el propio script añade al path las subcarpetas del trabajo)
   El robot sale de la base de carga, recoge en la cocina, sirve en la mesa M1,
   vuelve a la base y acude a la barra. La misión se cambia en la variable
   'mision' al principio de demostrador.m.

FICHEROS
Raíz
  restaurante.xml         mundo de Apolo. Las matrículas son de ejemplo (11111, 22222,
                          33333): fijan el ruido de los sensores, así que los
                          resultados numéricos no coinciden con los de la memoria.
  demostrador.m           misión completa

mapa/
  mapaRestaurante.m       definición del entorno (paredes, muebles, balizas, sensores)
  generarXMLApolo.m       genera restaurante.xml a partir del mapa
  dibujarMapa.m           dibuja el plano en MATLAB

localizacion/  (EKF)
  ekfIniciar.m, ekfPaso.m   filtro de Kalman extendido (odometría + balizas láser)
  ekfApoloFun.m             EKF sobre una ruta fija, con parámetros (experimentos)
  ekfTeleop.m               EKF con teleoperación por teclado

control/
  controladorPunto.m        controlador de puntos
  controladorReactivo.m     control reactivo (bordeo de obstáculos con ultrasonidos)
  navegar.m                 bucle de navegación: controlador + reactivo + EKF

planificacion/
  rejillaOcupacion.m, actualizarRejilla.m   rejilla de ocupación con coste por celda
  buscarCamino.m            A*, Dijkstra, primero el mejor, anchura y profundidad
  simplificarCamino.m       reduce el camino a puntos de giro
  planificar.m              camino entre dos puntos en metros
  lecturaEsperada.m, marcarObstaculos.m     detección de imprevistos y marcado en la rejilla
  irA.m                     ir a un destino replanificando ante imprevistos
  posicionDe.m              coordenadas de un lugar por su nombre

experimentos/  (generan las tablas y figuras de la memoria; cada script añade
               el trabajo al path, así que se pueden ejecutar directamente)
  CalibrarOdometria.m       calibración de la odometría (Q)
  CalibrarLaser.m           calibración del láser (R)
  calibrarUltrasonidos.m    calibración de los ultrasonidos y apertura del cono
  experimentosEKF.m         influencia de P(0|0), Q, R, validación y balizas
  experimentosReactivo.m    ajuste del control reactivo
  compararPlanificadores.m  comparación de algoritmos e influencia del inflado
  experimentoCoste.m        influencia del coste por celda

experimentos/resultados/
  Ficheros .mat con los datos de las calibraciones y de los experimentos
  (permiten rehacer las figuras sin volver a simular).
