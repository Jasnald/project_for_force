function visualize_results(t_steady, fx_steady, cut_indices, results, filename)
    % VISUALIZE_RESULTS Generates the standard force analysis panel.
    
    % --- TEXT CORRECTION (SHIELDED) ---
    % Converts any text input (String or Char) to a simple Char vector
    % This avoids the error "Argument must be a text scalar"
    title_text = char(filename); 
    window_name = sprintf('Report: %s', title_text);

    % Create the figure
    figure('Name', window_name, 'Color', 'w', 'Position', [100 100 1000 600]);
    
    %% 1. Steady State Signal with Detections
    subplot(2,2,1:2);
    plot(t_steady, fx_steady, 'Color', [0.8 0.8 0.8], 'DisplayName', 'Raw Signal'); hold on;
    
    % Plot points
    starts = cut_indices(:,1);
    ends   = cut_indices(:,2);
    
    % Index validation to avoid crash if the vector is short
    valid_s = starts <= length(fx_steady);
    valid_e = ends   <= length(fx_steady);
    
    plot(t_steady(starts(valid_s)), fx_steady(starts(valid_s)), 'g.', 'MarkerSize', 12, 'DisplayName', 'Start');
    plot(t_steady(ends(valid_e)),   fx_steady(ends(valid_e)),   'r.', 'MarkerSize', 12, 'DisplayName', 'End');
    
    title(sprintf('Cut Detection (%d Impacts)', size(cut_indices,1)));
    ylabel('Force X [N]'); xlabel('Time [s]');
    legend('Location', 'best'); grid on; axis tight;
    
    %% 2. Mean Profile
    subplot(2,2,3);
    
    x_axis = results.avg_profile.percent_axis;
    y_mean = results.avg_profile.x_mean;
    y_std  = results.avg_profile.x_std;
    
    % Shadow
    x_fill = [x_axis, fliplr(x_axis)];
    y_fill = [y_mean + y_std, fliplr(y_mean - y_std)];
    y_fill(isnan(y_fill)) = 0; % Protection against NaNs
    
    fill(x_fill, y_fill, 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Std Dev');
    hold on;
    plot(x_axis, y_mean, 'b', 'LineWidth', 2, 'DisplayName', 'Mean Profile');
    
    title('Mean Tooth Profile (Fx)');
    xlabel('% of Cycle'); ylabel('Force [N]'); 
    grid on; legend;
    
    %% 3. RPM
    subplot(2,2,4);
    plot(results.rpm_all, 'k.-');
    
    % Ensures the line label is also char
    lbl_str = sprintf('Mean: %.0f RPM', results.rpm_mean);
    yline(results.rpm_mean, 'r--', char(lbl_str), 'LabelHorizontalAlignment', 'left');
    
    title('RPM Calculated per Tooth');
    xlabel('Tooth Index'); ylabel('RPM');
    grid on; axis tight;
end