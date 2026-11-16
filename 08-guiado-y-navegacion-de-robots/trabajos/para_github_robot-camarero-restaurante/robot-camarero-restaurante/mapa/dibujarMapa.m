function dibujarMapa(mapa)
% DIBUJARMAPA  Vista en planta del mapa (para revisarlo antes de ir a Apolo).
figure; hold on; axis equal; grid on; box on;
xlim([-0.5 mapa.dim(1)+0.5]); ylim([-0.5 mapa.dim(2)+0.5]);
xlabel('x (m)'); ylabel('y (m)'); title(mapa.nombre);

% Paredes
for i = 1:size(mapa.paredes,1)
    s = mapa.paredes(i,:);
    plot(s([1 3]), s([2 4]), 'k-', 'LineWidth', 2.5);
end
% Muebles (fijos) e imprevistos
for i = 1:size(mapa.muebles,1)
    c = mapa.muebles(i,:);
    rectangle('Position', c(1:4), 'FaceColor', [0.8 0.65 0.45], 'EdgeColor', [0.4 0.3 0.2]);
end
for i = 1:size(mapa.imprevistos,1)
    c = mapa.imprevistos(i,:);
    rectangle('Position', c(1:4), 'FaceColor', [1 0.6 0.6], 'EdgeColor', 'r', 'LineStyle', '--');
end
% Balizas
b = mapa.balizas;
plot(b(:,2), b(:,3), 'm^', 'MarkerFaceColor', 'm');
text(b(:,2)+0.15, b(:,3)+0.2, compose('%d', b(:,1)), 'Color', 'm', 'FontSize', 7);
% Salas y puntos de entrega
for i = 1:size(mapa.salas,1)
    [nom, ~, pe] = mapa.salas{i,:};
    plot(pe(1), pe(2), 'bx', 'MarkerSize', 8, 'LineWidth', 1.5);
    text(pe(1), pe(2)-0.45, nom, 'HorizontalAlignment', 'center', 'Color', 'b', 'FontSize', 8);
end
% Robot
p = mapa.robot.pose;
plot(p(1), p(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
quiver(p(1), p(2), 0.8*cos(p(3)), 0.8*sin(p(3)), 0, 'g', 'LineWidth', 2);
end
