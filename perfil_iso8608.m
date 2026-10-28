function z = perfil_iso8608(xs, Gd0)
%PERFIL_ISO8608  [CIENCIA DE DATOS] Perfil de camino aleatorio ISO 8608.
%   z = perfil_iso8608(xs, Gd0)  xs: posiciones [m], Gd0: Gd(n0) en 1e-6 m^3
%   Usa el generador aleatorio actual (fijen rng antes para reproducir).
n   = linspace(0.011, 2.83, 300)';    % frecuencias espaciales [ciclos/m]
dn  = n(2) - n(1);
Gd  = Gd0*1e-6 * (n/0.1).^(-2);       % PSD [m^3]
amp = sqrt(2*Gd*dn);                  % amplitud de cada coseno [m]
fase = 2*pi*rand(numel(n), 1);
z = (amp' * cos(2*pi*n*xs(:)' + fase))';   % suma de cosenos (vectorizado)
end

