function [results] = calculate_cutting_forces_t(results, theta_start_deg, rotation_dir)
    % CALCULATE_CUTTING_FORCES Transforma Fx, Fy -> Fc, Fcn usando matriz de rotação temporal.
    %
    % Matriz aplicada (dependente do tempo t):
    % [ Fcn(t) ]   [  cos(w*t + phi)   sin(w*t + phi) ]   [ Fx(t) ]
    % [ Fc(t)  ] = [ -sin(w*t + phi)   cos(w*t + phi) ] * [ Fy(t) ]
    %
    % Inputs:
    %   results: Struct com dados normalizados e RPM
    %   theta_start_deg: Ângulo inicial (phi) em graus (define o ponto zero no tempo t=0)
    %   rotation_dir: 1 (Anti-horário) ou -1 (Horário). Afeta o sinal de Fc.

    %% 1. Configuração Inicial
    if nargin < 2 || isempty(theta_start_deg), theta_start_deg = 0; end
    if nargin < 3 || isempty(rotation_dir), rotation_dir = 1; end

    % Validação básica
    required = {'stack_x', 'stack_y', 'rpm_all', 'engagement_time_all'};
    for i = 1:length(required)
        if ~isfield(results, required{i})
            error('Campo obrigatório faltando: %s', required{i});
        end
    end
    
    %% 2. Preparação das Variáveis
    [num_cuts, num_samples] = size(results.stack_x);
    stack_fc = zeros(num_cuts, num_samples);
    stack_fcn = zeros(num_cuts, num_samples);
    
    % Converte o ângulo inicial (offset) para radianos (phi)
    phi = deg2rad(theta_start_deg);

    %% 3. Processamento Corte a Corte (Baseado no Tempo)
    for i = 1:num_cuts
        % A. Dados do Corte
        Fx = results.stack_x(i, :);
        Fy = results.stack_y(i, :);
        
        % B. Determinar Velocidade Angular (Omega)
        % Usa o RPM específico daquele corte para precisão máxima
        rpm = get_valid_rpm(results, i);
        w = (2 * pi * rpm) / 60;  % [rad/s]
        
        % C. Construir Vetor de Tempo (t)
        % Reconstrói o tempo real baseando-se na duração medida do corte
        duration = results.engagement_time_all(i);
        t = linspace(0, duration, num_samples);
        
        % D. Calcular o Ângulo Instantâneo (Theta em função de t)
        theta_t = phi + (w .* t);
        
        % E. Aplicar a Matriz de Rotação
        % Linha 1: Força Normal (Fcn) -> [cos  sin]
        Fcn_inst = Fx .* cos(theta_t) + Fy .* sin(theta_t);
        
        % Linha 2: Força de Corte (Fc) -> [-sin cos]
        % (Multiplicamos por rotation_dir para ajustar CW/CCW se necessário)
        Fc_inst  = rotation_dir * (-Fx .* sin(theta_t) + Fy .* cos(theta_t));
        
        % Armazenar
        stack_fc(i, :) = Fc_inst;
        stack_fcn(i, :) = Fcn_inst;
    end
    
    %% 4. Salvar Resultados e Médias
    results.stack_fc = stack_fc;
    results.stack_fcn = stack_fcn;
    
    % Calcula perfil médio
    results.avg_profile.fc_mean  = mean(stack_fc, 1, 'omitnan');
    results.avg_profile.fcn_mean = mean(stack_fcn, 1, 'omitnan');
    
    % Calcula desvio padrão
    results.avg_profile.fc_std   = std(stack_fc, 0, 1, 'omitnan');
    results.avg_profile.fcn_std  = std(stack_fcn, 0, 1, 'omitnan');
end

%% Helper: Obter RPM seguro
function rpm = get_valid_rpm(results, idx)
    rpm = results.rpm_all(idx);
    if isnan(rpm)
        valid = results.rpm_all(~isnan(results.rpm_all));
        if isempty(valid), error('Sem dados de RPM válidos.'); end
        rpm = mean(valid);
    end
end