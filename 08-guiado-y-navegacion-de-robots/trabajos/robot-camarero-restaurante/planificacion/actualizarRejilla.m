function R = actualizarRejilla(R)
% ACTUALIZARREJILLA  Recalcula celdas libres y coste de cada celda a partir de R.dist.
R.libre = R.dist >= R.radio;                                   % libre tras inflar
cerca = min(1, max(0, (R.dSeg - R.dist) / (R.dSeg - R.radio)));  % 0 lejos ... 1 junto a la zona inflada
R.coste = 1 + R.kCoste * cerca;                                % coste de pisar cada celda
end
