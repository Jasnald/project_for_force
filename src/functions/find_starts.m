function [cut_indices] = find_starts(force_signal, fs)
% FIND_CUTS_BY_PEAKS Detecta cortes achando o topo da montanha primeiro.
    % 1. Acha os Picos (Centros dos cortes).
    % 2. Caminha para a esquerda (Start) e direita (End) até o sinal "achatatar" ou zerar.
    
    %% 1. Preparação (Suavização Leve)
    % Importante para o findpeaks não pegar ruído como pico
    % Janela de 5ms é segura para fresamento
    smooth_win = round(fs * 0.005); 
    sig_smooth = smoothdata(force_signal, 'gaussian', smooth_win);
    
    %% 2. Análise do Ruído (Noise Floor)
    % Precisamos saber o que é "Zero" (mesmo que tenha drift)
    sorted_sig = sort(sig_smooth);
    n_samples = length(sig_smooth);
    % Pega os 20% menores valores como referência de "chão"
    noise_region = sorted_sig(1 : round(n_samples * 0.20));
    noise_level = mean(noise_region) + 3*std(noise_region);
    
    %% 3. Achar os "Picos MESTRES"
    % A chave aqui é o MinPeakDistance. 
    % Ele impede que o formato "M" seja detectado como dois cortes.
    % Estimamos uma distância segura (ex: 20ms) ou calculamos dinamicamente.
    
    min_dist = fs * 0.020; % 20ms entre picos (ajustável se a rotação for altíssima)
    min_height = max(sig_smooth) * 0.2; % O pico tem que ter pelo menos 20% da força máxima global
    
    % Se o sinal for muito baixo (só ruído), min_height protege
    min_height = max(min_height, noise_level * 2);

    [pks, locs] = findpeaks(sig_smooth, ...
                            'MinPeakDistance', min_dist, ...
                            'MinPeakHeight', min_height);
                        
    %% 4. O "Escorregador" (Crawler)
    % Para cada pico, vamos expandir para a esquerda e direita
    
    starts = zeros(size(locs));
    ends   = zeros(size(locs));
    
    % Derivada para detectar quando o sinal "achata" (chegou no vale)
    dF = gradient(sig_smooth);
    
    for i = 1:length(locs)
        peak_idx = locs(i);
        peak_val = pks(i);
        
        % --- BUSCA PARA TRÁS (START) ---
        idx = peak_idx;
        % Continua voltando ENQUANTO:
        % 1. Não chegou no início do arquivo
        % 2. O sinal ainda é forte (> noise_level ajustado localmente)
        % 3. O sinal não começou a subir de novo (o que indicaria um pico anterior vizinho)
        
        local_floor = noise_level; 
        
        % Critério de parada:
        % Parar se cair abaixo do ruído OU se encontrarmos um vale (derivada vira negativa/zero)
        % Adicionamos uma tolerância: só paramos no vale se ele for bem baixo (< 20% do pico)
        
        while idx > 1
            curr_val = sig_smooth(idx);
            
            % 1. Chegamos no ruído absoluto?
            if curr_val < local_floor
                break; 
            end
            
            % 2. Chegamos num vale entre dois picos? (Sinal começou a subir para a esquerda)
            % Só conta se já descemos bastante (abaixo de 50% do pico) para ignorar o "M"
            if curr_val < (peak_val * 0.5) && sig_smooth(idx-1) > curr_val
                break;
            end
            
            idx = idx - 1;
        end
        starts(i) = idx;
        
        % --- BUSCA PARA FRENTE (END) ---
        idx = peak_idx;
        while idx < n_samples
            curr_val = sig_smooth(idx);
            
            if curr_val < local_floor
                break;
            end
            
            % Chegamos num vale à direita?
            if curr_val < (peak_val * 0.5) && sig_smooth(idx+1) > curr_val
                break;
            end
            
            idx = idx + 1;
        end
        ends(i) = idx;
    end
    
    %% 5. Fusão de Sobreposições
    % Se a busca de um pico invadiu o outro (muito próximos), unimos eles.
    if isempty(starts)
        cut_indices = [];
        return;
    end
    
    final_intervals = [starts(1), ends(1)];
    
    for i = 2:length(starts)
        prev_end = final_intervals(end, 2);
        curr_start = starts(i);
        
        if curr_start <= prev_end + round(fs*0.005) % Se começa antes do anterior terminar (ou quase)
            % Fundir: Estende o anterior até o fim deste
            final_intervals(end, 2) = max(prev_end, ends(i));
        else
            % Novo corte
            final_intervals = [final_intervals; curr_start, ends(i)];
        end
    end
    
    cut_indices = final_intervals;
end