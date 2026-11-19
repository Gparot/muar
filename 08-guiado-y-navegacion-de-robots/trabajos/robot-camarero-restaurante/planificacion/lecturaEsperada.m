function esp = lecturaEsperada(R, X, mapa, semiCono)
% LECTURAESPERADA  Lo que deberían medir los ultrasonidos si solo existieran
% los obstáculos CONOCIDOS del mapa. Para cada sensor se lanzan 7 rayos
% dentro de su cono sobre la rejilla y se toma el obstáculo más cercano.
% Solo interesa hasta 1.3 m (por encima devuelve 1.3).
%   Si la lectura real es bastante menor que la esperada, hay un imprevisto.
dMax = 1.3;  paso = R.res/2;
U = mapa.ultrasonidos;  nS = size(U, 1);
esp = dMax*ones(1, nS);
d = paso:paso:dMax;
conocido = R.dist0 <= R.res/2;
for i = 1:nS
    o = U{i,2};
    sx = X(1) + o(1)*cos(X(3)) - o(2)*sin(X(3));
    sy = X(2) + o(1)*sin(X(3)) + o(2)*cos(X(3));
    for a = X(3) + U{i,3} + linspace(-semiCono, semiCono, 7)
        f = floor((sy + d*sin(a))/R.res) + 1;  c = floor((sx + d*cos(a))/R.res) + 1;
        fuera = f < 1 | f > numel(R.yc) | c < 1 | c > numel(R.xc);
        f(fuera) = 1;  c(fuera) = 1;
        choca = fuera | conocido(sub2ind(size(conocido), f, c));
        k = find(choca, 1);
        if ~isempty(k), esp(i) = min(esp(i), d(k)); end
    end
end
end
