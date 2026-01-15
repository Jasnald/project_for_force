function [win_start, win_end] = get_air_windows_auto(signal, fs)
    % GET_AIR_WINDOWS_AUTO Detecta zonas de "ar" baseada na vibração (ignora drift).
    
    %% 1. Mapa de Vibração (Blindado contra Drift)
    % Usamos 'diff' para pegar apenas a variação rápida (High Pass implícito)
    % O drift é lento, então a derivada dele é quase zero.
    d_sig = [0; diff(signal)]; 
    
    % Suaviza a energia da vibração para criar um envelope
    % Janela de 0.5s para fundir os dentes num bloco só
    vibration_energy = smoothdata(abs(d_sig), 'gaussian', fs*0.5);
    
    %% 2. Limiar Adaptativo
    % O ruído de fundo (máquina ligada mas sem cortar) tem vibração baixa.
    % O corte tem vibração alta.
    
    % Pega o nível de base (ruído) e o pico máximo
    base_noise = median(vibration_energy);
    peak_vib   = max(vibration_energy);
    
    % Trigger: Tudo que tiver 10% da vibração máxima (acima do chão) é Corte
    thresh = base_noise + (peak_vib - base_noise) * 0.10;
    
    is_cutting = vibration_energy > thresh;
    
    %% 3. Validar Detecção
    idx_first = find(is_cutting, 1, 'first');
    idx_last  = find(is_cutting, 1, 'last');
    
    % Proteção: Se não achar nada (sinal liso demais), avisa
    if isempty(idx_first)
        warning('Nenhuma vibração de corte detectada. Usando pontas do arquivo como fallback.');
    end
    
    %% 4. Margens de Segurança
    t = (0:length(signal)-1) / fs;
    t_cut_start = t(idx_first);
    t_cut_end   = t(idx_last);
    
    buffer_cut  = 2.0; % 2s longe do corte
    buffer_file = 1.0; % 1s longe do início/fim do arquivo
    
    % Janela 1 (Pré-Corte)
    w1_start = buffer_file;
    w1_end   = max(w1_start + 0.5, t_cut_start - buffer_cut); % Garante pelo menos 0.5s de janela
    
    % Janela 2 (Pós-Corte)
    w2_start = t_cut_end + buffer_cut;
    w2_end   = max(w2_start + 0.5, t(end) - buffer_file);
    
    % Proteção final: Se as janelas ficaram grudadas ou invertidas (arquivo curto demais)
    if w1_end > t_cut_start, w1_end = max(buffer_file, t_cut_start - 0.1); end
    if w2_start > t(end),    w2_start = t(end) - 1.0; w2_end = t(end) - 0.1; end

    win_start = [w1_start, w1_end];
    win_end   = [w2_start, w2_end];
    
    fprintf('Auto-Detect (Vibração): Corte de %.1fs a %.1fs\n', t_cut_start, t_cut_end);
end