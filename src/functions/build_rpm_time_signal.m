function rpm_t = build_rpm_time_signal(results, N)
% BUILD_RPM_TIME_SIGNAL Cria RPM(t) em degraus ao longo do sinal inteiro

    rpm_t = nan(N,1);

    for i = 1:size(results.cut_indices,1)
        idx_start = results.cut_indices(i,1);
        idx_end   = results.cut_indices(i,2);

        if idx_end > N
            continue
        end

        rpm_i = results.rpm_all(i);
        if isnan(rpm_i)
            rpm_i = results.rpm_mean;
        end

        rpm_t(idx_start:idx_end) = rpm_i;
    end

    % Preenche possíveis buracos com último valor válido
    rpm_t = fillmissing(rpm_t,'previous');
end
