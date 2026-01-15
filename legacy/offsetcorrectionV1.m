% Offset-Korrektur
function [corrected_data] = offsetcorrectionV1(data, int_start)
    corrected_data = data - mean(data(int_start+300:int_start+600));
end