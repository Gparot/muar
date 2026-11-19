%% EXPERIMENTOSEKF  Influencia de P(0|0), Q, R, la validación y el mapa.
% Lanza ekfApoloFun con distintos parámetros, siempre sobre la misma ruta.
% Por defecto el filtro valida con Mahalanobis y se recupera si se pierde.
% "Base (repetición)" mide la variación debida solo al ruido aleatorio.

clear; close all;
raiz = fileparts(mfilename('fullpath'));              % carpeta de este script
if isempty(raiz) || ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = pwd; end   % p. ej. al ejecutar por secciones
if ~exist(fullfile(raiz, 'mapa'), 'dir'), raiz = fileparts(raiz); end        % si se está en una subcarpeta
addpath(genpath(raiz));                               % subcarpetas del trabajo
errIni = [0.5 0.5 0.2];       % error inicial deliberado [m m rad]
P0peq  = diag([1e-4 1e-4 1e-4]);

exps = {
    'Base',                              struct()
    'Base (repetición)',                 struct()
    'Err. inicial, P0 peq., sin validar', struct('errorInicial', errIni, 'P0', P0peq, 'validar', false)
    'Err. inicial, P0 peq., sin recuperar', struct('errorInicial', errIni, 'P0', P0peq, 'recuperar', false)
    'Err. inicial, P0 peq., con recuperar', struct('errorInicial', errIni, 'P0', P0peq)
    'Err. inicial, P0 coherente',        struct('errorInicial', errIni, 'P0', diag(errIni.^2))
    'Q x0.1',                            struct('fQ', 0.1)
    'Q x10',                             struct('fQ', 10)
    'R x0.1',                            struct('fR', 0.1)
    'R x10',                             struct('fR', 10)
    'Mitad de balizas',                  struct('balizasUsadas', 1:2:24)
    'Sin corrección (300-450)',          struct('sinCorreccion', [300 450])
    };
nE = size(exps,1);
R = cell(nE,1);
for e = 1:nE
    fprintf('Experimento %d/%d: %s ...\n', e, nE, exps{e,1});
    R{e} = ekfApoloFun(exps{e,2});
end
save('resultadosExperimentos.mat', 'R', 'exps');

%% Tabla resumen
fprintf('\n%-38s %9s %10s %6s %18s %9s\n', 'Experimento', 'RMSE pos', 'RMSE th', 'NIS', '% dentro 3σ (x,y,th)', 'Rechazos');
for e = 1:nE
    fprintf('%-38s %7.4f m %7.4f rad %6.2f   %5.1f %5.1f %5.1f %9d\n', exps{e,1}, ...
        R{e}.rmsePos, R{e}.rmseTheta, R{e}.NISmedio, R{e}.dentro3s, R{e}.totalRechazadas);
end
fprintf('%-38s %7.4f m\n', 'Solo odometría (base)', R{1}.rmseOdo);

t = (1:size(R{1}.err,2)) * 0.1;      % tiempo (s)

%% Fig. 1 - Error inicial: P0, validación y recuperación
figure('Name', 'Exp. P0 y validación');
idx = [3 4 5 6];  col = {'g', 'r', 'm', 'b'};
for k = 1:numel(idx)
    e = idx(k);
    semilogy(t, sqrt(R{e}.err(1,:).^2 + R{e}.err(2,:).^2), col{k}); hold on;
end
for r = R{5}.recuperaciones, xline(r*0.1, 'm:'); end     % instantes de recuperación
grid on; xlim([0 10]); xlabel('t (s)'); ylabel('error de posición (m)');
legend(exps(idx,1), 'Location', 'northeast');
title('Convergencia desde un error inicial de 0.7 m');

%% Fig. 2 y 3 - Influencia de Q y de R (error en x con bandas ±3σ)
grupos = {[7 1 8], 'Influencia de Q';  [9 1 10], 'Influencia de R'};
for g = 1:2
    figure('Name', grupos{g,2});
    ids = grupos{g,1};
    for k = 1:3
        e = ids(k);
        subplot(3,1,k); hold on; grid on;
        plot(t, R{e}.err(1,:), 'r');
        plot(t, 3*sqrt(R{e}.Pacumulado(1,:)), 'k--', t, -3*sqrt(R{e}.Pacumulado(1,:)), 'k--');
        ylim([-0.03 0.03]);                                   % misma escala en los tres
        ylabel('error x (m)'); title(sprintf('%s  (RMSE %.4f m, %.0f%% dentro de 3σ, NIS %.2f)', ...
            exps{e,1}, R{e}.rmsePos, R{e}.dentro3s(1), R{e}.NISmedio));
    end
    xlabel('t (s)');
end

%% Fig. 4 - Influencia del mapa / sensores
figure('Name', 'Influencia de las balizas');
ids = [1 11 12];  col = {'b', 'm', 'r'};
subplot(2,1,1); hold on; grid on;
for k = 1:3
    plot(t, sqrt(R{ids(k)}.Pacumulado(1,:) + R{ids(k)}.Pacumulado(2,:)), col{k});
end
ylabel('\sigma posición (m)'); legend(exps(ids,1));
subplot(2,1,2); hold on; grid on;
for k = 1:3, stairs(t, R{ids(k)}.nBalizas, col{k}); end
ylabel('balizas usadas'); xlabel('t (s)');

%% Fig. 5 - Comparativa de RMSE
figure('Name', 'RMSE');
valores = [cellfun(@(r) r.rmsePos, R); R{1}.rmseOdo];
bar(valores); grid on; set(gca, 'YScale', 'log');
ylim([0.5*min(valores) 2*max(valores)]);
set(gca, 'XTick', 1:nE+1, 'XTickLabel', [exps(:,1); {'Solo odometría'}]); xtickangle(30);
ylabel('RMSE posición (m)');

%% Fig. 6 - Consistencia: NIS medio (ideal = 1)
figure('Name', 'NIS');
bar(cellfun(@(r) r.NISmedio, R)); hold on; yline(1, 'r--', 'ideal'); grid on;
set(gca, 'XTick', 1:nE, 'XTickLabel', exps(:,1)); xtickangle(30);
ylabel('NIS medio');
