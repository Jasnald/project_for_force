function visualize_results(t_steady, fx_steady, cut_indices, results, filename)
    % VISUALIZE_RESULTS Generates a consistent, publication-ready dashboard.
    
    title_text = char(filename); 
    
    % Setup Figure (White background, standard size)
    fig = figure('Name', ['Dashboard: ' title_text], 'Color', 'w', 'Position', [50 50 1000 900]);
    
    %% 1. Raw Signal (Top)
    subplot(3,2,1:2);
    plot_raw_signal(t_steady, fx_steady, cut_indices);
    apply_style(); % Apply standard styling
    
    %% 2. Diagnostics (Middle)
    % 2.1 Sensor Profile
    subplot(3,2,3);
    plot_sensor_profile(results);
    apply_style();
    
    % 2.2 RPM
    subplot(3,2,4);
    plot_rpm_stability(results);
    apply_style();

    %% 3. Kinematic Forces (Bottom)
    subplot(3,2,5:6);
    plot_kinematic_forces(results, title_text);
    apply_style();
    
    % Final Global Adjustments
    set(findall(fig, '-property', 'FontSize'), 'FontSize', 10, 'FontName', 'Arial');
end

%% ============================================================
%%                  LOCAL PLOTTING FUNCTIONS
%% ============================================================

function plot_raw_signal(t, signal, indices)
    % Raw signal: Thinner grey line to show background texture
    plot(t, signal, 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5, 'DisplayName', 'Raw Signal'); 
    hold on;
    
    % Valid indices check
    starts = indices(:,1); ends = indices(:,2);
    valid_s = starts <= length(signal); valid_e = ends <= length(signal);
    
    % Markers: Bold colors
    plot(t(starts(valid_s)), signal(starts(valid_s)), '.', 'Color', [0 0.8 0], 'MarkerSize', 12, 'DisplayName', 'Start');
    plot(t(ends(valid_e)),   signal(ends(valid_e)),   '.', 'Color', [0.8 0 0], 'MarkerSize', 12, 'DisplayName', 'End');
    
    title(sprintf('1. Detection Overview (%d Cuts)', size(indices,1)));
    ylabel('Force Fx [N]'); xlabel('Time [s]');
    legend('Location', 'northeast', 'Box', 'off'); axis tight;
end

function plot_sensor_profile(results)
    % Sensor Profile: Black (Neutral)
    plot_shaded_std(results.avg_profile.percent_axis, ...
                    results.avg_profile.x_mean, ...
                    results.avg_profile.x_std, 'k'); % 'k' for Black
                    
    title('2.1. Mean Sensor Profile (Fx)');
    xlabel('% of Engagement'); ylabel('Force [N]'); 
end

function plot_rpm_stability(results)
    % RPM: Dark Grey, distinctive markers
    plot(results.rpm_all, 'o-', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.0, ...
         'MarkerSize', 4, 'MarkerFaceColor', [0.5 0.5 0.5]);
    
    yline(results.rpm_mean, '--', sprintf('Mean: %.0f', results.rpm_mean), ...
          'Color', [0.8 0 0], 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    
    title('2.2. RPM Stability Check'); 
    xlabel('Tooth Index'); ylabel('RPM'); 
    xlim([1, max(2, length(results.rpm_all))]);
end

function plot_kinematic_forces(results, title_text)
    if isfield(results.avg_profile, 'fc_mean') && ~isempty(results.avg_profile.fc_mean)
        
        num_pts = length(results.avg_profile.fc_mean);
        duration_ms = results.engagement_time_mean * 1000; 
        time_axis = linspace(0, duration_ms, num_pts);
        
        % Plot Shadows
        plot_shaded_std(time_axis, results.avg_profile.fc_mean, results.avg_profile.fc_std, 'r');
        plot_shaded_std(time_axis, results.avg_profile.fcn_mean, results.avg_profile.fcn_std, 'b');
        
        % Plot Lines (Thicker)
        h1 = plot(time_axis, results.avg_profile.fc_mean, 'r', 'LineWidth', 1.5);
        h2 = plot(time_axis, results.avg_profile.fcn_mean, 'b', 'LineWidth', 1.5);
        
        ylabel('Force [N]'); xlabel('Time [ms]');
        title(['3. Final Kinematic Forces: ' title_text], 'Interpreter', 'none');
        legend([h1, h2], {'F_c (Tangential)', 'F_{cN} (Normal)'}, 'Location', 'northeast', 'Box', 'off');
        xlim([0 duration_ms]);
    else
        text(0.5, 0.5, 'Kinematic Data Missing', 'HorizontalAlignment', 'center');
    end
end

% --- Helpers ---
function apply_style()
    % Standardizes grid and box for the current subplot
    grid on; box on;
    set(gca, 'LineWidth', 1.0, 'TickDir', 'out');
end

function plot_shaded_std(x, y_mean, y_std, color_char)
    x_fill = [x, fliplr(x)];
    y_fill = [y_mean + y_std, fliplr(y_mean - y_std)];
    y_fill(isnan(y_fill)) = 0; 
    
    % Shadow
    fill(x_fill, y_fill, color_char, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    hold on;
    % Main Line
    plot(x, y_mean, color_char, 'LineWidth', 1.5);
end