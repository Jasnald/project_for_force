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
    
    start_frac = 0.0010;   % 10% do pico
    end_frac   = 0.0010;   % pode ser igual, ou um pouco menor, ex. 0.05

    for i = 1:length(locs)
        peak_idx = locs(i);
        peak_val = pks(i);

        % Limiar relativo ao pico
        start_lim = max(noise_floor, start_frac * peak_val);
        end_lim   = max(noise_floor, end_frac   * peak_val);

        % --- INÍCIO: varre para trás até cruzar abaixo do start_lim ---
        idx = peak_idx;
        while idx > 1 && sig_smooth(idx) > start_lim
            idx = idx - 1;
        end
        if idx == 1 && sig_smooth(1) > start_lim
            starts(i) = 1;
        else
            starts(i) = min(idx + 1, peak_idx);
        end

        % --- FIM: varre para frente até cruzar abaixo do end_lim ---
        idx = peak_idx;
        while idx < n_samples && sig_smooth(idx) > end_lim
            idx = idx + 1;
        end
        if idx == n_samples && sig_smooth(end) > end_lim
            ends(i) = n_samples;
        else
            ends(i) = max(idx - 1, peak_idx);
        end
    end
        
    %% 4. Retorno
    if isempty(starts)
        cut_indices = [];
    else
        cut_indices = [starts(:), ends(:)];
    end
end