function res = simular(sys, w, modo, K, p)
%SIMULAR  [MECATRÓNICA + MECÁNICA] Integra el cuarto de vehículo en tiempo
%   discreto (ZOH exacto) con el controlador elegido.
%
%   modo = 'pasivo'        u = 0 (solo resorte + amortiguador)
%          'activo'        u = -K x saturado (puede consumir o generar)
%          'regenerativo'  u = -K x SOLO cuando el actuador frena el
%                          movimiento (u·v_rel < 0) => siempre genera energía
%                          ("clipped LQR" / control semi-activo)
%
%   w = zr' (vector de velocidad del camino, un valor por paso dt)

Nt = numel(w);
x  = zeros(4,1);
X  = zeros(4, Nt);
u  = zeros(1, Nt);
if isempty(K), K = zeros(1,4); end

for i = 1:Nt
    vrel = x(2) - x(4);                    % velocidad relativa zs' - zu'
    switch modo
        case 'pasivo'
            ui = 0;
        case 'activo'
            ui = -K*x;
            ui = max(min(ui, p.umax), -p.umax);
        case 'regenerativo'
            ui = -K*x;
            ui = max(min(ui, p.umax), -p.umax);
            if ui*vrel > 0                 % pediría inyectar energía
                ui = 0;                    % -> no se permite
            end
        otherwise
            error('Modo desconocido: %s', modo);
    end
    X(:,i) = x;
    u(i)   = ui;
    x = sys.Ad*x + sys.Bd*ui + sys.Ed*w(i);
end

res.modo  = modo;
res.X     = X;
res.u     = u;
res.vrel  = X(2,:) - X(4,:);
res.acc_s = sys.A(2,:)*X + sys.B(2)*u;   % zs''  aceleración carrocería
res.acc_u = sys.A(4,:)*X + sys.B(4)*u;   % zu''  aceleración rueda (sensor)
res.carr  = X(1,:);                      % carrera de suspensión
res.llan  = X(3,:);                      % deflexión de llanta
res.Pmec  = u .* res.vrel;               % potencia que el actuador ENTREGA
                                         % (+ consume, - genera)
end
