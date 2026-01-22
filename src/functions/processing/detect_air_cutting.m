function [win_start, win_end, cut_interval] = detect_air_cutting(signal, fs, air_params)
% DETECT_AIR_CUTTING Detects safe air-cutting windows.
% Usage: detect_air_cutting(sig, fs, cfg.air)

    arguments
        signal     (:,1) double {mustBeNumeric} % Vetor coluna
        fs         (1,1) double {mustBePositive} % Frequência deve ser > 0
        % Se não passar params, carrega o default automaticamente:
        air_params (1,1) struct = config_processing().air 
    end

    %% 1. Vibration Map
    d_sig = [0; diff(signal)]; 
    % Use configured smoothing window
    smooth_samples = round(fs * air_params.vib_smooth_sec);
    vibration_energy = smoothdata(abs(d_sig), 'gaussian', smooth_samples);
    
    %% 2. Adaptive Threshold
    base_noise = median(vibration_energy);
    peak_vib   = max(vibration_energy);
    thresh = base_noise + (peak_vib - base_noise) * air_params.thresh_factor;
    
    is_cutting = vibration_energy > thresh;
    
    %% 3. Validation
    idx_first = find(is_cutting, 1, 'first');
    idx_last  = find(is_cutting, 1, 'last');
    
    if isempty(idx_first)
        warning('No vibration detected. Using default 20-80% fallback.');
        idx_first = round(length(signal)*0.2);
        idx_last  = round(length(signal)*0.8);
    end
    
    %% 4. Windows Calculation
    t = (0:length(signal)-1) / fs;
    cut_interval = [t(idx_first), t(idx_last)];
    
    w1_end   = max(air_params.buff_file_sec, cut_interval(1) - air_params.buff_cut_sec);
    w2_start = min(t(end) - air_params.buff_file_sec, cut_interval(2) + air_params.buff_cut_sec);
    
    win_start = [air_params.buff_file_sec, w1_end];
    win_end   = [w2_start, t(end) - air_params.buff_file_sec];
    
    % Basic safety clamp
    if win_start(2) <= win_start(1), win_start(2) = win_start(1) + 0.1; end
    if win_end(1) >= win_end(2),     win_end(1) = win_end(2) - 0.1; end
end