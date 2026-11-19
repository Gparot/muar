%% CALIBRARLASER  Mide el ruido del láser en modo balizas -> matriz R del EKF.
%
% Idea: colocar el robot en muchas poses aleatorias (válidas) del restaurante.
% En cada pose conocemos la posición REAL del robot y la de cada baliza, así
% que podemos calcular la medida "perfecta" (sin ruido) con nuestro modelo
% de observación y compararla con lo que devuelve Apolo.
%   error_distancia = medida - teórica
%   error_angulo    = medida - teórico   [-pi, pi]
% Además se repite la lectura varias veces en cada pose para ver si el ruido
% cambia entre lecturas o es fijo para una misma pose.
%
% Requiere mapaRestaurante.m en la misma carpeta (posiciones de las balizas).

clear; clc;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
robot = 'Marvin';  laser = 'LMS100';
mapa  = mapaRestaurante();
B     = mapa.balizas;                 % [id x y]
a     = mapa.laser.posicion(1);       % el láser va 0.1 m por delante del centro
Npos  = 200;                          % poses aleatorias
reps  = 5;                            % lecturas por pose
envolver = @(ang) atan2(sin(ang), cos(ang));

datos = [];   % filas: [pose rep id dist_teorica err_dist err_ang]

p = 0;  
intentos = 0;

while p < Npos && intentos < 20*Npos
    intentos = intentos + 1;
    % 1. Pose aleatoria; apoloPlaceMRobot devuelve 0 si choca con algo
    x = 0.5 + 17*rand;  y = 0.5 + 13*rand;  th = -pi + 2*pi*rand;
    if ~apoloPlaceMRobot(robot, [x y 0], th), continue; end
    p = p + 1;
    real = apoloGetLocationMRobot(robot);         % [x y z theta]
    xr = real(1);  yr = real(2);  tr = real(4);
    xl = xr + a*cos(tr);  yl = yr + a*sin(tr);    % posición del láser
    
    % 2. Varias lecturas en la misma pose
    for r = 1:reps
        lm = apoloGetLaserLandMarks(laser);
        for k = 1:numel(lm.id)
            fila = find(B(:,1) == double(lm.id(k)), 1);%Índice de la baliza en B
            dx = B(fila,2) - xl;  dy = B(fila,3) - yl;
            dT = sqrt(dx^2 + dy^2);                   % distancia teórica
            aT = envolver(atan2(dy, dx) - tr);        % ángulo teórico
            datos = [datos; p r double(lm.id(k)) dT ...
                lm.distance(k) - dT, envolver(lm.angle(k) - aT)]; 
        end
    end
    if mod(p, 20) == 0, fprintf('%d poses hechas\n', p); end
end
apoloPlaceMRobot(robot, [mapa.robot.pose(1:2) 0], mapa.robot.pose(3));  % a la base
apoloUpdate();

%% ===== ANÁLISIS =====
d  = datos(:,4);  eD = datos(:,5);  eA = datos(:,6);
fprintf('\nMedidas recogidas: %d (en %d poses)\n', size(datos,1), p);
fprintf('Balizas vistas por pose: media %.1f\n', size(datos,1)/(p*reps));

% ¿El ruido cambia entre lecturas repetidas en la misma pose?
% Si la varianza "dentro de la pose" es ~0, el ruido es fijo por pose.
grupos = findgroups(datos(:,1), datos(:,3));
varDentro = mean(splitapply(@var, eD, grupos), 'omitnan');
fprintf('Var. distancia entre lecturas repetidas: %.3e  (total: %.3e)\n', varDentro, var(eD));

% Varianza por tramos de distancia
bordes = 0:2:20;  cen = bordes(1:end-1) + 1;
vD = nan(size(cen));  vA = nan(size(cen));  n = zeros(size(cen));
 
for i = 1:numel(cen)

    sel = d >= bordes(i) & d < bordes(i+1);
    n(i) = sum(sel);

    if n(i) >= 20, vD(i) = var(eD(sel));
        vA(i) = var(eA(sel)); 
    end
end
ok = ~isnan(vD);
ajD = polyfit(cen(ok), vD(ok), 1);    % var_d = ajD(1)*d + ajD(2)
ajA = polyfit(cen(ok), vA(ok), 1);

calibL.var_dist   = var(eD);          % R constante (opción simple)
calibL.var_ang    = var(eA);
calibL.sesgo_dist = mean(eD);
calibL.sesgo_ang  = mean(eA);
calibL.ajuste_dist = ajD;             % R dependiente de la distancia (si procede)
calibL.ajuste_ang  = ajA;
disp(calibL);


%% ===== GRÁFICAS (para la memoria) =====
figure('Name', 'Calibración láser');
subplot(2,2,1); histogram(eD, 40); grid on;
title('Error de distancia'); xlabel('medida - teórica (m)');
subplot(2,2,2); histogram(eA, 40); grid on;
title('Error de ángulo'); xlabel('medida - teórico (rad)');
subplot(2,2,3); plot(cen, vD, 'o', cen, polyval(ajD, cen), '-'); grid on;
title('Var. distancia según distancia'); xlabel('distancia (m)'); ylabel('var (m^2)');
subplot(2,2,4); plot(cen, vA, 'o', cen, polyval(ajA, cen), '-'); grid on;
title('Var. ángulo según distancia'); xlabel('distancia (m)'); ylabel('var (rad^2)');


%% 
