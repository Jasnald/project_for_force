function [results] = calculate_forces_kinematic(results, raw_fx, raw_fy, rotation_dir)

    if nargin < 4 || isempty(rotation_dir)
        rotation_dir = 1;
    end

    if ~isfield(results,'cut_indices') || ~isfield(results,'fs') || ...
       ~isfield(results,'rpm_all') || ~isfield(results,'rpm_mean')
        error('Struct incompleta.');
    end

    num_cuts = size(results.cut_indices,1);
    norm_len = 1000;

    stack_fc  = nan(num_cuts, norm_len);
    stack_fcn = nan(num_cuts, norm_len);

    %% 1. Construir RPM(t) global (piecewise)
    N = length(raw_fx);
    rpm_t = nan(N,1);

    for i = 1:num_cuts
        idx_start = results.cut_indices(i,1);
        idx_end   = results.cut_indices(i,2);

        if idx_end > N, continue; end

        rpm_i = results.rpm_all(i);
        if isnan(rpm_i)
            rpm_i = results.rpm_mean;
        end

        rpm_t(idx_start:idx_end) = rpm_i;
    end

    rpm_t = fillmissing(rpm_t,'previous');

    %% 2. Integrar RPM(t) → theta(t)
    fs = results.fs;
    t  = (0:N-1)'/fs;

    w_t = 2*pi * rpm_t / 60;
    theta_t = cumtrapz(t, w_t);

    %% 3. Processamento corte a corte
    for i = 1:num_cuts
        idx_start = results.cut_indices(i,1);
        idx_end   = results.cut_indices(i,2);

        if idx_end > N, continue; end

        Fx_seg = raw_fx(idx_start:idx_end);
        Fy_seg = raw_fy(idx_start:idx_end);
        theta_seg = theta_t(idx_start:idx_end);

        num_samples = length(Fx_seg);
        if num_samples < 2, continue; end

        Fcn_inst = Fx_seg .* cos(theta_seg) + Fy_seg .* sin(theta_seg);
        Fc_inst  = rotation_dir * (-Fx_seg .* sin(theta_seg) + Fy_seg .* cos(theta_seg));

        original_grid = 1:num_samples;
        target_grid   = linspace(1, num_samples, norm_len);

        stack_fc(i,:)  = interp1(original_grid, Fc_inst,  target_grid,'linear');
        stack_fcn(i,:) = interp1(original_grid, Fcn_inst, target_grid,'linear');
    end

    %% 4. Estatísticas
    results.stack_fc  = stack_fc;
    results.stack_fcn = stack_fcn;

    results.avg_profile.fc_mean  = mean(stack_fc, 1,'omitnan');
    results.avg_profile.fcn_mean = mean(stack_fcn,1,'omitnan');
    results.avg_profile.fc_std   = std(stack_fc, 0,1,'omitnan');
    results.avg_profile.fcn_std  = std(stack_fcn,0,1,'omitnan');

    results.avg_profile.percent_axis = linspace(0,100,norm_len);
end
