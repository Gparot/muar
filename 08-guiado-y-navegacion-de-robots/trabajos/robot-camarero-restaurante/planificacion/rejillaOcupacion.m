function R = rejillaOcupacion(mapa, res, radio, dSeg, kCoste)
% REJILLAOCUPACION  Cuadrícula de ocupación del restaurante para el planificador.
%   R = rejillaOcupacion(mapaRestaurante(), 0.1, 0.35)
%   R = rejillaOcupacion(mapaRestaurante(), 0.1, 0.35, 0.8, 1)   % con mapa de costes
%   res    tamaño de celda (m)
%   radio  inflado (m): radio del robot + margen. Con él, el robot se trata
%          como un punto: si su centro va por celdas libres, el cuerpo no toca nada.
%
%   dSeg, kCoste (opcionales): coste de cada celda. Vale 1 lejos de los obstáculos
%          (a más de dSeg metros) y sube hasta 1 + kCoste junto a la zona inflada,
%          para que A* prefiera pasar por el centro de los pasillos.
%
% Solo usa obstáculos CONOCIDOS (paredes y muebles). Los imprevistos no se
% incluyen: de ellos se encarga el control reactivo.
%
% Convenio: R.libre(fila, col); la fila crece con y, la columna con x.
%   celda (f, c) <-> centro en x = (c - 0.5)*res,  y = (f - 0.5)*res

nx = round(mapa.dim(1)/res);  ny = round(mapa.dim(2)/res);
xc = ((1:nx) - 0.5)*res;      yc = ((1:ny) - 0.5)*res;
[XC, YC] = meshgrid(xc, yc);  % matrices ny x nx

% Todos los obstáculos como cajas [x0 x1 y0 y1] (una pared es una caja sin grosor)
P = mapa.paredes;
cajas = [min(P(:,1),P(:,3)) max(P(:,1),P(:,3)) min(P(:,2),P(:,4)) max(P(:,2),P(:,4))];
M = mapa.muebles;
cajas = [cajas; M(:,1) M(:,1)+M(:,3) M(:,2) M(:,2)+M(:,4)];

% Distancia de cada centro de celda al obstáculo más cercano
dist = inf(size(XC));
for k = 1:size(cajas,1)
    dx = max(max(cajas(k,1) - XC, XC - cajas(k,2)), 0);
    dy = max(max(cajas(k,3) - YC, YC - cajas(k,4)), 0);
    dist = min(dist, hypot(dx, dy));
end

if nargin < 4, dSeg = 0.8; end
if nargin < 5, kCoste = 0; end       % 0 = todas las celdas cuestan lo mismo
R.res = res;  R.radio = radio;  R.dSeg = dSeg;  R.kCoste = kCoste;
R.xc = xc;    R.yc = yc;
R.dist0 = dist;                      % distancia a los obstáculos CONOCIDOS (no cambia)
R.dist = dist;                       % distancia al obstáculo más cercano (se actualiza al descubrir imprevistos)
R.obstaculo = dist <= res/2;         % obstáculo real
R = actualizarRejilla(R);
end
