function [cut_indices] = find_starts(force_signal, fs)
% FIND_STARTS Detecta cortes com critério assimétrico.
% START: Rigoroso (10% do pico) para ignorar pré-vibração.
% END:   Paciente (Nível de ruído) para pegar a cauda inteira.

    %% 1. Preparação
    % Suavização leve para limpeza elétrica
    smooth_win = round(fs * 0.002); 
    sig_smooth = smoothdata(force_signal, 'gaussian', smooth_win);
    n_samples = length(sig_smooth);
    
    %% 2. Definir o "Chão" (Zero Real)
    sorted_sig = sort(sig_smooth);
    noise_region = sorted_sig(1 : round(n_samples * 0.20));
    noise_floor = mean(noise_region) + 3*std(noise_region);
    
    %% 3. Achar os Picos Mestres
    min_dist = fs * 0.015; 
    min_height = max(sig_smooth) * 0.15; 
    min_height = max(min_height, noise_floor * 2);

    [pks, locs] = findpeaks(sig_smooth, ...
                            'MinPeakDistance', min_dist, ...
                            'MinPeakHeight', min_height);
                        
    %% 4. O Crawler Assimétrico
    starts = zeros(size(locs));
    ends   = zeros(size(locs));
    
    % CONFIGURAÇÃO
    start_thresh_pct = 0.10; % Start: Corta em 10% do pico (Rigoroso)
    % End: Não usa porcentagem, usa o noise_floor direto (Paciente)
    
    for i = 1:length(locs)
        peak_idx = locs(i);
        peak_val = pks(i);
        
        % --- BUSCA PARA TRÁS (START) ---
        % Critério: "Só pare se cair abaixo de 10% da força máxima deste dente"
        limit_start = max(noise_floor, peak_val * start_thresh_pct);
        
        idx = peak_idx;
        while idx > 1
            if sig_smooth(idx) < limit_start
                break; 
            end
            idx = idx - 1;
        end
        starts(i) = idx;
        
        % --- BUSCA PARA FRENTE (END) ---
        % Critério: "Continue descendo até bater no chão (ruído)"
        % Usamos noise_floor * 1.2 apenas para não ficar preso em micro flutuações
        limit_end = noise_floor * 1.2; 
        
        idx = peak_idx;
        while idx < n_samples
            % Se cair abaixo do ruído, acabou.
            if sig_smooth(idx) < limit_end
                break;
            end
            
            % SEGURANÇA CONTRA LOOP INFINITO:
            % Se já andou muito (ex: 2x a distância mínima) e o sinal 
            % começou a subir forte de novo (outro dente), PARE.
            if (idx - peak_idx) > (min_dist * 1.5) && sig_smooth(idx) > sig_smooth(idx-1)
                 break; 
            end
            
            idx = idx + 1;
        end
        ends(i) = idx;
    end
    
    %% 5. Fusão de Cortes Próximos
    if isempty(starts)
        cut_indices = [];
        return;
    end
    
    final_intervals = [starts(1), ends(1)];
    for i = 2:length(starts)
        prev_end = final_intervals(end, 2);
        curr_start = starts(i);
        
        % Se o novo corte começa antes (ou quase junto) do anterior terminar
        if curr_start <= prev_end + round(fs*0.001)
            final_intervals(end, 2) = max(prev_end, ends(i));
        else
            final_intervals = [final_intervals; curr_start, ends(i)];
        end
    end
    
    cut_indices = final_intervals;
end