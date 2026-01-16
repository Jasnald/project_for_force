function [results] = calculate_cutting_forces(results, theta_start_deg, rotation_dir)
    % CALCULATE_CUTTING_FORCES Transforma Fx, Fy -> Fc, Fcn no referencial rotativo
    %
    % Inputs:
    %   results: Struct com stack_x, stack_y, rpm_all, engagement_time_all
    %   theta_start_deg: Ângulo de entrada [graus] (Opcional, padrão: 0)
    %   rotation_dir: 1 (CCW) ou -1 (CW) (Opcional, padrão: 1)

    %% 1. Tratamento de Inputs (Padrões)
    if nargin < 2 || isempty(theta_start_deg)
        theta_start_deg = 0;
    end
    
    if nargin < 3 || isempty(rotation_dir)
        rotation_dir = 1;
    end

    %% 2. Validação de Campos Necessários
    required = {'stack_x', 'stack_y', 'rpm_all', 'engagement_time_all'};
    for i = 1:length(required)
        if ~isfield(results, required{i})
            error('Campo obrigatório ausente na struct results: %s', required{i});
        end
    end
    
    %% 3. Inicialização
    [num_cuts, num_samples] = size(results.stack_x);
    stack_fc = zeros(num_cuts, num_samples);
    stack_fcn = zeros(num_cuts, num_samples);
    
    theta_start = deg2rad(theta_start_deg);

    %% 4. Processamento
    for i = 1:num_cuts
        Fx = results.stack_x(i, :);
        Fy = results.stack_y(i, :);
        
        % RPM Robusto (Usa helper local)
        rpm = get_valid_rpm(results, i);
        
        % Tempo Físico (Reconstruído a partir da duração do corte)
        duration = results.engagement_time_all(i);
        t = linspace(0, duration, num_samples);
        
        % Ângulo Instantâneo
        omega = (2 * pi * rpm) / 60;
        theta = theta_start + (omega * t);
        
        % Matriz de Rotação 2D
        % Fcn (Radial/Normal)
        Fcn_inst =  Fx .* cos(theta) + Fy .* sin(theta);
        
        % Fc (Tangencial/Corte) - Com direção configurável
        Fc_inst  = rotation_dir * (-Fx .* sin(theta) + Fy .* cos(theta));
        
        stack_fc(i, :) = Fc_inst;
        stack_fcn(i, :) = Fcn_inst;
    end
    
    %% 5. Salvar Resultados e Médias
    results.stack_fc = stack_fc;
    results.stack_fcn = stack_fcn;
    
    results.avg_profile.fc_mean  = mean(stack_fc, 1, 'omitnan');
    results.avg_profile.fcn_mean = mean(stack_fcn, 1, 'omitnan');
    results.avg_profile.fc_std   = std(stack_fc, 0, 1, 'omitnan');
    results.avg_profile.fcn_std  = std(stack_fcn, 0, 1, 'omitnan');
end

%% Helper Functions (Locais)

function rpm = get_valid_rpm(results, idx)
    % Tenta pegar o RPM específico do corte
    rpm = results.rpm_all(idx);
    
    % Se for NaN, tenta recuperar a média dos outros cortes válidos
    if isnan(rpm)
        valid_rpms = results.rpm_all(~isnan(results.rpm_all));
        if isempty(valid_rpms)
            % Se não houver NENHUM RPM válido, erro crítico
            error('Não há dados de RPM válidos para calcular omega no corte %d', idx);
        end
        rpm = mean(valid_rpms);
        % Opcional: warning apenas se quiser muito verboso
        % warning('Corte %d: RPM NaN, usando média (%.1f)', idx, rpm);
    end
end