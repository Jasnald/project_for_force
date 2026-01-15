%% Auto Drift Correction Validation
clear; clc; close all;
addpath('functions'); % Garante acesso às funções novas

% 1. Load Data
file_path = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
raw = load_tdms_data(file_path); %

% 2. AUTOMÁTICO: Achar as janelas seguras
% O algoritmo olha pro sinal e decide onde não tem "bagunça"
fprintf('Detectando janelas seguras...\n');
[win_start, win_end] = get_air_windows_auto(raw.fx, raw.fs);

fprintf('Janela Inicial: %.1fs - %.1fs\n', win_start(1), win_start(2));
fprintf('Janela Final:   %.1fs - %.1fs\n', win_end(1), win_end(2));

% 3. Aplicar Correção Robusta (Offset + Drift juntos)
% Não precisa mais do 'remove_offset' antes, essa função já zera tudo.
[fx_clean, trend_line] = drift_correction(raw.fx, raw.fs, win_start, win_end);

% 4. Visualization
figure('Name', 'Auto Correction Check', 'Color', 'w');

% Plot Raw (Cinza)
plot(raw.time, raw.fx, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'DisplayName', 'Raw (Com Drift)'); hold on;

% Plot da Linha de Tendência Calculada (Preta Tracejada)
plot(raw.time, trend_line, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Tendência Detectada');

% Plot Limpo (Azul)
plot(raw.time, fx_clean, 'b', 'LineWidth', 1.2, 'DisplayName', 'Corrigido (Auto)');

% --- A Mágica: Desenhar as áreas que ele usou para calibrar ---
yl = ylim; % Pega limites do gráfico para desenhar o retângulo
% Área Verde Inicial
patch([win_start(1) win_start(2) win_start(2) win_start(1)], ...
      [yl(1) yl(1) yl(2) yl(2)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Zona Segura 1');
% Área Verde Final
patch([win_end(1) win_end(2) win_end(2) win_end(1)], ...
      [yl(1) yl(1) yl(2) yl(2)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Zona Segura 2');

title('Correção Automática (Ignorando Arranque e Final)');
ylabel('Força [N]'); xlabel('Tempo [s]');
legend('Location', 'best'); grid on;