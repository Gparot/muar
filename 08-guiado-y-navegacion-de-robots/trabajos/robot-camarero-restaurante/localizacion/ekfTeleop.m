%% EKFTELEOP  EKF con el robot movido por teleoperación (teclado).
%   modo = 'teclado' -> flechas: avanzar / retroceder / girar (la orden se mantiene
%                       hasta pulsar otra tecla); Espacio: parar; Q: terminar.
%                       Hay que hacer clic en la figura para que reciba las teclas.
%                       Al terminar guarda los comandos en teleopCmds.mat
%   modo = 'repetir' -> repite la última teleoperación guardada. Sirve para
%                       comparar parámetros (fQ, fR, validar) sobre el MISMO recorrido.
% Necesita: mapaRestaurante, dibujarMapa, ekfIniciar, ekfPaso

clear; close all;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
modo  = 'teclado';
robot = 'Marvin';  laser = 'LMS100';
mapa  = mapaRestaurante();  dt = 0.1;
x0    = [10 9.2 -pi/2];                      % pose inicial (pasillo central)
errorInicial = [0 0 0];                      % error deliberado en la estimación inicial
P0 = diag([0.05^2 0.05^2 deg2rad(2)^2]);
fQ = 1;  fR = 1;                             % multiplicadores de Q y R (1 = calibrados)
validar = true;                              % validación por Mahalanobis
maxPasos = 6000;                             % 10 minutos como máximo

%% Inicialización
apoloPlaceMRobot(robot, [x0(1:2) 0], x0(3));
apoloResetOdometry(robot, [0 0 0]);          % odometría en su propio marco
apoloUpdate();
[f, cal] = ekfIniciar(x0 + errorInicial, P0, apoloGetOdometry(robot));
cal.k_d = fQ*cal.k_d;  cal.k_b = fQ*cal.k_b;
cal.R_d = fR*cal.R_d;  cal.R_a = fR*cal.R_a;
cal.validar = validar;

if strcmp(modo, 'repetir')
    S = load('teleopCmds.mat');  cmds = S.cmds;
    maxPasos = size(cmds, 1);
end
dibujarMapa(mapa);  fig = gcf;  hold on;
hR = plot(nan, nan, 'w-', 'LineWidth', 3);
hE = plot(nan, nan, 'r-', 'LineWidth', 1);
if strcmp(modo, 'teclado')
    setappdata(fig, 'cmd', [0 0]);  setappdata(fig, 'fin', false);
    set(fig, 'KeyPressFcn', @teclaPulsada);
    title('Flechas: mover | Espacio: parar | Q: terminar  (haz clic aquí primero)');
end

Xr = []; Xe = []; Xo = []; Pd = []; nB = []; nRech = []; NIS = []; cmdLog = [];

%% Bucle: orden -> Apolo -> odometría y balizas -> EKF
acel = 3;
for k = 1:maxPasos
    tPaso = tic;
    if strcmp(modo, 'teclado')
        drawnow;
        if ~ishandle(fig) || getappdata(fig, 'fin'), break; end
        u = getappdata(fig, 'cmd');
    else
        u = cmds(k, :);
    end
    if ~apoloMoveMRobot(robot, u, dt)                % choque: Apolo no mueve el robot
        u = [0 0];
        if strcmp(modo, 'teclado'), setappdata(fig, 'cmd', [0 0]); end
        fprintf('Choque en el paso %d: robot parado\n', k);
    end
    cmdLog(k, :) = u; %#ok<SAGROW>

    odo = apoloGetOdometry(robot);
    lm  = apoloGetLaserLandMarks(laser);
    [f, info] = ekfPaso(f, odo, lm, mapa, cal);

    real = apoloGetLocationMRobot(robot);            % solo para evaluar
    Xr(:,k) = [real(1); real(2); real(4)];  Xe(:,k) = f.X;  Pd(:,k) = diag(f.P); %#ok<SAGROW>
    Xo(:,k) = [x0(1) + odo(1)*cos(x0(3)) - odo(2)*sin(x0(3));                    %#ok<SAGROW>
               x0(2) + odo(1)*sin(x0(3)) + odo(2)*cos(x0(3));
               odo(3) + x0(3)];
    nB(k) = info.nUsadas;  nRech(k) = info.nRechazadas;  NIS(k) = info.NIS;      %#ok<SAGROW>

    if mod(k, 2) == 0
        apoloUpdate();
        set(hR, 'XData', Xr(1,:), 'YData', Xr(2,:));
        set(hE, 'XData', Xe(1,:), 'YData', Xe(2,:));
        drawnow limitrate;
    end
    if strcmp(modo, 'teclado'), pause(max(0, dt/acel - toc(tPaso))); end
end
apoloUpdate();
if strcmp(modo, 'teclado')
    cmds = cmdLog;  save('teleopCmds.mat', 'cmds');
    fprintf('Teleoperación guardada en teleopCmds.mat (%d pasos, %.0f s)\n', size(cmds,1), size(cmds,1)*dt);
end

%% Resultados
envolver = @(a) atan2(sin(a), cos(a));
N = size(Xe, 2);  t = (1:N)*dt;
err  = Xe - Xr;  err(3,:)  = envolver(err(3,:));
errO = Xo - Xr;  errO(3,:) = envolver(errO(3,:));
fprintf('\nRecorrido: %.1f s, %.1f m\n', t(end), sum(hypot(diff(Xr(1,:)), diff(Xr(2,:)))));
fprintf('RMSE posición     EKF: %.4f m   | solo odometría: %.4f m\n', ...
        sqrt(mean(err(1,:).^2 + err(2,:).^2)), sqrt(mean(errO(1,:).^2 + errO(2,:).^2)));
fprintf('RMSE orientación  EKF: %.4f rad | solo odometría: %.4f rad\n', ...
        sqrt(mean(err(3,:).^2)), sqrt(mean(errO(3,:).^2)));
fprintf('Dentro de 3 sigma (x, y, theta): %.1f %.1f %.1f %%\n', 100*mean(abs(err) <= 3*sqrt(Pd), 2));
fprintf('NIS medio: %.2f | balizas usadas: %.1f de media (mín. %d) | rechazadas: %d\n', ...
        mean(NIS(~isnan(NIS))), mean(nB), min(nB), sum(nRech));
save('teleopResultado.mat', 'Xr', 'Xe', 'Xo', 'Pd', 'nB', 'nRech', 'NIS', 'cmdLog');

% Trayectorias sobre el plano
figure(fig);  title(mapa.nombre);
set(hR, 'XData', Xr(1,:), 'YData', Xr(2,:));  set(hE, 'XData', Xe(1,:), 'YData', Xe(2,:));
hO = plot(Xo(1,:), Xo(2,:), 'c--');
legend([hR hE hO], {'Real', 'EKF', 'Solo odometría'}, 'Location', 'northeast');

% Errores con bandas de 3 sigma y balizas usadas
figure('Name', 'EKF con teleoperación');
nom = {'error x (m)', 'error y (m)', 'error \theta (rad)'};
for j = 1:3
    subplot(4,1,j); hold on; grid on;
    plot(t, err(j,:), 'r');
    plot(t, 3*sqrt(Pd(j,:)), '--', t, -3*sqrt(Pd(j,:)), '--', 'Color', [0.55 0.55 0.55]);
    ylabel(nom{j});
end
subplot(4,1,4); stairs(t, nB); grid on; ylabel('balizas usadas'); xlabel('t (s)');

%% ---------------------------------------------------------------
function teclaPulsada(fig, ev)
switch ev.Key
    case 'uparrow',    setappdata(fig, 'cmd', [0.3 0]);
    case 'downarrow',  setappdata(fig, 'cmd', [-0.2 0]);
    case 'leftarrow',  setappdata(fig, 'cmd', [0 0.5]);
    case 'rightarrow', setappdata(fig, 'cmd', [0 -0.5]);
    case 'space',      setappdata(fig, 'cmd', [0 0]);
    case 'q',          setappdata(fig, 'fin', true);
end
end
