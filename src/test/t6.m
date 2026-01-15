%% Drift Correction Validation
clear; clc; close all;
addpath('functions');

% 1. Load Data
file_path = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
raw = load_tdms_data(file_path);

% 2. Prepare Input (Standard Step A)
% We remove static offset first so we can see pure drift
fx_before = remove_offset(raw.fx, 1000); 

% 3. Apply Drift Correction (Step B)
fx_after = drift_correction(fx_before, 1, length(fx_before));

% 4. Visualization (Before vs After)
figure('Name', 'Drift Correction Focus', 'Color', 'w');

% Plot Input (Red - Has Drift)
plot(raw.time, fx_before, 'r', 'LineWidth', 1, 'DisplayName', 'Before (Offset Removed, Has Drift)'); hold on;

% Plot Output (Blue - Flat)
plot(raw.time, fx_after, 'b', 'LineWidth', 1.5, 'DisplayName', 'After (Drift Corrected)');

% Visual Guide: Trend Line approximation
p = polyfit(raw.time, fx_before, 1);
trend_line = polyval(p, raw.time);
plot(raw.time, trend_line, 'k--', 'LineWidth', 1, 'DisplayName', 'Detected Trend');

title('Drift Correction Effect');
ylabel('Force [N]'); xlabel('Time [s]');
legend('Location', 'best'); grid on;