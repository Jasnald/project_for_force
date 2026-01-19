function theta_s = calc_theta(ae, D)
    % Calcula o angulo de engajamento fisico (em graus)
    % ae: profundidade radial de corte (mm)
    % D:  diametro da ferramenta (mm)
    
    % Evita numeros complexos se ae > D
    if ae >= D
        theta_s = 180; 
    else
        % Formula geometrica padrao
        rad = acos(1 - (2 * ae) / D);
        theta0_deg = rad * (180 / pi);
        theta_s = 90 - theta0_deg;
    end
end