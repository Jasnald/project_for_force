%% Main Batch Processing (Fully Refactored)
clear; clc; close all;

% --- Setup ---
cfg = config_processing(); % Carrega TUDO aqui
all_experiments = config_experiments();

% Seleciona arquivos (ex: PS3)
queue = all_experiments(contains([all_experiments.set_name], "PS3"));

%% Processing Loop
fprintf('Starting processing of %d files...\n', length(queue));

for k = 1:length(queue)
    exp_data = queue(k);
    filename = exp_data.filename;
    fprintf('\n>>> [%d/%d] Processing: %s <<<\n', k, length(queue), filename);
    
    try
        % 1. Read Data
        raw = read_tdms_file(exp_data.full_path);
        if numel(raw.fs) > 1, raw.fs = raw.fs(1); end
        
        % 2. Auto-Cleaning
        [win_start, win_end, cut_limits] = detect_air_cutting(raw.fx, raw.fs, cfg.air);
        [fx_c, ~] = remove_linear_drift(raw.fx, raw.fs, win_start, win_end);
        [fy_c, ~] = remove_linear_drift(raw.fy, raw.fs, win_start, win_end);
        
        % 3. Filtering (Usa cfg.filter)
        fprintf('    Filter: Butterworth Order %d @ %.0f Hz\n', cfg.filter.order, cfg.filter.cutoff_freq);
        
        Wn = cfg.filter.cutoff_freq / (raw.fs / 2);
        [b, a] = butter(cfg.filter.order, Wn, 'low');
        
        fx_c = filtfilt(b, a, fx_c);
        fy_c = filtfilt(b, a, fy_c);
        
        % 4. Isolation
        [fx_steady, t_steady] = crop_steady_state(fx_c, raw.time, cut_limits, cfg.stats.default_trim);
        [fy_steady, ~]        = crop_steady_state(fy_c, raw.time, cut_limits, cfg.stats.default_trim);
        
        % 5. Segmentation
        cut_indices = detect_cut_indices(fx_steady, raw.fs, cfg.det);

        if isempty(cut_indices)
            warning('Skipping %s: No cuts detected.', filename);
            continue;
        end

        % 6. Metrics (Usa cfg.tool.num_teeth)
        results = compute_cut_statistics(fx_steady, fy_steady, cut_indices, raw.fs, ...
                                         cfg.tool.num_teeth, cfg.stats);
        
        % Validação rápida
        if isfield(results, 'avg_profile') && all(isnan(results.avg_profile.x_mean))
            warning('Results contain NaN.');
            continue;
        end

        fprintf('    -> Cuts: %d | Mean RPM: %.0f\n', size(cut_indices,1), results.rpm_mean);

        % 7. Kinematic Forces
        results = compute_kinematic_forces(results, fx_steady, fy_steady, exp_data.theta_s_deg, cfg.stats);
        
        % 8. Visualization
        plot_analysis_dashboard(t_steady, fx_steady, cut_indices, results, filename);
        
    catch ME
        fprintf('ERROR processing %s: %s\n', filename, ME.message);
    end
end