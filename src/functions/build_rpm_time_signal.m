function rpm_t = build_rpm_time_signal(results, total_samples)
    % BUILD_RPM_TIME_SIGNAL Constructs a full-length RPM vector from per-cut data.
    
    rpm_t = nan(total_samples, 1);
    
    % Fill known regions (during cuts)
    for i = 1:size(results.cut_indices, 1)
        idx_s = results.cut_indices(i, 1);
        idx_e = results.cut_indices(i, 2);
        
        if idx_e > total_samples, continue; end
        
        val = results.rpm_all(i);
        if isnan(val), val = results.rpm_mean; end
        
        rpm_t(idx_s:idx_e) = val;
    end
    
    % Fill gaps (Air cutting) with previous known value (Piecewise Constant)
    rpm_t = fillmissing(rpm_t, 'previous');
    
    % Fallback for initial NaNs if signal starts with air
    if any(isnan(rpm_t))
        rpm_t = fillmissing(rpm_t, 'next');
    end
    
    % Final safety fallback
    if all(isnan(rpm_t))
        rpm_t(:) = results.rpm_mean; 
    end
end