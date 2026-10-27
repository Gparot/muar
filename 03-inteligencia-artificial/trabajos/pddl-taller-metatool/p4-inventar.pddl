; P4 (INVENT): tuerca antirrobo sin herramienta ni diseno
(define (problem p4-inventar)
  (:domain taller)
  (:objects
    robi - robot
    izq der - brazo
    almacen zona-coche impresora - lugar
    extractor - herramienta
    filamento - material
    d-nuevo - diseno
    agarre-presion giro-palanca - principio
    quitar-antirrobo - tarea
    girar-antirrobo - capacidad)
  (:init
    (en robi almacen)
    (brazo-de izq robi) (brazo-de der robi)
    (libre izq) (libre der)
    (estacion-fabricacion impresora) (en filamento impresora)
    (por-fabricar extractor)
    (diseno-vacio d-nuevo)
    (conoce robi agarre-presion) (conoce robi giro-palanca)
    (combinan agarre-presion giro-palanca girar-antirrobo)
    (en quitar-antirrobo zona-coche)
    (requiere quitar-antirrobo girar-antirrobo))
  (:goal (hecha quitar-antirrobo)))