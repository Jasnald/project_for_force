function theta_t = build_theta_from_rpm(results, rpm_t)
% BUILD_THETA_FROM_RPM Integra RPM(t) para obter posição angular

    fs = results.fs;
    t  = (0:length(rpm_t)-1)' / fs;

    w_t = 2*pi * rpm_t / 60;   % [rad/s]
    theta_t = cumtrapz(t, w_t);

    % Opcional: manter theta limitado
    theta_t = mod(theta_t, 2*pi);
end
