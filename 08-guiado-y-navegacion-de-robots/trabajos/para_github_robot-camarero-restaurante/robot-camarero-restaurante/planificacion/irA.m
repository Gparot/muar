function [f, R, reg] = irA(destino, f, R, robot, laser, cal, mapa, ctl, rc, semiCono, modo)
% IRA  Lleva el robot a un destino [x y] replanificando ante imprevistos.
%   1) Planifica con A* desde la pose estimada y navega SIN bordear: si el
%      frontal o una diagonal ven algo que no está en el mapa, el robot se para.
%   2) Marca el imprevisto en la rejilla, retrocede si ha quedado dentro de la
%      zona inflada y vuelve a planificar.
%   3) Si con lo marcado no queda camino, olvida las marcas y hace un intento
%      bordeando el obstáculo con el control reactivo.
%   modo (opcional): 'replanificar' (por defecto, lo descrito arriba) o 'bordear':
%        el tramo empieza olvidando las marcas y bordeando los imprevistos con
%        el control reactivo; si aun así se bloquea, pasa a replanificar.
%   reg  registro: resultado, replanificaciones, veces que bordeó, tiempo,
%        longitud, trayectorias y planes [x y] de cada intento.
if nargin < 10, semiCono = 0.3; end
if nargin < 11, modo = 'replanificar'; end
reg.resultado = 'sin camino';  reg.replan = 0;  reg.bordeos = 0;  reg.tiempo = 0;  reg.longitud = 0;
reg.Xr = zeros(3,0);  reg.Xe = zeros(3,0);  reg.reactivo = false(1,0);  reg.planes = {};
bordear = strcmp(modo, 'bordear');
if bordear                                                % empezar sin marcas y con el reactivo
    R.dist = R.dist0;  R = actualizarRejilla(R);  reg.bordeos = 1;
end
for intento = 1:10
    [puntos, info] = planificar(R, f.X(1:2)', destino, 'Astar');
    if ~info.encontrado                                   % sin camino con lo descubierto
        R.dist = R.dist0;  R = actualizarRejilla(R);      % olvidar las marcas...
        bordear = true;  reg.bordeos = reg.bordeos + 1;   % ...y bordear con el reactivo
        fprintf('   Sin camino alternativo: se intenta bordear con el control reactivo\n');
        [puntos, info] = planificar(R, f.X(1:2)', destino, 'Astar');
        if ~info.encontrado, reg.resultado = 'sin camino';  return; end
    end
    reg.planes{end+1} = [f.X(1:2)'; puntos];
    [f, r] = navegar(robot, laser, puntos, f, cal, mapa, ctl, rc, bordear, [], R, semiCono);
    bordear = false;
    reg.tiempo = reg.tiempo + r.tiempo;  reg.longitud = reg.longitud + r.longitud;
    reg.Xr = [reg.Xr r.Xr];  reg.Xe = [reg.Xe r.Xe];  reg.reactivo = [reg.reactivo r.reactivo];
    reg.resultado = r.resultado;
    if ~strcmp(r.resultado, 'bloqueado'), return; end
    [R, n] = marcarObstaculos(R, f.X, r.us, r.esp, mapa);  % aprender el obstáculo
    reg.replan = reg.replan + 1;
    fprintf('   Imprevisto en [%.2f %.2f]: %d puntos marcados, replanificando...\n', f.X(1:2), n);
    % Si el robot ha quedado dentro de la zona inflada, retrocede por donde vino
    for k = 1:40
        fc = min(max(floor(f.X(2)/R.res) + 1, 1), numel(R.yc));
        cc = min(max(floor(f.X(1)/R.res) + 1, 1), numel(R.xc));
        if R.libre(fc, cc), break; end
        if ~apoloMoveMRobot(robot, [-0.15 0], 0.1), break; end
        f = ekfPaso(f, apoloGetOdometry(robot), apoloGetLaserLandMarks(laser), mapa, cal);
        real = apoloGetLocationMRobot(robot);
        reg.Xr(:,end+1) = [real(1); real(2); real(4)];  reg.Xe(:,end+1) = f.X;  reg.reactivo(end+1) = false;
        reg.tiempo = reg.tiempo + 0.1;
    end
    apoloUpdate();
end
reg.resultado = 'demasiados intentos';
end
