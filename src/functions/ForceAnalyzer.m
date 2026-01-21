classdef ForceAnalyzer < handle
    % FORCEANALYZER Encapsulates the cutting force analysis pipeline.
    % This class manages configuration, data loading, processing, and visualization.
    
    properties
        Config      % Configuration struct (from config_processing)
        RawData     % Struct containing raw fx, fy, fs, time
        Results     % Struct containing statistics and kinematic forces
        FilePath    % Path of the loaded file
        FileName    % Name of the loaded file
    end
    
    methods
        function obj = ForceAnalyzer()
            % Constructor: Load default configuration
            obj.Config = config_processing();
        end
        
        function update_config(obj, struct_part, field_name, value)
            % Helper to update configuration safely
            if isfield(obj.Config, struct_part) && isfield(obj.Config.(struct_part), field_name)
                obj.Config.(struct_part).(field_name) = value;
                fprintf('Config Updated: %s.%s = %s\n', struct_part, field_name, string(value));
            else
                warning('Invalid config field: %s.%s', struct_part, field_name);
            end
        end
        
        function success = run_analysis(obj, full_path, geometry)
            % RUN_ANALYSIS Executes the full processing pipeline.
            % geometry: struct with .D (Diameter) and .ae (Radial Depth)
            
            success = false;
            [~, name, ext] = fileparts(full_path);
            obj.FileName = [name ext];
            obj.FilePath = full_path;
            
            fprintf('\n=== Starting Analysis: %s ===\n', obj.FileName);
            
            try
                %% 1. Load Data
                % Uses the centralized read function
                obj.RawData = read_tdms_file(full_path, obj.Config.io);
                
                % Ensure sampling rate is scalar
                if numel(obj.RawData.fs) > 1, obj.RawData.fs = obj.RawData.fs(1); end
                
                %% 2. Auto-Cleaning (Air Cutting & Drift)
                [win_start, win_end, cut_limits] = detect_air_cutting(obj.RawData.fx, obj.RawData.fs, obj.Config.air);
                
                [fx_c, ~] = remove_linear_drift(obj.RawData.fx, obj.RawData.fs, win_start, win_end);
                [fy_c, ~] = remove_linear_drift(obj.RawData.fy, obj.RawData.fs, win_start, win_end);
                
                %% 3. Filtering
                fprintf('   -> Filtering: %d-Order Butterworth @ %.0f Hz\n', ...
                        obj.Config.filter.order, obj.Config.filter.cutoff_freq);
                
                Wn = obj.Config.filter.cutoff_freq / (obj.RawData.fs / 2);
                [b, a] = butter(obj.Config.filter.order, Wn, 'low');
                
                fx_c = filtfilt(b, a, fx_c);
                fy_c = filtfilt(b, a, fy_c);
                
                %% 4. Isolation (Steady State)
                [fx_steady, t_steady] = crop_steady_state(fx_c, obj.RawData.time, cut_limits, obj.Config.stats.default_trim);
                [fy_steady, ~]        = crop_steady_state(fy_c, obj.RawData.time, cut_limits, obj.Config.stats.default_trim);
                
                %% 5. Segmentation (Find Teeth)
                cut_indices = detect_cut_indices(fx_steady, obj.RawData.fs, obj.Config.det);
                
                if isempty(cut_indices)
                    warning('No cuts detected in file %s', obj.FileName);
                    return;
                end
                
                %% 6. Calculate Metrics (RPM, Avg Profile)
                obj.Results = compute_cut_statistics(fx_steady, fy_steady, cut_indices, ...
                                                     obj.RawData.fs, obj.Config.tool.num_teeth, obj.Config.stats);
                
                % Safety Check
                if isfield(obj.Results, 'avg_profile') && all(isnan(obj.Results.avg_profile.x_mean))
                    warning('Analysis produced NaN results.');
                    return;
                end
                
                fprintf('   -> Success: Detected %d cuts | Mean RPM: %.0f\n', ...
                        size(cut_indices,1), obj.Results.rpm_mean);
                
                %% 7. Kinematic Forces (Fc, Fcn)
                % Calculate Entry Angle based on Geometry
                theta_s = calculate_entry_angle(geometry.ae, geometry.D);
                fprintf('   -> Geometry: D=%.1fmm, ae=%.1fmm => Entry Angle=%.1f deg\n', ...
                        geometry.D, geometry.ae, theta_s);
                
                obj.Results = compute_kinematic_forces(obj.Results, fx_steady, fy_steady, ...
                                                    theta_s, obj.Config.stats);
                                                   
                %% 8. Visualization
                plot_analysis_dashboard(t_steady, fx_steady, cut_indices, obj.Results, obj.FileName, obj.Config.vis);
                
                success = true;
                
            catch ME
                fprintf('ERROR in analysis: %s\n', ME.message);
                fprintf('Trace: %s line %d\n', ME.stack(1).name, ME.stack(1).line);
            end
        end
    end
end