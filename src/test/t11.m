%% Main Batch Processing (Isolation + Average + RPM)
clear; clc; close all;

% --- Setup de Caminhos ---
script_path = fileparts(mfilename('fullpath'));
% Adiciona pasta 'functions' (ajuste '../' ou './' dependendo de onde salvar este arquivo)
if exist(fullfile(script_path, 'functions'), 'dir')
    addpath(fullfile(script_path, 'functions')); 
elseif exist(fullfile(script_path, '../functions'), 'dir')
    addpath(fullfile(script_path, '../functions'));
end

% --- Configuração ---
data_folder = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\";
% Lista manual OU usar dir() para pegar todos os .tdms
file_list   = {"PS1_Probe3L.tdms"}; 

num_teeth   = 1;
trim_pct    = [0.50, 0.4950];   % Cortar 5% inicio, 10% fim
cutoff_freq = 600;            % Filtro Lowpass [Hz]

%% Loop de Arquivos
for f = 1:length(file_list)
    filename = file_list{f};
    full_path = fullfile(data_folder, filename);
    
    fprintf('\n>>> Processando: %s <<<\n', filename);
    

    % 1. Load
    raw = load_tdms_data(full_path); %
    
    % 2. Auto-Cleaning (Janelas, Drift, Filtro)
    [win_start, win_end, cut_limits] = get_air_windows_auto(raw.fx, raw.fs); %
    
    [fx_c, ~] = drift_correction(raw.fx, raw.fs, win_start, win_end); %
    [fy_c, ~] = drift_correction(raw.fy, raw.fs, win_start, win_end);
    
    if exist('noisefilter_Signal', 'file')
        fx_c = noisefilter_Signal(fx_c, 1/raw.fs, cutoff_freq);
        fy_c = noisefilter_Signal(fy_c, 1/raw.fs, cutoff_freq);
    else
        fx_c = lowpass(fx_c, cutoff_freq, raw.fs);
        fy_c = lowpass(fy_c, cutoff_freq, raw.fs);
    end
    
    % 3. Isolation (Steady State)
    [fx_steady, t_steady] = extract_steady_state(fx_c, raw.time, cut_limits, trim_pct); %
    [fy_steady, ~]        = extract_steady_state(fy_c, raw.time, cut_limits, trim_pct);
    
    % 4. Segmentation (Find Teeth)
    cut_indices = find_starts(fx_steady, raw.fs); %
    

    % 5. Metrics (Average & RPM)
    results = analyze_cuts_and_average(fx_steady, fy_steady, cut_indices, raw.fs, num_teeth); %
    
    fprintf('   -> Cortes: %d | RPM Médio: %.0f | Tempo Médio: %.4fs\n', ...
            size(cut_indices,1), results.rpm_mean, results.engagement_time_mean);
    
    % 6. Visualization (Função Nova)
    visualize_results(t_steady, fx_steady, cut_indices, results, filename);


end