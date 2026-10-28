function sys = modelo_cuarto_vehiculo(p, graficar)
%MODELO_CUARTO_VEHICULO  [ING. MECÁNICA] Modelo masa-resorte-amortiguador
%   de 2 GDL (cuarto de vehículo) con actuador activo entre masas.
%
%   Ecuaciones (2a ley de Newton, z positivo hacia arriba):
%     ms*zs'' = -ks(zs-zu) - cs(zs'-zu') + u
%     mu*zu'' =  ks(zs-zu) + cs(zs'-zu') - kt(zu-zr) - u
%
%   Estados:  x = [zs-zu ; zs' ; zu-zr ; zu']
%             (carrera de suspensión, vel. carrocería, deflexión de llanta,
%              vel. rueda)  -> así el camino entra como VELOCIDAD w = zr'
%   Entradas: u  = fuerza del actuador [N]  (+ separa las masas)
%             w  = zr' velocidad vertical del camino [m/s]
%
%   x' = A x + B u + E w
%
%   Salidas útiles (y = C x + D u):
%     y1 = zs''  aceleración de carrocería (CONFORT)
%     y2 = zs-zu carrera de suspensión     (LÍMITE MECÁNICO)
%     y3 = zu-zr deflexión de llanta       (AGARRE / SEGURIDAD)

if nargin < 2, graficar = false; end
ms = p.ms; mu = p.mu; ks = p.ks; cs = p.cs; kt = p.kt;

A = [ 0       1       0      -1;
     -ks/ms  -cs/ms   0       cs/ms;
      0       0       0       1;
      ks/mu   cs/mu  -kt/mu  -cs/mu];
B = [0; 1/ms; 0; -1/mu];
E = [0; 0; -1; 0];

C = [A(2,:);          % zs''
     1 0 0 0;         % zs - zu
     0 0 1 0];        % zu - zr
D = [1/ms; 0; 0];

%% Discretización exacta con retenedor de orden cero (ZOH) usando expm
%  Truco: exponencial de la matriz aumentada [A [B E]; 0 0]  (MATLAB puro,
%  no requiere c2d ni Control System Toolbox).
n  = size(A,1);
M  = zeros(n+2);
M(1:n,1:n)     = A;
M(1:n,n+1:n+2) = [B E];
Md = expm(M*p.dt);

sys.A = A;  sys.B = B;  sys.E = E;  sys.C = C;  sys.D = D;
sys.Ad = Md(1:n,1:n);
sys.Bd = Md(1:n,n+1);
sys.Ed = Md(1:n,n+2);

%% Verificación física: frecuencias naturales y amortiguamiento
lam = eig(A);
wn  = abs(lam);
zeta = -real(lam)./wn;
[fn, idx] = unique(round(wn/(2*pi), 3));
sys.fn   = fn;                 % [Hz]  ~1.1 Hz carrocería, ~11 Hz rueda
sys.zeta = zeta(idx);

fprintf('\n[Mecánica] Frecuencias naturales del modelo pasivo:\n');
for k = 1:numel(fn)
    fprintf('   f = %6.2f Hz   zeta = %.2f\n', fn(k), sys.zeta(k));
end
fprintf('   Referencia de diseño: carrocería 1-1.5 Hz, rueda 10-15 Hz\n');

%% (Opcional) respuesta a un escalón suave de 5 cm para validar el modelo
if graficar
    t  = 0:p.dt:3;
    zr = 0.05*(1 - cos(pi*min(t/0.1,1)))/2;   % rampa coseno de 0.1 s
    w  = gradient(zr, p.dt);
    x  = zeros(4,1);  zs = zeros(size(t));  zu = zs;
    for i = 1:numel(t)
        zu(i) = x(3) + zr(i);
        zs(i) = x(1) + zu(i);
        x = sys.Ad*x + sys.Ed*w(i);
    end
    figure('Name','Validación modelo');
    plot(t, 100*zr, 'k--', t, 100*zs, t, 100*zu, 'LineWidth', 1.2);
    grid on; xlabel('t [s]'); ylabel('desplazamiento [cm]');
    legend('camino z_r','carrocería z_s','rueda z_u','Location','southeast');
    title('Escalón de 5 cm: la carrocería debe asentarse en ~1-2 s');
end
end
