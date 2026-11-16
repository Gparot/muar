%% DEMOSTRADOR  Robot camarero: integra planificación, control, reactivo y EKF.
% El robot recibe una misión (lista de lugares por nombre). Para cada lugar:
%   1) planifica con A* sobre la rejilla con costes, desde la pose estimada por el EKF
%   2) navega con el controlador de puntos y el EKF, vigilando los ultrasonidos
%   3) si aparece un imprevisto, se para, lo añade a la rejilla y replanifica;
%      si no queda camino alternativo, lo bordea con el control reactivo
% Lugares disponibles: 'Cocina (pase)', 'Barra', 'Recepcion', 'Base de carga', 'M1' ... 'M10'

clear; close all;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
robot = 'Marvin';  laser = 'LMS100';
mapa  = mapaRestaurante();

mision = {'Cocina (pase)', 'M1', 'Base de carga', 'Barra'};   % recoger, servir, volver a la base y acudir a la barra
% Cómo se tratan los imprevistos en cada tramo: 'replanificar' (parar, marcar y
% buscar otro camino) o 'bordear' (rodearlos con el control reactivo)
modos  = {'replanificar', 'replanificar', 'replanificar', 'bordear'};
espera = 2;                                             % segundos parado en cada lugar (recoger / servir)

semiCono = 0.17;     % semiángulo del cono de los ultrasonidos (rad), de calibrarUltrasonidos

% Planificador: celdas de 10 cm, inflado 0.40 m (media diagonal del robot),
% coste extra a menos de 0.8 m de obstáculos
R = rejillaOcupacion(mapa, 0.1, 0.40, 0.8, 1);
% Controlador de puntos
ctl.Kv = 0.5;  ctl.Kalpha = 1.5;  ctl.vmax = 0.3;  ctl.wmax = 0.5;
ctl.alphaGiro = deg2rad(45);  ctl.tol = 0.15;
% Control reactivo
rc.dEntrada = 0.7;  rc.dDiag = 0.35;  rc.rCerca = 0.6;  rc.dParada = 0.3;
rc.dLibre = 1.0;    rc.dFrente = 0.45; rc.dRef = 0.4;   rc.dLadoLibre = 0.35;
rc.Kw = 2.0;        rc.eMin = -0.15;   rc.vBordeo = 0.15;
rc.dSalida = 1.0;   rc.dSalidaDiag = 0.6;  rc.progreso = 0.2;  rc.nSalida = 5;  rc.tMax = 600;

%% Inicio: robot en la base de carga
x0 = mapa.robot.pose;
apoloPlaceMRobot(robot, [x0(1:2) 0], x0(3));
apoloResetOdometry(robot, [0 0 0]);  apoloUpdate();
[f, cal] = ekfIniciar(x0, diag([0.05^2 0.05^2 deg2rad(2)^2]), apoloGetOdometry(robot));

%% Misión
nT = numel(mision);  REG = cell(nT, 1);
for t = 1:nT
    fprintf('Tramo %d/%d: hacia %s (%s)\n', t, nT, mision{t}, modos{t});
    [f, R, REG{t}] = irA(posicionDe(mapa, mision{t}), f, R, robot, laser, cal, mapa, ctl, rc, semiCono, modos{t});
    fprintf('   %s en %.1f s, %.1f m, %d replanificaciones, %d bordeos\n', REG{t}.resultado, ...
            REG{t}.tiempo, REG{t}.longitud, REG{t}.replan, REG{t}.bordeos);
    if ~strcmp(REG{t}.resultado, 'llega'), break; end
    pause(espera);
end
save('resultadoDemostrador.mat', 'REG', 'mision');

%% Resumen y figura
Xr = [];  Xe = [];
for t = 1:nT
    if ~isempty(REG{t}), Xr = [Xr REG{t}.Xr];  Xe = [Xe REG{t}.Xe]; end %#ok<AGROW>
end
err = hypot(Xe(1,:) - Xr(1,:), Xe(2,:) - Xr(2,:));
fprintf('\nMisión: %.1f s, %.1f m | error de localización: medio %.4f m, máximo %.4f m\n', ...
        size(Xr,2)*0.1, sum(hypot(diff(Xr(1,:)), diff(Xr(2,:)))), mean(err), max(err));

dibujarMapa(mapa);  hold on;  title('Demostrador: misión completa');
col = lines(nT);  h = [];  nombres = {};
for t = 1:nT
    if isempty(REG{t}), continue; end
    for p = 1:numel(REG{t}.planes)                       % planes de A* (los descartados también)
        plot(REG{t}.planes{p}(:,1), REG{t}.planes{p}(:,2), ':o', 'Color', col(t,:), 'MarkerSize', 4);
    end
    h(end+1) = plot(REG{t}.Xr(1,:), REG{t}.Xr(2,:), '-', 'Color', col(t,:), 'LineWidth', 2); %#ok<SAGROW>
    nombres{end+1} = sprintf('%d: a %s', t, mision{t}); %#ok<SAGROW>
    k = REG{t}.reactivo;
    plot(REG{t}.Xr(1,k), REG{t}.Xr(2,k), '.', 'Color', [0 1 1], 'MarkerSize', 6);   % reactivo activo
end
legend(h, nombres, 'Location', 'northeast');
