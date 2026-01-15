function [steady_data, steady_time] = extract_steady_state(data, time, cut_interval, trim_pct)
    % EXTRACT_STEADY_STATE Crops the signal to keep only the stable cutting region.
    % Inputs:
    %   cut_interval: [t_start, t_end] found by auto-detection
    %   trim_pct: [pct_start, pct_end] e.g., [0.05 0.10] (5% start, 10% end)
    
    t_start = cut_interval(1);
    t_end   = cut_interval(2);
    duration = t_end - t_start;
    
    % Calculate new limits
    new_t1 = t_start + (duration * trim_pct(1));
    new_t2 = t_end   - (duration * trim_pct(2));
    
    % Find indices corresponding to these times
    idx_start = find(time >= new_t1, 1, 'first');
    idx_end   = find(time <= new_t2, 1, 'last');
    
    % Crop
    steady_data = data(idx_start:idx_end);
    steady_time = time(idx_start:idx_end);
    
    fprintf('Steady State: %.2fs to %.2fs (Removed %.0f%% Start, %.0f%% End)\n', ...
            new_t1, new_t2, trim_pct(1)*100, trim_pct(2)*100);
end