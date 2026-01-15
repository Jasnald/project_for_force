%% Auto Drift Correction + Steady State Crop
clear; clc; close all;
addpath('functions'); 

% 1. Load & Auto-Detect
file_path = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
raw = load_tdms_data(file_path); 

fprintf('1. Detectando corte bruto...\n');
[win_start, win_end, cut_limits] = get_air_windows_auto(raw.fx, raw.fs); %

% 2. Apply Drift Correction
[fx_clean, ~] = drift_correction(raw.fx, raw.fs, win_start, win_end); %

% 3. CROP STEADY STATE (Novo Passo)
% Config: Cortar 5% do início (entrada) e 10% do final (saída/taper)
trim_percentages = [0.10, 0.10]; 

fprintf('2. Extraindo regime permanente...\n');
[fx_steady, t_steady] = extract_steady_state(fx_clean, raw.time, cut_limits, trim_percentages);

% 4. Visualization
figure('Name', 'Steady State Extraction', 'Color', 'w');

% Plot 1: O Corte Inteiro (Bruto Corrigido)
subplot(2,1,1);
plot(raw.time, fx_clean, 'Color', [0.7 0.7 0.7]); hold on;
xline(cut_limits(1), 'r--'); xline(cut_limits(2), 'r--');
title('Corte Completo (Com transientes)');
xlim([cut_limits(1)-1, cut_limits(2)+1]); 
ylabel('Força [N]'); grid on;

% Plot 2: O "Filet Mignon" (Steady State)
subplot(2,1,2);
plot(t_steady, fx_steady, 'b');
title('Steady State (Pontas removidas)');
xlim([cut_limits(1)-1, cut_limits(2)+1]); % Mantém mesma escala visual
ylabel('Força [N]'); grid on;

% Estatísticas Rápidas
avg_force = mean(fx_steady);
fprintf('\nForça Média no Steady State: %.2f N\n', avg_force);