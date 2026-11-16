function [f, info] = ekfPaso(f, odo, lm, mapa, cal)
% EKFPASO  Un paso del EKF (predicción + validación + corrección).
% Es exactamente el mismo algoritmo que ekfApoloFun, separado en una función
% para poder usarlo dentro de cualquier bucle (controlador, demostrador...).
%   f    estado del filtro (X, P, odoAnt, seguidos), creado con ekfIniciar
%   odo  lectura actual de apoloGetOdometry
%   lm   lectura actual de apoloGetLaserLandMarks
envolver = @(ang) atan2(sin(ang), cos(ang));

%% Uk = [Δd; Δβ] a partir de la odometría
dB  = envolver(odo(3) - f.odoAnt(3));
dxo = odo(1) - f.odoAnt(1);  dyo = odo(2) - f.odoAnt(2);
dD  = hypot(dxo, dyo);
if dxo*cos(f.odoAnt(3)+dB/2) + dyo*sin(f.odoAnt(3)+dB/2) < 0, dD = -dD; end
f.odoAnt = odo;
Qk = [cal.k_d*abs(dD) + cal.q_min, 0; 0, cal.k_b*abs(dB) + cal.q_min];

%% Predicción
X = f.X;  th = X(3) + dB/2;
X_k = [X(1) + dD*cos(th);  X(2) + dD*sin(th);  X(3) + dB];
Ak = [1 0 -dD*sin(th); 0 1 dD*cos(th); 0 0 1];
Bk = [cos(th) -0.5*dD*sin(th); sin(th) 0.5*dD*cos(th); 0 1];
P_k = Ak*f.P*Ak' + Bk*Qk*Bk';

%% Medidas de balizas, validadas una a una
a = mapa.laser.posicion(1);  B = mapa.balizas;
xl = X_k(1) + a*cos(X_k(3));  yl = X_k(2) + a*sin(X_k(3));
Zk = []; Zk_ = []; Hk = []; Rdiag = []; esAngulo = [];
vistas = numel(lm.id);  rechazadas = 0;
for i = 1:vistas
    fila = find(B(:,1) == double(lm.id(i)), 1);
    dx = B(fila,2) - xl;  dy = B(fila,3) - yl;  q = dx^2 + dy^2;
    Hdist = [-dx/sqrt(q), -dy/sqrt(q),  a*(dx*sin(X_k(3)) - dy*cos(X_k(3)))/sqrt(q)];
    Hang  = [ dy/q,       -dx/q,       -a*(dx*cos(X_k(3)) + dy*sin(X_k(3)))/q - 1];
    if lm.distance(i) > 0.1
        zi = [lm.distance(i); lm.angle(i)];  zpi = [sqrt(q); atan2(dy,dx) - X_k(3)];
        Hi = [Hdist; Hang];  Ri = [cal.R_d; cal.R_a];  angi = [0; 1];  umbral = 9.21;
    else
        zi = lm.angle(i);  zpi = atan2(dy,dx) - X_k(3);
        Hi = Hang;  Ri = cal.R_a;  angi = 1;  umbral = 6.63;
    end
    if cal.validar
        yi = zi - zpi;  yi(angi == 1) = envolver(yi(angi == 1));
        if yi' * ((Hi*P_k*Hi' + diag(Ri)) \ yi) > umbral
            rechazadas = rechazadas + 1;
            continue;
        end
    end
    Zk = [Zk; zi];  Zk_ = [Zk_; zpi];  Hk = [Hk; Hi];       %#ok<AGROW>
    Rdiag = [Rdiag; Ri];  esAngulo = [esAngulo; angi];      %#ok<AGROW>
end

%% Corrección
info.NIS = NaN;
if isempty(Zk)
    f.X = X_k;  f.P = P_k;
else
    Yk = Zk - Zk_;  Yk(esAngulo == 1) = envolver(Yk(esAngulo == 1));
    Sk = Hk*P_k*Hk' + diag(Rdiag);
    Wk = P_k*Hk'/Sk;
    f.X = X_k + Wk*Yk;
    f.P = (eye(3) - Wk*Hk)*P_k;
    info.NIS = (Yk' * (Sk \ Yk)) / length(Yk);
end
f.X(3) = envolver(f.X(3));

%% Detección de pérdida y recuperación
info.recuperado = false;
if vistas > 0 && rechazadas == vistas, f.seguidos = f.seguidos + 1; else, f.seguidos = 0; end
if cal.recuperar && f.seguidos >= cal.pasosPerdido
    f.P = f.P + cal.inflado;  f.seguidos = 0;  info.recuperado = true;
end
info.nUsadas = vistas - rechazadas;
info.nRechazadas = rechazadas;
end
