function corrected = drift_correction(data, int_start, int_end)
    % DRIFT_CORRECTION Removes linear drift from signal based on start/end points.
    
    % Determine start and end points for correction
    x_start = max(int_start - 750, 1);
    x_end = min(int_end + 450, length(data));
    
    % Calculate the mean of data in regions before and after the interval
    y_start = movmean(data(x_start), 500);
    y_end = movmean(data(x_end), 500);
    
    % Linear regression: m is slope, b is y-intercept
    x_values = [x_start, x_end];
    y_values = [y_start, y_end];
    
    p = polyfit(x_values, y_values, 1);
    m = p(1);
    b = p(2);
    
    % --- CORREÇÃO AQUI ---
    % Cria o vetor de índices
    idx_vec = (1:length(data));
    
    % Se 'data' for coluna, transpoe o índice para coluna também
    if iscolumn(data)
        idx_vec = idx_vec'; 
    end
    
    correction_line = m * idx_vec + b;
    % ---------------------
    
    corrected = data - correction_line;
end