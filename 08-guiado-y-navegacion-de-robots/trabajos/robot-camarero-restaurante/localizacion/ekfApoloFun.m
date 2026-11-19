function res = ekfApoloFun(par)
% EKFAPOLOFUN  Misma lógica que ekfApolo.m, como función con parámetros.
% Todos los campos de 'par' son opcionales:
%   fQ, fR          multiplicadores de Q y R (1 = valores calibrados)
%   P0              matriz 3x3, P(0|0)
%   errorInicial    [ex ey eth]: error deliberado en X(0|0)
%   balizasUsadas   ids de las balizas que se aceptan (vacío = todas)
%   sinCorreccion   [k1 k2]: tramo de muestras sin corrección (vacío = nunca)
%   validar         true = validación por distancia de Mahalanobis      (NUEVO)
%   recuperar       true = si se rechazan todas las balizas durante
%                   'pasosPerdido' pasos seguidos, se infla P             (NUEVO)
%   pasosPerdido    nº de pasos seguidos con todo rechazado (20 = 2 s)  (NUEVO)
%   inflado         covarianza que se suma a P al recuperar             (NUEVO)
%   dibujar         true = refrescar la vista de Apolo durante la ejecución

%% Parámetros por defecto
def.fQ = 1;  def.fR = 1;
def.P0 = diag([0.05^2, 0.05^2, deg2rad(2)^2]);
def.errorInicial = [0 0 0];
def.balizasUsadas = [];
def.sinCorreccion = [];
def.validar = true;
def.recuperar = true;
def.pasosPerdido = 20;
def.inflado = diag([1, 1, 0.5^2]);
def.dibujar = false;
if nargin < 1, par = struct(); end
campos = fieldnames(def);
for i = 1:numel(campos)
    if ~isfield(par, campos{i}), par.(campos{i}) = def.(campos{i}); end
end

%% Calibración (valores finales)
k_d = 1.50e-4;   k_b = 3.29e-5;   q_min = 1e-8;     % odometría (N = 50)
R_d = 3.5e-4;    R_a = 5.0e-4;                      % láser

robot = 'Marvin';  laser = 'LMS100';
mapa = mapaRestaurante();
balizas = mapa.balizas;  a = mapa.laser.posicion(1);
envolver = @(ang) atan2(sin(ang), cos(ang));

%% Trayectoria (la misma ruta que ekfApolo)
timestep = 0.1;
segmentos = [0.3 0 6.4/0.3; 0 0.5 pi; 0.3 0 6/0.3; 0 0.5 2*pi; ...
             0.3 0 6/0.3;   0 -0.5 pi; 0.3 0 6.4/0.3];
velocidadL = [];  velocidadA = [];
for s = 1:size(segmentos,1)
    n = round(segmentos(s,3)/timestep);  f = segmentos(s,3)/(n*timestep);
    velocidadL = [velocidadL, repmat(segmentos(s,1)*f, 1, n)]; %#ok<AGROW>
    velocidadA = [velocidadA, repmat(segmentos(s,2)*f, 1, n)]; %#ok<AGROW>
end
N = length(velocidadL);

%% Inicialización
xini = 10;  yini = 9.2;  thetaini = -pi/2;
apoloPlaceMRobot(robot, [xini yini 0], thetaini);
apoloResetOdometry(robot, [0 0 0]);          % odometría en su propio marco
apoloUpdate();
Xk = [xini; yini; thetaini] + par.errorInicial(:);
Pk = par.P0;
odoAnterior = apoloGetOdometry(robot);

Xreal = zeros(3,N);  Xestimado = zeros(3,N);  Xodo = zeros(3,N);
Pacumulado = zeros(3,N);  nBalizas = zeros(1,N);  nRechazadas = zeros(1,N);
NIS = nan(1,N);
seguidos = 0;  recuperaciones = [];

%% Algoritmo
for l = 1:N
    % Avance real (Apolo)
    apoloMoveMRobot(robot, [velocidadL(l) velocidadA(l)], timestep);
    real = apoloGetLocationMRobot(robot);
    Xreal(:,l) = [real(1); real(2); real(4)];

    % Uk a partir de la odometría
    odo = apoloGetOdometry(robot);
    dB = envolver(odo(3) - odoAnterior(3));
    dD = hypot(odo(1) - odoAnterior(1), odo(2) - odoAnterior(2));
    if (odo(1)-odoAnterior(1))*cos(odoAnterior(3)+dB/2) + ...
       (odo(2)-odoAnterior(2))*sin(odoAnterior(3)+dB/2) < 0
        dD = -dD;
    end
    odoAnterior = odo;
    Xodo(:,l) = [xini + odo(1)*cos(thetaini) - odo(2)*sin(thetaini);
                 yini + odo(1)*sin(thetaini) + odo(2)*cos(thetaini);
                 envolver(odo(3) + thetaini)];
    Uk = [dD; dB];
    Qk_1 = par.fQ * [k_d*abs(Uk(1)) + q_min, 0; 0, k_b*abs(Uk(2)) + q_min];

    % Predicción
    Xk_1 = Xk;  Pk_1 = Pk;
    X_k = [(Xk_1(1) + Uk(1)*cos(Xk_1(3)+(Uk(2)/2)));
           (Xk_1(2) + Uk(1)*sin(Xk_1(3)+(Uk(2)/2)));
           (Xk_1(3) + Uk(2))];
    Ak = [1 0 (-Uk(1)*sin(Xk_1(3)+Uk(2)/2));
          0 1 (Uk(1)*cos(Xk_1(3)+Uk(2)/2));
          0 0 1];
    Bk = [(cos(Xk_1(3)+Uk(2)/2)) (-0.5*Uk(1)*sin(Xk_1(3)+Uk(2)/2));
          (sin(Xk_1(3)+Uk(2)/2)) (0.5*Uk(1)*cos(Xk_1(3)+Uk(2)/2));
           0 1];
    P_k = Ak*Pk_1*Ak' + Bk*Qk_1*Bk';

    % Medidas: se construyen baliza a baliza y se validan antes de apilarlas
    corregir = isempty(par.sinCorreccion) || ...
               l < par.sinCorreccion(1) || l > par.sinCorreccion(2);
    Zk = []; Zk_ = []; Hk = []; Rdiag = []; esAngulo = [];
    vistas = 0;  rechazadas = 0;
    if corregir
        lm = apoloGetLaserLandMarks(laser);
        xl = X_k(1) + a*cos(X_k(3));  yl = X_k(2) + a*sin(X_k(3));
        for i = 1:numel(lm.id)
            id = double(lm.id(i));
            if ~isempty(par.balizasUsadas) && ~ismember(id, par.balizasUsadas), continue; end
            vistas = vistas + 1;
            fila = find(balizas(:,1) == id, 1);
            dx = balizas(fila,2) - xl;  dy = balizas(fila,3) - yl;  q = dx^2 + dy^2;
            Hdist = [-dx/sqrt(q), -dy/sqrt(q),  a*(dx*sin(X_k(3)) - dy*cos(X_k(3)))/sqrt(q)];
            Hang  = [ dy/q,       -dx/q,       -a*(dx*cos(X_k(3)) + dy*sin(X_k(3)))/q - 1];
            if lm.distance(i) > 0.1                       % distancia y ángulo
                zi = [lm.distance(i); lm.angle(i)];  zpi = [sqrt(q); atan2(dy,dx) - X_k(3)];
                Hi = [Hdist; Hang];  Ri = par.fR*[R_d; R_a];  angi = [0; 1];  umbral = 9.21;
            else                                          % distancia inválida: solo ángulo
                zi = lm.angle(i);  zpi = atan2(dy,dx) - X_k(3);
                Hi = Hang;  Ri = par.fR*R_a;  angi = 1;  umbral = 6.63;
            end
            % Validación por distancia de Mahalanobis (chi2 al 99 %)
            if par.validar
                yi = zi - zpi;  yi(angi == 1) = envolver(yi(angi == 1));
                Si = Hi*P_k*Hi' + diag(Ri);
                if yi' * (Si \ yi) > umbral
                    rechazadas = rechazadas + 1;
                    continue;
                end
            end
            Zk = [Zk; zi];  Zk_ = [Zk_; zpi];  Hk = [Hk; Hi];             %#ok<AGROW>
            Rdiag = [Rdiag; Ri];  esAngulo = [esAngulo; angi];            %#ok<AGROW>
            nBalizas(l) = nBalizas(l) + 1;
        end
    end
    nRechazadas(l) = rechazadas;

    % Corrección
    if isempty(Zk)
        Xk = X_k;  Pk = P_k;                 % solo predicción
    else
        Yk = Zk - Zk_;
        Yk(esAngulo == 1) = envolver(Yk(esAngulo == 1));
        Sk = Hk*P_k*Hk' + diag(Rdiag);
        Wk = P_k*Hk'/Sk;
        Xk = X_k + Wk*Yk;
        Pk = (eye(3) - Wk*Hk)*P_k;
        NIS(l) = (Yk' * (Sk \ Yk)) / length(Yk);   % debería valer ~1 de media
    end
    Xk(3) = envolver(Xk(3));

    % Detección de pérdida y recuperación: se ven balizas pero se rechazan todas
    if vistas > 0 && rechazadas == vistas
        seguidos = seguidos + 1;
    else
        seguidos = 0;
    end
    if par.recuperar && seguidos >= par.pasosPerdido
        Pk = Pk + par.inflado;               % reabre la puerta de validación
        seguidos = 0;
        recuperaciones(end+1) = l;           %#ok<AGROW>
    end

    Xestimado(:,l) = Xk;
    Pacumulado(:,l) = diag(Pk);
    if par.dibujar && mod(l,10) == 0, apoloUpdate(); end
end
apoloUpdate();

%% Métricas
err = Xestimado - Xreal;  err(3,:) = envolver(err(3,:));
errOdo = Xodo - Xreal;    errOdo(3,:) = envolver(errOdo(3,:));
res.Xreal = Xreal;  res.Xestimado = Xestimado;  res.Xodo = Xodo;
res.Pacumulado = Pacumulado;  res.nBalizas = nBalizas;  res.nRechazadas = nRechazadas;
res.err = err;  res.errOdo = errOdo;
res.rmsePos   = sqrt(mean(err(1,:).^2 + err(2,:).^2));
res.rmseTheta = sqrt(mean(err(3,:).^2));
res.rmseOdo   = sqrt(mean(errOdo(1,:).^2 + errOdo(2,:).^2));
res.dentro3s  = 100 * mean(abs(err) <= 3*sqrt(Pacumulado), 2)';   % consistencia
res.NIS = NIS;  res.NISmedio = mean(NIS, 'omitnan');
res.totalRechazadas = sum(nRechazadas);
res.recuperaciones = recuperaciones;
res.par = par;
end
