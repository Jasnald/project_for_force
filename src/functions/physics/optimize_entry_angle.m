function best_theta = optimize_entry_angle(results)
    % Testa ângulos de 0 a 360 graus para achar o melhor ajuste
    search_angles = 0:1:360; 
    best_score = -inf;
    best_theta = 0;
    
    % Pega o perfil médio de força para ser mais rápido
    Fx_mean = mean(results.stack_x, 1, 'omitnan');
    Fy_mean = mean(results.stack_y, 1, 'omitnan');
    duration = mean(results.engagement_time_all);
    rpm = results.rpm_mean;
    
    t = linspace(0, duration, length(Fx_mean));
    omega = (2 * pi * rpm) / 60;
    
    for theta_guess = search_angles
        th_rad = deg2rad(theta_guess);
        theta_vec = th_rad + (omega * t);
        
        % Calcula Fcn (Normal) hipotética
        % Nota: Fcn = Fx*cos(th) + Fy*sin(th)
        Fcn_temp = Fx_mean .* cos(theta_vec) + Fy_mean .* sin(theta_vec);
        
        % Critério: Queremos maximizar a área POSITIVA e minimizar a negativa
        % Score = Soma(Fcn) - Penalidade(Fcn_negativa * 10)
        score = sum(Fcn_temp) - 10 * sum(abs(Fcn_temp(Fcn_temp < 0)));
        
        if score > best_score
            best_score = score;
            best_theta = theta_guess;
        end
    end
    
    fprintf('Auto-Detected Theta Start: %.1f degrees\n', best_theta);
end