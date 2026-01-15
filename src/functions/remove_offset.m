% REMOVE_OFFSET Tares the signal using a static region before the event.
% Refactored from 'offsetcorrection.m'.

function corrected_data = remove_offset(data, event_start_idx)
    
    % Define static region (heuristic: 50% to 80% of pre-event path)
    % Avoids startup noise and immediate pre-cut rise
    win_start = max(1, round(event_start_idx * 0.5));
    win_end   = max(win_start, round(event_start_idx * 0.8));
    
    % Calculate offset (DC bias)
    offset_val = mean(data(win_start:win_end));
    
    % Subtract offset
    corrected_data = data - offset_val;
end