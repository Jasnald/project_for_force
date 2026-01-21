function plot_analysis_dashboard(t_steady, fx_steady, cut_indices, results, filename, vis_params)
    % PLOT_ANALYSIS_DASHBOARD Gera um dashboard padronizado e pronto para publicação.
    % Aceita vis_params para controle centralizado de estilo.
    
    % --- Config Handling ---
    if nargin < 6 || isempty(vis_params)
        cfg = config_processing();
        vis_params = cfg.vis;
    end
    
    title_text = char(filename); 
    
    % Setup Figure (White background, standard size)
    fig = figure('Name', ['Dashboard: ' title_text], 'Color', 'w', 'Position', [50 50 1000 900]);
    
    %% 1. Raw Signal (Top)
    subplot(3,2,1:2);
    plot_raw_signal(t_steady, fx_steady, cut_indices, vis_params);
    apply_style(vis_params); 
    
    %% 2. Diagnostics (Middle)
    % 2.1 Sensor Profile
    subplot(3,2,3);
    plot_sensor_profile(results, vis_params);
    apply_style(vis_params);
    
    % 2.2 RPM
    subplot(3,2,4);
    plot_rpm_stability(results, vis_params);
    apply_style(vis_params);

    %% 3. Kinematic Forces (Bottom)
    subplot(3,2,5:6);
    plot_kinematic_forces(results, title_text, vis_params);
    apply_style(vis_params);
    
    % Final Global Adjustments (Fonts)
    set(findall(fig, '-property', 'FontSize'), 'FontSize', vis_params.font_size, 'FontName', vis_params.font_name);
end

%% ============================================================
%%                  LOCAL PLOTTING FUNCTIONS
%% ============================================================

function plot_raw_signal(t, signal, indices, v)
    % Raw signal: Thinner line with configured color
    plot(t, signal, 'Color', v.color_raw, 'LineWidth', v.line_width_thin, 'DisplayName', 'Raw Signal'); 
    hold on;
    
    % Valid indices check
    starts = indices(:,1); ends = indices(:,2);
    valid_s = starts <= length(signal); valid_e = ends <= length(signal);
    
    % Markers: Start/End colors from config
    plot(t(starts(valid_s)), signal(starts(valid_s)), '.', 'Color', v.color_start, 'MarkerSize', 12, 'DisplayName', 'Start');
    plot(t(ends(valid_e)),   signal(ends(valid_e)),   '.', 'Color', v.color_end,   'MarkerSize', 12, 'DisplayName', 'End');
    
    title(sprintf('1. Detection Overview (%d Cuts)', size(indices,1)));
    ylabel('Force Fx [N]'); xlabel('Time [s]');
    legend('Location', 'northeast', 'Box', 'off'); axis tight;
end

function plot_sensor_profile(results, v)
    % Sensor Profile: Configured Mean Color
    plot_shaded_std(results.avg_profile.percent_axis, ...
                    results.avg_profile.x_mean, ...
                    results.avg_profile.x_std, v.color_mean, v); 
                    
    title('2.1. Mean Sensor Profile (Fx)');
    xlabel('% of Engagement'); ylabel('Force [N]'); 
end

function plot_rpm_stability(results, v)
    % RPM: Dark Grey standard, distinctive markers
    plot(results.rpm_all, 'o-', 'Color', [0.2 0.2 0.2], 'LineWidth', v.line_width_thin, ...
         'MarkerSize', 4, 'MarkerFaceColor', [0.5 0.5 0.5]);
    
    yline(results.rpm_mean, '--', sprintf('Mean: %.0f', results.rpm_mean), ...
          'Color', v.color_end, 'LineWidth', v.line_width_thick, 'LabelHorizontalAlignment', 'left');
    
    title('2.2. RPM Stability Check'); 
    xlabel('Tooth Index'); ylabel('RPM'); 
    xlim([1, max(2, length(results.rpm_all))]);
end

function plot_kinematic_forces(results, title_text, v)
    if isfield(results.avg_profile, 'fc_mean') && ~isempty(results.avg_profile.fc_mean)
        
        num_pts = length(results.avg_profile.fc_mean);
        duration_ms = results.engagement_time_mean * 1000; 
        time_axis = linspace(0, duration_ms, num_pts);
        
        % Cores fixas para física (Tangencial/Normal) ou adicione ao config se preferir
        color_fc = 'r';
        color_fcn = 'b';

        % Plot Shadows
        plot_shaded_std(time_axis, results.avg_profile.fc_mean, results.avg_profile.fc_std, color_fc, v);
        plot_shaded_std(time_axis, results.avg_profile.fcn_mean, results.avg_profile.fcn_std, color_fcn, v);
        
        % Plot Lines (Thicker)
        h1 = plot(time_axis, results.avg_profile.fc_mean, 'Color', color_fc, 'LineWidth', v.line_width_thick);
        h2 = plot(time_axis, results.avg_profile.fcn_mean, 'Color', color_fcn, 'LineWidth', v.line_width_thick);
        
        ylabel('Force [N]'); xlabel('Time [ms]');
        title(['3. Final Kinematic Forces: ' title_text], 'Interpreter', 'none');
        legend([h1, h2], {'F_c (Tangential)', 'F_{cN} (Normal)'}, 'Location', 'northeast', 'Box', 'off');
        xlim([0 duration_ms]);
    else
        text(0.5, 0.5, 'Kinematic Data Missing', 'HorizontalAlignment', 'center');
    end
end

% --- Helpers ---
function apply_style(v)
    % Standardizes grid and box for the current subplot
    grid on; box on;
    set(gca, 'LineWidth', v.axis_line_width, 'TickDir', 'out'); % Pode parametrizar esse 1.0 no config se quiser (ex: v.axis_width)
end

function plot_shaded_std(x, y_mean, y_std, color_char, v)
    x_fill = [x, fliplr(x)];
    y_fill = [y_mean + y_std, fliplr(y_mean - y_std)];
    y_fill(isnan(y_fill)) = 0; 
    
    % Shadow
    fill(x_fill, y_fill, color_char, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    hold on;
    % Main Line
    plot(x, y_mean, 'Color', color_char, 'LineWidth', v.line_width_thick);
end