%% Main Batch Processing (Isolation + Average + RPM)
% Arquivo: src/test/run_batch_processing.m
clear; clc; close all;

% --- 1. Setup de Caminhos ---
% Adiciona 'src/functions' e todas as subpastas (io, physics, processing, vis)
script_path = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(script_path, '../functions'))); 

% Adiciona a pasta onde está o config_experiments (se estiver na raiz do src)
addpath(fullfile(script_path, '..')); 

% --- 2. Carregar Configuração ---
all_experiments = config_experiments();

% --- 3. Parâmetros de Processamento ---
processing_params.num_teeth   = 1;
processing_params.trim_pct    = [0.150, 0.150]; % Cortar 15% inicio/fim do steady state
processing_params.cutoff_freq = 1000;           % Filtro Lowpass [Hz]

% --- SELEÇÃO DE ARQUIVOS ---
% Opção A: Rodar TUDO
% queue = all_experiments;

% Opção B: Rodar apenas PS1 (Exemplo de filtro)
queue = all_experiments(contains([all_experiments.set_name], "PS2"));

%% Loop de Processamento
fprintf('Iniciando processamento de %d arquivos...\n', length(queue));

for k = 1:length(queue)
    exp_data = queue(k);
    filename = exp_data.filename;
    
    fprintf('\n>>> [%d/%d] Processando: %s <<<\n', k, length(queue), filename);
    fprintf('    Geometria: ae=%.1f mm, Theta Start=%.1f deg\n', exp_data.ae, exp_data.theta_s_deg);

    try
        % 1. Read (Leitura)
        % Antigo: load_tdms_data
        raw = read_tdms_file(exp_data.full_path);
        
        % 2. Auto-Cleaning (Detecção de Ar e Drift)
        % Antigo: get_air_windows_auto
        [win_start, win_end, cut_limits] = detect_air_cutting(raw.fx, raw.fs);
        
        % Antigo: drift_correction
        [fx_c, ~] = remove_linear_drift(raw.fx, raw.fs, win_start, win_end);
        [fy_c, ~] = remove_linear_drift(raw.fy, raw.fs, win_start, win_end);
        
        % Filtragem (Lowpass padrão para Força)
        fx_c = lowpass(fx_c, processing_params.cutoff_freq, raw.fs);
        fy_c = lowpass(fy_c, processing_params.cutoff_freq, raw.fs);
        
        % 3. Isolation (Recorte do Regime Permanente)
        % Antigo: extract_steady_state
        [fx_steady, t_steady] = crop_steady_state(fx_c, raw.time, cut_limits, processing_params.trim_pct);
        [fy_steady, ~]        = crop_steady_state(fy_c, raw.time, cut_limits, processing_params.trim_pct);
        
        % 4. Segmentation (Detecção dos Dentes)
        % Antigo: find_starts
        cut_indices = detect_cut_indices(fx_steady, raw.fs);

        if isempty(cut_indices)
            warning('Pulando %s: Nenhum corte detectado.', filename);
            continue;
        end

        % 5. Metrics (Cálculo de Médias e RPM)
        % Antigo: analyze_cuts_and_average
        results = compute_cut_statistics(fx_steady, fy_steady, cut_indices, raw.fs, processing_params.num_teeth);
        
        % Validação básica
        if isfield(results, 'avg_profile') && all(isnan(results.avg_profile.x_mean))
            warning('A análise gerou resultados NaN. Verifique a qualidade do sinal.');
            continue;
        end

        fprintf('    -> Cortes Detectados: %d | RPM Médio: %.0f\n', ...
                size(cut_indices,1), results.rpm_mean);

        % 6. Coordinate Transformation (Cálculo de Fc e Fcn)
        % Antigo: calculate_forces_kinematic
        % Nota: Agora passamos o theta_s_deg que veio do config_experiments
        results = compute_kinematic_forces(results, fx_steady, fy_steady, exp_data.theta_s_deg);
        
        % 7. Visualization (Dashboard)
        % Antigo: visualize_results
        plot_analysis_dashboard(t_steady, fx_steady, cut_indices, results, filename);
        
    catch ME
        fprintf('ERRO ao processar %s: %s\n', filename, ME.message);
    end
end