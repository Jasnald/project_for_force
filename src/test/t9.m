%% Main Analysis Workflow (Complete)
clear; clc; close all;
addpath('functions'); 

%% 1. Configuration
file_path   = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
num_teeth   = 1;              % Number of teeth (flutes)
trim_pct    = [0.1, 0.1];   % Crop 10% from start/end of steady state
min_dist_ms = 50;             % Min distance between teeth (in ms) for detection

%% 2. Load & Pre-processing (Macro)
raw = load_tdms_data(file_path); %

fprintf('1. Auto-detecting cut region...\n');
[win_start, win_end, cut_limits] = get_air_windows_auto(raw.fx, raw.fs); %

fprintf('2. Removing Drift & Offset...\n');
[fx_clean, ~] = drift_correction(raw.fx, raw.fs, win_start, win_end); %
[fy_clean, ~] = drift_correction(raw.fy, raw.fs, win_start, win_end);

%% 3. Extract Steady State (The "Filet Mignon")
fprintf('3. Extracting steady state (%.0f%% - %.0f%% crop)...\n', trim_pct(1)*100, trim_pct(2)*100);
[fx_steady, t_steady] = extract_steady_state(fx_clean, raw.time, cut_limits, trim_pct); %
% We need fy matched to the same indices
[fy_steady, ~]        = extract_steady_state(fy_clean, raw.time, cut_limits, trim_pct);

%% 4. Micro-Segmentation (Find Individual Teeth)
% Using 'find_starts' because it detects peaks, better for continuous blocks
fprintf('4. Detecting individual tooth impacts...\n');

% Update 'find_starts' min_dist parameter dynamically or ensure it matches RPM
% Here we assume find_starts is available in functions
cut_indices = find_starts(fx_steady, raw.fs); %

fprintf('   -> Found %d impacts.\n', size(cut_indices, 1));

%% 5. Analysis & Statistics
if isempty(cut_indices)
    warning('No cuts found! Check min_dist or threshold in find_starts.');
else
    fprintf('5. Calculating averages and RPM...\n');
    %
    results = analyze_cuts_and_average(fx_steady, fy_steady, cut_indices, raw.fs, num_teeth);
    
    %% 6. Visualization
    figure('Name', 'Final Analysis', 'Color', 'w');
    
    % Subplot 1: Steady State with Detections
    subplot(2,2,1:2);
    plot(t_steady, fx_steady, 'Color', [0.8 0.8 0.8]); hold on;
    % Plot starts (green) and ends (red)
    plot(t_steady(cut_indices(:,1)), fx_steady(cut_indices(:,1)), 'g.', 'MarkerSize', 10);
    plot(t_steady(cut_indices(:,2)), fx_steady(cut_indices(:,2)), 'r.', 'MarkerSize', 10);
    title(sprintf('Steady State: %d Impacts Detected', size(cut_indices,1)));
    ylabel('Force X [N]'); grid on; axis tight;
    
    % Subplot 2: Average Profile (Cycle)
    subplot(2,2,3);
    plot(results.avg_profile.percent_axis, results.avg_profile.x_mean, 'b', 'LineWidth', 2);
    hold on;
    % Optional: Show standard deviation shadow
    x_fill = [results.avg_profile.percent_axis, fliplr(results.avg_profile.percent_axis)];
    y_fill = [results.avg_profile.x_mean + results.avg_profile.x_std, ...
              fliplr(results.avg_profile.x_mean - results.avg_profile.x_std)];
    fill(x_fill, y_fill, 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    title('Average Tooth Profile (Force X)');
    xlabel('% Cycle'); ylabel('Force [N]'); grid on;
    
    % Subplot 3: RPM Stability
    subplot(2,2,4);
    plot(results.rpm_all, 'k.-');
    yline(results.rpm_mean, 'r--', sprintf('Mean: %.0f', results.rpm_mean));
    title('Calculated RPM per Tooth');
    xlabel('Tooth Index'); ylabel('RPM'); grid on; axis tight;
end