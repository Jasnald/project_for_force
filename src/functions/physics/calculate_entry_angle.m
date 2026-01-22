function theta_s = calculate_entry_angle(ae, D)
    arguments
        ae (1,1) double {mustBeNonnegative} % Profundidade radial
        D  (1,1) double {mustBePositive}    % Diâmetro da ferramenta
    end
    
    if ae >= D
        theta_s = 180; 
    else
        % Formula geometrica padrao
        rad = acos(1 - (2 * ae) / D);
        theta0_deg = rad * (180 / pi);
        theta_s = 90 - theta0_deg;
    end
end