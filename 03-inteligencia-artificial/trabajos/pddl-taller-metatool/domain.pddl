; Dominio: robot de dos brazos en un taller mecanico (METATOOL)
(define (domain taller)
  (:requirements :strips :typing)

  (:types
    lugar localizable brazo diseno principio capacidad - object
    robot herramienta material tarea - localizable)

  (:predicates
    (en ?x - localizable ?l - lugar)              ; algo esta en un lugar
    (brazo-de ?b - brazo ?r - robot)              ; el brazo pertenece al robot
    (libre ?b - brazo)                            ; el brazo no sujeta nada
    (sujeta ?b - brazo ?h - herramienta)          ; el brazo sujeta una herramienta
    (localizada ?h - herramienta)                 ; el robot sabe donde esta
    (proporciona ?h - herramienta ?c - capacidad) ; para que sirve la herramienta
    (requiere ?t - tarea ?c - capacidad)          ; que necesita la tarea
    (hecha ?t - tarea)                            ; la tarea esta terminada
    (estacion-fabricacion ?l - lugar)             ; aqui hay una impresora 3D
    (por-fabricar ?h - herramienta)               ; herramienta que aun no existe
    (diseno-para ?d - diseno ?c - capacidad)      ; el diseno da esa capacidad
    (diseno-vacio ?d - diseno)                    ; idea aun no inventada
    (conoce ?r - robot ?p - principio)            ; principio que el robot conoce
    (combinan ?p1 - principio ?p2 - principio ?c - capacidad))

  (:action mover
    :parameters (?r - robot ?desde - lugar ?hasta - lugar)
    :precondition (en ?r ?desde)
    :effect (and (not (en ?r ?desde)) (en ?r ?hasta)))

  ; FIND: el robot inspecciona un lugar y descubre la herramienta
  (:action buscar
    :parameters (?r - robot ?h - herramienta ?l - lugar)
    :precondition (and (en ?r ?l) (en ?h ?l))
    :effect (localizada ?h))

  (:action coger
    :parameters (?r - robot ?b - brazo ?h - herramienta ?l - lugar)
    :precondition (and (en ?r ?l) (en ?h ?l) (localizada ?h)
                       (brazo-de ?b ?r) (libre ?b))
    :effect (and (sujeta ?b ?h) (not (libre ?b)) (not (en ?h ?l))))

  (:action soltar
    :parameters (?r - robot ?b - brazo ?h - herramienta ?l - lugar)
    :precondition (and (en ?r ?l) (brazo-de ?b ?r) (sujeta ?b ?h))
    :effect (and (en ?h ?l) (libre ?b) (not (sujeta ?b ?h))))

  ; USE: un brazo aplica la herramienta y el otro sujeta la pieza
  (:action usar
    :parameters (?r - robot ?b1 - brazo ?b2 - brazo ?h - herramienta
                 ?t - tarea ?c - capacidad ?l - lugar)
    :precondition (and (en ?r ?l) (en ?t ?l)
                       (brazo-de ?b1 ?r) (brazo-de ?b2 ?r)
                       (sujeta ?b1 ?h) (libre ?b2)
                       (proporciona ?h ?c) (requiere ?t ?c))
    :effect (hecha ?t))

  ; MAKE: imprimir una herramienta a partir de un diseno
  (:action fabricar
    :parameters (?r - robot ?d - diseno ?h - herramienta ?m - material
                 ?c - capacidad ?l - lugar)
    :precondition (and (en ?r ?l) (estacion-fabricacion ?l) (en ?m ?l)
                       (diseno-para ?d ?c) (por-fabricar ?h))
    :effect (and (en ?h ?l) (localizada ?h) (proporciona ?h ?c)
                 (not (por-fabricar ?h)) (not (en ?m ?l))))

  ; INVENT: combinar dos principios conocidos en un diseno nuevo
  (:action inventar
    :parameters (?r - robot ?d - diseno ?p1 - principio ?p2 - principio
                 ?c - capacidad)
    :precondition (and (conoce ?r ?p1) (conoce ?r ?p2)
                       (combinan ?p1 ?p2 ?c) (diseno-vacio ?d))
    :effect (and (diseno-para ?d ?c) (not (diseno-vacio ?d))))
)
