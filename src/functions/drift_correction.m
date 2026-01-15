% DRIFT_CORRECTION Removes linear drift from signal based on start/end points.
% This is the translated version of the legacy 'KSS_drift_correction.m'.

function corrected = drift_correction(data, int_start, int_end)
    % Determine start and end points for correction
    x_start = max(int_start - 750, 1);           % Start point before int_start
    x_end = min(int_end + 450, length(data));    % End point after int_end
    
    % Calculate the mean of data in regions before and after the interval
    y_start = movmean(data(x_start), 500);
    y_end = movmean(data(x_end), 500);
    
    % Calculate slope (m) and y-intercept (b) of the linear correction
    x_values = [x_start, x_end];  % x-values of both points
    y_values = [y_start, y_end];  % y-values of both points
    
    % Linear regression: m is slope, b is y-intercept
    p = polyfit(x_values, y_values, 1);  % polyfit returns [m, b]
    
    m = p(1);  % Slope
    b = p(2);  % Y-intercept
    
    % Create a line with the same length as data, modeling the drift
    correction_line = m * (1:length(data)) + b;
    
    % Subtract drift line from data to perform correction
    corrected = data - correction_line;
end