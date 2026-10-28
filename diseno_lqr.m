function ctrl = diseno_lqr(sys, pesos)
%DISENO_LQR  [ING. MECATRÓNICA] Controlador LQR de realimentación de estado
%   u = -K x  que minimiza
%       J = ∫ ( y'*W*y + r*u^2 ) dt ,   y = [zs''; zs-zu; zu-zr]
%
%   Como zs'' depende de u (y = C x + D u), el costo tiene término cruzado:
%       Q = C'WC ,  R = D'WD + r ,  N = C'WD
%
%   pesos.acc   -> castigo a la aceleración de carrocería (confort)
%   pesos.carr  -> castigo a la carrera de suspensión (no topar)
%   pesos.llan  -> castigo a la deflexión de llanta (agarre)
%   pesos.r     -> castigo al esfuerzo de control (energía)
%
%   Regla práctica de Bryson para empezar: peso = 1/(valor máximo aceptable)^2

if nargin < 2
    pesos.acc  = 1;      % [1/(m/s^2)^2]
    pesos.carr = 5e3;    % ~ 1/(1.4 cm)^2
    pesos.llan = 2e4;    % ~ 1/(0.7 cm)^2
    pesos.r    = 1e-7;   % [1/N^2]
end

W = diag([pesos.acc, pesos.carr, pesos.llan]);
Q = sys.C' * W * sys.C;
R = sys.D' * W * sys.D + pesos.r;
N = sys.C' * W * sys.D;

K = lqr_seguro(sys.A, sys.B, Q, R, N);

ctrl.K = K;
ctrl.pesos = pesos;
ctrl.polos_lc = eig(sys.A - sys.B*K);

fprintf('\n[Mecatrónica] Ganancia LQR K = [%s]\n', num2str(K, '%10.1f'));
fprintf('   Polos en lazo cerrado (todos con parte real < 0 => estable):\n');
disp(ctrl.polos_lc.');
if any(real(ctrl.polos_lc) >= 0)
    warning('¡Lazo cerrado INESTABLE! Revisen los pesos.');
end
end

% -------------------------------------------------------------------------
function K = lqr_seguro(A, B, Q, R, N)
% Usa lqr() si tienen Control System Toolbox; si no, resuelve la ecuación
% algebraica de Riccati con el método de la matriz Hamiltoniana (MATLAB puro).
try
    K = lqr(A, B, Q, R, N);
catch
    fprintf('   (lqr no disponible: resolviendo Riccati con Hamiltoniana)\n');
    n  = size(A,1);
    Ab = A - B*(R\N');
    Qb = Q - N*(R\N');
    H  = [Ab, -B*(R\B'); -Qb, -Ab'];
    [V, Lam] = eig(H);
    estables = real(diag(Lam)) < 0;        % los n eigenvalores estables
    V1 = V(1:n, estables);
    V2 = V(n+1:end, estables);
    P  = real(V2 / V1);                    % solución de Riccati
    K  = R \ (B'*P + N');
end
end
