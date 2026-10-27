# Taller METATOOL: planificación automática en PDDL

Ejercicio de planificación automática en PDDL de la asignatura de
**Inteligencia Artificial** del Máster Universitario en Automática y Robótica
(UPM).

## Escenario

Un robot de dos brazos trabaja en un taller mecánico y tiene que completar
tareas sobre un coche (cambiar una rueda, quitar una tuerca...). Cada tarea
requiere una *capacidad* (por ejemplo, girar una tuerca de 19 mm) que
proporciona alguna herramienta. Según lo que el robot sabe y tiene a su
alcance, el problema se vuelve cada vez más difícil:

1. **Usar** una herramienta que ya sabe dónde está.
2. **Buscar** una herramienta cuya ubicación desconoce.
3. **Fabricar** la herramienta en una impresora 3D a partir de un diseño
   existente.
4. **Inventar** un diseño nuevo combinando dos principios que conoce, y
   después fabricarlo.

Para usar una herramienta, un brazo la sujeta mientras el otro debe quedar
libre para sujetar la pieza.

## Dominio (`domain.pddl`)

Dominio `taller` con requisitos `:strips` y `:typing`. Acciones:

| Acción      | Descripción                                                                 |
|-------------|-----------------------------------------------------------------------------|
| `mover`     | El robot se desplaza entre dos lugares.                                     |
| `buscar`    | Inspecciona un lugar y localiza una herramienta que está allí.              |
| `coger`     | Coge con un brazo libre una herramienta localizada.                         |
| `soltar`    | Deja la herramienta que sujeta un brazo.                                    |
| `usar`      | Aplica la herramienta a la tarea (con el otro brazo libre) y la completa.   |
| `fabricar`  | En la estación de fabricación, gasta material e imprime una herramienta.    |
| `inventar`  | Combina dos principios conocidos para crear un diseño con una capacidad.    |

## Archivos

| Archivo              | Contenido                                                                                       |
|----------------------|-------------------------------------------------------------------------------------------------|
| `domain.pddl`        | Dominio del taller: tipos, predicados y acciones.                                               |
| `p1-usar.pddl`       | **USE**: la llave de cruz está localizada en la mesa; hay que ir a por ella y cambiar la rueda. |
| `p2-buscar.pddl`     | **FIND**: el robot no sabe dónde está la llave de cruz y debe buscarla (hay un destornillador que no sirve). |
| `p3-fabricar.pddl`   | **MAKE**: tuerca de 22 mm sin llave; hay que imprimir un adaptador a partir de un diseño.        |
| `p4-inventar.pddl`   | **INVENT**: tuerca antirrobo sin herramienta ni diseño; hay que inventar el diseño y fabricarlo. |
| `informe_pddl.pdf`   | Informe del trabajo.                                                                            |

## Ejecución

Los problemas se resuelven con [pyperplan](https://github.com/aibasel/pyperplan):

```bash
pip install pyperplan

pyperplan domain.pddl p1-usar.pddl
pyperplan domain.pddl p2-buscar.pddl
pyperplan domain.pddl p3-fabricar.pddl
pyperplan domain.pddl p4-inventar.pddl
```

pyperplan muestra el plan por pantalla y lo guarda en un archivo
`<problema>.pddl.soln` junto al problema. Estos archivos están excluidos del
repositorio mediante `.gitignore`.
