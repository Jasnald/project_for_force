function [win_start, win_end, cut_interval] = detect_air_cutting(signal, fs)
    % DETECT_AIR_CUTTING Retorna zonas seguras E o intervalo exato do corte.

    %% 1. Mapa de Vibração
    d_sig = [0; diff(signal)]; 
    vibration_energy = smoothdata(abs(d_sig), 'gaussian', fs*0.5);
    
    %% 2. Limiar Adaptativo
    base_noise = median(vibration_energy);
    peak_vib   = max(vibration_energy);
    thresh = base_noise + (peak_vib - base_noise) * 0.10;
    
    is_cutting = vibration_energy > thresh;
    
    %% 3. Validar
    idx_first = find(is_cutting, 1, 'first');
    idx_last  = find(is_cutting, 1, 'last');
    
    if isempty(idx_first)
        warning('Nenhuma vibração. Usando padrão.');
        idx_first = round(length(signal)*0.2);
        idx_last  = round(length(signal)*0.8);
    end
    
    %% 4. Tempos e Margens
    t = (0:length(signal)-1) / fs;
    
    % --- NOVO: Salva os tempos exatos do corte ---
    cut_interval = [t(idx_first), t(idx_last)];
    
    buffer_cut  = 2.0; 
    buffer_file = 1.0; 
    
    w1_start = buffer_file;
    w1_end   = max(w1_start + 0.5, cut_interval(1) - buffer_cut);
    
    w2_start = cut_interval(2) + buffer_cut;
    w2_end   = max(w2_start + 0.5, t(end) - buffer_file);

    % Proteção final
    if w1_end > cut_interval(1), w1_end = max(buffer_file, cut_interval(1) - 0.1); end
    if w2_start > t(end),        w2_start = t(end) - 1.0; w2_end = t(end) - 0.1; end

    win_start = [w1_start, w1_end];
    win_end   = [w2_start, w2_end];
end