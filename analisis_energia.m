function en = analisis_energia(res, p, clase_t, nombres_clase)
%ANALISIS_ENERGIA  [ING. DESARROLLO SUSTENTABLE] Balance energético de la
%   suspensión y su impacto ambiental.
%
%   Potencia mecánica del actuador: P = u * (zs' - zu')
%     P < 0  -> el camino "empuja" al actuador: GENERA  (E_gen = eta_gen*|P|)
%     P > 0  -> el actuador empuja: CONSUME de la batería (E_cons = P/eta_mot)
%   Potencial teórico: energía que el amortiguador pasivo disipa en calor
%     P_amort = cs * (zs' - zu')^2   (lo máximo que se podría recuperar)
%
%   Escalado: 1 rueda -> 4 ruedas, por km, por año, y CO2e evitado.
%
%   res: arreglo de structs de simular() (pasivo, activo, regenerativo)

dt = p.dt;
km = p.L / 1000;
J2Wh = 1/3600;
n = numel(res);
en = struct('modo', {}, 'E_gen_Wh_km', {}, 'E_cons_Wh_km', {}, ...
            'E_neta_Wh_km', {}, 'pct_consumo_VE', {}, 'kWh_anio', {}, ...
            'kgCO2_anio', {}, 'P_media_W', {});

for k = 1:n
    P = res(k).Pmec;
    E_gen  = p.eta_gen * sum(max(-P, 0)) * dt;     % [J] 1 rueda
    E_cons = sum(max(P, 0)) * dt / p.eta_mot;      % [J] 1 rueda
    E_neta = E_gen - E_cons;                       % + => ahorro neto
    en(k).modo         = res(k).modo;
    en(k).E_gen_Wh_km  = 4 * E_gen  * J2Wh / km;
    en(k).E_cons_Wh_km = 4 * E_cons * J2Wh / km;
    en(k).E_neta_Wh_km = 4 * E_neta * J2Wh / km;
    en(k).pct_consumo_VE = 100 * en(k).E_neta_Wh_km / p.consumo_ve;
    en(k).kWh_anio   = en(k).E_neta_Wh_km * p.km_anuales / 1000;
    en(k).kgCO2_anio = en(k).kWh_anio * p.fe_co2;
    en(k).P_media_W  = 4 * E_neta / (numel(P)*dt);
end

% Potencial teórico (amortiguador pasivo convertido 100 % en generador)
vrel = res(1).vrel;
E_amort = sum(p.cs * vrel.^2) * dt;                       % [J] 1 rueda
pot.Wh_km = 4 * p.eta_gen * E_amort * J2Wh / km;
pot.pct_consumo_VE = 100 * pot.Wh_km / p.consumo_ve;
pot.P_media_W = 4 * p.eta_gen * E_amort / (numel(vrel)*dt);

% Energía generada por tipo de terreno (usa la salida de Ciencia de Datos)
iReg = find(strcmp({res.modo}, 'regenerativo'), 1);
P = res(iReg).Pmec(:);
porTerreno = zeros(numel(nombres_clase), 1);
for c = 1:numel(nombres_clase)
    m = clase_t(:) == c;
    t_c = sum(m) * dt;                                    % [s] en esa clase
    porTerreno(c) = 4 * p.eta_gen * sum(max(-P(m), 0)) * dt / max(t_c, dt);
end

en_tabla = struct2table(en);
fprintf('\n[Desarrollo Sustentable] Balance energético (4 ruedas):\n');
disp(en_tabla);
fprintf('   Potencial teórico (amortiguador -> generador): %.2f Wh/km ', pot.Wh_km);
fprintf('(%.2f %% del consumo del VE, %.0f W medios)\n', pot.pct_consumo_VE, pot.P_media_W);
fprintf('   Potencia media generada por terreno (modo regenerativo):\n');
for c = 1:numel(nombres_clase)
    fprintf('     %-20s %6.1f W\n', nombres_clase{c}, porTerreno(c));
end

en = struct('tabla', en_tabla, 'potencial', pot, ...
            'P_por_terreno_W', porTerreno);
end
