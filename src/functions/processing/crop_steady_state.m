function [steady_data, steady_time] = crop_steady_state(data, time, cut_interval, trim_pct)
    % CROP_STEADY_STATE Crops signal to stable region.
    % trim_pct: Optional. Default loaded from config if omitted.

    arguments
        data         (:,1) double
        time         (:,1) double
        cut_interval (1,2) double {mustBeNumeric}
        % Validação individual básica: deve ser positivo e menor que 1
        trim_pct     (1,2) double {mustBeNonnegative, mustBeLessThan(trim_pct, 1)} = config_processing().stats.default_trim
    end

    % --- Validação de Tamanho (Vetores) ---
    if ~isequal(size(data), size(time))
        error('Erro de Dimensão: Data (%dx%d) e Time (%dx%d) incompatíveis.', size(data), size(time));
    end

    % --- Validação da SOMA (Regra do Usuário) ---
    % Garante que sobra sinal (Start% + End% < 100%)
    if sum(trim_pct) >= 1
        error('Configuração Inválida: A soma dos cortes (%.1f%% + %.1f%% = %.1f%%) deve ser menor que 100%%.', ...
              trim_pct(1)*100, trim_pct(2)*100, sum(trim_pct)*100);
    end
    
    t_start = cut_interval(1);
    t_end   = cut_interval(2);
    duration = t_end - t_start;
    
    new_t1 = t_start + (duration * trim_pct(1));
    new_t2 = t_end   - (duration * trim_pct(2));
    
    idx_start = find(time >= new_t1, 1, 'first');
    idx_end   = find(time <= new_t2, 1, 'last');
    
    steady_data = data(idx_start:idx_end);
    steady_time = time(idx_start:idx_end);
    
    fprintf('Steady State: %.2fs to %.2fs (Removed %.0f%% Start, %.0f%% End)\n', ...
            new_t1, new_t2, trim_pct(1)*100, trim_pct(2)*100);
end