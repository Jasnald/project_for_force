%% Step 1: Load and Pre-process Data
clear; close all; clc;

% Configuration
file_path = 'caminho/para/seu_arquivo.tdms'; % Update path
conf.fs = 10000; % Sampling frequency (Hz)
conf.use_filter = false; % Set true if signal is too noisy

%% 1. Load Data
% Assuming you have the TDMS reader in path
% If not, we need to add the specific reader function
try
    data_struct = TDMS_readTDMSFile(file_path);
    % Extract channels (Adjust indices 3,4,5 based on your TDMS structure)
    raw_x = data_struct.data{3}; 
    raw_y = data_struct.data{4};
    raw_z = data_struct.data{5}; % Parallel to lathe axis (ignored for now)
catch
    error('TDMS Reader not found or file path incorrect.');
end

%% 2. Signal Treatment (Offset & Drift)
% Calculate sample indices for "air cutting" (start and end)
% Adjust these values based on your data length
n_samples = length(raw_x);
idx_start = 1:500;                % First 500 points
idx_end = n_samples-500:n_samples; % Last 500 points

% Apply Offset Correction (Zeroing based on start)
clean_x = raw_x - mean(raw_x(idx_start));
clean_y = raw_y - mean(raw_y(idx_start));

% Apply Drift Correction (Linear trend removal using start and end)
% Using a simplified version of your KSS_drift_correction logic
slope_x = (mean(raw_x(idx_end)) - mean(raw_x(idx_start))) / n_samples;
trend_x = slope_x * (1:n_samples)';
clean_x = clean_x - trend_x;

slope_y = (mean(raw_y(idx_end)) - mean(raw_y(idx_start))) / n_samples;
trend_y = slope_y * (1:n_samples)';
clean_y = clean_y - trend_y;

%% 3. Filter (Optional)
if conf.use_filter
    % Using your existing function
    clean_x = noisefilter_Signal(clean_x, 1/conf.fs, 600); % Example freq
    clean_y = noisefilter_Signal(clean_y, 1/conf.fs, 600);
end

%% 4. Calculate Resultant Force (For Detection)
force_res = sqrt(clean_x.^2 + clean_y.^2);

%% 5. Visualization
t = (0:length(clean_x)-1) / conf.fs;

figure('Name', 'Data Pre-processing');
subplot(3,1,1); plot(t, clean_x); title('Force X (Treated)'); grid on;
subplot(3,1,2); plot(t, clean_y); title('Force Y (Treated)'); grid on;
subplot(3,1,3); plot(t, force_res); title('Resultant Force'); grid on;
ylabel('Force [N]'); xlabel('Time [s]');