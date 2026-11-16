function [v, w, rho, alpha] = controladorPunto(X, objetivo, ctl)
% CONTROLADORPUNTO  Velocidades (v, w) para llevar el robot hacia un punto.
%   X        pose estimada [x y theta] (la del EKF)
%   objetivo punto [xg yg]
%   ctl      ganancias y límites: Kv, Kalpha, vmax, wmax, alphaGiro
%
% Ley de control:  v = Kv*rho*cos(alpha)   w = Kalpha*alpha
%   rho   = distancia al objetivo
%   alpha = ángulo que habría que girar para mirar al objetivo
% Estable si Kalpha > Kv (ver memoria). Si |alpha| > alphaGiro el robot
% gira sobre el sitio (v = 0) antes de avanzar.

dx = objetivo(1) - X(1);  dy = objetivo(2) - X(2);
rho = hypot(dx, dy);
alpha = atan2(dy, dx) - X(3);
alpha = atan2(sin(alpha), cos(alpha));               % a [-pi, pi]

w = max(-ctl.wmax, min(ctl.wmax, ctl.Kalpha*alpha));  % saturación de giro
if abs(alpha) > ctl.alphaGiro
    v = 0;                                            % primero orientarse
elseif ctl.frenar
    v = min(ctl.vmax, ctl.Kv*rho) * cos(alpha);       % saturación de avance
else 
    v = ctl.vmax * cos(alpha); 

end
end
