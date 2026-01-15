function [cut_indices] = find_cut_indices(force_signal, fs)
    % FIND_CUT_INDICES Detecta "Ilhas de Atividade" na derivada.
    % Robusto contra: Vibração (oscilação no início), Drift (subida lenta) e Ruído.
    
    %% 1. Mapa de Energia (Aceleração da Força)
    % Suaviza levemente para não pegar ruído branco
    smooth_win = round(fs * 0.005); % 5ms
    sig_smooth = smoothdata(force_signal, 'gaussian', smooth_win);
    
    % Calcula a derivada. O abs() unifica subidas e descidas (vibração)
    % em uma única mancha de "atividade".
    dF = gradient(sig_smooth);
    energy = abs(dF);
    
    %% 2. Limiar Estatístico Robusto (Sem números mágicos fixos)
    % Usamos a Mediana e o MAD (Median Absolute Deviation).
    % Diferente da média/desvio padrão, o MAD ignora os cortes gigantes 
    % e calcula o ruído base real do sensor.
    
    bg_noise = median(energy);
    robust_sigma = mad(energy, 1); % Estimativa robusta do desvio padrão
    
    % Trigger: Tudo que for 5x mais agitado que o ruído de fundo é Evento.
    % Esse '5' é estatístico (5 Sigma), funciona pra qualquer sensor.
    trigger_level = bg_noise + 5 * robust_sigma;
    
    %% 3. Binarização e Fusão (A Solução para a Vibração)
    % Onde existe agitação?
    is_active = energy > trigger_level;
    
    % --- BRIDGE GAPS (A Mágica) ---
    % A vibração faz a derivada ir a zero rapidinho enquanto inverte a direção.
    % O código abaixo diz: "Se a agitação parou por menos de 50ms, 
    % considere que ainda é o mesmo evento".
    
    min_gap_samples = round(fs * 0.050); % 50ms de tolerância p/ vibração
    is_active = merge_gaps(is_active, min_gap_samples);
    
    %% 4. Extração dos Intervalos
    edges = diff([0; is_active; 0]);
    starts = find(edges == 1);
    ends   = find(edges == -1) - 1;
    
    if isempty(starts)
        cut_indices = [];
        return;
    end
    
    %% 5. Refinamento das Bordas (Opcional)
    % A detecção de energia pega o "grosso" do evento. 
    % Expandimos 1ms para garantir que pegamos o start exato.
    margin = round(fs * 0.001);
    
    real_starts = max(1, starts - margin);
    real_ends   = min(length(force_signal), ends + margin);
    
    % Filtra cliques muito curtos (< 5ms) que podem ser erro elétrico
    durations = real_ends - real_starts;
    valid = durations > (fs * 0.00005);
    
    cut_indices = [real_starts(valid), real_ends(valid)];
end

function binary_signal = merge_gaps(binary_signal, max_gap)
    % Função para ignorar buracos pequenos (vibração) dentro de um corte
    edges = diff([0; binary_signal; 0]);
    falling = find(edges == -1) - 1;
    rising  = find(edges == 1);
    
    if length(rising) < 2, return; end
    
    % Distância entre o fim de um bloco e o começo do próximo
    gaps = rising(2:end) - falling(1:end-1);
    
    % Acha buracos pequenos (vibração passando pelo zero)
    small_gaps_idx = find(gaps <= max_gap);
    
    for i = 1:length(small_gaps_idx)
        idx = small_gaps_idx(i);
        % Preenche o buraco com 1
        binary_signal(falling(idx) : rising(idx+1)) = 1;
    end
end