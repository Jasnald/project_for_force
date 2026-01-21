function best_theta = optimize_entry_angle(results, phys_params)
    % OPTIMIZE_ENTRY_ANGLE Finds best entry angle based on force positivity.
    % Usage: optimize_entry_angle(results, cfg.phys)

    if nargin < 2 || isempty(phys_params)
        full_cfg = config_processing();
        phys_params = full_cfg.phys;
    end

    % Configurable search space
    step = phys_params.angle_step;
    rng = phys_params.search_range;
    search_angles = rng(1):step:rng(2); 
    
    best_score = -inf;
    best_theta = 0;
    
    % Mean profile for speed
    Fx_mean = mean(results.stack_x, 1, 'omitnan');
    Fy_mean = mean(results.stack_y, 1, 'omitnan');
    duration = mean(results.engagement_time_all);
    rpm = results.rpm_mean;
    
    t = linspace(0, duration, length(Fx_mean));
    omega = (2 * pi * rpm) / 60;
    
    for theta_guess = search_angles
        th_rad = deg2rad(theta_guess);
        theta_vec = th_rad + (omega * t);
        
        % Hypothetical Fcn
        Fcn_temp = Fx_mean .* cos(theta_vec) + Fy_mean .* sin(theta_vec);
        
        % Score = Sum(Pos) - Penalty * Sum(Neg)
        score = sum(Fcn_temp) - phys_params.optim_penalty * sum(abs(Fcn_temp(Fcn_temp < 0)));
        
        if score > best_score
            best_score = score;
            best_theta = theta_guess;
        end
    end
    
    fprintf('Auto-Detected Theta Start: %.1f degrees\n', best_theta);
end