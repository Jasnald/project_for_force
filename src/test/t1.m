addpath(fullfile(fileparts(mfilename('fullpath')), '../functions'));

% --- Gerar dados sintéticos ---
fs = 10000;
x_profile = linspace(0, 6, 500);

profile_shape = 10*exp(-4*(x_profile-1).^2) + 8*exp(-4*(x_profile-2).^2) + ...
                6*exp(-4*(x_profile-3).^2) + 4*exp(-4*(x_profile-4).^2) + ...
                2*exp(-3*(x_profile-5).^2);

num_cuts = 3;
gap_samples = 500;  % Aumentado para garantir separação clara
sinal = [];
for i = 1:num_cuts
    sinal = [sinal; profile_shape'; zeros(gap_samples,1)];
end
sinal = sinal + randn(size(sinal))*0.05;  % Menos ruído
sinal(sinal<0) = 0;

% --- Detecção ---
cuts = find_cut_indices(sinal, fs);

fprintf('Cortes detectados: %d\n', size(cuts,1));

% --- Plot ---
figure; plot(sinal, 'LineWidth', 1.5); hold on;
title(sprintf('Detecção: %d cortes', size(cuts,1)));

% Marcar todos os cortes
colors = lines(size(cuts,1));
for i = 1:size(cuts,1)
    xline(cuts(i,1), 'Color', colors(i,:), 'LineWidth', 2, ...
          'Label', sprintf('Cut %d Start', i));
    xline(cuts(i,2), '--', 'Color', colors(i,:), 'LineWidth', 1.5, ...
          'Label', sprintf('Cut %d End', i));
end

% Marcar pontos específicos apenas se existirem
if size(cuts,1) >= 1
    i = 1;
    ponto1 = cuts(i, 1);
    ponto2 = cuts(i, 2);
    fprintf('Ponto 1: %d, Ponto 2: %d\n', ponto1, ponto2);
    
    if size(cuts,1) >= 2
        ponto3 = cuts(i+1, 1);
        fprintf('Ponto 3: %d\n', ponto3);
    else
        warning('Apenas 1 corte detectado. Esperado: %d', num_cuts);
    end
end

xlabel('Sample'); ylabel('Force (N)');
grid on;