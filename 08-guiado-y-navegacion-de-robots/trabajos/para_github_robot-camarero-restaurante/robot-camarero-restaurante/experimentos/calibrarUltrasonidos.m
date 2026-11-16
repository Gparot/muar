%% CALIBRACIÓN DE LOS ULTRASONIDOS
% (Se puede pegar al final de CalibrarLaser.m o ejecutar por separado.)
% A) Ruido y sesgo: cada sensor se coloca mirando de frente a una pared lisa
%    (fachada, y = 0, en x ~ 7) a distancias conocidas y se compara la lectura
%    con la distancia real sensor-pared.
% B) Apertura del cono: con el sensor frontal a ~1 m de la pared de la cocina
%    (y = 10) se gira el robot. Un rayo ideal mediría d/cos(phi); un cono
%    sigue midiendo d (el punto más cercano) hasta que phi supera su semiángulo.

raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
robot = 'Marvin';
mapa  = mapaRestaurante();
US    = mapa.ultrasonidos;                 % {nombre, [x y z], guiñada}
nS    = size(US, 1);
dTeo  = 0.4:0.3:2.8;                       % distancias de prueba (m); alcance = 3 m
Nrep  = 30;                                % lecturas por distancia y sensor

%% A) Ruido y sesgo frente a la distancia
datosU = [];                               % filas: [sensor  d_teorica  lectura]
for s = 1:nS
    o = US{s,2};  yaw = US{s,3};
    th = -pi/2 - yaw;                      % orientación del robot para que el sensor mire a y = 0
    dyS = o(1)*sin(th) + o(2)*cos(th);     % altura del sensor respecto al centro del robot
    for d = dTeo
        for r = 1:Nrep
            x = 7.0 + 0.4*(rand - 0.5);    % pequeña variación lateral entre lecturas
            if ~apoloPlaceMRobot(robot, [x, d - dyS, 0], th), continue; end
            real = apoloGetLocationMRobot(robot);                 % [x y z theta]
            dReal = real(2) + o(1)*sin(real(4)) + o(2)*cos(real(4));   % distancia real sensor-pared
            us = apoloGetAllultrasonicSensors(robot);
            datosU = [datosU; s, dReal, us(s)]; %#ok<AGROW>
        end
    end
    apoloUpdate();
    fprintf('Sensor %s: hecho\n', US{s,1});
end

valido = datosU(:,3) < 2.99;               % 3.0 = sin eco (saturación)
errU = datosU(:,3) - datosU(:,2);
fprintf('\n%-6s %12s %12s %10s\n', 'Sensor', 'Sesgo (m)', 'Var (m^2)', 'Sigma (m)');
for s = 1:nS
    k = datosU(:,1) == s & valido;
    fprintf('%-6s %12.4f %12.3e %10.4f\n', US{s,1}, mean(errU(k)), var(errU(k)), std(errU(k)));
end
% Dependencia con la distancia (todos los sensores juntos)
dC = unique(round(datosU(:,2)*10)/10);  sesgoD = nan(size(dC));  varD = nan(size(dC));
for i = 1:numel(dC)
    k = abs(datosU(:,2) - dC(i)) < 0.05 & valido;
    if sum(k) >= 10, sesgoD(i) = mean(errU(k));  varD(i) = var(errU(k)); end
end
ok = ~isnan(varD);
calibU.var_dist    = var(errU(valido));            % R de los ultrasonidos (constante)
calibU.sesgo       = mean(errU(valido));
calibU.ajusteSesgo = polyfit(dC(ok), sesgoD(ok), 1);   % sesgo = a*d + b
calibU.ajusteVar   = polyfit(dC(ok), varD(ok), 1);
calibU.sinEco      = mean(~valido);                % fracción de lecturas saturadas

%% B) Apertura del cono (sensor frontal)
phi = deg2rad(0:2.5:60);
o1  = US{1,2};
lectC = nan(size(phi));  perpC = nan(size(phi));
for i = 1:numel(phi)
    th = pi/2 + phi(i);                               % mirando a la pared y = 10, girado phi
    if ~apoloPlaceMRobot(robot, [3.25, 8.75, 0], th), continue; end
    real = apoloGetLocationMRobot(robot);
    perpC(i) = 10 - (real(2) + o1(1)*sin(real(4)));   % distancia perpendicular sensor-pared
    lect = zeros(1, 10);
    for r = 1:10, us = apoloGetAllultrasonicSensors(robot);  lect(r) = us(1); end
    lectC(i) = mean(lect);
end
rayo = perpC ./ cos(phi);                             % lo que mediría un rayo sin cono
% Con cono de semiángulo beta: lectura = perp/cos(phi - beta) cuando phi > beta
k = lectC > 1.03*perpC & lectC < 2.9;
if any(k)
    calibU.semiCono = median(phi(k) - acos(min(1, perpC(k)./lectC(k))));
else
    calibU.semiCono = NaN;                            % no se ha superado el cono en 60°
end
fprintf('\n');  disp(calibU);
fprintf('Semiángulo del cono: %.1f grados\n', rad2deg(calibU.semiCono));
save('calib_ultrasonidos.mat', 'calibU', 'datosU', 'phi', 'lectC', 'perpC');
apoloPlaceMRobot(robot, [mapa.robot.pose(1:2) 0], mapa.robot.pose(3));  apoloUpdate();

%% Gráficas (para la memoria)
figure('Name', 'Calibración ultrasonidos');
subplot(2,2,1); histogram(errU(valido), 40); grid on;
title('Error de distancia'); xlabel('lectura - real (m)');
subplot(2,2,2); plot(dC, sesgoD, 'o', dC, polyval(calibU.ajusteSesgo, dC), '-'); grid on;
title('Sesgo según distancia'); xlabel('distancia (m)'); ylabel('sesgo (m)');
subplot(2,2,3); plot(dC, varD, 'o', dC, polyval(calibU.ajusteVar, dC), '-'); grid on;
title('Varianza según distancia'); xlabel('distancia (m)'); ylabel('var (m^2)'); ylim([0 inf]);
subplot(2,2,4); plot(rad2deg(phi), lectC, 'o-', rad2deg(phi), perpC, '--', rad2deg(phi), rayo, ':'); grid on;
legend('lectura', 'dist. perpendicular (cono)', 'rayo ideal', 'Location', 'northwest');
title('Apertura del cono'); xlabel('giro respecto a la pared (º)'); ylabel('distancia (m)');
