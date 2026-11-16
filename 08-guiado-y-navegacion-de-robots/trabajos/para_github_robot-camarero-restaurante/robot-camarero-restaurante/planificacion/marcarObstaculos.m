function [R, n] = marcarObstaculos(R, X, us, esp, mapa)
% MARCAROBSTACULOS  Añade a la rejilla los obstáculos imprevistos que ven los ultrasonidos.
%   X    pose estimada [x y theta] (EKF)
%   us   lecturas de los 5 ultrasonidos;  esp = lecturas esperadas (lecturaEsperada)
% Una lectura es un imprevisto si es menor de 1 m y bastante menor (0.25 m)
% que la esperada con el mapa conocido. Su punto se marca como un obstáculo
% de 0.2 m de radio y se recalculan las celdas libres y los costes.
dMax = 1.0;  rObs = 0.2;  n = 0;
[XC, YC] = meshgrid(R.xc, R.yc);
U = mapa.ultrasonidos;
for i = 1:size(U, 1)
    if us(i) >= dMax || us(i) >= esp(i) - 0.25, continue; end
    o = U{i,2};  a = X(3) + U{i,3};
    px = X(1) + o(1)*cos(X(3)) - o(2)*sin(X(3)) + us(i)*cos(a);
    py = X(2) + o(1)*sin(X(3)) + o(2)*cos(X(3)) + us(i)*sin(a);
    R.dist = min(R.dist, max(hypot(XC - px, YC - py) - rObs, 0));
    n = n + 1;
end
R = actualizarRejilla(R);
end
