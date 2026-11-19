function [v, w, est, activo] = controladorReactivo(v, w, alpha, rho, us, est, ctl, rc)
% CONTROLADORREACTIVO  Control reactivo de dos modos con los 5 ultrasonidos.
%   IR     -> manda el controlador de puntos (solo frena si hay algo muy cerca delante)
%   GIRAR  -> obstáculo delante: gira sobre el sitio hacia el lado más libre
%   SEGUIR -> bordea el obstáculo manteniéndolo a una distancia dRef en un costado
% Vuelve a IR cuando la dirección del objetivo está libre Y el robot está más
% cerca del objetivo que cuando empezó a rodear (condición de los algoritmos Bug).
%
%   v, w   comandos del controlador de puntos
%   alpha  ángulo hacia el objetivo (rad);  rho = distancia al objetivo (m)
%   us     [uc0 ul1 ur1 ul2 ur2] = frontal, diag. izq., diag. der., lateral izq., lateral der.
%   est    estado entre llamadas (inicializar con est.modo = 'IR')
%   rc     parámetros (definidos en seguirPuntos)

envolver = @(a) atan2(sin(a), cos(a));
angS = [0, pi/4, -pi/4, pi/2, -pi/2];        % orientación de cada sensor en el robot
frente = us(1);
activo = false;

%% Modo IR: manda el controlador de puntos
if strcmp(est.modo, 'IR')
    if frente < rc.dEntrada && abs(alpha) < deg2rad(60) && rho > rc.rCerca
        % Obstáculo delante: rodearlo por el lado más libre
        if us(2) + us(4) < us(3) + us(5), o = 1; else, o = -1; end   % o = lado del obstáculo (+1 = izq.)
        est = struct('modo', 'GIRAR', 'o', o, 'rho0', rho, 'cont', 0, 't', 0);
    elseif min(us(2), us(3)) < rc.dDiag && rho > rc.rCerca
        % Obstáculo en una diagonal: solo molesta si el objetivo está hacia ese lado
        if us(2) < us(3), o = 1; else, o = -1; end
        if sign(alpha) == o || abs(alpha) < deg2rad(10)
            est = struct('modo', 'SEGUIR', 'o', o, 'rho0', rho, 'cont', 0, 't', 0);
        end
    end
    if strcmp(est.modo, 'IR')
        if frente < rc.dParada, v = 0; end            % seguridad
        return;
    end
end

activo = true;
est.t = est.t + 1;
o = est.o;
if o == 1
    iD = 2; iL = 4; fD = 3; fL = 5;    % obstáculo a la izquierda, lado libre a la derecha
else
    iD = 3; iL = 5; fD = 2; fL = 4;    % obstáculo a la derecha, lado libre a la izquierda
end

%% Modo GIRAR: girar sobre el sitio hasta tener el frente despejado
if strcmp(est.modo, 'GIRAR')
    if frente > rc.dLibre
        est.modo = 'SEGUIR';
    else
        v = 0;  w = -o*ctl.wmax;       % gira alejándose del obstáculo
        return;
    end
end

%% Modo SEGUIR
% 1) ¿Se puede volver a ir al objetivo? Dirección del objetivo libre + progreso,
%    durante nSalida pasos seguidos (evita salir por un parpadeo del cono)
[~, j] = min(abs(envolver(alpha - angS)));                 % sensor que mira hacia el objetivo
libre = abs(envolver(alpha - angS(j))) < deg2rad(30) && ...
    us(j) > rc.dSalida && us(iD) > rc.dSalidaDiag;
if libre && rho < est.rho0 - rc.progreso
    est.cont = est.cont + 1;
else
    est.cont = 0;
end
if est.cont >= rc.nSalida || est.t > rc.tMax
    est = struct('modo', 'IR');
    activo = false;
    return;                            % en este paso manda el controlador de puntos
end

% 2) Algo delante mientras bordea: volver a girar
if frente < rc.dFrente
    est.modo = 'GIRAR';
    v = 0;  w = -o*ctl.wmax;
    return;
end

% 3) Seguir el contorno: mantener dRef al obstáculo y separarse del otro
%    costado si también se cierra (pasos estrechos)
d  = min(us(iL), us(iD)*cos(pi/4));     % distancia al obstáculo (lateral o diagonal proyectada)
e  = max(rc.eMin, rc.dRef - d);         % >0 demasiado cerca; <0 lejos (limitado: no cortar esquinas)
dl = min(us(fL), us(fD)*cos(pi/4));     % distancia en el lado libre
el = max(0, rc.dLadoLibre - dl);        % >0 si el lado libre también se cierra
w  = -o*rc.Kw*e + o*rc.Kw*el;
w  = max(-ctl.wmax, min(ctl.wmax, w));
v  = rc.vBordeo;
if el > 0, v = 0.6*rc.vBordeo; end       % más despacio en pasos estrechos
end