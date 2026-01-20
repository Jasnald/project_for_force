function [cut_indices] = detect_cut_indices(force_signal, fs)
% DETECT_CUT_INDICES Detects cuts with Precise Indexing (Section 2 Logic).
% Start: First point ABOVE 10% threshold.
% End: Last point ABOVE noise floor (before next tooth).

    %% 1. Preparação
    smooth_win = round(fs * 0.0005); 
    sig_smooth = smoothdata(force_signal, 'gaussian', smooth_win);
    n_samples = length(sig_smooth);
    
    % Calcula Noise Floor
    sorted_sig = sort(sig_smooth);
    noise_region = sorted_sig(1 : round(n_samples * 0.20));
    noise_floor = mean(noise_region) + 3*std(noise_region);
    
    %% 2. Achar Picos
    min_dist = fs * 0.015; 
    min_height = max(sig_smooth) * 0.15; 
    min_height = max(min_height, noise_floor * 2);

    [pks, locs] = findpeaks(sig_smooth, ...
                            'MinPeakDistance', min_dist, ...
                            'MinPeakHeight', min_height);
                        
    %% 3. Busca Precisa (Índices "Para Dentro")
    starts = zeros(size(locs));
    ends   = zeros(size(locs));
    
    start_thresh_pct = 0.10; % 10% do pico para início
    
    for i = 1:length(locs)
        peak_idx = locs(i);
        peak_val = pks(i);
        
        % --- BUSCA PARA TRÁS (START) ---
        limit_start = max(noise_floor, peak_val * start_thresh_pct);
        
        idx = peak_idx;
        while idx > 1
            if sig_smooth(idx) < limit_start
                break; % Encontrou o "chão", para.
            end
            idx = idx - 1;
        end
        % CORREÇÃO SEÇÃO 2: Pega o ponto anterior (idx+1), que ainda está na curva
        starts(i) = min(idx + 1, peak_idx);
        
        % --- BUSCA PARA FRENTE (END) ---
        limit_end = noise_floor * 1.2; % Tolerância leve acima do ruído
        
        idx = peak_idx;
        while idx < n_samples
            % 1. Checa se começou a subir de novo (Próximo dente)
            if (idx - peak_idx) > (min_dist * 0.5) && sig_smooth(idx) > sig_smooth(idx-1)
                idx = idx - 1; % Volta um passo para não pegar a subida
                break; 
            end
            
            % 2. Checa se caiu no chão
            if sig_smooth(idx) < limit_end
                idx = idx - 1; % Volta um passo para ficar na curva
                break;
            end
            
            idx = idx + 1;
        end
        ends(i) = max(idx, peak_idx);
    end
    
    %% 4. Retorno
    if isempty(starts)
        cut_indices = [];
    else
        cut_indices = [starts(:), ends(:)];
    end
end