function tune_processing_params()
    %% 1. Setup & Load
    script_path = fileparts(mfilename('fullpath'));
    addpath(genpath(fullfile(script_path, '../functions'))); 
    
    % Carrega arquivo
    all_exp = config_experiments();
    if isempty(all_exp), error('Nenhum experimento encontrado.'); end
    test_file = all_exp(1); 
    
    fprintf('Carregando: %s...\n', test_file.filename);
    raw = read_tdms_file(test_file.full_path);
    if numel(raw.fs) > 1, raw.fs = raw.fs(1); end
    
    % Parâmetros Iniciais
    p.trim_s = 10; p.trim_e = 10;   
    p.cut_freq = 1000; p.order = 4; 
    p.min_dist = 15; p.min_h = 1.5;   
    p.start_th = 1.0; % [NOVO] Threshold de início
    p.smooth = 0.5;   % [NOVO] Suavização

    %% 2. Interface Gráfica
    fig = uifigure('Name', 'Tuning Tool', 'Position', [100 50 1200 750]);
    panel = uipanel(fig, 'Position', [10 10 250 730], 'Title', 'Controles');
    
    y = 690; % Começa um pouco mais alto para caber tudo
    
    % --- Sliders ---
    [sld_trim_s, ~, y] = make_slider(panel, y, 'Trim Start (%)', [0 50], p.trim_s, '%.1f%%');
    [sld_trim_e, ~, y] = make_slider(panel, y, 'Trim End (%)', [0 50], p.trim_e, '%.1f%%');
    [sld_freq,   ~, y] = make_slider(panel, y, 'Cutoff Freq (Hz)', [100 5000], p.cut_freq, '%.0f Hz');
    [sld_order,  ~, y] = make_slider(panel, y, 'Filter Order', [2 8], p.order, '%.0f');
    [sld_dist,   ~, y] = make_slider(panel, y, 'Min Peak Dist (ms)', [5 500], p.min_dist, '%.1f ms');
    [sld_h,      ~, y] = make_slider(panel, y, 'Min Peak Height (%)', [0.1 10], p.min_h, '%.1f%%');
    
    % [NOVOS PARÂMETROS]
    [sld_sth,    ~, y] = make_slider(panel, y, 'Start Threshold (%)', [0.1 20], p.start_th, '%.1f%%');
    [sld_sm,     ~, y] = make_slider(panel, y, 'Smooth Window (ms)', [0.1 5.0], p.smooth, '%.2f ms');

    % Botões
    uibutton(panel, 'Position', [10 60 230 40], 'Text', 'Atualizar Plots', ...
             'ButtonPushedFcn', @(~,~) update_plots(), 'FontWeight', 'bold');

    uibutton(panel, 'Position', [10 10 230 30], 'Text', 'Gerar Código (CMD)', ...
             'ButtonPushedFcn', @(~,~) export_config(), 'BackgroundColor', [0.9 1 0.9]);

    ax1 = uiaxes(fig, 'Position', [280 420 900 300]); grid(ax1, 'on');
    ax2 = uiaxes(fig, 'Position', [280 50 900 350]);  grid(ax2, 'on');

    % Cache para performance
    [ws, we, lims] = detect_air_cutting(raw.fx, raw.fs);
    [fx_no_drift, ~] = remove_linear_drift(raw.fx, raw.fs, ws, we);

    update_plots(); 

    %% 3. Funções Locais
    function update_plots()
        % 1. Filtro
        Wn = sld_freq.Value / (raw.fs/2);
        [b, a] = butter(round(sld_order.Value), Wn, 'low');
        fx_filt = filtfilt(b, a, fx_no_drift);
        
        % 2. Crop
        cur_ts = sld_trim_s.Value/100;
        cur_te = sld_trim_e.Value/100;
        [fx_ss, t_ss] = crop_steady_state(fx_filt, raw.time, lims, [cur_ts, cur_te]);
        
        % 3. Detecção (Config Completa)
        full_cfg = config_processing(); 
        det_cfg = full_cfg.det;
        
        det_cfg.min_dist_sec = sld_dist.Value / 1000;      
        det_cfg.min_height_pct = sld_h.Value / 100;       
        det_cfg.start_thresh_pct = sld_sth.Value / 100;  % [Novo]
        det_cfg.smooth_win_sec = sld_sm.Value / 1000;    % [Novo]
        
        cuts = detect_cut_indices(fx_ss, raw.fs, det_cfg);
        
        % --- Visualização ---
        cla(ax1); hold(ax1, 'on');
        plot(ax1, raw.time, fx_no_drift, 'Color', [0.8 0.8 0.8]);
        plot(ax1, raw.time, fx_filt, 'b');
        xregion(ax1, lims(1) + (lims(2)-lims(1))*cur_ts, ...
                     lims(2) - (lims(2)-lims(1))*cur_te, 'FaceColor', 'g', 'FaceAlpha', 0.1);
        title(ax1, 'Sinal Filtrado'); axis(ax1, 'tight');
        
        cla(ax2); hold(ax2, 'on');
        plot(ax2, t_ss, fx_ss, 'k');
        if ~isempty(cuts)
            plot(ax2, t_ss(cuts(:,1)), fx_ss(cuts(:,1)), 'go', 'MarkerFaceColor', 'g');
            plot(ax2, t_ss(cuts(:,2)), fx_ss(cuts(:,2)), 'rs', 'MarkerFaceColor', 'r');
        end
        title(ax2, sprintf('Cortes: %d | Start Thresh: %.1f%%', size(cuts,1), sld_sth.Value)); 
        axis(ax2, 'tight');
    end

    function export_config()
        fprintf('\n%% --- PARAMETROS SELECIONADOS ---\n');
        fprintf('params.filter.cutoff_freq    = %.0f;\n', sld_freq.Value);
        fprintf('params.filter.order          = %d;\n', round(sld_order.Value));
        fprintf('params.stats.default_trim    = [%.2f, %.2f];\n', sld_trim_s.Value/100, sld_trim_e.Value/100);
        fprintf('params.det.min_dist_sec      = %.4f;\n', sld_dist.Value/1000);
        fprintf('params.det.min_height_pct    = %.4f;\n', sld_h.Value/100);
        fprintf('params.det.start_thresh_pct  = %.4f;\n', sld_sth.Value/100);
        fprintf('params.det.smooth_win_sec    = %.5f;\n', sld_sm.Value/1000);
        fprintf('%% -----------------------------\n');
    end

    function [sld, lbl, next_y] = make_slider(parent, y, txt, lims, val, fmt)
        uilabel(parent, 'Position', [10 y 200 20], 'Text', txt, 'FontWeight', 'bold');
        sld = uislider(parent, 'Position', [10 y-25 220 3], 'Limits', lims, 'Value', val);
        lbl = uilabel(parent, 'Position', [10 y-45 100 20], 'Text', sprintf(fmt, val), 'FontColor', [0.4 0.4 0.4]);
        sld.ValueChangedFcn = @(src,~) set(lbl, 'Text', sprintf(fmt, src.Value));
        next_y = y - 75; % Reduzi um pouco o espaçamento para caber tudo
    end
end