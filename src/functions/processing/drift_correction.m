function [corrected, trend_line] = drift_correction(data, fs, win1, win2)
    % ROBUST_DRIFT_CORRECTION Remove drift usando duas janelas de tempo seguras.
    
    % Converte tempo (segundos) para índices (amostras)
    idx1 = max(1, round(win1 * fs));
    idx2 = min(length(data), round(win2 * fs));
    
    % Calcula a média da força nessas regiões seguras
    val1 = mean(data(idx1(1):idx1(2)));
    val2 = mean(data(idx2(1):idx2(2)));
    
    % Acha o "centro" (em amostras) de cada região
    center1 = mean(idx1);
    center2 = mean(idx2);
    
    % Equação da Reta (y = mx + b)
    m = (val2 - val1) / (center2 - center1); % Inclinação
    b = val1 - (m * center1);                % Offset
    
    % Cria a linha de tendência para o arquivo todo
    idx_vec = 1:length(data);
    if iscolumn(data), idx_vec = idx_vec'; end % Garante dimensão correta
    
    trend_line = m * idx_vec + b;
    
    % Subtrai a tendência
    corrected = data - trend_line;
end