%% Fluxo Completo de Teste
clear; clc; close all;
addpath(genpath('functions')); % Garante acesso

% --- 1. Carregar Dados (Use seu arquivo real aqui) ---
% simulando dados do Cenário 1 para teste rápido
fs = 10000; t = 0:1/fs:0.5;
raw_x = [zeros(1,500), 100*sin(0:0.01:pi), zeros(1,500), 100*sin(0:0.01:pi), zeros(1,500)]'; 
raw_x = raw_x + randn(size(raw_x))*2; % Ruído
raw_y = raw_x * 0.5; % Y proporcional a X só pra teste

% --- 2. Isolar Cortes ---
cuts = find_cut_indices(raw_x, fs);

% --- 3. Calcular Médias e RPM ---
num_dentes = 6; % Exemplo
data = analyze_cuts_and_average(raw_x, raw_y, cuts, fs, num_dentes);

% --- 4. Plotar Resultados ---
figure('Name', 'Perfil Médio', 'Color', 'w');

% Plot da Nuvem (Todos os cortes em cinza fraco)
plot(data.avg_profile.percent_axis, data.stack_x', 'Color', [0.8 0.8 0.8]); hold on;

% Plot da Média (Em azul forte)
plot(data.avg_profile.percent_axis, data.avg_profile.x_mean, 'b', 'LineWidth', 2);

title(sprintf('Perfil Médio (RPM Médio: %.1f)', data.rpm_mean));
xlabel('Engajamento [%]'); ylabel('Força [N]');
grid on;
legend('Cortes Individuais', 'Média');