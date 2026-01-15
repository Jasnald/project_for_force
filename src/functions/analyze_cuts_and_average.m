function [results] = analyze_cuts_and_average(force_x, force_y, cut_indices, fs, num_teeth)
    % ANALYZE_CUTS_AND_AVERAGE Processa os cortes isolados.
    % Realiza a reamostragem para calcular o perfil médio e calcula o RPM.
    
    num_cuts = size(cut_indices, 1);
    
    % --- Configuração da Reamostragem ---
    % Normaliza todos os cortes para terem exatamente 1000 pontos.
    % Isso permite tirar a média ponto a ponto, independente da velocidade.
    norm_len = 1000; 
    norm_time = linspace(0, 100, norm_len); % Eixo X de 0 a 100%
    
    % Matrizes para guardar todos os cortes normalizados
    stack_x = zeros(num_cuts, norm_len);
    stack_y = zeros(num_cuts, norm_len);
    
    % Vetores para métricas escalares
    durations = zeros(num_cuts, 1);
    rpms = zeros(num_cuts, 1);
    
    %% Loop de Processamento Individual
    for i = 1:num_cuts
        idx_start = cut_indices(i, 1);
        idx_end   = cut_indices(i, 2);
        
        % 1. Extração
        seg_x = force_x(idx_start:idx_end);
        seg_y = force_y(idx_start:idx_end);
        
        % 2. Métricas de Tempo (Objetivo 3)
        % Tempo de engajamento deste dente específico
        durations(i) = length(seg_x) / fs; 
        
        % Cálculo do RPM Instantâneo
        % Baseado na distância até o INÍCIO do próximo dente
        if i < num_cuts
            next_start = cut_indices(i+1, 1);
            samples_diff = next_start - idx_start;
            time_diff = samples_diff / fs;
            
            % RPM = (1 rotação / periodo_dente * num_dentes) * 60s
            % Periodo_dente = time_diff
            rpms(i) = (1 / (time_diff * num_teeth)) * 60;
        else
            rpms(i) = NaN; % Não dá pra calcular RPM do último corte
        end
        
        % 3. Reamostragem (Interpolação Linear)
        % Cria um eixo de tempo original para este corte específico
        original_points = 1:length(seg_x);
        % Cria o eixo alvo (esticado ou encolhido para caber em norm_len)
        target_points = linspace(1, length(seg_x), norm_len);
        
        stack_x(i, :) = interp1(original_points, seg_x, target_points, 'linear');
        stack_y(i, :) = interp1(original_points, seg_y, target_points, 'linear');
    end
    
    %% Cálculo das Médias (Objetivo 2)
    % 'omitnan' garante que se houver falha em um, não quebra tudo
    avg_profile.x_mean = mean(stack_x, 1, 'omitnan');
    avg_profile.y_mean = mean(stack_y, 1, 'omitnan');
    
    % Desvio padrão (útil para ver se o processo está estável)
    avg_profile.x_std = std(stack_x, 0, 1, 'omitnan');
    avg_profile.y_std = std(stack_y, 0, 1, 'omitnan');
    
    avg_profile.percent_axis = norm_time;
    
    %% Empacotar Resultados
    results.avg_profile = avg_profile;
    results.rpm_mean = mean(rpms, 'omitnan');
    results.rpm_all = rpms;
    results.engagement_time_mean = mean(durations);
    results.engagement_time_all = durations;
    
    % Guarda os dados "empilhados" caso queira plotar a nuvem de dispersão
    results.stack_x = stack_x;
    results.stack_y = stack_y;
end