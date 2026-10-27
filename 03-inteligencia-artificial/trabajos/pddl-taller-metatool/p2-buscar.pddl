; P2 (FIND): el robot no sabe donde esta la llave de cruz
(define (problem p2-buscar)
  (:domain taller)
  (:objects
    robi - robot
    izq der - brazo
    almacen mesa panel zona-coche - lugar
    llave-cruz destornillador - herramienta
    cambiar-rueda - tarea
    girar-19 atornillar - capacidad)
  (:init
    (en robi almacen)
    (brazo-de izq robi) (brazo-de der robi)
    (libre izq) (libre der)
    (en llave-cruz mesa)                 ; no esta localizada
    (proporciona llave-cruz girar-19)
    (en destornillador panel)            ; tampoco, y no sirve
    (proporciona destornillador atornillar)
    (en cambiar-rueda zona-coche)
    (requiere cambiar-rueda girar-19))
  (:goal (hecha cambiar-rueda)))