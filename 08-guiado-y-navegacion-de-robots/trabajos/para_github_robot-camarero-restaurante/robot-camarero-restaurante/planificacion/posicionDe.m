function p = posicionDe(mapa, nombre)
% POSICIONDE  Coordenadas [x y] de un lugar del mapa por su nombre ('M1', 'Barra'...).
k = find(strcmp(mapa.salas(:,1), nombre), 1);
if isempty(k), error('posicionDe: no existe el lugar "%s"', nombre); end
p = mapa.salas{k, 3};
end
