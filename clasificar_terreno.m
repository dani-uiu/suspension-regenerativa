function ds = clasificar_terreno(acc_u, etiqueta_t, sys, p)
%CLASIFICAR_TERRENO  [ING. CIENCIA DE DATOS] Identifica el tipo de terreno
%   a partir de la aceleración vertical medida en la rueda (acelerómetro en
%   la mangueta), por ventanas de 1 s.
%
%   Flujo (pipeline clásico de ML, todo en MATLAB base):
%     1. Datos de entrenamiento sintéticos: 600 m de cada clase ISO,
%        simulados con el MISMO modelo de Mecánica + ruido de sensor.
%     2. Ingeniería de características por ventana:
%          f1 = log(RMS)           energía de vibración
%          f2 = log(pico a pico)   amplitud
%          f3 = factor de cresta   pico/RMS  -> golpes aislados (eventos)
%          f4 = fracción de energía espectral en 8-20 Hz (modo de rueda), vía FFT
%     3. Normalización z-score y clasificador de CENTROIDE MÁS CERCANO.
%     4. Evaluación: exactitud y matriz de confusión vs etiqueta real.
%     5. Detección de eventos (bache/tope): factor de cresta > umbral.

win = round(p.ventana_s / p.dt);
Gd  = [64 256 1024];                 % mismas clases ISO que el camino real
rng(p.semilla + 100);                % semilla DISTINTA: datos nuevos

%% 1) Entrenamiento
Xtr = [];  ytr = [];
xtr = (0:p.dx:600)';
ttr = (0:p.dt:600/p.v)';
for c = 1:3
    z  = movmean(perfil_iso8608(xtr, Gd(c)), round(2/p.dx));
    zt = interp1(xtr, z, p.v*ttr, 'linear', 'extrap');
    r  = simular(sys, gradient(zt, p.dt), 'pasivo', [], p);
    a  = r.acc_u(:) + p.ruido_acc*randn(numel(r.acc_u), 1);
    F  = extraer_features(a, win, p.dt);
    Xtr = [Xtr; F];                          %#ok<AGROW>
    ytr = [ytr; c*ones(size(F,1), 1)];       %#ok<AGROW>
end
mu = mean(Xtr, 1);
sd = std(Xtr, 0, 1);
Ztr = (Xtr - mu) ./ sd;
cent = zeros(3, size(Ztr,2));
for c = 1:3
    cent(c,:) = mean(Ztr(ytr == c, :), 1);
end

%% 2) Aplicar al recorrido real
a  = acc_u(:) + p.ruido_acc*randn(numel(acc_u), 1);
F  = extraer_features(a, win, p.dt);
Z  = (F - mu) ./ sd;
d2 = sum((permute(Z, [1 3 2]) - permute(cent, [3 1 2])).^2, 3);  % nW x 3
[~, pred] = min(d2, [], 2);

%% 3) Evaluación
nW = size(F,1);
ytrue = zeros(nW,1);
for j = 1:nW
    ytrue(j) = mode(etiqueta_t((j-1)*win+1 : j*win));
end
ds.exactitud = mean(pred == ytrue);
ds.CM = accumarray([ytrue pred], 1, [3 3]);   % filas: real, cols: predicho
ds.evento = F(:,3) > p.umbral_cf;             % golpes aislados

%% Salidas
ds.F = F;  ds.pred = pred;  ds.ytrue = ytrue;
ds.Xtr = Xtr;  ds.ytr = ytr;  ds.centroides = cent;
ds.t_ventana = ((1:nW)' - 0.5) * p.ventana_s;
ds.x_ventana = ds.t_ventana * p.v;
ds.nombres_feat = {'log RMS','log pico-pico','factor cresta','frac. 8-20 Hz'};
% etiqueta predicha por muestra de tiempo (para contabilidad de energía)
pred_t = repelem(pred, win);
ds.pred_t = [pred_t; pred(end)*ones(numel(acc_u) - numel(pred_t), 1)];

fprintf('\n[Ciencia de Datos] Exactitud de clasificación: %.1f %%\n', ...
        100*ds.exactitud);
fprintf('   Eventos detectados (x aprox. en m): %s\n', ...
        mat2str(round(ds.x_ventana(ds.evento)')));
end

% -------------------------------------------------------------------------
function F = extraer_features(a, win, dt)
nW = floor(numel(a)/win);
F  = zeros(nW, 4);
f  = (0:floor(win/2))' / (win*dt);            % eje de frecuencia [Hz]
banda_rueda = f > 8   & f < 20;
banda_total = f > 0.5 & f < 30;
for j = 1:nW
    s = a((j-1)*win+1 : j*win);
    s = s - mean(s);
    rmsv = sqrt(mean(s.^2));
    S = abs(fft(s)).^2;
    S = S(1:numel(f));
    F(j,:) = [log(rmsv), log(max(s) - min(s)), max(abs(s))/rmsv, ...
              sum(S(banda_rueda)) / sum(S(banda_total))];
end
end
