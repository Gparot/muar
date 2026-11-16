function generarXMLApolo(mapa, fichero, incluirImprevistos)
% GENERARXMLAPOLO  Escribe el mundo de Apolo (XML) a partir del struct mapa.
%   generarXMLApolo(mapaHospital(), 'hospital.xml')        % con imprevistos
%   generarXMLApolo(mapaHospital(), 'hospital.xml', false) % sin imprevistos
%
%   Solo usa tres tipos de cara, los mismos del XML de ejemplo del profesor:
%     - cara horizontal (suelo, tapas de muebles)
%     - pared paralela a X:  orientación {1.5708,0,0}
%     - pared paralela a Y:  orientación {0,-1.5708,0}

if nargin < 3, incluirImprevistos = true; end
f = fopen(fichero, 'w');
if f < 0, error('No se pudo crear %s', fichero); end

fprintf(f, '<root>\n<World>\n');

% --- Información del mundo y matrículas (fijan el ruido de los sensores)
fprintf(f, '<WorldInfo name="%s">\n', mapa.nombre);
for n = mapa.matriculas
    fprintf(f, '  <RegisterNumber number="%d"/>\n', n);
end
fprintf(f, '</WorldInfo>\n');

% --- Edificio: suelo, paredes y muebles
fprintf(f, '<FaceSetPart name="Hospital" id="0">\n');
caraHorizontal(f, 0, 0, mapa.dim(1), mapa.dim(2), 0, [0.75 0.78 0.85]);  % suelo
H = mapa.alturaPared;
for i = 1:size(mapa.paredes, 1)
    pared(f, mapa.paredes(i,:), H, [0.95 0.93 0.85]);
end
for i = 1:size(mapa.muebles, 1)
    caja(f, mapa.muebles(i,:), [0.55 0.40 0.25]);
end
fprintf(f, '</FaceSetPart>\n');

% --- Imprevistos: cada uno en su propia pieza, con nombre propio
if incluirImprevistos
    for i = 1:size(mapa.imprevistos, 1)
        fprintf(f, '<FaceSetPart name="Imprevisto%d">\n', i);
        caja(f, mapa.imprevistos(i,:), [0.85 0.15 0.15]);
        fprintf(f, '</FaceSetPart>\n');
    end
end

% --- Robot
r = mapa.robot;
fprintf(f, '<Pioneer3ATSim name="%s" id="1">\n', r.nombre);
fprintf(f, '  <position> {%.3f,%.3f,0} </position>\n', r.pose(1), r.pose(2));
fprintf(f, '  <orientation> {0,0,%.4f} </orientation>\n', r.pose(3));
fprintf(f, '</Pioneer3ATSim>\n');

% --- Láser
L = mapa.laser;
fprintf(f, '<LMS100Sim name="%s" linkTo="$%s$">\n', L.nombre, r.nombre);
fprintf(f, '  <position> {%.3f,%.3f,%.3f} </position>\n', L.posicion);
fprintf(f, '  <colour r="0" g="1" b="0"/>\n');
fprintf(f, '</LMS100Sim>\n');

% --- Ultrasonidos (orientación {0,-0.1,guiñada} como en el ejemplo de Apolo)
for i = 1:size(mapa.ultrasonidos, 1)
    [nom, pos, yaw] = mapa.ultrasonidos{i,:};
    fprintf(f, '<UltrasonicSensor name="%s" linkTo="$%s$">\n', nom, r.nombre);
    fprintf(f, '  <orientation> {0,-0.1,%.4f} </orientation>\n', yaw);
    fprintf(f, '  <position> {%.3f,%.3f,%.3f} </position>\n', pos);
    fprintf(f, '  <colour r="0" g="0" b="1"/>\n');
    fprintf(f, '</UltrasonicSensor>\n');
end

% --- Balizas
for i = 1:size(mapa.balizas, 1)
    b = mapa.balizas(i,:);
    fprintf(f, '<LandMark name="LM%d" mark_id="%d">\n', b(1), b(1));
    fprintf(f, '  <position> {%.3f,%.3f,%.3f} </position>\n', b(2), b(3), mapa.alturaBaliza);
    fprintf(f, '</LandMark>\n');
end

fprintf(f, '</World>\n</root>\n');
fclose(f);
fprintf('XML generado: %s\n', fichero);
end

%% ===================== Funciones auxiliares =====================

function caraHorizontal(f, x, y, dx, dy, z, col)
% Rectángulo horizontal con esquina en (x,y) a altura z
fprintf(f, '<face>\n');
fprintf(f, '  <colour r="%.2f" g="%.2f" b="%.2f"/>\n', col);
fprintf(f, '  <vertex> {0,0,0} {%.3f,0,0} {%.3f,%.3f,0} {0,%.3f,0} </vertex>\n', dx, dx, dy, dy);
fprintf(f, '  <position> {%.3f,%.3f,%.3f} </position>\n', x, y, z);
fprintf(f, '</face>\n');
end

function pared(f, seg, h, col)
% Pared vertical de altura h sobre el segmento [x1 y1 x2 y2]
x1 = seg(1); y1 = seg(2); x2 = seg(3); y2 = seg(4);
fprintf(f, '<face>\n');
fprintf(f, '  <colour r="%.2f" g="%.2f" b="%.2f"/>\n', col);
if abs(y1 - y2) < 1e-9          % paralela al eje X
    Lx = abs(x2 - x1);
    fprintf(f, '  <vertex> {0,0,0} {%.3f,0,0} {%.3f,%.3f,0} {0,%.3f,0} </vertex>\n', Lx, Lx, h, h);
    fprintf(f, '  <orientation> {1.5708,0,0} </orientation>\n');
    fprintf(f, '  <position> {%.3f,%.3f,0} </position>\n', min(x1,x2), y1);
elseif abs(x1 - x2) < 1e-9      % paralela al eje Y
    Ly = abs(y2 - y1);
    fprintf(f, '  <vertex> {0,0,0} {%.3f,0,0} {%.3f,%.3f,0} {0,%.3f,0} </vertex>\n', h, h, Ly, Ly);
    fprintf(f, '  <orientation> {0,-1.5708,0} </orientation>\n');
    fprintf(f, '  <position> {%.3f,%.3f,0} </position>\n', x1, min(y1,y2));
else
    error('Pared no alineada con los ejes: [%g %g %g %g]', seg);
end
fprintf(f, '</face>\n');
end

function caja(f, c, col)
% Caja [x y dx dy h]: cuatro caras laterales + tapa superior
x = c(1); y = c(2); dx = c(3); dy = c(4); h = c(5);
pared(f, [x y x+dx y], h, col);
pared(f, [x y+dy x+dx y+dy], h, col);
pared(f, [x y x y+dy], h, col);
pared(f, [x+dx y x+dx y+dy], h, col);
caraHorizontal(f, x, y, dx, dy, h, col);
end
