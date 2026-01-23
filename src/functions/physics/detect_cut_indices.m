function [cut_indices, diagnostics] = detect_cut_indices(signal, fs, det_params)

    arguments
        signal     (:,1) double
        fs         (1,1) double
        det_params (1,1) struct = config_processing().det
    end

    %% 1. Trigger (Envelope ONLY for search regions)
    sig_abs = abs(signal);

    win_len  = max(1, round(fs * 0.0005));
    envelope = movmean(sig_abs, win_len);

    noise_floor = prctile(envelope, 10);
    peak_val    = max(envelope);
    threshold   = noise_floor + (peak_val - noise_floor) * det_params.start_thresh_pct;

    mask = envelope > threshold;
    edges = diff([0; mask; 0]);
    raw_s = find(edges > 0);
    raw_e = find(edges < 0) - 1;

    %% 2. Merge close candidates (NO dilation)
    max_gap = round(fs * det_params.min_dist_sec);

    starts = [];
    ends   = [];

    if ~isempty(raw_s)
        cs = raw_s(1);
        ce = raw_e(1);

        for k = 2:length(raw_s)
            if raw_s(k) - ce <= max_gap
                ce = raw_e(k);
            else
                starts = [starts; cs];
                ends   = [ends; ce];
                cs = raw_s(k);
                ce = raw_e(k);
            end
        end
        starts = [starts; cs];
        ends   = [ends; ce];
    end

    %% 3. Impulse validation (PHYSICAL FILTER)
    valid_cuts = [];
    impulses   = [];
    min_imp    = det_params.min_impulse;

    for k = 1:length(starts)
        s = starts(k);
        e = ends(k);

        if e <= s, continue; end

        segment_impulse = trapz(sig_abs(s:e)) / fs;

        if segment_impulse >= min_imp
            valid_cuts = [valid_cuts; s, e];
            impulses   = [impulses; segment_impulse];
        end
    end

    cut_indices = valid_cuts;

    %% 4. Diagnostics
    diagnostics.energy        = envelope;
    diagnostics.threshold     = threshold;
    diagnostics.cut_impulses  = impulses;
end
