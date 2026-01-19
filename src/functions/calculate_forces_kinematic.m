function [results] = calculate_forces_kinematic(results, raw_fx, raw_fy, rotation_dir)
    % CALCULATE_FORCES_KINEMATIC Transforms Fx/Fy to Fc/Fcn using instantaneous Theta(t).
    % Physics: Theta(t) = Integral(Omega(t) dt)
    
    if nargin < 4, rotation_dir = 1; end

    % 1. Validation
    if isempty(results.cut_indices), return; end
    
    % 2. Build Global RPM Vector (Stepwise approximation)
    N = length(raw_fx);
    rpm_t = build_rpm_time_signal(results, N);
    
    % 3. Integrate RPM -> Theta (Global)
    dt = 1 / results.fs;
    t_global = (0:N-1)' * dt;
    
    omega_t = (2 * pi * rpm_t) / 60; % [rad/s]
    theta_t = cumtrapz(t_global, omega_t); % [rad]
    
    % 4. Process Cuts with Instantaneous Angle
    num_cuts = size(results.cut_indices, 1);
    norm_len = 1000;
    
    stack_fc  = nan(num_cuts, norm_len);
    stack_fcn = nan(num_cuts, norm_len);
    
    for i = 1:num_cuts
        idx_s = results.cut_indices(i, 1);
        idx_e = results.cut_indices(i, 2);
        
        if idx_e > N, continue; end
        
        % Extract slices
        Fx_seg = raw_fx(idx_s:idx_e);
        Fy_seg = raw_fy(idx_s:idx_e);
        Theta_seg = theta_t(idx_s:idx_e);
        
        % Normalize Theta relative to cut start (assuming cut starts at 0 or aligns later)
        % Note: If you have a specific start angle offset, add it here:
        Theta_local = Theta_seg - Theta_seg(1); 
        
        % Transformation (Using instantaneous angle)
        Fcn_inst = Fx_seg .* cos(Theta_local) + Fy_seg .* sin(Theta_local);
        Fc_inst  = rotation_dir * (-Fx_seg .* sin(Theta_local) + Fy_seg .* cos(Theta_local));
        
        % Interpolate to normalized grid for averaging
        orig_grid = linspace(0, 100, length(Fx_seg));
        targ_grid = linspace(0, 100, norm_len);
        
        stack_fc(i, :)  = interp1(orig_grid, Fc_inst, targ_grid, 'linear');
        stack_fcn(i, :) = interp1(orig_grid, Fcn_inst, targ_grid, 'linear');
    end
    
    % 5. Store Results
    results.stack_fc  = stack_fc;
    results.stack_fcn = stack_fcn;
    
    results.avg_profile.fc_mean  = mean(stack_fc, 1, 'omitnan');
    results.avg_profile.fcn_mean = mean(stack_fcn, 1, 'omitnan');
    results.avg_profile.fc_std   = std(stack_fc, 0, 1, 'omitnan');
    results.avg_profile.fcn_std  = std(stack_fcn, 0, 1, 'omitnan');
    
    % Ensure x-axis exists for plotting
    results.avg_profile.percent_axis = linspace(0, 100, norm_len);
end