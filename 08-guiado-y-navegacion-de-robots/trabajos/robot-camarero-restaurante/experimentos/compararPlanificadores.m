%% COMPARARPLANIFICADORES  Experimentos de planificación sobre el restaurante.
%  1) Compara anchura, profundidad, primero el mejor, Dijkstra y A* en la
%     misma ruta (nodos expandidos, memoria, longitud, tiempo).
%  2) Influencia del inflado (radio) en el camino de A*.
% Necesita: mapaRestaurante, rejillaOcupacion, buscarCamino, simplificarCamino, planificar

clear; close all;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
mapa = mapaRestaurante();
res = 0.1;  radio = 0.35;                       % celda de 10 cm; inflado = medio ancho del robot + margen
R = rejillaOcupacion(mapa, res, radio);
origen  = [5.8 11.5];                           % pase de cocina
destino = [16.4 2.8];                           % mesa M4: cruza todo el restaurante

%% 1) Comparación de algoritmos
metodos = {'BF', 'DF', 'BestFirst', 'Dijkstra', 'Astar'};
nombres = {'Anchura', 'Profundidad', 'BestFirst', 'Dijkstra', 'A*'};
nM = numel(metodos);  pts = cell(nM,1);  info = cell(nM,1);
fprintf('\nRuta [%.1f %.1f] -> [%.1f %.1f], rejilla %dx%d, inflado %.2f m\n', ...
        origen, destino, size(R.libre), radio);
fprintf('%-17s %7s %8s %9s %6s %10s %7s %9s\n', 'Método', 'Nodos', 'MaxOpen', ...
        'MaxClosed', 'Pasos', 'Long. (m)', 'Puntos', 'Tiempo');
for m = 1:nM
    [pts{m}, info{m}] = planificar(R, origen, destino, metodos{m});
    I = info{m};
    fprintf('%-17s %7d %8d %9d %6d %10.2f %7d %8.3fs\n', nombres{m}, I.nodos, ...
            I.maxOpen, I.maxClosed, I.pasos, I.longitud, size(pts{m},1), I.tiempo);
end

figure('Name', 'Comparación de planificadores');
for m = 1:nM
    subplot(2,3,m);
    dibujarRejilla(R, info{m}, pts{m}, origen, destino);
    title(sprintf('%s: %d nodos, %.1f m', nombres{m}, info{m}.nodos, info{m}.longitud));
end
subplot(2,3,6); axis off;
text(0, 0.8, 'negro: obstáculo', 'Color', 'k');
text(0, 0.65, 'gris: zona inflada', 'Color', [0.5 0.5 0.5]);
text(0, 0.5, 'azul: celdas examinadas', 'Color', [0.2 0.5 0.9]);
text(0, 0.35, 'rojo: camino de celdas', 'Color', 'r');
text(0, 0.2, 'amarillo: puntos para el controlador', 'Color', [0.8 0.6 0]);

%% 2) Influencia del inflado en A*
radios = [0.25 0.30 0.35 0.40 0.45];
fprintf('\nInfluencia del inflado (A*)\n');
fprintf('%8s %10s %7s %22s\n', 'Radio', 'Long. (m)', 'Nodos', 'Dist. mín. a obstáculo');
figure('Name', 'Influencia del inflado');
for k = 1:numel(radios)
    Rk = rejillaOcupacion(mapa, res, radios(k));
    [pk, ik] = planificar(Rk, origen, destino, 'Astar');
    if ik.encontrado
        dmin = min(Rk.dist(sub2ind(size(Rk.dist), ik.camino(:,1), ik.camino(:,2))));
        fprintf('%8.2f %10.2f %7d %20.2f m\n', radios(k), ik.longitud, ik.nodos, dmin);
    else
        fprintf('%8.2f %10s %7d %22s\n', radios(k), 'sin camino', ik.nodos, '-');
    end
    subplot(2,3,k);
    dibujarRejilla(Rk, ik, pk, origen, destino);
    title(sprintf('radio %.2f m', radios(k)));
end

%% ---------------------------------------------------------------
function dibujarRejilla(R, info, pts, origen, destino)
% Rejilla en color + celdas examinadas + camino + puntos de giro
img = ones([size(R.libre) 3]);                                % blanco: libre
capas = {~R.libre,              [0.75 0.75 0.75];             % gris: inflado
         info.cerradas & R.libre, [0.70 0.85 1.00];           % azul: examinadas
         R.obstaculo,           [0 0 0]};                     % negro: obstáculo
for k = 1:size(capas,1)
    for ch = 1:3
        canal = img(:,:,ch);
        canal(capas{k,1}) = capas{k,2}(ch);
        img(:,:,ch) = canal;
    end
end
image(R.xc, R.yc, img);  set(gca, 'YDir', 'normal');  axis equal tight;  hold on;
if info.encontrado
    plot(info.caminoXY(:,1), info.caminoXY(:,2), 'r-', 'LineWidth', 1.5);
    plot([origen(1); pts(:,1)], [origen(2); pts(:,2)], 'o--', ...
         'Color', [0.9 0.7 0], 'MarkerFaceColor', [1 0.85 0], 'LineWidth', 1);
end
plot(origen(1), origen(2), 'gs', 'MarkerSize', 9, 'MarkerFaceColor', 'g');
plot(destino(1), destino(2), 'mp', 'MarkerSize', 11, 'MarkerFaceColor', 'm');
xlabel('x (m)');  ylabel('y (m)');
end
