function [results] = compute_cut_statistics(force_x, force_y, cut_indices, fs, num_teeth, stats_params)
    % COMPUTE_CUT_STATISTICS Process cuts and store metadata.
    % Usage: compute_cut_statistics(..., cfg.stats)

    if nargin < 6 || isempty(stats_params)
        full_cfg = config_processing();
        stats_params = full_cfg.stats;
    end
    
    num_cuts = size(cut_indices, 1);
    
    % Use configured normalization length
    norm_len = stats_params.norm_len; 
    norm_time = linspace(0, 100, norm_len); 
    
    % Initialize matrices
    stack_x = zeros(num_cuts, norm_len);
    stack_y = zeros(num_cuts, norm_len);
    durations = zeros(num_cuts, 1);
    rpms = zeros(num_cuts, 1);
    
    %% Processing Loop
    for i = 1:num_cuts
        idx_start = cut_indices(i, 1);
        idx_end   = cut_indices(i, 2);
        
        seg_x = force_x(idx_start:idx_end);
        seg_y = force_y(idx_start:idx_end);
        
        % 1. Time Metrics
        durations(i) = length(seg_x) / fs; 
        
        % 2. Instantaneous RPM Calculation
        if i < num_cuts
            next_start = cut_indices(i+1, 1);
            time_diff = (next_start - idx_start) / fs;
            rpms(i) = (1 / (time_diff * num_teeth)) * 60;
        else
            rpms(i) = NaN; 
        end
        
        % 3. Normalization
        original_points = 1:length(seg_x);
        target_points = linspace(1, length(seg_x), norm_len);
        
        stack_x(i, :) = interp1(original_points, seg_x, target_points, 'linear');
        stack_y(i, :) = interp1(original_points, seg_y, target_points, 'linear');
    end
    
    %% Pack Results
    results.avg_profile.x_mean = mean(stack_x, 1, 'omitnan');
    results.avg_profile.y_mean = mean(stack_y, 1, 'omitnan');
    results.avg_profile.x_std  = std(stack_x, 0, 1, 'omitnan');
    results.avg_profile.y_std  = std(stack_y, 0, 1, 'omitnan');
    results.avg_profile.percent_axis = norm_time;
    
    results.rpm_mean = mean(rpms, 'omitnan');
    results.rpm_all = rpms;
    results.engagement_time_mean = mean(durations);
    results.engagement_time_all = durations;
    
    results.stack_x = stack_x;
    results.stack_y = stack_y;

    results.cut_indices = cut_indices;
    results.fs = fs; 
end