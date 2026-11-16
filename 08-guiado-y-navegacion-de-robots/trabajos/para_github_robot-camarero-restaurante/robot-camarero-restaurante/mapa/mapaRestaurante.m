function mapa = mapaRestaurante()
% MAPARESTAURANTE  Definición del entorno: restaurante de 18 x 14 m.
%   Mismo formato que mapaHospital, así que sirven igual:
%     generarXMLApolo(mapaRestaurante(), 'restaurante.xml')
%     dibujarMapa(mapaRestaurante())
%
%   Zonas: comedor (y = 0..10) con 10 mesas y 2 columnas; arriba, de izquierda
%   a derecha: cocina (puerta 1.2 m), barra (abierta al comedor) y aseos.
%   Entrada de 2 m en la pared inferior. Todas las paredes paralelas a los ejes.

%% Datos generales
mapa.nombre      = 'Restaurante - Guiado y Navegacion MUAR UPM 2026';
mapa.matriculas  = [11111 22222 33333];   % matrículas de ejemplo
mapa.dim         = [18 14];
mapa.alturaPared = 3.0;

%% Paredes [x1 y1 x2 y2]
mapa.paredes = [
    0 0 8 0;   10 0 18 0;              % fachada con entrada (x = 8..10)
    18 0 18 14; 0 14 18 14; 0 0 0 14;  % resto del contorno
    0 10 5.2 10; 6.4 10 7 10;          % pared cocina-comedor, puerta 5.2..6.4
    7 10 7 14;                         % tabique cocina | barra
    13 10 14.2 10; 15.2 10 18 10;      % pared aseos, puerta 14.2..15.2
    13 10 13 14];                      % tabique barra | aseos

%% Mesas: [id cx cy tipo]  (tipo 4 = cuadrada 0.9x0.9, 6 = rectangular 1.6x0.9)
% Tres filas; en la fila central una mesa de 6 por zona.
mesas = [];  id = 1;
filas = [1.3 4; 4.3 6; 7.3 4];         % [y centro, tipo]
for f = 1:size(filas,1)
    cy = filas(f,1);  tipo = filas(f,2);
    if tipo == 4, xs = [1.6 4.9 13.1 16.4]; else, xs = [3.25 14.75]; end
    for cx = xs
        mesas = [mesas; id cx cy tipo]; 
        id = id + 1;
    end
end
mapa.mesas = mesas;

%% Muebles fijos [x y dx dy h]: mesas, sillas y mobiliario
m = [];
for i = 1:size(mesas,1)
    m_i = mesaConSillas(mesas(i,2), mesas(i,3), mesas(i,4));
    m = [m; m_i];                       %#ok<AGROW>
end
m = [m;
    6.3  4.1  0.4 0.4 3.0;              % columna izquierda
    11.3 4.1  0.4 0.4 3.0;              % columna derecha
    10.4 0.3  0.6 0.6 1.1;              % atril de recepción
    0.1  13.3 6.8 0.6 0.9;              % cocina: encimera pared superior
    0.1  10.6 0.6 2.6 0.9;              % cocina: encimera pared izquierda
    2.0  11.4 2.4 0.8 0.9;              % cocina: isla
    8.0  11.0 4.0 0.6 1.1;              % barra
    7.2  13.4 5.6 0.5 1.8];             % botellero
mapa.muebles = m;

%% Imprevistos (NO los conoce el planificador)
mapa.imprevistos = [
    8.7  5.5 0.5  0.4  1.7              % camarero de pie en el pasillo central
    3.0  2.6 0.45 0.45 0.9              % silla desplazada entre mesas
    14.4 8.9 0.8  0.5  1.0];            % carrito de servicio junto a la base

%% Puntos de interés: {nombre, (sin uso), punto [x y]}
% Incluye el punto de servicio de cada mesa (en el pasillo junto a ella).
mapa.salas = {
    'Cocina (pase)', [], [5.8 11.5]
    'Barra',         [], [10.0 10.4]
    'Recepcion',     [], [9.0 1.2]
    'Base de carga', [], [16.8 9.2]};
for i = 1:size(mesas,1)    % punto de servicio: 1.5 m por encima del centro
    mapa.salas(end+1,:) = {sprintf('M%d', mesas(i,1)), [], ...
                           [mesas(i,2) mesas(i,3)+1.5]};
end

%% Balizas [id x y]  (en paredes, columnas y barra)
b = [2 0.1; 6 0.1; 12 0.1; 16 0.1;            % fachada
     0.1 3; 0.1 7; 17.9 3; 17.9 7;            % laterales
     6.5 4.0; 6.5 4.6; 11.5 4.0; 11.5 4.6;    % columnas
     2 9.9; 4 9.9; 16.5 9.9;                  % pared cocina y aseos (lado comedor)
     9 10.9; 11 10.9;                         % frontal de la barra
     0.1 12.0; 3.0 13.9; 6.9 12.5; 3.0 10.1;  % cocina
     7.1 12.5; 12.9 12.5; 10 13.3];           % zona de barra
mapa.balizas = [(1:size(b,1))' b];
mapa.alturaBaliza = 1.2;                      % a la altura del láser (mástil)

%% Robot: arranca en la base de carga mirando hacia -x
mapa.robot.nombre = 'Marvin';
mapa.robot.pose   = [16.8 9.2 pi];

%% Sensores
% Láser en mástil a 1.2 m: ve por encima de mesas (0.75) y sillas (0.9)
mapa.laser.nombre   = 'LMS100';
mapa.laser.posicion = [0.1 0 1.2];
% Anillo bajo de ultrasonidos (0.3 m): detecta sillas, mesas y piernas
mapa.ultrasonidos = {
    'uc0', [0.25  0.00 0.3],  0
    'ul1', [0.22  0.15 0.3],  pi/4
    'ur1', [0.22 -0.15 0.3], -pi/4
    'ul2', [0.00  0.25 0.3],  pi/2
    'ur2', [0.00 -0.25 0.3], -pi/2
    };
end

%% 
function cajas = mesaConSillas(cx, cy, tipo)
% Devuelve la mesa y sus sillas como cajas [x y dx dy h]
s = 0.45;  hs = 0.9;  sep = 0.1;          % silla: lado, altura, holgura
if tipo == 4
    a = 0.9; b = 0.9;
    o = a/2 + sep + s/2;
    centros = [cx+o cy; cx-o cy; cx cy+o; cx cy-o];
else
    a = 1.6; b = 0.9;
    oy = b/2 + sep + s/2;  ox = a/2 + sep + s/2;
    centros = [cx-0.4 cy+oy; cx-0.4 cy-oy; cx+0.4 cy+oy; cx+0.4 cy-oy;
               cx+ox cy; cx-ox cy];
end
cajas = [cx-a/2 cy-b/2 a b 0.75];
for k = 1:size(centros,1)
    cajas = [cajas; centros(k,1)-s/2 centros(k,2)-s/2 s s hs]; 
end
end