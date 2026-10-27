; P3 (MAKE): tuerca de 22 mm sin llave, pero hay un diseno de adaptador
(define (problem p3-fabricar)
  (:domain taller)
  (:objects
    robi - robot
    izq der - brazo
    almacen zona-coche impresora - lugar
    adaptador-22 - herramienta
    filamento - material
    d-adaptador - diseno
    quitar-tuerca-22 - tarea
    girar-22 - capacidad)
  (:init
    (en robi almacen)
    (brazo-de izq robi) (brazo-de der robi)
    (libre izq) (libre der)
    (estacion-fabricacion impresora) (en filamento impresora)
    (diseno-para d-adaptador girar-22)
    (por-fabricar adaptador-22)
    (en quitar-tuerca-22 zona-coche)
    (requiere quitar-tuerca-22 girar-22))
  (:goal (hecha quitar-tuerca-22)))