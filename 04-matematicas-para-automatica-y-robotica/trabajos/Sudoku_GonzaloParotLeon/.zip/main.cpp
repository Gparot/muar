#include <iostream>
#include "BitGraph/graph/graph.h"
#include <chrono>
#include <vector>      // vector<double>
#include <algorithm> 
using namespace std;
using namespace bitgraph;
using namespace std::chrono;

int indice(int r, int c, int v);                   // (r,c,v) -> 0..728
void decodificar(int idx, int& r, int& c, int& v); // 0..728 -> (r,c,v)
bool mismacasilla(int i, int j);   // i, j: índices de vértices (0..728), con i != j
bool mismafila(int i, int j);     // i, j: índices de vértices (0..728), con i != j
bool mismacolumna(int i, int j);  // i, j: índices de vér
bool mismobloque(int i, int j);   // i, j: índices de vértices (0..728), con i != j
bool mismovalor(int i, int j);     // i, j: índices de vértices (0..728), con i != j
bool compatibles(int i, int j);   // i, j: índices de vértices (0..728), con i != j
int casillas(bitarray& P);  // P: conjunto de candidatos (bitarray de 729 bits)
bool encontrado = false;
void buscar(ugraph& g, bitarray P);
int C[81];            // el clique actual
int tamC = 0;         // cuántos vértices tiene C
void rellenar(const int C[], int tamC, int sol[9][9]);
int sol[9][9] = {0};
bool validar_solucion(int sol[9][9]);
int nodos = 0; // Contador de nodos visitados



int main() {
    using namespace bitgraph;
    int r, c, v;
    decodificar(728, r, c, v);
    cout << "r: " << r << ", c: " << c << ", v: " << v << endl;
    int ans = indice(r, c, v);
    cout << "ans: " << ans << endl;

 auto t0 = steady_clock::now();

    ugraph g(729);
    for (int i = 0; i < 729; i++)
    for (int j = i + 1; j < 729; j++)
        if (compatibles(i, j))
            g.add_edge(i, j);

    auto t1 = steady_clock::now();
    

   

    int puzzle[9][9] = {
    {5,3,0, 0,7,0, 0,0,0},
    {6,0,0, 1,9,5, 0,0,0},
    {0,9,8, 0,0,0, 0,6,0},
    {8,0,0, 0,6,0, 0,0,3},
    {4,0,0, 8,0,3, 0,0,1},
    {7,0,0, 0,2,0, 0,0,6},
    {0,6,0, 0,0,0, 2,8,0},
    {0,0,0, 4,1,9, 0,0,5},
    {0,0,0, 0,8,0, 0,7,9}
    };
    

    bitarray cand(729);
    cand.set_bit(0, 728);   // todos a 1
    

  
    cand.set_bit(0, 728);

    for (int r = 0; r < 9; r++)
        for (int c = 0; c < 9; c++)
            if (puzzle[r][c] != 0) {
                int p = indice(r, c, puzzle[r][c] - 1);
                    for (int k = 0; k < 729; k++) {
                        if (k!= p && !compatibles(k, p)) {
                        cand.erase_bit(k);
                        }
                    }   
            }
        
    

   
    auto t2 = steady_clock::now();
   

    buscar(g, cand);
    auto t3 = steady_clock::now();
    
    cout << "Aristas: " << g.num_edges() << endl;
    cout << "Candidatos: " << cand.count() << endl;
    cout << "Encontrado: " << encontrado << ", tam: " << tamC << endl;

    rellenar(C, tamC, sol);
    cout << "Solucion:";
    if (validar_solucion(sol)) {
        cout << " valida" << endl;
        for (int i = 0; i < 9; i++) {
            for (int j = 0; j < 9; j++) {
                cout << sol[i][j] << " ";
            }
            cout << endl;
        }
    } else {
        cout << " No es válida" << endl;
    }
    
double t_grafo = duration<double, milli>(t1 - t0).count();
double t_cand  = duration<double, milli>(t2 - t1).count();
double t_busq  = duration<double, micro>(t3 - t2).count();
double t_total = duration<double, milli>(t3 - t0).count();


const int N = 100;
vector<double> tiempos;

for (int rep = 0; rep < N; rep++) {
    // 1. reiniciar el estado global
    nodos = 0;
    encontrado = false;
    tamC = 0;

    // 2. medir solo la búsqueda
    auto ta = steady_clock::now();
    buscar(g, cand);
    auto tb = steady_clock::now();

    // 3. guardar el tiempo en µs
    tiempos.push_back( duration<double, micro>(tb - ta).count() );
}

// media

 double suma = 0;
for (double t : tiempos) suma += t;
double media = suma/N;

// mediana
sort(tiempos.begin(), tiempos.end());
double mediana = (tiempos[N/2 - 1] + tiempos[N/2]) / 2; 
 cout << "Busqueda (" << N << " reps): media " << media
 << " us, mediana " << mediana << " us" << endl;   





cout << "Tiempo grafo: " << t_grafo << " ms" << endl;
cout << "Tiempo candidatos: " << t_cand << " ms" << endl;
cout << "Tiempo busqueda: " << t_busq << " us" << endl;
cout << "Tiempo total: " << t_total << " ms" << endl;
cout << "Nodos visitados: " << nodos << endl;

    return 0;
}



int indice(int r, int c, int v){

return r*81 + c*9 + v;

}                   

void decodificar(int idx, int& r, int& c, int& v){
    r = idx / 81;
    c = (idx % 81) / 9;
    v = idx % 9;
}

bool mismacasilla(int i, int j){
    int r1, c1, v1;
    int r2, c2, v2;
    decodificar(i, r1, c1, v1);
    decodificar(j, r2, c2, v2);
    return (r1 == r2) && (c1 == c2);
}  

bool mismafila(int i, int j){
    int r1, c1, v1;
    int r2, c2, v2;
    decodificar(i, r1, c1, v1);
    decodificar(j, r2, c2, v2);
    return (r1 == r2);
}

bool mismacolumna(int i, int j){
    int r1, c1, v1;
    int r2, c2, v2;
    decodificar(i, r1, c1, v1);
    decodificar(j, r2, c2, v2);
    return (c1 == c2);
}

bool mismobloque(int i, int j){

    int r1, c1, v1;
    int r2, c2, v2;
    decodificar(i, r1, c1, v1);
    decodificar(j, r2, c2, v2);
    return (r1/3 == r2/3) && (c1/3 == c2/3);
}

bool mismovalor(int i, int j){

    int r1, c1, v1;
    int r2, c2, v2;
    decodificar(i, r1, c1, v1);
    decodificar(j, r2, c2, v2);
    return (v1 == v2);
}

bool compatibles(int i, int j){

    bool incompatibles = mismacasilla(i,j) || (mismovalor(i,j) && (mismafila(i,j) || mismacolumna(i,j) || mismobloque(i,j)));

    return !incompatibles;
}




void buscar(ugraph& g, bitarray P) {
    
    
    nodos++;

    if (P.is_empty()) {
        if (tamC == 81) encontrado = true;
        return;
    }
    if (tamC + casillas(P) < 81) return;      // poda

    while (!P.is_empty()) {
        int v = P.lsb();                    // primer candidato de P (el bit a 1 más bajo)

        // 1. meter v en C
        C[tamC] = v;
        tamC++;
        // 2. Pnueva = P ∩ vecinos de v
        bitarray Pnueva = P;
        Pnueva &= g.neighbors(v);
        // 3. llamar a buscar con Pnueva; si encontrado, salir (return)
        buscar(g, Pnueva);
        if (encontrado) return;
        // 4. sacar v de C y quitar v de P (erase_bit)
        tamC--;
        P.erase_bit(v);
        if (tamC + casillas(P) < 81) return;      // poda
    }


}

int casillas(bitarray& P) {
    bool usada[81] = {false};    
    int total = 0;
    for (int k = 0; k < 729; k++) {
        if (P.is_bit(k)) {
            int r, c, v;
            decodificar(k, r, c, v);
            if (!usada[r * 9 + c]) {
                usada[r * 9 + c] = true;
                total++;
            }
        }
    }
    return total;
}


void rellenar(const int C[], int tamC, int sol[9][9]) {
    for (int i = 0; i < tamC; i++) {
        int r, c, v;
        decodificar(C[i], r, c, v);
        sol[r][c] = v + 1; // +1 porque los valores van de 0 a 8
    }
}

bool validar_solucion(int sol[9][9]) {
    // Validar filas
    for (int r = 0; r < 9; r++) {
        bool seen[10] = {false}; // Índices de 1 a 9
        for (int c = 0; c < 9; c++) {
            int val = sol[r][c];
            if (val < 1 || val > 9 || seen[val]) return false;
            seen[val] = true;
        }
    }

    // Validar columnas
    for (int c = 0; c < 9; c++) {
        bool seen[10] = {false}; // Índices de 1 a 9
        for (int r = 0; r < 9; r++) {
            int val = sol[r][c];
            if (val < 1 || val > 9 || seen[val]) return false;
            seen[val] = true;
        }
    }

    // Validar bloques de 3x3
    for (int br = 0; br < 3; br++) {
        for (int bc = 0; bc < 3; bc++) {
            bool seen[10] = {false}; // Índices de 1 a 9
            for (int r = br * 3; r < br * 3 + 3; r++) {
                for (int c = bc * 3; c < bc * 3 + 3; c++) {
                    int val = sol[r][c];
                    if (val < 1 || val > 9 || seen[val]) return false;
                    seen[val] = true;
                }
            }
        }
    }

    return true;
}
