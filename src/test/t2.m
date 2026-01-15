%% T2: Stress Test para Detecção de Cortes
% Esse script gera sinais "feios" para validar a robustez do algoritmo.
clear; close all; clc;

% Setup do Path (garante que acha a função)
addpath(fullfile(fileparts(mfilename('fullpath')), '../functions'));

fs = 10000;
t_cut = 0:1/fs:0.05; % Duração de um corte (50ms)

%% Cenário 1: Sinal "M" (Comum em Fresamento) + Ruído Alto
% Desafio: O pico não é único, ele desce no meio e sobe de novo. 
% O algoritmo não pode achar que o corte acabou no meio do "M".

fprintf('--- Testando Cenário 1: Formato M ---\n');

% Cria um pulso com dois picos (formato M)
pulse_M = 80*sin(2*pi*10*t_cut) + 30*sin(2*pi*30*t_cut);
pulse_M(pulse_M < 0) = 0; % Remove parte negativa

% Monta o sinal completo: Ar - Corte - Ar - Corte
signal1 = [zeros(1000,1); pulse_M'; zeros(500,1); pulse_M'; zeros(1000,1)];

% Adiciona Ruído Branco forte (SNR baixo)
noise = randn(size(signal1)) * 15; % 15N de ruído
signal1 = signal1 + abs(noise);    % Ruído retificado (só positivo)

% --- TESTE ---
cuts = find_cut_indices(signal1, fs);
plot_results(signal1, cuts, 'Cenário 1: Formato M com Ruído');


%% Cenário 2: Drift (Deriva) + Amplitudes Variáveis
% Desafio: O "chão" sobe. O trigger fixo pode falhar se o offset for alto demais,
% ou detectar o drift como corte.

fprintf('--- Testando Cenário 2: Drift e Variabilidade ---\n');

base_pulse = 100 * hamming(length(t_cut)); % Pulso formato sino
signal2 = [zeros(500,1); base_pulse*0.5; zeros(500,1); base_pulse*1.2; zeros(500,1); base_pulse*0.8; zeros(500,1)];

% Adiciona Drift Linear (o zero sobe de 0 a 40N)
drift = linspace(0, 40, length(signal2))';
signal2 = signal2 + drift + randn(size(signal2))*2;

% --- TESTE ---
% Nota: Se falhar aqui, prova que precisamos usar a função 'remove_drift' antes!
cuts = find_cut_indices(signal2, fs);
plot_results(signal2, cuts, 'Cenário 2: Drift de Sensor');


%% Cenário 3: Vibração (Chatter)
% Desafio: Frequência alta sobreposta. O sinal oscila violentamente durante o corte.
% O algoritmo não pode detectar múltiplos "início/fim" dentro do mesmo corte.

fprintf('--- Testando Cenário 3: Vibração (Chatter) ---\n');

% Pulso base quadrado suavizado
pulse_sq = 100 * (1 - cos(2*pi*10*t_cut));
% Adiciona vibração de 800Hz APENAS durante o corte
chatter = 40 * sin(2*pi*800*t_cut);
full_pulse = pulse_sq + chatter;
full_pulse(full_pulse<0) = 0;

signal3 = [zeros(800,1); full_pulse'; zeros(800,1)];
signal3 = signal3 + randn(size(signal3))*3;

% --- TESTE ---
cuts = find_cut_indices(signal3, fs);
plot_results(signal3, cuts, 'Cenário 3: Vibração Intensa (Chatter)');


%% Cenário 4: "Micro-Cortes" e Picos Falsos
% Desafio: Picos muito rápidos (fagulhas ou erro elétrico) que devem ser ignorados.

fprintf('--- Testando Cenário 4: Rejeição de Ruído ---\n');

real_cut = 100 * sin(2*pi*10*t_cut)'; real_cut(real_cut<0)=0;
spike = [0; 150; 0]; % Pico de 1 amostra (erro elétrico)
mini_bump = 15 * hamming(50); % Pequena batida (não é corte)

signal4 = [zeros(500,1); spike; zeros(500,1); real_cut; zeros(500,1); mini_bump; zeros(500,1)];

% --- TESTE ---
cuts = find_cut_indices(signal4, fs);
plot_results(signal4, cuts, 'Cenário 4: Picos Falsos e Spikes');


%% Função Auxiliar de Plotagem (Local)
function plot_results(sig, idxs, title_str)
    figure; plot(sig, 'Color', [0 0.4470 0.7410]); hold on;
    title(title_str); ylabel('Força [N]');
    
    if isempty(idxs)
        subtitle('NENHUM CORTE DETECTADO!');
    else
        for i = 1:size(idxs,1)
            xline(idxs(i,1), 'g', 'LineWidth', 1.5); % Início Verde
            xline(idxs(i,2), 'r', 'LineWidth', 1.5); % Fim Vermelho
            
            % Pinta a área detectada
            x_fill = [idxs(i,1), idxs(i,2), idxs(i,2), idxs(i,1)];
            y_fill = [min(sig), min(sig), max(sig), max(sig)];
            fill(x_fill, y_fill, 'g', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        end
        subtitle(sprintf('Detectados: %d cortes', size(idxs,1)));
    end
    grid on;
end