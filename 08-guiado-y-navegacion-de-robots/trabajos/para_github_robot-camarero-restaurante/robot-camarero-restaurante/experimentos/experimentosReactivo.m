%% EXPERIMENTOSREACTIVO  Ajuste del control reactivo.
% Repite la ruta 'colision' (base de carga -> barra, con el carrito imprevisto
% en medio) cambiando un parámetro cada vez y mide: si llega, tiempo, longitud
% recorrida, tiempo con el reactivo activo y distancia mínima a los obstáculos.
% Necesita: mapaRestaurante, dibujarMapa, ekfIniciar, ekfPaso, controladorPunto,
%           controladorReactivo, navegar

clear; close all;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
robot = 'Marvin';  laser = 'LMS100';
mapa = mapaRestaurante();
x0 = [16.8 9.2 pi];  puntos = [10.0 9.2];

ctl.Kv = 0.5;  ctl.Kalpha = 1.5;  ctl.vmax = 0.3;  ctl.wmax = 0.5;
ctl.alphaGiro = deg2rad(45);  ctl.tol = 0.15;

% Valores de referencia del reactivo
rc0.dEntrada = 0.7;  rc0.dDiag = 0.35;  rc0.rCerca = 0.6;  rc0.dParada = 0.3;
rc0.dLibre = 1.0;    rc0.dFrente = 0.45; rc0.dRef = 0.4;   rc0.dLadoLibre = 0.35;
rc0.Kw = 2.0;        rc0.eMin = -0.15;   rc0.vBordeo = 0.15;
rc0.dSalida = 1.0;   rc0.dSalidaDiag = 0.6;  rc0.progreso = 0.2;  rc0.nSalida = 5;  rc0.tMax = 600;

% Experimentos: {nombre, parámetro que cambia, valor, ¿usar reactivo?}
exps = {
    'Sin reactivo',        '',         [],   false
    'Referencia',          '',         [],   true
    'Referencia (rep.)',   '',         [],   true
    'dRef = 0.25',         'dRef',     0.25, true
    'dRef = 0.60',         'dRef',     0.60, true
    'Kw = 0.5',            'Kw',       0.5,  true
    'Kw = 8',              'Kw',       8,    true
    'dEntrada = 0.45',     'dEntrada', 0.45, true
    'dEntrada = 1.2',      'dEntrada', 1.2,  true
    'vBordeo = 0.10',      'vBordeo',  0.10, true
    'vBordeo = 0.30',      'vBordeo',  0.30, true
    };
nE = size(exps, 1);  REG = cell(nE, 1);
for e = 1:nE
    rc = rc0;
    if ~isempty(exps{e,2}), rc.(exps{e,2}) = exps{e,3}; end
    apoloPlaceMRobot(robot, [x0(1:2) 0], x0(3));
    apoloResetOdometry(robot, [0 0 0]);  apoloUpdate();
    [f, cal] = ekfIniciar(x0, diag([0.05^2 0.05^2 deg2rad(2)^2]), apoloGetOdometry(robot));
    [~, REG{e}] = navegar(robot, laser, puntos, f, cal, mapa, ctl, rc, exps{e,4}, 1500);
    fprintf('%d/%d %-18s -> %s\n', e, nE, exps{e,1}, REG{e}.resultado);
end
save('resultadosReactivo.mat', 'REG', 'exps');

%% Tabla resumen
fprintf('\n%-18s %-8s %9s %10s %12s %13s\n', 'Experimento', 'Result.', 'Tiempo', 'Long. (m)', 'T. reactivo', 'Dist. mín.');
for e = 1:nE
    r = REG{e};
    fprintf('%-18s %-8s %8.1fs %10.2f %11.1fs %11.2f m\n', exps{e,1}, r.resultado, ...
            r.tiempo, r.longitud, r.tReactivo, min(r.usMin));
end

%% Figuras: trayectorias de cada grupo sobre el plano (zona del carrito)
grupos = {[1 2 3], 'Con y sin reactivo';  [4 2 5], 'Distancia de bordeo dRef';
          [6 2 7], 'Ganancia Kw';         [8 2 9], 'Distancia de entrada dEntrada';
          [10 2 11], 'Velocidad de bordeo'};
col = {[1 0.4 0.4], [1 1 1], [0.3 0.8 1]};
for g = 1:size(grupos, 1)
    dibujarMapa(mapa);  hold on;  title(grupos{g,2});
    ids = grupos{g,1};  h = zeros(1,3);
    for j = 1:3
        r = REG{ids(j)};
        h(j) = plot(r.Xr(1,:), r.Xr(2,:), '-', 'Color', col{j}, 'LineWidth', 1.8);
        if strcmp(r.resultado, 'choque')
            plot(r.Xr(1,end), r.Xr(2,end), 'x', 'Color', col{j}, 'MarkerSize', 14, 'LineWidth', 3);
        end
    end
    legend(h, exps(ids,1), 'Location', 'southwest');
    xlim([9 18]);  ylim([6 10.5]);
end
