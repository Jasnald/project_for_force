% Offset-Korrektur
function [corrected_data] = offsetcorrection(data, int_start)
    corrected_data = data - mean(data(round(int_start/2):round(4*int_start/5)));
end