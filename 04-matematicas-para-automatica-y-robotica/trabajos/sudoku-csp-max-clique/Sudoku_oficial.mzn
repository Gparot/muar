
include "alldifferent.mzn";

puzzle = [|
    5,3,0, 0,7,0, 0,0,0 |
    6,0,0, 1,9,5, 0,0,0 |
    0,9,8, 0,0,0, 0,6,0 |
    8,0,0, 0,6,0, 0,0,3 |
    4,0,0, 8,0,3, 0,0,1 |
    7,0,0, 0,2,0, 0,0,6 |
    0,6,0, 0,0,0, 2,8,0 |
    0,0,0, 4,1,9, 0,0,5 |
    0,0,0, 0,8,0, 0,7,9
|];


int: N = 9;
set of int: I = 1..N;

% Datos: 0 indica una casilla vacía
array[I, I] of 0..9: puzzle;

% Variables de decisión
array[I, I] of var 1..9: x;

% Restricciones de las pistas iniciales
constraint
    forall(i, j in I where puzzle[i,j] != 0) (
        x[i,j] = puzzle[i,j]
    );

% Filas: todos los valores diferentes
constraint
    forall(i in I) (
        all_different([x[i,j] | j in I])
    );

% Columnas: todos los valores diferentes
constraint
    forall(j in I) (
        all_different([x[i,j] | i in I])
    );

% Bloques 3x3: todos los valores diferentes
constraint
    forall(bi, bj in 0..2) (
        all_different([
            x[i,j] |
            i in 3*bi+1..3*bi+3,
            j in 3*bj+1..3*bj+3
        ])
    );

solve satisfy;

output [
    concat([
        show(x[i,j]) ++
        (if j = 9 then "\n" else " " endif)
        | j in I
    ])
    | i in I
];
