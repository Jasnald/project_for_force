%% Debug Theta: Por que 123 e nao 78?
% Copie e cole isso num script temporario ou no command window apos rodar a analise

% 1. Configurações
expected_theta = 78;   % O valor que voce sabe que e verdade
detected_theta = 123;  % O valor que o algoritmo achou
rotation_dir   = -1;    % <--- TENTE MUDAR ISSO PARA -1 SE FOR GIRA HORARIO (CW)

% 2. Recalcula a geometria (igual ao auto_find_theta)
Fx = results.avg_profile.x_mean;
Fy = results.avg_profile.y_mean;
rpm = results.rpm_mean;
duration = results.engagement_time_mean;

omega = (2 * pi * rpm) / 60; 
swept_angle = min(omega * duration, 2*pi);
num_points = length(Fx);
theta_relative = linspace(0, swept_angle, num_points);

% 3. Calcula Fc para os dois casos
% Caso A: Detectado (123)
vec_A = deg2rad(detected_theta) + theta_relative;
Fc_A  = rotation_dir * (-Fx .* sin(vec_A) + Fy .* cos(vec_A));

% Caso B: Esperado (78)
vec_B = deg2rad(expected_theta) + theta_relative;
Fc_B  = rotation_dir * (-Fx .* sin(vec_B) + Fy .* cos(vec_B));

% 4. Plota a comparação
figure('Name', 'Debug Theta', 'Color', 'w');

subplot(2,1,1);
plot(0:360, get_score_curve(Fx, Fy, theta_relative, rotation_dir), 'k');
xline(detected_theta, 'r--', 'Detectado (123)');
xline(expected_theta, 'b--', 'Esperado (78)');
title('Landscape de Otimização (Onde o Score é maior?)');
xlabel('Ângulo de Entrada [graus]'); ylabel('Score (Positividade)');
grid on; axis tight;

subplot(2,1,2);
plot(Fc_A, 'r', 'LineWidth', 1.5, 'DisplayName', sprintf('Em %.0f deg (Detectado)', detected_theta)); hold on;
plot(Fc_B, 'b', 'LineWidth', 1.5, 'DisplayName', sprintf('Em %.0f deg (Esperado)', expected_theta));
yline(0, 'k-');
title('Perfil de Força Tangencial (Fc) Resultante');
legend; grid on; axis tight;
ylabel('Força [N] (Deve ser > 0)');

% --- Função Auxiliar Local ---
function scores = get_score_curve(Fx, Fy, theta_rel, r_dir)
    scores = zeros(1, 361);
    for deg = 0:360
        th = deg2rad(deg) + theta_rel;
        Fc = r_dir * (-Fx .* sin(th) + Fy .* cos(th));
        % Mesma metrica do algoritmo
        pos = sum(Fc(Fc>0));
        neg = sum(abs(Fc(Fc<0)));
        scores(deg+1) = pos - (neg * 10);
    end
end