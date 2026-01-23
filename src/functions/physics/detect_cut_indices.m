function [cut_indices, diagnostics] = detect_cut_indices(signal, fs, det_params)
    % DETECT_CUT_INDICES_SIMPLE Streamlined detection based on Impulse.
    % 1. Defines search regions using an envelope.
    % 2. Integrates raw signal within those regions.
    % 3. Filters based on physical impulse (N.s).

    arguments
        signal     (:,1) double
        fs         (1,1) double
        det_params (1,1) struct = config_processing().det
    end

    %% 1. Trigger Definition (Corrected Logic)
    sig_abs = abs(signal);
    
    % Short window for trigger detection
    win_len = max(1, round(fs * 0.0005)); 
    envelope = movmean(sig_abs, win_len);

    % Threshold calculation
    noise_floor = mean(envelope(1:round(end*0.15)));
    peak_val    = max(envelope);
    threshold   = noise_floor + (peak_val - noise_floor) * det_params.start_thresh_pct;

    % Initial Raw Candidates (No convolution yet)
    mask = envelope > threshold;
    edges = diff([0; mask; 0]);
    raw_s = find(edges > 0);
    raw_e = find(edges < 0) - 1;

    %% 2. Smart Merge (Fix for the "Fat" Window problem)
    % Merges gaps strictly INSIDE the cut, without expanding outer edges.
    
    max_gap = round(fs * det_params.min_dist_sec);
    
    starts = [];
    ends   = [];
    
    if ~isempty(raw_s)
        current_s = raw_s(1);
        current_e = raw_e(1);
        
        for k = 2:length(raw_s)
            gap = raw_s(k) - current_e;
            
            if gap <= max_gap
                % BRIDGE THE GAP: Extend current end to next segment
                current_e = raw_e(k);
            else
                % GAP TOO BIG: Save current cut and start new one
                starts = [starts; current_s]; %#ok<AGROW>
                ends   = [ends;   current_e]; %#ok<AGROW>
                
                current_s = raw_s(k);
                current_e = raw_e(k);
            end
        end
        % Save the last segment
        starts = [starts; current_s];
        ends   = [ends;   current_e];
    end


    %% 2. Impulse Validation (The Filter)
    valid_cuts = [];
    impulses   = [];
    min_imp    = det_params.min_impulse;

    for k = 1:length(starts)
        s = starts(k);
        e = ends(k);
        
        % Safety check
        if e <= s, continue; end

        % Integrate RAW signal using envelope limits
        % Note: This includes slight 'tails' from the smoothing window, 
        % but ensures no signal is missed.
        seg_p_one = sig_abs(s:e);
        seg_p_two = seg_p_one.^3; % Just to be sure
        segment_impulse = trapz(seg_p_two) / fs; 

        if segment_impulse >= min_imp
            valid_cuts = [valid_cuts; s, e];
            impulses   = [impulses; segment_impulse];
        end
    end

    cut_indices = valid_cuts;

    %% 3. Diagnostics
    diagnostics.energy = envelope;
    diagnostics.threshold = threshold;
    diagnostics.cut_impulses = impulses;
end