%% Main Analysis Workflow (Fixed Path)
clear; clc; close all;

% --- CORREÇÃO DO PATH (BLINDADO) ---
% Descobre onde este arquivo 't9.m' está salvo
script_path = fileparts(mfilename('fullpath'));

% Adiciona a pasta 'functions' relativa a este script.
% Se t9 está em 'src/test', subimos um nivel (..) e entramos em 'functions'
% Ajuste '../functions' para 'functions' se o script estiver na mesma pasta que ela.
if exist(fullfile(script_path, '../functions'), 'dir')
    addpath(fullfile(script_path, '../functions'));
elseif exist(fullfile(script_path, 'functions'), 'dir')
    addpath(fullfile(script_path, 'functions'));
else
    error('Pasta "functions" não encontrada! Verifique onde você salvou os arquivos.');
end
% -----------------------------------

%% 1. Configuration
file_path   = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
num_teeth   = 1;
% AVISO: [0.5, 0.49] cortaria 99% do sinal. Voltei para 5% e 10%.
trim_pct    = [0.1, 0.1];   
min_dist_ms = 50;            

%% 2. Load & Pre-processing
% Agora ele deve encontrar a função
raw = load_tdms_data(file_path); %

fprintf('1. Auto-detecting cut region...\n');
[win_start, win_end, cut_limits] = get_air_windows_auto(raw.fx, raw.fs); %

fprintf('2. Removing Drift & Offset...\n');
[fx_clean, ~] = drift_correction(raw.fx, raw.fs, win_start, win_end); %
[fy_clean, ~] = drift_correction(raw.fy, raw.fs, win_start, win_end);

%% 2.5 Filtering
cutoff_freq = 1000;
fprintf('2.5. Applying Noise Filter (Cutoff: %d Hz)...\n', cutoff_freq);

% Verifica filtros disponíveis
if exist('noisefilter_Signal', 'file')
    dt = 1/raw.fs;
    fx_clean = noisefilter_Signal(fx_clean, dt, cutoff_freq);
    fy_clean = noisefilter_Signal(fy_clean, dt, cutoff_freq);
elseif exist('apply_bandpass', 'file')
    % Se não tiver noisefilter, usa lowpass do MATLAB
    fx_clean = lowpass(fx_clean, cutoff_freq, raw.fs);
    fy_clean = lowpass(fy_clean, cutoff_freq, raw.fs);
end

%% 3. Extract Steady State
fprintf('3. Extracting steady state (%.0f%% - %.0f%% crop)...\n', trim_pct(1)*100, trim_pct(2)*100);
[fx_steady, t_steady] = extract_steady_state(fx_clean, raw.time, cut_limits, trim_pct); %
[fy_steady, ~]        = extract_steady_state(fy_clean, raw.time, cut_limits, trim_pct);

%% 4. Micro-Segmentation
fprintf('4. Detecting individual tooth impacts...\n');
cut_indices = find_starts(fx_steady, raw.fs); %

if isempty(cut_indices)
    warning('No cuts found! Try reducing min_dist_ms or checking thresholds.');
    fprintf('   -> Found 0 impacts.\n');
else
    fprintf('   -> Found %d impacts.\n', size(cut_indices, 1));
    
    %% 5. Analysis & Visualization
    results = analyze_cuts_and_average(fx_steady, fy_steady, cut_indices, raw.fs, num_teeth); %
    
    figure('Name', 'Final Analysis', 'Color', 'w');
    
    % Plot 1: Detections
    subplot(2,2,1:2);
    plot(t_steady, fx_steady, 'Color', [0.8 0.8 0.8]); hold on;
    plot(t_steady(cut_indices(:,1)), fx_steady(cut_indices(:,1)), 'g.', 'MarkerSize', 15);
    plot(t_steady(cut_indices(:,2)), fx_steady(cut_indices(:,2)), 'r.', 'MarkerSize', 15);
    title(sprintf('Steady State: %d Impacts Detected', size(cut_indices,1)));
    ylabel('Force X [N]'); grid on; axis tight;
    
    % Plot 2: Profile
    subplot(2,2,3);
    plot(results.avg_profile.percent_axis, results.avg_profile.x_mean, 'b', 'LineWidth', 2);
    x_fill = [results.avg_profile.percent_axis, fliplr(results.avg_profile.percent_axis)];
    y_fill = [results.avg_profile.x_mean + results.avg_profile.x_std, ...
              fliplr(results.avg_profile.x_mean - results.avg_profile.x_std)];
    fill(x_fill, y_fill, 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    title('Average Tooth Profile'); xlabel('% Cycle'); grid on;
    
    % Plot 3: RPM
    subplot(2,2,4);
    plot(results.rpm_all, 'k.-');
    yline(results.rpm_mean, 'r--', sprintf('Mean: %.0f', results.rpm_mean));
    title('RPM per Tooth'); xlabel('Index'); grid on;
end