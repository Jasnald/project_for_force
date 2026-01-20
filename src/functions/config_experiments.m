function experiments = config_experiments()
% CONFIG_EXPERIMENTS Gera o registro de todos os ensaios do projeto.
% Retorna um array de structs com caminhos e parametros fisicos.

    % --- Caminho Raiz dos Dados (Ajuste se mudar de PC) ---
    root_dir = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data";

    % Inicializa a estrutura
    experiments = struct('id', {}, 'set_name', {}, 'filename', {}, 'full_path', {}, ...
                         'ae', {}, 'D', {}, 'theta_s_deg', {});
    
    idx = 1;

    %% --- PARAMETER SET 1 (PS1) ---
    % ae = 1.8mm, D = 20mm
    files_ps1 = ["PS1_Probe3L.tdms", "PS1_Probe4L.tdms"];
    folder_ps1 = "Parameter set 1";
    
    for f = files_ps1
        experiments(idx).id = idx;
        experiments(idx).set_name = "PS1";
        experiments(idx).filename = f;
        experiments(idx).full_path = fullfile(root_dir, folder_ps1, f);
        experiments(idx).ae = 1.8;
        experiments(idx).D  = 20;
        idx = idx + 1;
    end

    %% --- PARAMETER SET 2 (PS2) ---
    % ae = 0.2mm, D = 20mm
    files_ps2 = ["PS2_Probe1L.tdms", "PS2_Probe2L.tdms"];
    folder_ps2 = "Parameter set 2";

    for f = files_ps2
        experiments(idx).id = idx;
        experiments(idx).set_name = "PS2";
        experiments(idx).filename = f;
        experiments(idx).full_path = fullfile(root_dir, folder_ps2, f);
        experiments(idx).ae = 0.2;
        experiments(idx).D  = 20;
        idx = idx + 1;
    end

    %% --- PARAMETER SET 3 (PS3) ---
    % ae = 0.2mm, D = 20mm
    files_ps3 = ["PS3_Probe5L.tdms", "PS3_Probe6L.tdms"];
    folder_ps3 = "Parameter set 3";

    for f = files_ps3
        experiments(idx).id = idx;
        experiments(idx).set_name = "PS3";
        experiments(idx).filename = f;
        experiments(idx).full_path = fullfile(root_dir, folder_ps3, f);
        experiments(idx).ae = 0.2;
        experiments(idx).D  = 20;
        idx = idx + 1;
    end

    %% --- Pós-Processamento Automático ---
    % Calcula theta_s para todos baseados na geometria
    % Usa a nova funcao: calculate_entry_angle
    for i = 1:length(experiments)
        experiments(i).theta_s_deg = calculate_entry_angle(experiments(i).ae, experiments(i).D);
    end
end