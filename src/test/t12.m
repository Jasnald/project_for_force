%% Main Batch Processing (CORRECTED)
clear; clc; close all;

% --- Path Setup ---
script_path = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(script_path, '../functions'))); 
addpath(fullfile(script_path, '..')); 

% --- Configuration ---
all_experiments = config_experiments();
proc_params.num_teeth   = 1;
proc_params.trim_pct    = [0.50, 0.495]; 
proc_params.cutoff_freq = 2000; 
proc_params.filter_ord  = 4;

% --- Select Files ---
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
        
        % --- FIX: Forçar fs ser escalar ---
        if numel(raw.fs) > 1
            raw.fs = raw.fs(1); 
        end
        % ----------------------------------
        
        % 2. Auto-Cleaning
        [win_start, win_end, cut_limits] = detect_air_cutting(raw.fx, raw.fs);
        [fx_c, ~] = remove_linear_drift(raw.fx, raw.fs, win_start, win_end);
        [fy_c, ~] = remove_linear_drift(raw.fy, raw.fs, win_start, win_end);
        
        % 3. Filtering (Butterworth + Filtfilt)
        fprintf('    Applying Butterworth (Order %d): %.1f Hz\n', proc_params.filter_ord, proc_params.cutoff_freq);
        
        Wn = proc_params.cutoff_freq / (raw.fs / 2);
        [b, a] = butter(proc_params.filter_ord, Wn, 'low');
        
        fx_c = filtfilt(b, a, fx_c);
        fy_c = filtfilt(b, a, fy_c);
        
        % 4. Isolation
        [fx_steady, t_steady] = crop_steady_state(fx_c, raw.time, cut_limits, proc_params.trim_pct);
        [fy_steady, ~]        = crop_steady_state(fy_c, raw.time, cut_limits, proc_params.trim_pct);
        
        % 5. Segmentation
        cut_indices = detect_cut_indices(fx_steady, raw.fs);

        if isempty(cut_indices)
            warning('Skipping %s: No cuts detected.', filename);
            continue;
        end

        % 6. Metrics
        results = compute_cut_statistics(fx_steady, fy_steady, cut_indices, raw.fs, proc_params.num_teeth);
        
        if isfield(results, 'avg_profile') && all(isnan(results.avg_profile.x_mean))
            warning('Results contain NaN.');
            continue;
        end

        fprintf('    -> Cuts: %d | Mean RPM: %.0f\n', size(cut_indices,1), results.rpm_mean);

        % 7. Kinematic Forces
        results = compute_kinematic_forces(results, fx_steady, fy_steady, exp_data.theta_s_deg);
        
        % 8. Visualization
        plot_analysis_dashboard(t_steady, fx_steady, cut_indices, results, filename);
        
    catch ME
        fprintf('ERROR processing %s: %s\n', filename, ME.message);
        % Opcional: ver onde deu erro
        % fprintf('Line: %d\n', ME.stack(1).line); 
    end
end