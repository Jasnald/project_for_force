%% Auto Drift Correction (Zoom Estrito)
clear; clc; close all;
addpath('functions'); 

% 1. Load
file_path = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
raw = load_tdms_data(file_path); 

% 2. Auto-Detect
fprintf('Detectando janelas...\n');
% Agora pegamos o 3º argumento: cut_limits
[win_start, win_end, cut_limits] = get_air_windows_auto(raw.fx, raw.fs); 

fprintf('Corte detectado de %.2fs até %.2fs\n', cut_limits(1), cut_limits(2));

% 3. Apply Correction
[fx_clean, trend_line] = drift_correction(raw.fx, raw.fs, win_start, win_end);

% 4. Visualization
figure('Name', 'Analise Focada (Estrito)', 'Color', 'w');

% Plot
plot(raw.time, raw.fx, 'Color', [0.8 0.8 0.8], 'DisplayName', 'Raw'); hold on;
plot(raw.time, trend_line, 'k--', 'LineWidth', 1, 'DisplayName', 'Drift');
plot(raw.time, fx_clean, 'b', 'LineWidth', 1, 'DisplayName', 'Clean');

% --- ZOOM ESTRITO (Sem margens) ---
xlim([cut_limits(1), cut_limits(2)]);

title(sprintf('Sinal Corrigido (Zoom: %.1fs - %.1fs)', cut_limits(1), cut_limits(2)));
ylabel('Força [N]'); xlabel('Tempo [s]');
legend('Location', 'best'); grid on;