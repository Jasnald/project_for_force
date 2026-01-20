function theta_t = compute_angular_position(results, rpm_t)
% COMPUTE_ANGULAR_POSITION Integra RPM(t) para obter posição angular

    fs = results.fs;
    t  = (0:length(rpm_t)-1)' / fs;

    w_t = 2*pi * rpm_t / 60;   % [rad/s]
    theta_t = cumtrapz(t, w_t);

    % Opcional: manter theta limitado
    theta_t = mod(theta_t, 2*pi);
end
