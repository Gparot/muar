    #include <iostream>
    using namespace std;
    #include <fstream>
    #include <string>
    #include <vector>
    #include <queue>
    #include <stack>

    struct celda{

    int fila;  int col;

        

    };

    
    int main(){


    ifstream f("ejemplo_mio.txt");
    int filas, columnas;

    f >> filas >> columnas;

    cout << "Filas: " << filas << " Columnas: " << columnas << endl;

    vector<string> grid;

        for (int r =0; r<filas; r++){

        string linea = "";
        char ch;
            for (int c =0; c<columnas; c++){
                f >> ch;
                linea += ch;
                
            }
    
        grid.push_back(linea);
        }

    celda start, end;

    for (int r =0;r<filas;r++){
        for (int c = 0;c<columnas;c++){

            if (grid[r][c] == '4'){
                start.fila = r;
                start.col = c;
            }
            if (grid[r][c] == '5'){
                end.fila = r;
                end.col = c;
            }
        }
    }

    cout << "Start: (" << start.fila << ", " << start.col << ")" << endl;
    cout << "End: (" << end.fila << ", " << end.col << ")" << endl;


        int dr[4] = {-1, 1, 0, 0};    // cambio en la fila
        int dc[4] = {0, 0, -1, 1};    // cambio en la columna

        stack<celda> open;
        open.push(start);
        vector<vector<celda>> camino(filas, vector<celda>(columnas, {-1, -1}));
        vector<vector<bool>> descubiertas(filas, vector<bool>(columnas, false));
        descubiertas[start.fila][start.col] = true;

        int nodos = 0;
        bool encontrado = false;

        while (!open.empty()) {
        

            celda n = open.top();
            open.pop();
            nodos++;

            

            if (n.fila == end.fila && n.col == end.col) {
                cout << "Se encontro el final en: (" << n.fila << ", " << n.col << ")" << endl;
                encontrado = true;
                cout << "Nodos explorados: " << nodos << endl;
                break;
            } else  {
                
                for (int d = 0; d < 4; d++) {

                int nr = n.fila + dr[d];       // fila del vecino  arriba, abajo, izq, der
                int nc = n.col + dc[d];       // columna del vecino arriba, abajo, izq, der


                    if (nr >= 0 && nr < filas && nc >= 0 && nc < columnas) { // verificar límites
                    
                        if (grid[nr][nc] != '3' && !descubiertas[nr][nc]) { // si el vecino no es un muro y no ha sido descubierto

                            descubiertas[nr][nc] = true;
                            camino[nr][nc] = n; // guardar el nodo anterior para reconstruir el camino
                            open.push({nr, nc});

                            }
                        

                    }

            
                }


            }   
        
        
        
    };

        celda actual = end;
        int pasos = 0;

        if (encontrado) {
          
         celda actual = end;
         int pasos = 0;
        while (!(actual.fila == start.fila && actual.col == start.col)) {
            actual = camino[actual.fila][actual.col];   // salto a su padre
            grid[actual.fila][actual.col] = '*';  // marcar el camino
            pasos++;
        }
        cout << "Pasos: " << pasos << endl;

        for (const auto& linea : grid) {
            cout << linea << endl;
        }

    }else {
        cout << "No hay solucion" << endl;
    }

return 0;
    };