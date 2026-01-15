%% Simple TDMS Viewer
clear; close all; clc;
addpath('functions'); % Garante acesso às funções

% 1. Abre janela para selecionar arquivo
[file, path] = uigetfile('../Data/*/*.tdms', 'Selecione um arquivo TDMS');
if isequal(file,0), return; end % Cancela se não escolher nada

fullpath = fullfile(path, file);
fprintf('Carregando: %s ...\n', file);

% 2. Lê os dados
data_struct = TDMS_readTDMSFile(fullpath);
% Ajuste os índices {3}, {4}, {5} conforme seus dados reais
fx = data_struct.data{3};
fy = data_struct.data{4};
fz = data_struct.data{5};

% 3. Plota
fs = 10000; % Frequência (se souber)
t = (0:length(fx)-1)/fs;

figure('Name', ['Visualizador: ' file], 'NumberTitle', 'off');
ax1 = subplot(3,1,1); plot(t, fx); title('Força X'); grid on;
ax2 = subplot(3,1,2); plot(t, fy); title('Força Y'); grid on;
ax3 = subplot(3,1,3); plot(t, fz); title('Força Z'); grid on;
linkaxes([ax1, ax2, ax3], 'x'); % Zoom em um reflete nos outros