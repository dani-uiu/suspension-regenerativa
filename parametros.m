function p = parametros()
%PARAMETROS  Parámetros compartidos de todo el proyecto (UN solo lugar).
%   Regla de oro del equipo: nadie escribe números "mágicos" en su módulo;
%   todo valor físico vive aquí. Si alguien cambia algo, avisa al grupo.

%% --- Vehículo: cuarto de vehículo eléctrico (Ing. Mecánica) -------------
p.ms = 400;        % masa suspendida por rueda [kg] (VE de ~1,800 kg / 4, con baterías)
p.mu = 45;         % masa no suspendida: rueda + mangueta + actuador [kg]
p.ks = 22000;      % rigidez del resorte de suspensión [N/m]
p.cs = 1600;       % amortiguamiento pasivo [N·s/m]
p.kt = 200000;     % rigidez vertical de la llanta [N/m]

%% --- Escenario de simulación -------------------------------------------
p.v  = 40/3.6;     % velocidad constante [m/s] (40 km/h, vialidad urbana)
p.L  = 1000;       % longitud del recorrido [m]
p.dx = 0.05;       % resolución espacial del camino [m]
p.dt = 1e-3;       % paso de integración [s] (1 kHz, >> 11 Hz de la rueda)
p.semilla = 7;     % semilla aleatoria: TODOS obtienen el mismo camino

%% --- Actuador electromagnético (Ing. Mecatrónica) -----------------------
p.umax = 2500;     % fuerza máxima del actuador lineal [N]

%% --- Sensado y clasificación (Ing. en Ciencia de Datos) -----------------
p.ruido_acc = 0.05;  % ruido del acelerómetro en la rueda [m/s^2 RMS]
p.ventana_s = 1.0;   % ventana de análisis [s]
p.umbral_cf = 4.5;   % factor de cresta para marcar "evento" (bache/tope)

%% --- Energía y sustentabilidad (Ing. en Desarrollo Sustentable) ---------
p.eta_gen = 0.75;    % eficiencia mecánica->eléctrica (modo generador)
p.eta_mot = 0.85;    % eficiencia eléctrica->mecánica (modo motor)
p.consumo_ve = 150;  % consumo típico de un VE compacto [Wh/km] (supuesto)
p.km_anuales = 15000;% recorrido anual supuesto [km/año]
p.fe_co2 = 0.44;     % factor de emisión de la red [kg CO2e/kWh]
                     % VERIFICAR con el factor oficial vigente (SEMARNAT/CRE)
end
