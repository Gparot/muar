; P1 (USE): el robot sabe donde esta la llave de cruz
(define (problem p1-usar)
  (:domain taller)
  (:objects
    robi - robot
    izq der - brazo
    almacen mesa zona-coche - lugar
    llave-cruz - herramienta
    cambiar-rueda - tarea
    girar-19 - capacidad)
  (:init
    (en robi almacen)
    (brazo-de izq robi) (brazo-de der robi)
    (libre izq) (libre der)
    (en llave-cruz mesa) (localizada llave-cruz)
    (proporciona llave-cruz girar-19)
    (en cambiar-rueda zona-coche)
    (requiere cambiar-rueda girar-19))
  (:goal (hecha cambiar-rueda)))