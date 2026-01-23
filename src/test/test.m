%% Visual Test: SIMPLIFIED Impulse Method
clear; clc; close all;

RANGE_ZOOM   = [12.0, 12.3];
FILE_KEYWORD = "PS1";

% Parameters
cfg.det.start_thresh_pct = 0.05; % 5-10% typical
cfg.det.min_dist_sec     = 0.015;
cfg.det.min_impulse      = 4e-3; % [N.s]

% Load Data
experiments = config_experiments();
exp_data = experiments(contains([experiments.set_name], FILE_KEYWORD));
raw = read_tdms_file(exp_data(1).full_path);
fs  = raw.fs(1);

% Pre-processing (Same as Main)
[ws, we, ~] = detect_air_cutting(raw.fx, fs);
[fx_c, ~]   = remove_linear_drift(raw.fx, fs, ws, we);

Wn = 5000 / (fs/2);
[b, a]  = butter(4, Wn, 'low');
fx_filt = filtfilt(b, a, fx_c);

% Crop for Zoom
idx = find(raw.time >= RANGE_ZOOM(1) & raw.time <= RANGE_ZOOM(2));
t   = raw.time(idx);
sig = fx_filt(idx);

% --- EXECUTE DETECTION ---
[cuts, diag] = detect_cut_indices(sig, fs, cfg.det);

% --- Post-Calc for Visualization Only ---
% Recreates the cumulative curve since the simplified function doesn't output it
impulse_viz = zeros(size(sig));
for k = 1:size(cuts, 1)
    s = cuts(k,1); e = cuts(k,2);
    impulse_viz(s:e) = cumtrapz(abs(sig(s:e))) / fs;
end

%% Visualization
figure('Color', 'w', 'Position', [100, 100, 1200, 700]);

% Plot 1: Signal + Envelope (Trigger View)
ax1 = subplot(3,1,1);
plot(t, sig, 'Color', [0.7 0.7 0.7], 'DisplayName', 'Filtered Fx'); hold on;
plot(t, diag.energy, 'b', 'LineWidth', 1.5, 'DisplayName', 'Envelope');
yline(diag.threshold, 'r--', 'Trigger Thresh');
legend; grid on; ylabel('Force [N]');
title('1. Trigger Candidates (Envelope)');

% Plot 2: Impulse Accumulation (Physics View)
ax2 = subplot(3,1,2);
plot(t, impulse_viz, 'g', 'LineWidth', 2); hold on;
yline(cfg.det.min_impulse, 'r--', sprintf('Min: %.3f N.s', cfg.det.min_impulse));
ylabel('Impulse [N.s]'); grid on;
title('2. Accumulated Impulse (Calculated in Viz)');

% Plot 3: Final Validated Cuts
ax3 = subplot(3,1,3);
plot(t, sig, 'k'); hold on;

if ~isempty(cuts)
    for i = 1:size(cuts, 1)
        idx_s = cuts(i,1);
        idx_e = cuts(i,2);
        
        % Green area for valid cuts
        area(t(idx_s:idx_e), sig(idx_s:idx_e), 'FaceColor', 'g', ...
             'FaceAlpha', 0.3, 'EdgeColor', 'none');
        
        % Label with value
        txt_x = (t(idx_s) + t(idx_e)) / 2;
        txt_y = max(sig(idx_s:idx_e)) * 1.1;
        text(txt_x, txt_y, sprintf('%.3f', diag.cut_impulses(i)), ...
             'HorizontalAlignment', 'center', 'Color', 'r', 'FontWeight', 'bold', 'FontSize', 8);
    end
end

ylabel('Force [N]'); xlabel('Time [s]'); grid on;
title(sprintf('3. Validated Cuts (%d found)', size(cuts,1)));

linkaxes([ax1, ax2, ax3], 'x');
xlim(RANGE_ZOOM);

% Console Output
if ~isempty(cuts)
    fprintf('Impulses found: %s\n', mat2str(diag.cut_impulses', 3));
else
    fprintf('No cuts found.\n');
end