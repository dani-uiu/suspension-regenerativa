%% MAIN_SUSPENSION  Suspensión activa regenerativa para un vehículo eléctrico
%  Modelo de cuarto de vehículo sobre un camino irregular de 1 km.
%  Integra los 4 módulos del equipo:
%     Mecánica        -> modelo_cuarto_vehiculo.m
%     Mecatrónica     -> diseno_lqr.m, simular.m
%     Ciencia de Datos-> generar_camino.m, perfil_iso8608.m, clasificar_terreno.m
%     Sustentable     -> analisis_energia.m
%  Ejecutar sección por sección con Ctrl+Enter (o todo con F5).

clear; clc; close all;
set(0, 'DefaultFigureWindowStyle', 'docked');   % todas las figuras como pestañas en una sola ventana

%% 0. Parámetros comunes
p = parametros();

%% 1. [Ciencia de Datos] Camino
cam = generar_camino(p);

%% 2. [Mecánica] Modelo
sys = modelo_cuarto_vehiculo(p, true);   % true = grafica validación

%% 3. [Mecatrónica] Controlador y simulación de los 3 escenarios
ctrl = diseno_lqr(sys);
modos = {'pasivo', 'activo', 'regenerativo'};
for k = 1:3
    res(k) = simular(sys, cam.w, modos{k}, ctrl.K, p); %#ok<SAGROW>
end

%% 4. [Ciencia de Datos] Clasificación del terreno (sensor en la rueda)
ds = clasificar_terreno(res(1).acc_u, cam.etiqueta_t, sys, p);

%% 5. [Desarrollo Sustentable] Energía e impacto
en = analisis_energia(res, p, ds.pred_t, cam.clases);

%% 6. Indicadores de desempeño (confort y seguridad)
rmsf = @(s) sqrt(mean(s.^2));
T = table('Size', [3 6], ...
    'VariableTypes', repmat({'double'}, 1, 6), ...
    'VariableNames', {'acc_RMS_ms2','mejora_confort_pct','acc_pico_ms2', ...
                      'carrera_max_cm','llanta_RMS_mm','F_max_N'}, ...
    'RowNames', modos);
for k = 1:3
    T.acc_RMS_ms2(k)    = rmsf(res(k).acc_s);
    T.acc_pico_ms2(k)   = max(abs(res(k).acc_s));
    T.carrera_max_cm(k) = 100*max(abs(res(k).carr));
    T.llanta_RMS_mm(k)  = 1000*rmsf(res(k).llan);
    T.F_max_N(k)        = max(abs(res(k).u));
end
T.mejora_confort_pct = 100*(1 - T.acc_RMS_ms2/T.acc_RMS_ms2(1));
fprintf('\n=== Desempeño (1 rueda, 1 km a %.0f km/h) ===\n', p.v*3.6);
disp(T);
fprintf(['Escala ISO 2631 (orientativa, sin ponderación en frecuencia):\n', ...
         '  <0.315 cómodo | 0.315-0.63 algo incómodo | 0.5-1 incómodo | >0.8 muy incómodo\n']);

%% 7. Gráficas para la presentación
xt = p.v * cam.t;                 % posición del vehículo en cada instante
col = lines(3);

% --- Figura 1: camino y clasificación
figure('Name', 'Camino y clasificación', 'Position', [50 50 1100 600]);
tiledlayout(2, 1);
nexttile;
hz = plot(cam.x, 100*cam.zr, 'k'); grid on; hold on;
hc = gobjects(1, 3);
for k = 1:size(cam.tramos, 1)
    a = cam.tramos(k,1);  b = cam.tramos(k,2);  c = cam.tramos(k,4);
    hc(c) = patch([a b b a], [-10 -10 10 10], col(c,:), ...
                  'FaceAlpha', 0.12, 'EdgeColor', 'none');
end
uistack(hz, 'top');
ylim(1.2*[min(100*cam.zr) max(100*cam.zr)]);
xline(cam.eventos.x_m, 'r--', cam.eventos.tipo);
ylabel('z_r [cm]'); title('Perfil del camino (ISO 8608) y tramos reales');
legend([hz hc], [{'perfil'}, cam.clases], 'Location', 'northwest');
nexttile;
stairs(ds.x_ventana, ds.ytrue, 'k', 'LineWidth', 2); hold on;
stairs(ds.x_ventana, ds.pred, 'Color', col(2,:), 'LineWidth', 1.2);
plot(ds.x_ventana(ds.evento), 3.3*ones(sum(ds.evento),1), 'rv', ...
     'MarkerFaceColor', 'r');
yticks(1:3); yticklabels(cam.clases); ylim([0.5 3.6]); grid on;
xlabel('x [m]');
title(sprintf('Clasificación por ventana: exactitud %.1f %%', 100*ds.exactitud));
legend('real', 'predicha', 'evento detectado', 'Location', 'southeast');

% --- Figura 2: confort
figure('Name', 'Confort', 'Position', [80 80 1100 600]);
tiledlayout(2, 1);
nexttile;
for k = 1:3
    plot(xt, res(k).acc_s, 'Color', col(k,:)); hold on;
end
grid on; ylabel('z_s'''' [m/s^2]'); legend(modos);
title('Aceleración de la carrocería (lo que sienten los pasajeros)');
nexttile;
ventanaRMS = round(2/p.dt);       % RMS móvil de 2 s
for k = 1:3
    plot(xt, sqrt(movmean(res(k).acc_s.^2, ventanaRMS)), ...
         'Color', col(k,:), 'LineWidth', 1.5); hold on;
end
yline([0.315 0.63], ':', {'cómodo', 'algo incómodo'});
grid on; xlabel('x [m]'); ylabel('RMS móvil 2 s [m/s^2]'); legend(modos);

% --- Figura 3: restricciones mecánicas
figure('Name', 'Carrera y llanta', 'Position', [110 110 1100 500]);
tiledlayout(2, 1);
nexttile;
for k = 1:3, plot(xt, 100*res(k).carr, 'Color', col(k,:)); hold on; end
grid on; ylabel('carrera [cm]'); legend(modos);
title('Carrera de suspensión (límite físico ~ ±8 cm)');
nexttile;
for k = 1:3, plot(xt, 1000*res(k).llan, 'Color', col(k,:)); hold on; end
grid on; xlabel('x [m]'); ylabel('deflexión llanta [mm]');
title('Deflexión de llanta (si z_u - z_r > peso/k_t la llanta despega)');

% --- Figura 4: energía
figure('Name', 'Energía', 'Position', [140 140 1100 600]);
tiledlayout(2, 1);
nexttile;
for k = 2:3
    plot(xt, res(k).Pmec, 'Color', col(k,:)); hold on;
end
grid on; ylabel('P mecánica [W]'); legend(modos(2:3));
title('Potencia del actuador (+ consume batería, - genera)');
nexttile;
for k = 2:3
    P = res(k).Pmec;
    Eacc = cumsum(p.eta_gen*max(-P,0) - max(P,0)/p.eta_mot) * p.dt / 3600;
    plot(xt, 4*Eacc, 'Color', col(k,:), 'LineWidth', 1.5); hold on;
end
grid on; xlabel('x [m]'); ylabel('energía neta acumulada [Wh]');
legend(modos(2:3), 'Location', 'northwest');
title('Balance eléctrico acumulado, 4 ruedas (+ = energía recuperada)');

% --- Figura 5: ciencia de datos
figure('Name', 'Ciencia de datos', 'Position', [170 170 1000 420]);
tl = tiledlayout(1, 2);
nexttile(tl, 1);
gscatter_simple(ds.Xtr(:,1), ds.Xtr(:,4), ds.ytr, col);
xlabel(ds.nombres_feat{1}); ylabel(ds.nombres_feat{4}); grid on;
legend(cam.clases, 'Location', 'best'); title('Espacio de características (entrenamiento)');
hold off;   % heatmap no se puede crear con hold activo
hm = heatmap(tl, cam.clases, cam.clases, ds.CM);
hm.Layout.Tile = 2;
hm.XLabel = 'Predicho';  hm.YLabel = 'Real';  hm.Title = 'Matriz de confusión';

% Guardar figuras para la presentación
% figs = findall(0, 'Type', 'figure');
% for k = 1:numel(figs), exportgraphics(figs(k), sprintf('fig_%d.png', k)); end

%% Función local (gscatter es de Statistics Toolbox; esta es MATLAB puro)
function gscatter_simple(x, y, g, col)
grupos = unique(g);
for i = 1:numel(grupos)
    m = g == grupos(i);
    scatter(x(m), y(m), 18, col(i,:), 'filled', 'MarkerFaceAlpha', 0.6);
    hold on;
end
end
