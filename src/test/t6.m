%% Validação da Função Padronizada
clear; close all; clc;
addpath(fullfile(fileparts(mfilename('fullpath')), '../functions'));

% --- 1. Gerar Dados Sintéticos (Cenário Difícil) ---
fs = 10000;
t = 0:1/fs:1.5; % 1.5 segundos

% Drift + Ruído
drift = linspace(0, 8, length(t))'; % Drift sobe até 8N
sinal = drift + randn(size(drift))*0.2; 
sinal(sinal<0) = 0;

% Criar formato de corte complexo
x_cut = linspace(0, 6, 400);
cut_shape = 12*exp(-4*(x_cut-1).^2) + 8*exp(-4*(x_cut-3).^2); % Dois lobos
cut_shape = cut_shape(:);

% Inserir cortes em posições variadas
indices = [2000, 6000, 10000];
for idx = indices
    sinal(idx : idx+length(cut_shape)-1) = sinal(idx : idx+length(cut_shape)-1) + cut_shape;
end

% --- 2. CHAMADA DA FUNÇÃO OFICIAL ---
cuts = find_cut_indices(sinal, fs);

% --- 3. Visualização ---
figure('Color', 'w', 'Name', 'Validação Final');
plot(sinal, 'Color', [0.2 0.2 0.2], 'LineWidth', 1); hold on;
title(sprintf('Detecção Final: %d cortes encontrados', size(cuts,1)));
ylabel('Força [N]'); xlabel('Amostras');
grid on;

colors = lines(size(cuts,1));
for i = 1:size(cuts,1)
    p1 = cuts(i,1);
    p2 = cuts(i,2);
    
    % Linhas Verticais
    xline(p1, 'Color', 'g', 'LineWidth', 2);
    xline(p2, 'Color', 'r', 'LineWidth', 2);
    
    % Preenchimento
    fill([p1 p2 p2 p1], [min(sinal) min(sinal) max(sinal) max(sinal)], ...
         colors(i,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
end

% Zoom no primeiro corte para ver detalhes
xlim([indices(1)-500, indices(1)+length(cut_shape)+500]);
subtitle('Zoom no primeiro corte (Verde=Início, Vermelho=Fim)');