function res = buscarCamino(libre, ini, fin, metodo, coste)
% BUSCARCAMINO  Búsqueda en una cuadrícula (traducción a MATLAB del código C++
% del laberinto, con 8 vecinos en lugar de 4).
%   libre   matriz lógica (true = celda transitable)
%   ini,fin celdas [fila col]
%   metodo  'BF' (anchura), 'DF' (profundidad), 'BestFirst', 'Astar' o
%           'Dijkstra' (= A* con heurística nula)
%   coste   (opcional) coste de cada celda; lo usan A* y Dijkstra: cada paso
%           cuesta su longitud por el coste medio de las dos celdas
% Devuelve: encontrado, camino [fila col], nodos (expandidos), pasos,
% coste (en celdas: 1 recto, sqrt(2) diagonal), maxOpen, maxClosed,
% cerradas (celdas examinadas, para dibujarlas) y tiempo (s).

tic;
if nargin < 5, coste = ones(size(libre)); end
[nf, nc] = size(libre);
N = nf*nc;
dr = [-1  1  0  0 -1 -1  1  1];          % los 4 del laberinto + 4 diagonales
dc = [ 0  0 -1  1 -1  1 -1  1];
cst = [1 1 1 1 sqrt(2) sqrt(2) sqrt(2) sqrt(2)];
iniL = sub2ind([nf nc], ini(1), ini(2));
finL = sub2ind([nf nc], fin(1), fin(2));
conCoste = any(strcmp(metodo, {'Astar', 'Dijkstra'}));   % usan g (coste acumulado)
if strcmp(metodo, 'Dijkstra')
    h = @(f, c) 0;
else
    h = @(f, c) heuristica(f, c, fin);
end

padre = zeros(N, 1);                     % celda anterior (índice lineal) para reconstruir el camino
g = inf(N, 1);  g(iniL) = 0;             % coste acumulado desde el inicio
cerrada = false(N, 1);
descubierta = false(N, 1);  descubierta(iniL) = true;

% OPEN: vector de celdas + vector de prioridades
cap = 8*N;
openC = zeros(cap, 1);  openF = zeros(cap, 1);
cabeza = 1;  nOpen = 1;                  % BF usa cola (cabeza), DF pila, BestFirst/A* prioridad
openC(1) = iniL;  openF(1) = h(ini(1), ini(2));

res.encontrado = false;  res.nodos = 0;  res.maxOpen = 1;  res.maxClosed = 0;
while true
    % ---- sacar un nodo de OPEN según el método ----
    switch metodo
        case 'BF'                                     % cola FIFO
            if cabeza > nOpen, break; end
            n = openC(cabeza);  cabeza = cabeza + 1;
        case 'DF'                                     % pila LIFO
            if nOpen < 1, break; end
            n = openC(nOpen);  nOpen = nOpen - 1;
        otherwise                                     % cola de prioridad: menor f
            if nOpen < 1, break; end
            [~, k] = min(openF(1:nOpen));
            n = openC(k);
            openC(k) = openC(nOpen);  openF(k) = openF(nOpen);  nOpen = nOpen - 1;
            if cerrada(n), continue; end              % copia repetida ya examinada (A*, Dijkstra)
    end
    cerrada(n) = true;
    res.nodos = res.nodos + 1;
    if n == finL
        res.encontrado = true;
        break;
    end
    res.maxClosed = res.maxClosed + 1;

    % ---- expandir los 8 vecinos ----
    [f, c] = ind2sub([nf nc], n);
    for d = 1:8
        fr = f + dr(d);  cc = c + dc(d);
        if fr < 1 || fr > nf || cc < 1 || cc > nc, continue; end
        if ~libre(fr, cc), continue; end
        if d > 4 && ~(libre(f + dr(d), c) && libre(f, c + dc(d)))
            continue;                                 % diagonal: no cortar esquinas de obstáculos
        end
        v = sub2ind([nf nc], fr, cc);
        if conCoste
            if cerrada(v), continue; end
            nuevoG = g(n) + cst(d)*(coste(n) + coste(v))/2;
            if nuevoG < g(v)                          % ¿mejor que lo que tenía?
                g(v) = nuevoG;  padre(v) = n;
                nOpen = nOpen + 1;
                openC(nOpen) = v;  openF(nOpen) = nuevoG + h(fr, cc);
            end
        else
            if descubierta(v), continue; end
            descubierta(v) = true;  padre(v) = n;  g(v) = g(n) + cst(d);
            nOpen = nOpen + 1;
            openC(nOpen) = v;  openF(nOpen) = h(fr, cc);   % solo la usa BestFirst
        end
    end
    if strcmp(metodo, 'BF')
        res.maxOpen = max(res.maxOpen, nOpen - cabeza + 1);
    else
        res.maxOpen = max(res.maxOpen, nOpen);
    end
end

% ---- reconstruir el camino desde el final ----
res.camino = zeros(0, 2);  res.pasos = 0;  res.coste = inf;
if res.encontrado
    L = finL;
    while L(1) ~= iniL
        L = [padre(L(1)); L];  %#ok<AGROW>
    end
    [cf, cc] = ind2sub([nf nc], L);
    res.camino = [cf cc];
    res.pasos = numel(L) - 1;
    d = abs(diff(res.camino));
    res.coste = sum(sqrt(sum(d.^2, 2)));             % 1 recto, sqrt(2) diagonal
end
res.cerradas = reshape(cerrada, nf, nc);
res.tiempo = toc;
end

function h = heuristica(f, c, fin)
% Distancia octil: el coste mínimo real con 8 vecinos y diagonal sqrt(2).
% Nunca sobreestima (admisible), así que A* da el camino óptimo.
a = abs(f - fin(1));  b = abs(c - fin(2));
h = (sqrt(2) - 1)*min(a, b) + max(a, b);
end
