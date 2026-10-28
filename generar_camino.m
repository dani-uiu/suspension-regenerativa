function cam = generar_camino(p)
%GENERAR_CAMINO  [ING. CIENCIA DE DATOS] Genera un camino sintético de 1 km
%   con tramos de distinta rugosidad según la norma ISO 8608 más eventos
%   puntuales (un bache y un tope), y lo convierte a señal en el tiempo.
%
%   ISO 8608: densidad espectral de desplazamiento
%       Gd(n) = Gd(n0) * (n/n0)^-2 ,   n0 = 0.1 ciclos/m
%   Gd(n0) [1e-6 m^3]:  A=16  B=64  C=256  D=1024  E=4096
%   Se sintetiza como suma de cosenos con fase aleatoria.
%
%   Salida (struct cam):
%     x, zr          perfil en el espacio [m]
%     etiqueta       clase real por punto (1,2,3)
%     tramos         [inicio fin Gd0 clase] de cada tramo
%     t, zr_t, w     perfil en el tiempo y su derivada (entrada al modelo)
%     etiqueta_t     clase real por muestra de tiempo
%     clases         nombres de las clases
%     eventos        tabla con posición de bache y tope

rng(p.semilla);
x  = (0:p.dx:p.L)';
zr = zeros(size(x));
et = zeros(size(x));

%      inicio  fin   Gd(n0)  clase
tramos = [   0   300     64    1;     % asfalto bueno       (ISO B)
           300   550    256    2;     % asfalto deteriorado (ISO C)
           550   800   1024    3;     % terracería          (ISO D)
           800  1000     64    1];    % asfalto bueno       (ISO B)

for k = 1:size(tramos,1)
    m = x >= tramos(k,1) & x < tramos(k,2);
    if k == size(tramos,1), m = x >= tramos(k,1); end
    zr(m) = perfil_iso8608(x(m) - tramos(k,1), tramos(k,3));
    et(m) = tramos(k,4);
end
% suaviza las uniones entre tramos (ventana de 2 m ~ huella de la llanta)
zr = movmean(zr, round(2/p.dx));

% Eventos puntuales con forma de medio coseno
zr = zr - bache_tope(x, 180, 0.8, 0.04);   % bache: 4 cm de profundidad
zr = zr + bache_tope(x, 900, 3.5, 0.08);   % tope:  8 cm de alto, 3.5 m

cam.x = x;  cam.zr = zr;  cam.etiqueta = et;  cam.tramos = tramos;
cam.clases  = {'Asfalto bueno', 'Asfalto deteriorado', 'Terracería'};
cam.eventos = table([180; 900], {'bache'; 'tope'}, ...
                    'VariableNames', {'x_m', 'tipo'});

% De espacio a tiempo: el vehículo pasa a velocidad constante
cam.t    = (0:p.dt:p.L/p.v)';
cam.zr_t = interp1(x, zr, p.v*cam.t, 'linear', 'extrap');
cam.w    = gradient(cam.zr_t, p.dt);           % zr'  [m/s]
cam.etiqueta_t = interp1(x, et, p.v*cam.t, 'nearest', 'extrap');
end

% -------------------------------------------------------------------------
function z = bache_tope(x, x0, largo, altura)
z = zeros(size(x));
m = x >= x0 & x <= x0 + largo;
z(m) = altura * 0.5 * (1 - cos(2*pi*(x(m) - x0)/largo));
end
