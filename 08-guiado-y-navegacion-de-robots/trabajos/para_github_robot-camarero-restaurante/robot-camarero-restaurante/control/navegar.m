function [f, reg] = navegar(robot, laser, puntos, f, cal, mapa, ctl, rc, usarReactivo, maxPasos, R, semiCono)
% NAVEGAR  Lleva el robot por una secuencia de puntos:
% controlador de puntos -> (reactivo) -> Apolo -> EKF.
%   puntos   [x y] por filas
%   f, cal   estado y calibración del EKF. El filtro NO se reinicia entre tramos.
%   usarReactivo  true: los imprevistos se bordean con controladorReactivo.
%   R, semiCono   (opcionales) rejilla del planificador y semiángulo del cono.
%      Si se pasan, se vigila el bloqueo y el tramo puede acabar en 'bloqueado':
%        - siempre: si el robot lleva 20 s sin acercarse al punto;
%        - con usarReactivo = false: en cuanto el sensor frontal o una diagonal
%          ven algo que no está en el mapa (lectura bastante menor que la
%          esperada). El robot se para para que se replanifique.
%   reg      registro: resultado ('llega', 'choque', 'bloqueado' o 'tiempo'), tiempo,
%            longitud, trayectorias, comandos, reactivo activo, lecturas (us, esp).
if nargin < 9,  usarReactivo = true; end
if nargin < 10 || isempty(maxPasos), maxPasos = 3000; end
if nargin < 11, R = []; end
if nargin < 12, semiCono = 0.3; end
dt = 0.1;
tBloqueo = 200;                          % pasos sin progreso (20 s)
umbral = [0.7 0.45 0.45];                % frontal y diagonales: distancia de detección
mejor = inf;  kMejor = 0;
est.modo = 'IR';
N = size(puntos, 1);  i = 1;
reg.resultado = 'tiempo';
reg.Xr = zeros(3,0);  reg.Xe = zeros(3,0);  reg.V = [];  reg.W = [];
reg.reactivo = false(1,0);  reg.usMin = [];  reg.llegadas = zeros(0,3);  reg.us = [];  reg.esp = [];

for k = 1:maxPasos
    ctl.frenar = (i == N);
    [v, w, rho, alpha] = controladorPunto(f.X, puntos(i,:), ctl);
    if rho < ctl.tol                                         % punto alcanzado
        real = apoloGetLocationMRobot(robot);
        reg.llegadas(end+1,:) = [i, k, hypot(real(1)-puntos(i,1), real(2)-puntos(i,2))];
        i = i + 1;  mejor = inf;  kMejor = k;
        if i > N, reg.resultado = 'llega'; break; end
        ctl.frenar = (i == N);
        [v, w, rho, alpha] = controladorPunto(f.X, puntos(i,:), ctl);
    end
    us = apoloGetAllultrasonicSensors(robot);  reg.us = us;
    if rho < mejor - 0.2, mejor = rho;  kMejor = k; end      % progreso hacia el punto
    if ~isempty(R)
        reg.esp = lecturaEsperada(R, f.X, mapa, semiCono);
        if k - kMejor > tBloqueo, reg.resultado = 'bloqueado';  break; end
        if ~usarReactivo && hayImprevisto(R, f.X, us, reg.esp, umbral, mapa)
            reg.resultado = 'bloqueado';  break;
        end
    end
    activo = false;
    if usarReactivo
        [v, w, est, activo] = controladorReactivo(v, w, alpha, rho, us, est, ctl, rc);
    elseif us(1) < rc.dParada && v > 0
        v = 0;                                               % seguridad
    end
    if ~apoloMoveMRobot(robot, [v w], dt)                    % Apolo devuelve 0 si choca
        reg.resultado = 'choque';  break;
    end
    f = ekfPaso(f, apoloGetOdometry(robot), apoloGetLaserLandMarks(laser), mapa, cal);

    real = apoloGetLocationMRobot(robot);                    % solo para evaluar
    reg.Xr(:,end+1) = [real(1); real(2); real(4)];  reg.Xe(:,end+1) = f.X;
    reg.V(end+1) = v;  reg.W(end+1) = w;
    reg.reactivo(end+1) = activo;  reg.usMin(end+1) = min(us);
    if mod(k, 5) == 0, apoloUpdate(); end
end
apoloUpdate();
reg.tiempo = numel(reg.V)*dt;
reg.longitud = sum(hypot(diff(reg.Xr(1,:)), diff(reg.Xr(2,:))));
reg.tReactivo = sum(reg.reactivo)*dt;
end

function si = hayImprevisto(R, X, us, esp, umbral, mapa)
% ¿El frontal o una diagonal ven algo cercano que no está en el mapa ni marcado ya?
si = false;
U = mapa.ultrasonidos;
for j = 1:3
    if us(j) < umbral(j) && us(j) < esp(j) - 0.25
        o = U{j,2};  a = X(3) + U{j,3};
        px = X(1) + o(1)*cos(X(3)) - o(2)*sin(X(3)) + us(j)*cos(a);
        py = X(2) + o(1)*sin(X(3)) + o(2)*cos(X(3)) + us(j)*sin(a);
        if px <= 0 || px >= R.xc(end) || py <= 0 || py >= R.yc(end), continue; end
        fc = floor(py/R.res) + 1;  cc = floor(px/R.res) + 1;
        if R.dist(fc, cc) > 0.15, si = true;  return; end    % aún no está marcado
    end
end
end
