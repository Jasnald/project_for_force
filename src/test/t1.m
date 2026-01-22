%% Main Batch Processing (Flexible Mode)
clear; clc; close all;

% --- CONFIGURAÇÃO DO TESTE ---
% Escolha o modo de operação:
% 'FULL'   -> Processa tudo e mostra o dashboard completo (todos os cortes)
% 'SINGLE' -> Foca num único corte específico (visualização detalhada)
ANALYSIS_MODE = 'SINGLE'; 
TARGET_POS    = 0.30;     % Só usado se ANALYSIS_MODE = 'SINGLE' (30% do sinal)

% --- Setup ---
cfg = config_processing(); 
% Nota: Removemos o trim agressivo. Usa o padrão do config (ex: 10%)
% cfg.stats.default_trim = [0.10, 0.10]; % (Opcional: descomente para forçar valores)

all_experiments = config_experiments();
queue = all_experiments(contains([all_experiments.set_name], "PS2"));

%% Processing Loop
fprintf('Starting processing of %d files (Mode: %s)...\n', length(queue), ANALYSIS_MODE);

for k = 1:length(queue)
    exp_data = queue(k);
    filename = exp_data.filename;
    fprintf('\n>>> [%d/%d] Processing: %s <<<\n', k, length(queue), filename);
    
    try
        % 1. Read & Clean
        raw = read_tdms_file(exp_data.full_path, cfg.io);
        if numel(raw.fs) > 1, raw.fs = raw.fs(1); end
        
        [win_start, win_end, cut_limits] = detect_air_cutting(raw.fx, raw.fs, cfg.air);
        [fx_c, ~] = remove_linear_drift(raw.fx, raw.fs, win_start, win_end);
        [fy_c, ~] = remove_linear_drift(raw.fy, raw.fs, win_start, win_end);
        
        % 2. Filter
        Wn = cfg.filter.cutoff_freq / (raw.fs / 2);
        [b, a] = butter(cfg.filter.order, Wn, 'low');
        fx_c = filtfilt(b, a, fx_c);
        fy_c = filtfilt(b, a, fy_c);
        
        % 3. Isolation (Steady State)
        % Aqui pegamos o "Período" estável inteiro primeiro
        [fx_steady, t_steady] = crop_steady_state(fx_c, raw.time, cut_limits, cfg.stats.default_trim);
        [fy_steady, ~]        = crop_steady_state(fy_c, raw.time, cut_limits, cfg.stats.default_trim);
        
        % --- SELETOR DE MODO ---
        if strcmp(ANALYSIS_MODE, 'SINGLE')
            % ====================================================
            % MODO: APENAS UM CORTE (SINGLE CUT)
            % ====================================================
            [cut_fx, t_cut, info] = crop_cut_at_location(fx_steady, raw.fs, TARGET_POS, cfg.det);
            
            % Plot dedicado ao corte único
            figure('Name', "Single Cut: " + filename, 'Color', 'w');
            plot(t_cut*1000, cut_fx, 'b.-', 'LineWidth', 1.5);
            title(sprintf('%s | Corte #%d (em %.0f%%)', filename, info.cut_index, TARGET_POS*100));
            xlabel('Tempo [ms]'); ylabel('Força Fx [N]'); 
            grid on; axis tight;
            
        else
            % ====================================================
            % MODO: ANÁLISE COMPLETA (FULL)
            % ====================================================
            cut_indices = detect_cut_indices(fx_steady, raw.fs, cfg.det);

            if isempty(cut_indices)
                warning('Skipping %s: No cuts detected.', filename);
                continue;
            end

            results = compute_cut_statistics(fx_steady, fy_steady, cut_indices, raw.fs, ...
                                             cfg.tool.num_teeth, cfg.stats);
            
            results = compute_kinematic_forces(results, fx_steady, fy_steady, ...
                                            exp_data.theta_s_deg, cfg.stats);
            
            plot_analysis_dashboard(t_steady, fx_steady, cut_indices, ...
                                    results, filename, cfg.vis);
                                    
            fprintf('    -> Full Analysis Done: %d cuts found.\n', size(cut_indices,1));
        end
        
    catch ME
        fprintf('ERROR processing %s: %s\n', filename, ME.message);
    end
end