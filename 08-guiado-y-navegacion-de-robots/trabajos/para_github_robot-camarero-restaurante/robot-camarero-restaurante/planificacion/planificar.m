function [puntos, info] = planificar(R, origen, destino, metodo)
% PLANIFICAR  Camino entre dos puntos del restaurante (en metros).
%   [puntos, info] = planificar(R, [5.8 11.5], [16.4 2.8], 'Astar')
%   R        rejilla de rejillaOcupacion
%   puntos   puntos de giro [x y] para seguirPuntos (sin el origen)
%   info     resultado de la búsqueda + longitud (m), camino completo (m)
if nargin < 4, metodo = 'Astar'; end
ini = celdaLibre(R, origen);
fin = celdaLibre(R, destino);
info = buscarCamino(R.libre, ini, fin, metodo, R.coste);
puntos = zeros(0, 2);
info.longitud = info.coste * R.res;
if ~info.encontrado
    return;
end
info.caminoXY = [R.xc(info.camino(:,2))' R.yc(info.camino(:,1))'];
k = simplificarCamino(R.libre, info.camino, R.dist);
puntos = info.caminoXY(k(2:end), :);          % el primero es donde ya está el robot
if R.libre(fin(1), fin(2)) && isequal(fin, celdaDe(R, destino))
    puntos(end, :) = destino;                 % terminar exactamente en el destino pedido
end
end

function rc = celdaDe(R, p)
rc = [min(max(floor(p(2)/R.res) + 1, 1), numel(R.yc)), ...
      min(max(floor(p(1)/R.res) + 1, 1), numel(R.xc))];
end

function rc = celdaLibre(R, p)
% Celda del punto; si cae en zona ocupada o inflada, la celda libre más cercana
rc = celdaDe(R, p);
if ~R.libre(rc(1), rc(2))
    [F, C] = find(R.libre);
    [~, k] = min(hypot(R.xc(C)' - p(1), R.yc(F)' - p(2)));
    rc = [F(k) C(k)];
end
end
