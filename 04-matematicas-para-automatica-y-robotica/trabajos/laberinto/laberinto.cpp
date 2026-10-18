#include <iostream>
using namespace std;
#include <fstream>
#include <string>
#include <vector>
#include <queue>
#include <stack>
#include <cstdlib>
#include <algorithm>


struct celda
{

    int fila;
    int col;
};

struct Laberinto
{
    int filas;
    int columnas;
    vector<string> grid;
    celda start;
    celda end;
};

struct Nodo
{
    int f;   // prioridad: en Best First será h; en A*, g + h
    celda c; // la casilla
};

bool operator>(const Nodo &a, const Nodo &b)
{
    return a.f > b.f;
}

struct Resultado
{
    bool encontrado;
    int nodos;
    int pasos;
    vector<string> dibujo; // el laberinto con el camino marcado con '*'
    int maxOpen;
    int maxClosed;
};

bool leerLaberinto(string nombre, Laberinto &lab)
{
    ifstream f(nombre);
    if (!f)
        return false; // no se pudo abrir

    f >> lab.filas >> lab.columnas;

    lab.grid.clear();
    lab.start = {-1, -1};
    lab.end = {-1, -1};

    for (int r = 0; r < lab.filas; r++)
    {

        string linea = "";
        char ch;
        for (int c = 0; c < lab.columnas; c++)
        {
            f >> ch;
            linea += ch;
        }

        lab.grid.push_back(linea);
    }

    for (int r = 0; r < lab.filas; r++)
    {
        for (int c = 0; c < lab.columnas; c++)
        {

            if (lab.grid[r][c] == '4')
            {
                lab.start.fila = r;
                lab.start.col = c;
            }
            if (lab.grid[r][c] == '5')
            {
                lab.end.fila = r;
                lab.end.col = c;
            }
        }
    }

    return true;
}




Resultado bf(const Laberinto &lab)
{
    Resultado res;
    res.encontrado = false;
    res.nodos = 0;
    res.pasos = 0;
    res.dibujo = lab.grid; // copia del laberinto para dibujar en ella
    res.maxOpen = 1;      // al empezar, OPEN ya tiene el nodo inicial
    res.maxClosed = 0;

    int dr[4] = {-1, 1, 0, 0}; // cambio en la fila
    int dc[4] = {0, 0, -1, 1}; // cambio en la columna

    queue<celda> open;
    open.push(lab.start);
    vector<vector<celda>> camino(lab.filas, vector<celda>(lab.columnas, {-1, -1}));
    vector<vector<bool>> descubiertas(lab.filas, vector<bool>(lab.columnas, false));
    descubiertas[lab.start.fila][lab.start.col] = true;

    while (!open.empty())
    {

        celda n = open.front();
        open.pop();
        res.nodos++;

        if (n.fila == lab.end.fila && n.col == lab.end.col)
        {
            cout << "Se encontro el final en: (" << n.fila << ", " << n.col << ")" << endl;
            res.encontrado = true;
            cout << "Nodos explorados: " << res.nodos << endl;
            break;
        }
        else
        {
            res.maxClosed++;          
            for (int d = 0; d < 4; d++)
            {

                int nr = n.fila + dr[d]; // fila del vecino  arriba, abajo, izq, der
                int nc = n.col + dc[d];  // columna del vecino arriba, abajo, izq, der

                if (nr >= 0 && nr < lab.filas && nc >= 0 && nc < lab.columnas)
                { // verificar límites

                    if (lab.grid[nr][nc] != '3' && !descubiertas[nr][nc])
                    { // si el vecino no es un muro y no ha sido descubierto

                        descubiertas[nr][nc] = true;
                        camino[nr][nc] = n; // guardar el nodo anterior para reconstruir el camino
                        open.push({nr, nc});
                    }
                }
            }
            res.maxOpen = max(res.maxOpen, (int)open.size());
        }
    };

        if (!res.encontrado)
        {
            cout << "No hay solucion. Nodos explorados: " << res.nodos << endl;
            cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
            return res;
        }


    celda actual = lab.end;

    while (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
    {
        actual = camino[actual.fila][actual.col];  // salto a su padre
        if (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
        res.dibujo[actual.fila][actual.col] = '*'; // marcar el camino
        
        res.pasos++;
    }
    cout << "Pasos: " << res.pasos << endl;
    

    for (const auto &linea : res.dibujo)
    {
        cout << linea << endl;
    }
    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
    return res;
}

Resultado df(const Laberinto &lab)
{
    Resultado res;
    res.encontrado = false;
    res.nodos = 0;
    res.pasos = 0;
    res.dibujo = lab.grid; // copia del laberinto para dibujar en ella
    res.maxOpen = 1;      // al empezar, OPEN ya tiene el nodo inicial
    res.maxClosed = 0;

    int dr[4] = {-1, 1, 0, 0}; // cambio en la fila
    int dc[4] = {0, 0, -1, 1}; // cambio en la columna

    stack<celda> open;
    open.push(lab.start);
    vector<vector<celda>> camino(lab.filas, vector<celda>(lab.columnas, {-1, -1}));
    vector<vector<bool>> descubiertas(lab.filas, vector<bool>(lab.columnas, false));
    descubiertas[lab.start.fila][lab.start.col] = true;

    while (!open.empty())
    {

        celda n = open.top();
        open.pop();
        res.nodos++;

        if (n.fila == lab.end.fila && n.col == lab.end.col)
        {
            cout << "Se encontro el final en: (" << n.fila << ", " << n.col << ")" << endl;
            res.encontrado = true;
            cout << "Nodos explorados: " << res.nodos << endl;
            break;
        }
        else
        {
            res.maxClosed++;          
            for (int d = 0; d < 4; d++)
            {

                int nr = n.fila + dr[d]; // fila del vecino  arriba, abajo, izq, der
                int nc = n.col + dc[d];  // columna del vecino arriba, abajo, izq, der

                if (nr >= 0 && nr < lab.filas && nc >= 0 && nc < lab.columnas)
                { // verificar límites

                    if (lab.grid[nr][nc] != '3' && !descubiertas[nr][nc])
                    { // si el vecino no es un muro y no ha sido descubierto

                        descubiertas[nr][nc] = true;
                        camino[nr][nc] = n; // guardar el nodo anterior para reconstruir el camino
                        open.push({nr, nc});
                    }
                }
            }
            res.maxOpen = max(res.maxOpen, (int)open.size());
        }
    };

    if (!res.encontrado)
{
    cout << "No hay solucion. Nodos explorados: " << res.nodos << endl;
    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
    return res;
}

    celda actual = lab.end;

    while (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
    {
        actual = camino[actual.fila][actual.col];  // salto a su padre
        if (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
        res.dibujo[actual.fila][actual.col] = '*'; // marcar el camino
        res.pasos++;
    }
    cout << "Pasos: " << res.pasos << endl;
    

    for (const auto &linea : res.dibujo)
    {
        cout << linea << endl;
    }
    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
    return res;
}

int heuristica(celda a, celda b)
{
    return abs(a.fila - b.fila) + abs(a.col - b.col);
}

Resultado bestfirstf(const Laberinto &lab)
{
    Resultado res;
    res.encontrado = false;
    res.nodos = 0;
    res.pasos = 0;
    res.dibujo = lab.grid; // copia del laberinto para dibujar en ella
    res.maxOpen = 1;
    res.maxClosed = 0;

    int dr[4] = {-1, 1, 0, 0}; // cambio en la fila
    int dc[4] = {0, 0, -1, 1}; // cambio en la columna

    priority_queue<Nodo, vector<Nodo>, greater<Nodo>> open;
    open.push({heuristica(lab.start, lab.end), lab.start});
    vector<vector<celda>> camino(lab.filas, vector<celda>(lab.columnas, {-1, -1}));
    vector<vector<bool>> descubiertas(lab.filas, vector<bool>(lab.columnas, false));
    descubiertas[lab.start.fila][lab.start.col] = true;

    while (!open.empty())
    {

        Nodo x = open.top();
        open.pop();
        celda n = x.c; // ← esta línea la has perdido; hace falta
        res.nodos++;

        if (n.fila == lab.end.fila && n.col == lab.end.col)
        {
            cout << "Se encontro el final en: (" << n.fila << ", " << n.col << ")" << endl;
            res.encontrado = true;
            cout << "Nodos explorados: " << res.nodos << endl;
            break;
        }
        else
        {
            res.maxClosed++;         
            for (int d = 0; d < 4; d++)
            {

                int nr = n.fila + dr[d]; // fila del vecino  arriba, abajo, izq, der
                int nc = n.col + dc[d];  // columna del vecino arriba, abajo, izq, der

                if (nr >= 0 && nr < lab.filas && nc >= 0 && nc < lab.columnas)
                { // verificar límites

                    if (lab.grid[nr][nc] != '3' && !descubiertas[nr][nc])
                    { // si el vecino no es un muro y no ha sido descubierto

                        descubiertas[nr][nc] = true;
                        camino[nr][nc] = n; // guardar el nodo anterior para reconstruir el camino
                        open.push({heuristica({nr, nc}, lab.end), {nr, nc}});
                    }
                }
            }
            res.maxOpen = max(res.maxOpen, (int)open.size());
        }
    };

    if (!res.encontrado)
{
    cout << "No hay solucion. Nodos explorados: " << res.nodos << endl;
    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
    return res;
}

    celda actual = lab.end;

    while (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
    {
        actual = camino[actual.fila][actual.col];  // salto a su padre
        if (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
        res.dibujo[actual.fila][actual.col] = '*'; // marcar el camino
        res.pasos++;
    }
    cout << "Pasos: " << res.pasos << endl;
    

    for (const auto &linea : res.dibujo)
    {
        cout << linea << endl;
    }
    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
    return res;
}

Resultado Aestrella(const Laberinto &lab)
{
    Resultado res;
    res.encontrado = false;
    res.nodos = 0;
    res.pasos = 0;
    res.dibujo = lab.grid; // copia del laberinto para dibujar en ella
    res.maxOpen = 1;
    res.maxClosed = 0;

    int dr[4] = {-1, 1, 0, 0}; // cambio en la fila
    int dc[4] = {0, 0, -1, 1}; // cambio en la columna

    priority_queue<Nodo, vector<Nodo>, greater<Nodo>> open;
    open.push({heuristica(lab.start, lab.end), lab.start});
    vector<vector<celda>> camino(lab.filas, vector<celda>(lab.columnas, {-1, -1}));

    vector<vector<int>> g(lab.filas, vector<int>(lab.columnas, 1000000)); // "infinito"
    vector<vector<bool>> cerrada(lab.filas, vector<bool>(lab.columnas, false));
    g[lab.start.fila][lab.start.col] = 0;

    while (!open.empty())
    {

        Nodo x = open.top();
        open.pop();
        celda n = x.c;
        if (cerrada[n.fila][n.col])
            continue;                  // copia repetida y ya examinada: la ignoro
        cerrada[n.fila][n.col] = true; // ← esta línea la has perdido; hace falta
        res.nodos++;

        if (n.fila == lab.end.fila && n.col == lab.end.col)
        {
            cout << "Se encontro el final en: (" << n.fila << ", " << n.col << ")" << endl;
            res.encontrado = true;
            cout << "Nodos explorados: " << res.nodos << endl;
            break;
        }
        else
        {
            res.maxClosed++;          
            for (int d = 0; d < 4; d++)
            {

                int nr = n.fila + dr[d]; // fila del vecino  arriba, abajo, izq, der
                int nc = n.col + dc[d];  // columna del vecino arriba, abajo, izq, der

                if (nr >= 0 && nr < lab.filas && nc >= 0 && nc < lab.columnas)
                { // verificar límites

                    if (lab.grid[nr][nc] != '3' && !cerrada[nr][nc])
                    {
                        int nuevoG = g[n.fila][n.col] + 1; // un paso más que su padre

                        if (nuevoG < g[nr][nc])
                        { // ¿es mejor que lo que tenía?
                            g[nr][nc] = nuevoG;
                            camino[nr][nc] = n;
                            open.push({nuevoG + heuristica({nr, nc}, lab.end), {nr, nc}});
                        }
                    }
                }
            }
            res.maxOpen = max(res.maxOpen, (int)open.size());
        }
    };

    if (!res.encontrado)
{
    cout << "No hay solucion. Nodos explorados: " << res.nodos << endl;
    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
    return res;
}

    celda actual = lab.end;

    while (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
    {
        actual = camino[actual.fila][actual.col];  // salto a su padre
        if (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
        res.dibujo[actual.fila][actual.col] = '*'; 
        res.pasos++;
    }
    cout << "Pasos: " << res.pasos << endl;
    

    for (const auto &linea : res.dibujo)
    {
        cout << linea << endl;
    }

    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;

    return res;
}

Resultado iddf(const Laberinto &lab)
{
    Resultado res;
    res.encontrado = false;
    res.nodos = 0;
    res.pasos = 0;
    res.dibujo = lab.grid;
    res.maxOpen = 1;
    res.maxClosed = 0;

    int dr[4] = {-1, 1, 0, 0};
    int dc[4] = {0, 0, -1, 1};

    for (int limite = 0; ; limite++)
    {
        stack<Nodo> open;   // Nodo: f = profundidad, c = casilla
        vector<vector<int>> profundidad(lab.filas, vector<int>(lab.columnas, 1000000));
        vector<vector<celda>> camino(lab.filas, vector<celda>(lab.columnas, {-1, -1}));
        bool cortado = false;
        vector<vector<bool>> examinada(lab.filas, vector<bool>(lab.columnas, false));
        int cerrados = 0;

        open.push({0, lab.start});
        profundidad[lab.start.fila][lab.start.col] = 0;

        while (!open.empty())
        {
            Nodo x = open.top();
            open.pop();
            celda n = x.c;
            if (x.f > profundidad[n.fila][n.col])
            continue;               // copia antigua: ignorar
            res.nodos++;

            if (n.fila == lab.end.fila && n.col == lab.end.col)
            {
                cout << "Se encontro el final en: (" << n.fila << ", " << n.col << ")" << endl;
                res.encontrado = true;
                cout << "Nodos explorados: " << res.nodos << endl;
                break;
            }

            if (!examinada[n.fila][n.col]) {
                examinada[n.fila][n.col] = true;
                cerrados++;
            }

            if (x.f == limite)
            {
                

                cortado = true;         // hay más laberinto, pero no paso del límite
                continue;
            }

            for (int d = 0; d < 4; d++)
            {
                int nr = n.fila + dr[d];
                int nc = n.col + dc[d];

                if (nr >= 0 && nr < lab.filas && nc >= 0 && nc < lab.columnas)
                {
                    int nuevaProf = x.f + 1;
                    if (lab.grid[nr][nc] != '3' && nuevaProf < profundidad[nr][nc])
                    {
                        profundidad[nr][nc] = nuevaProf;
                        camino[nr][nc] = n;
                        open.push({nuevaProf, {nr, nc}});
                    }
                }
            }
            res.maxOpen = max(res.maxOpen, (int)open.size());

        }

        res.maxClosed = max(res.maxClosed, cerrados);

        if (res.encontrado)
        {
            celda actual = lab.end;
            while (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
            {
                actual = camino[actual.fila][actual.col];
                if (!(actual.fila == lab.start.fila && actual.col == lab.start.col))
                    res.dibujo[actual.fila][actual.col] = '*';
                res.pasos++;
            }
            cout << "Pasos: " << res.pasos << endl;
           
            break;
        }

        if (!cortado){

            cout << "No hay solucion. Nodos explorados: " << res.nodos << endl;
            cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;
            return res;
               
        }
                          
    }

    for (const auto &linea : res.dibujo)
    {
        cout << linea << endl;
    }

    cout << "Max OPEN: " << res.maxOpen << "  Max CLOSED: " << res.maxClosed << endl;

    return res;
}



int main()
{

    Laberinto lab;

  


    vector<string> laberintos = {
        "maze_1.txt",
        "maze_2.txt",
        "maze_3.txt",
        "maze_4.txt",
        "maze_5.txt",
        "maze_ejemplo.txt",
        "maze_horizontal.txt",
        "maze_libre.txt",
        "maze_noexit_small.txt",
        "maze_noexit.txt",
        "maze_trampa.txt",
        "maze_trampa2.txt",

    };


    cout << "Elige un laberinto:" << endl;
    for (int i = 0; i < (int)laberintos.size(); i++)
    {
        cout << i + 1 << ") " << laberintos[i] << endl;
    }

    int opcion;
    cin >> opcion;

    if (opcion < 1 || opcion > (int)laberintos.size())
    {
        cout << "Opcion no valida" << endl;
        return 1;
    }

    
    if (!leerLaberinto(laberintos[opcion - 1], lab))
    {
        cout << "No se pudo abrir " << laberintos[opcion - 1] << endl;
        return 1;
    }

 


    cout << "===== BF =====" << endl;
    Resultado res = bf(lab);
    cout << "===== DF =====" << endl;
    Resultado res2 = df(lab);
    cout << "===== Best First =====" << endl;
    Resultado res3 = bestfirstf(lab);
    cout << "===== A* =====" << endl;
    Resultado res4 = Aestrella(lab);
    cout << "===== IDDF =====" << endl;
    Resultado res5 = iddf(lab);
    cout << "Start: (" << lab.start.fila << ", " << lab.start.col << ")" << endl;
    cout << "End: (" << lab.end.fila << ", " << lab.end.col << ")" << endl;
    return 0;
}
