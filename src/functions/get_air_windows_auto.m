function [win_start, win_end] = get_air_windows_auto(signal, fs)
    % GET_AIR_WINDOWS_AUTO Finds safe air regions before and after the main cut block.
    % Returns time windows [t1, t2] in seconds.
    
    %% 1. Detect Macro Activity (The "Block")
    % Heavy smoothing to see the "shape" of the block, not individual teeth
    % 0.5s window ensures we ignore small spikes but catch the main event
    env = smoothdata(abs(signal - mean(signal)), 'gaussian', fs*0.5);
    
    % Threshold: 10% of the max activity is considered "Cutting"
    % This is robust against the small "machine start" noise which is usually lower
    thresh = max(env) * 0.10;
    
    is_cutting = env > thresh;
    
    % Find First and Last index of the cutting block
    idx_first = find(is_cutting, 1, 'first');
    idx_last  = find(is_cutting, 1, 'last');
    
    if isempty(idx_first)
        error('No cutting activity detected. Check signal.');
    end
    
    %% 2. Define Safety Margins (Buffers)
    % We need to step away from the cut to avoid the "volume changing" region
    % and step away from the file ends to avoid "machine startup"
    
    buffer_cut  = 2.0; % Keep 2s away from the cut (Avoids the taper/volume change)
    buffer_file = 2.0; % Keep 2s away from start/end of file (Avoids startup instability)
    
    t = (0:length(signal)-1) / fs;
    t_cut_start = t(idx_first);
    t_cut_end   = t(idx_last);
    t_total     = t(end);
    
    %% 3. Calculate Windows
    % Window 1: Pre-Cut
    % From [FileStart + 2s]  to  [CutStart - 2s]
    w1_start = buffer_file;
    w1_end   = max(w1_start, t_cut_start - buffer_cut);
    
    % Window 2: Post-Cut
    % From [CutEnd + 2s]     to  [FileEnd - 2s]
    w2_start = t_cut_end + buffer_cut;
    w2_end   = max(w2_start, t_total - buffer_file);
    
    % Pack results
    win_start = [w1_start, w1_end];
    win_end   = [w2_start, w2_end];
    
    % Debug output
    fprintf('Auto-Detected Cut Block: %.1fs to %.1fs\n', t_cut_start, t_cut_end);
    fprintf('Safe Air Zones: [%.1f-%.1f]s and [%.1f-%.1f]s\n', ...
            win_start(1), win_start(2), win_end(1), win_end(2));
end