function params = config_processing()
    % CONFIG_PROCESSING Centralizes all signal processing constants.
    
    %% 1. Detection (detect_cut_indices)
    params.det.smooth_win_sec    = 0.0005; 
    params.det.noise_rgn_pct     = 0.20;   
    params.det.noise_std_factor  = 3;      
    params.det.min_dist_sec      = 0.015;  
    params.det.min_height_pct    = 0.15;   
    params.det.start_thresh_pct  = 0.10;   
    params.det.end_thresh_frac   = 1.0;    

    %% 2. Air Cutting (detect_air_cutting)
    params.air.vib_smooth_sec    = 0.5;    
    params.air.thresh_factor     = 0.10;   
    params.air.buff_cut_sec      = 2.0;    
    params.air.buff_file_sec     = 1.0;    

    %% 3. Statistics & Normalization (compute_cut_statistics, compute_kinematic_forces)
    params.stats.norm_len        = 1000;          % Points for force profile interpolation
    params.stats.default_trim    = [0.10, 0.10];  % Default crop: 10% start, 10% end

    %% 4. Physics Optimization (optimize_entry_angle)
    params.phys.optim_penalty    = 10;     % Penalty weight for negative forces
    params.phys.angle_step       = 1;      % Search resolution [deg]
    params.phys.search_range     = [0, 360]; % Min/Max angle

    %% 5. Filtering
    params.filter.cutoff_freq    = 2000; 
    params.filter.order          = 2;
    
    %% 6. Tool Defaults
    params.tool.num_teeth        = 1;

    params.io.default_fs         = 100000; % Default sampling frequency [Hz]

    %% 6. Visualization Styles (Default plotting parameters)
    params.vis.font_name         = 'Arial';
    params.vis.font_size         = 10;
    params.vis.line_width_thin   = 0.5;
    params.vis.line_width_thick  = 1.5;
    params.vis.axis_line_width   = 1.0;
    params.vis.color_raw         = [0.7 0.7 0.7];
    params.vis.color_start       = [0 0.8 0];
    params.vis.color_end         = [0.8 0 0];
    params.vis.color_mean        = 'k';
end