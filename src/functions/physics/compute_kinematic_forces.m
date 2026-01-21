function [results] = compute_kinematic_forces(results, raw_fx, raw_fy, theta_s_deg, stats_params)
    % CALCULATE_FORCES_KINEMATIC Transforms Fx/Fy to Fc/Fcn.
    % Usage: compute_kinematic_forces(..., cfg.stats)

    if nargin < 4, theta_s_deg = 0; end
    if nargin < 5 || isempty(stats_params)
        full_cfg = config_processing();
        stats_params = full_cfg.stats;
    end

    if isempty(results.cut_indices), return; end
    
    % ... (RPM & Integration code unchanged) ...
    N = length(raw_fx);
    dt = 1 / results.fs;
    rpm_t = reconstruct_rpm_signal(results, N);
    omega_t = (2 * pi * rpm_t) / 60;       
    theta_t = cumtrapz((0:N-1)'*dt, omega_t); 
    theta_offset_rad = theta_s_deg * (pi / 180);

    % Process Cuts
    num_cuts = size(results.cut_indices, 1);
    
    % Use Configured Length
    norm_len = stats_params.norm_len;
    
    stack_fc  = nan(num_cuts, norm_len);
    stack_fcn = nan(num_cuts, norm_len);
    
    for i = 1:num_cuts
        idx_s = results.cut_indices(i, 1);
        idx_e = results.cut_indices(i, 2);
        
        if idx_e > N, continue; end
        
        Fx_seg = raw_fx(idx_s:idx_e);
        Fy_seg = raw_fy(idx_s:idx_e);
        Theta_seg = theta_t(idx_s:idx_e);
        
        Theta_inst = (Theta_seg - Theta_seg(1)) + theta_offset_rad; 
        
        Fcn_inst = Fx_seg .* cos(Theta_inst) + Fy_seg .* sin(Theta_inst);
        Fc_inst  = -1 * (-Fx_seg .* sin(Theta_inst) + Fy_seg .* cos(Theta_inst));
        
        orig_grid = linspace(0, 100, length(Fx_seg));
        targ_grid = linspace(0, 100, norm_len);
        
        stack_fc(i, :)  = interp1(orig_grid, Fc_inst, targ_grid, 'linear');
        stack_fcn(i, :) = interp1(orig_grid, Fcn_inst, targ_grid, 'linear');
    end
    
    results.stack_fc  = stack_fc;
    results.stack_fcn = stack_fcn;
    
    results.avg_profile.fc_mean  = mean(stack_fc, 1, 'omitnan');
    results.avg_profile.fcn_mean = mean(stack_fcn, 1, 'omitnan');
    results.avg_profile.fc_std   = std(stack_fc, 0, 1, 'omitnan');
    results.avg_profile.fcn_std  = std(stack_fcn, 0, 1, 'omitnan');
    results.avg_profile.percent_axis = linspace(0, 100, norm_len);
end