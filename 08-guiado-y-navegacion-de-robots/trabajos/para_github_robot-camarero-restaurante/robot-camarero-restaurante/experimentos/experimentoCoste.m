%% EXPERIMENTOCOSTE  Influencia del coste por celda en el camino de A*.
% Mismo trayecto con kCoste = 0 (todas las celdas cuestan 1), 1 (valor del
% demostrador) y 3. Mide longitud, nodos expandidos y margen a los obstáculos.
% Necesita: mapaRestaurante, dibujarMapa, rejillaOcupacion, actualizarRejilla,
%           buscarCamino, simplificarCamino, planificar

clear; close all;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
mapa = mapaRestaurante();
res = 0.1;  radio = 0.40;  dSeg = 0.8;           % los valores del demostrador
kCostes = [0 1 3];
rutas = {[5.8 11.5], [16.4 2.8], 'Cocina -> M4';
         [10 10.4],  [1.6 2.8],  'Barra -> M1'};
col = {[1 0.4 0.4], [1 1 1], [0.3 0.8 1]};

for r = 1:size(rutas, 1)
    fprintf('\n%s\n%8s %10s %7s %12s %13s %8s\n', rutas{r,3}, 'kCoste', 'Long. (m)', ...
            'Nodos', 'Dist. mín.', 'Dist. media', 'Puntos');
    dibujarMapa(mapa);  hold on;  title(['Coste por celda: ' rutas{r,3}]);
    h = zeros(1, numel(kCostes));  nombres = cell(1, numel(kCostes));
    for k = 1:numel(kCostes)
        R = rejillaOcupacion(mapa, res, radio, dSeg, kCostes(k));
        [pts, info] = planificar(R, rutas{r,1}, rutas{r,2}, 'Astar');
        d = R.dist(sub2ind(size(R.dist), info.camino(:,1), info.camino(:,2)));   % margen en cada celda
        fprintf('%8.0f %10.2f %7d %10.2f m %11.2f m %8d\n', kCostes(k), info.longitud, ...
                info.nodos, min(d), mean(d), size(pts, 1));
        h(k) = plot(info.caminoXY(:,1), info.caminoXY(:,2), '-', 'Color', col{k}, 'LineWidth', 1.8);
        nombres{k} = sprintf('kCoste = %g', kCostes(k));
    end
    legend(h, nombres, 'Location', 'northeast');
end
