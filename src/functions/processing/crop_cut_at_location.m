function [cut_sig, cut_time, cut_info] = crop_cut_at_location(signal, fs, target_pct, det_params)
    % CROP_CUT_AT_LOCATION Extrai um único corte baseado na posição relativa.
    % target_pct: Posição desejada (0.0 a 1.0). Ex: 0.3 para 30%.
    
    arguments
        signal     (:,1) double
        fs         (1,1) double {mustBePositive}
        target_pct (1,1) double {mustBeNonnegative, mustBeLessThanOrEqual(target_pct, 1)}
        det_params (1,1) struct = config_processing().det
    end

    %% 1. Detetar cortes
    indices = detect_cut_indices(signal, fs, det_params);
    
    if isempty(indices)
        error('Nenhum corte detetado para extração.');
    end

    %% 2. Encontrar o corte alvo
    total_samples = length(signal);
    target_sample_idx = round(total_samples * target_pct);
    
    % Centro de cada corte
    cut_centers = mean(indices, 2);
    
    % Busca o mais próximo
    [distance, selected_idx] = min(abs(cut_centers - target_sample_idx));
    
    % Aviso de distância (opcional)
    if distance > (0.1 * total_samples)
        warning('O corte selecionado (#%d) está a %.0f amostras da posição %.0f%%.', ...
                selected_idx, distance, target_pct*100);
    end

    %% 3. Extrair
    idx_start = indices(selected_idx, 1);
    idx_end   = indices(selected_idx, 2);
    
    cut_sig = signal(idx_start:idx_end);
    
    dt = 1/fs;
    cut_time = (0:length(cut_sig)-1)' * dt;
    
    cut_info.cut_index = selected_idx;
    cut_info.global_indices = [idx_start, idx_end];
    cut_info.duration = cut_time(end);
    
    fprintf('   -> Crop Single Cut: Selecionado corte #%d (%.0f%% do sinal)\n', selected_idx, target_pct*100);
end