function [results] = calculate_cutting_forces(results, theta_start_deg)
    % CALCULATE_CUTTING_FORCES Transforma forças fixas (Fx, Fy) para o referencial rotativo (Fc, Fcn).
    %
    % Inputs:
    %   results: Struct contendo 'stack_x', 'stack_y' e 'rpm_all' (normalizados)
    %   theta_start_deg: Ângulo de entrada [graus]. Ajustar até Fcn fazer sentido físico.
    %
    % Outputs:
    %   results: Struct atualizada com 'stack_fc' (Tangencial) e 'stack_fcn' (Normal/Radial)

    if nargin < 2
        theta_start_deg = 0; % Padrão 0 se não for fornecido
    end

    num_cuts = size(results.stack_x, 1);
    num_samples = size(results.stack_x, 2);
    
    % Inicializa matrizes
    stack_fc = zeros(num_cuts, num_samples);
    stack_fcn = zeros(num_cuts, num_samples);
    
    % Converte ângulo inicial para radianos
    theta_start = deg2rad(theta_start_deg);

    %% Processar cada corte individualmente
    for i = 1:num_cuts
        % 1. Recuperar forças deste corte específico (Normalizado)
        Fx = results.stack_x(i, :);
        Fy = results.stack_y(i, :);
        
        % 2. Recuperar RPM deste corte
        rpm = results.rpm_all(i); 
        if isnan(rpm), rpm = results.rpm_mean; end
        
        % 3. Criar Vetor de Tempo Físico
        % ATENÇÃO: Como o stack_x está normalizado (ex: 1000 pontos), 
        % não usamos 'fs'. Usamos a duração real pré-calculada para distribuir o tempo.
        duration = results.engagement_time_all(i);
        t = linspace(0, duration, num_samples);
        
        % 4. Calcular Ângulo Instantâneo Theta(t)
        omega = (2 * pi * rpm) / 60; % Velocidade angular [rad/s]
        theta = theta_start + (omega * t);
        
        % 5. Matriz de Rotação 2D
        % Fcn (Normal) = Fx*cos(th) + Fy*sin(th)
        % Fc (Corte)   = -Fx*sin(th) + Fy*cos(th)
        % Nota: Sinais podem precisar de inversão dependendo do quadrante do sensor.
        
        Fcn_inst =  Fx .* cos(theta) + Fy .* sin(theta);
        Fc_inst  = -Fx .* sin(theta) + Fy .* cos(theta);
        
        stack_fc(i, :) = Fc_inst;
        stack_fcn(i, :) = Fcn_inst;
    end
    
    %% Guardar Resultados
    results.stack_fc = stack_fc;
    results.stack_fcn = stack_fcn;
    
    % Médias
    results.avg_profile.fc_mean  = mean(stack_fc, 1, 'omitnan');
    results.avg_profile.fcn_mean = mean(stack_fcn, 1, 'omitnan');
    
    % Desvio Padrão
    results.avg_profile.fc_std  = std(stack_fc, 0, 1, 'omitnan');
    results.avg_profile.fcn_std = std(stack_fcn, 0, 1, 'omitnan');

end