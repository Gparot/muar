%% CALIBRARODOMETRIA  Mide el error de la odometría frente a la posición real.
%
% Idea: el robot avanza (o gira) una cantidad conocida muchas veces.
% En cada repetición comparamos:
%   - lo que CREE el robot      -> apoloGetOdometry       [x y theta]
%   - dónde está DE VERDAD      -> apoloGetLocationMRobot [x y z theta]
% La varianza de esa diferencia, dividida por lo recorrido, es lo que luego
% usaremos para construir Q(k) en el EKF.
%
% Se hacen dos experimentos separados:
%   A) Avance en línea recta (varias distancias)   -> error por metro
%   B) Giro sobre sí mismo (varios ángulos)        -> error por radián


clear; clc;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
robot = 'Marvin';
N     = 50;          % repeticiones por cada distancia / ángulo
dt    = 0.1;         % paso de simulación (s)
v     = 0.3;         % velocidad lineal en los avances (m/s)
w     = 0.5;         % velocidad angular en los giros (rad/s)

% Punto de partida: pasillo frontal del comedor (y=9.2), mirando a +x (libre hasta x~13)
x0 = 1.0; y0 = 9.2; th0 = 0;

envolver = @(a) atan2(sin(a), cos(a));   % ángulo a [-pi, pi]

%% A) AVANCE EN LÍNEA RECTA 
distancias = [1 2 3 4 5];                  % m
eLong = zeros(N, numel(distancias));       % error en la dirección de avance
eLat  = zeros(N, numel(distancias));       % error lateral
eThA  = zeros(N, numel(distancias));       % error de orientación al avanzar

for j = 1:numel(distancias)
    pasos = round(distancias(j) / (v*dt));
    for i = 1:N
        % 1. Colocar el robot y poner la odometría a la misma pose
        apoloPlaceMRobot(robot, [x0 y0 0], th0);
        apoloResetOdometry(robot, [x0 y0 th0]);
        % 2. Avanzar en recta
        for k = 1:pasos
            apoloMoveMRobot(robot, [v 0], dt);
        end
        % 3. Comparar odometría con realidad
        odo  = apoloGetOdometry(robot);         % [x y th]
        real = apoloGetLocationMRobot(robot);   % [x y z th]
        eLong(i,j) = odo(1) - real(1);          % el robot va en +x
        eLat(i,j)  = odo(2) - real(2);
        eThA(i,j)  = envolver(odo(3) - real(4));
    end
    apoloUpdate();
    fprintf('Avance %.0f m: hecho\n', distancias(j));
end

%%  B) GIRO SOBRE SÍ MISMO 
angulos = [pi/4 pi/2 3*pi/4 pi 5*pi/4 6*pi/4 7*pi/4 2*pi];           % rad
eThB = zeros(N, numel(angulos));

for j = 1:numel(angulos)
    pasos = round(angulos(j) / (w*dt));
    for i = 1:N

        apoloPlaceMRobot(robot, [3 y0 0], th0);
        apoloResetOdometry(robot, [3 y0 th0]);

        for k = 1:pasos
            apoloMoveMRobot(robot, [0 w], dt);
        end

        odo  = apoloGetOdometry(robot);
        real = apoloGetLocationMRobot(robot);
        eThB(i,j) = envolver(odo(3) - real(4));
    end

    apoloUpdate();
    fprintf('Giro %.0f grados: hecho\n', rad2deg(angulos(j)));
end

%%
% Si el modelo "varianza proporcional a lo recorrido" es correcto,
% var(error) frente a distancia debe ser una recta que pasa por el origen.
% Pendiente por mínimos cuadrados sin término independiente: k = (d'*s)/(d'*d)
d = distancias(:);  a = angulos(:);
pend = @(x, s) (x' * s) / (x' * x);

vLong = var(eLong)';  vLat = var(eLat)';  vThA = var(eThA)';  vThB = var(eThB)';
calib.k_long   = pend(d, vLong);    % m^2 por m avanzado
calib.k_lat    = pend(d, vLat);     % m^2 por m avanzado
calib.k_th_av  = pend(d, vThA);     % rad^2 por m avanzado
calib.k_th_gir = pend(a, vThB);     % rad^2 por rad girado
calib.sesgo_long = mean(eLong(:,end)) / distancias(end);   % error sistemático
calib.sesgo_gir  = mean(eThB(:,end)) / angulos(end);

disp(calib);
%save('calib_odometria.mat', 'calib', 'eLong', 'eLat', 'eThA', 'eThB','distancias', 'angulos');

%% GRÁFICAS
figure('Name', 'Calibración odometría');
subplot(2,2,1); plot(d, vLong, 'o', d, calib.k_long*d, '-');
title('Error longitudinal'); xlabel('distancia (m)'); ylabel('var (m^2)'); grid on;
subplot(2,2,2); plot(d, vLat, 'o', d, calib.k_lat*d, '-');
title('Error lateral'); xlabel('distancia (m)'); ylabel('var (m^2)'); grid on;
subplot(2,2,3); plot(d, vThA, 'o', d, calib.k_th_av*d, '-');
title('Error de orientación al avanzar'); xlabel('distancia (m)'); ylabel('var (rad^2)'); grid on;
subplot(2,2,4); plot(a, vThB, 'o', a, calib.k_th_gir*a, '-');
title('Error de orientación al girar'); xlabel('ángulo (rad)'); ylabel('var (rad^2)'); grid on;

figure('Name', 'Distribución del error (5 m)');
histogram(eLong(:,end), 10); grid on;
title('Error longitudinal tras 5 m'); xlabel('odometría - real (m)');