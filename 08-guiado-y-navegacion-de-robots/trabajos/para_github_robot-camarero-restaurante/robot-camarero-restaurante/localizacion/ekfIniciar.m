function [f, cal] = ekfIniciar(X0, P0, odo0)
% EKFINICIAR  Crea el estado del filtro y la calibración para usar ekfPaso.
%   X0   pose inicial [x y theta]
%   P0   covarianza inicial 3x3
%   odo0 primera lectura de apoloGetOdometry (tras resetearla a [0 0 0])

f.X = X0(:);
f.P = P0;
f.odoAnt = odo0;
f.seguidos = 0;          % pasos seguidos con todas las balizas rechazadas

% Calibración (valores finales)
cal.k_d = 1.50e-4;   cal.k_b = 3.29e-5;   cal.q_min = 1e-8;
cal.R_d = 3.5e-4;    cal.R_a = 5.0e-4;
% Validación y recuperación
cal.validar = true;  cal.recuperar = true;
cal.pasosPerdido = 20;
cal.inflado = diag([1, 1, 0.5^2]);
end
