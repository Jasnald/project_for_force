addpath(fullfile(fileparts(mfilename('fullpath')), '../functions'));

% --- Gerar dados sintéticos ---
fs = 10000;
x_profile = linspace(0, 6, 500);

% Perfil complexo (Vários picos)
profile_shape = 10*exp(-5*(x_profile-1.1).^2) + 8*exp(-4*(x_profile-2).^2) + ...
                6*exp(-4*(x_profile-3).^2) + 4*exp(-4*(x_profile-4).^2) + ...
                2*exp(-3*(x_profile-5).^2);

zeta = 0.08;           % Coeficiente de amortecimento (0 < zeta < 1)
omega_n = 100;         % Frequência natural [rad/s]
omega_d = omega_n * sqrt(1 - zeta^2); % Frequência amortecida
t_vib = linspace(0, 6/omega_n*10, length(profile_shape)); % Tempo
vibration = exp(-zeta * omega_n * t_vib) .* sin(omega_d * t_vib);

% Combinar perfil com vibração
amplitude_vib = 15; % Amplitude da vibração

profile = profile_shape + amplitude_vib * vibration;
profile_shape = profile; 

num_cuts = 80;
gap_samples = 600;
sinal = [];
for i = 1:num_cuts
    sinal = [sinal; profile_shape'; zeros(gap_samples,1)];
end

% ADICIONAL: Drift e Ruído
% O sinal começa no 0 e termina no 5 (simulando sensor esquentando)
drift = linspace(0, 1, length(sinal))'; 
sinal = sinal + drift + randn(size(sinal))*0.05; 
sinal(sinal<0) = 0;

% --- Detecção (USANDO DERIVADA) ---
% Essa função retorna apenas o vetor de INÍCIOS (Start indices)
start_indices = find_cut_indices(sinal, fs);

fprintf('Inícios detectados: %d\n', length(start_indices));

% --- Plot ---
figure('Color', 'w');

% Subplot 1: O Sinal Real
ax1 = subplot(2,1,1);
plot(sinal, 'LineWidth', 1.5); hold on;
title(sprintf('Detecção do Início (Derivada): %d cortes', length(start_indices)));
ylabel('Força [N]'); grid on;

% Marcar os inícios encontrados
colors = lines(length(start_indices));
for i = 1:length(start_indices)
    xline(start_indices(i), 'Color', colors(i,:), 'LineWidth', 2, ...
          'Label', sprintf('Start %d', i));
end

% Subplot 2: A Derivada (O que o algoritmo "vê")
ax2 = subplot(2,1,2);
% Recalculando derivada aqui apenas para visualização
dF = gradient(smoothdata(sinal, 'gaussian', 20)); 
plot(dF, 'm', 'LineWidth', 1); hold on;
yline(max(dF)*0.05, 'k--', 'Trigger (Velocidade)');
title('Derivada (Velocidade de subida da força)');
ylabel('dF/dt'); grid on;

linkaxes([ax1, ax2], 'x'); % Zoom em um mexe no outro

% --- Log dos Pontos ---
if length(start_indices) >= 1
    i = 1;
    % Ponto 1: Início do primeiro corte
    ponto1 = start_indices(i);
    fprintf('Ponto 1 (Início Corte 1): %d\n', ponto1);
    
    if length(start_indices) >= 2
        % Ponto 3: Início do PRÓXIMO corte (como na sua imagem)
        ponto3 = start_indices(i+1);
        fprintf('Ponto 3 (Início Corte 2): %d\n', ponto3);
    else
        warning('Apenas 1 corte detectado. Esperado: %d', num_cuts);
    end
end