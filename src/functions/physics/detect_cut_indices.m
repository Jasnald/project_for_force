function [cut_indices] = detect_cut_indices(force_signal, fs, det_params)
% DETECT_CUT_INDICES Detects cuts using configured parameters.
% Usage: detect_cut_indices(sig, fs, cfg.det)

    %% 0. Config handling
    if nargin < 3 || isempty(det_params)
        full_cfg = config_processing();
        det_params = full_cfg.det;
    end

    %% 1. Preparation
    smooth_win = round(fs * det_params.smooth_win_sec); 
    sig_smooth = smoothdata(force_signal, 'gaussian', smooth_win);
    n_samples = length(sig_smooth);
    
    % Calculate Noise Floor
    sorted_sig = sort(sig_smooth);
    noise_region_idx = round(n_samples * det_params.noise_rgn_pct);
    noise_region = sorted_sig(1 : max(1, noise_region_idx));
    noise_floor = mean(noise_region) + det_params.noise_std_factor * std(noise_region);
    
    %% 2. Find Peaks
    min_dist = fs * det_params.min_dist_sec; 
    min_height = max(sig_smooth) * det_params.min_height_pct; 
    min_height = max(min_height, noise_floor * 2);

    [pks, locs] = findpeaks(sig_smooth, ...
                            'MinPeakDistance', min_dist, ...
                            'MinPeakHeight', min_height);
                        
    %% 3. Precise Search ("Inward" Indexing)
    starts = zeros(size(locs));
    ends   = zeros(size(locs));
    
    for i = 1:length(locs)
        peak_idx = locs(i);
        peak_val = pks(i);

        % Dynamic Thresholds
        start_lim = max(noise_floor, det_params.start_thresh_pct * peak_val);
        end_lim   = max(noise_floor, det_params.start_thresh_pct * peak_val); % Using same logic for simplicity, or use specific param

        % --- Backward Search (Start) ---
        idx = peak_idx;
        while idx > 1 && sig_smooth(idx) > start_lim
            idx = idx - 1;
        end
        starts(i) = min(idx + 1, peak_idx);

        % --- Forward Search (End) ---
        idx = peak_idx;
        while idx < n_samples && sig_smooth(idx) > end_lim
            idx = idx + 1;
        end
        ends(i) = max(idx - 1, peak_idx);
    end
        
    %% 4. Return
    if isempty(starts)
        cut_indices = [];
    else
        cut_indices = [starts(:), ends(:)];
    end
end