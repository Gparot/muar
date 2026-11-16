function idx = simplificarCamino(libre, camino, dist)
% SIMPLIFICARCAMINO  Reduce el camino de celdas a unos pocos puntos de giro.
% Desde cada punto guardado, avanza por el camino mientras la línea recta
% hasta la siguiente celda (1) pase solo por celdas libres y (2) no se
% acerque a los obstáculos más de lo que ya lo hace el propio camino
% (margen de 5 cm). Así el atajo no deshace lo que consigue el coste por
% celda: seguir pasando por el centro de puertas y pasillos.
%   dist (opcional)  distancia de cada celda al obstáculo más cercano
%   idx              índices (filas de 'camino') de los puntos que se conservan
if nargin < 3, dist = inf(size(libre)); end
N = size(camino, 1);
dC = dist(sub2ind(size(dist), camino(:,1), camino(:,2)));    % distancia en cada celda del camino
idx = 1;  i = 1;
while i < N
    j = i + 1;  dMin = min(dC(i), dC(j));
    while j < N
        dM = min(dMin, dC(j+1));
        if ~visible(libre, dist, camino(i,:), camino(j+1,:), dM), break; end
        j = j + 1;  dMin = dM;
    end
    idx(end+1) = j; %#ok<AGROW>
    i = j;
end
end

function ok = visible(libre, dist, a, b, dMin)
n = max(2, ceil(4*norm(b - a)));             % 4 muestras por celda
f = round(linspace(a(1), b(1), n));
c = round(linspace(a(2), b(2), n));
k = sub2ind(size(libre), f, c);
ok = all(libre(k)) && min(dist(k)) >= dMin - 0.05;
end
