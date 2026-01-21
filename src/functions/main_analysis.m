%% Main Force Analysis Interface
% This script allows the user to select a TDMS file and perform
% a complete cutting force analysis using the ForceAnalyzer class.
clear; close all; clc;

% --- Add Paths (Dynamically finds the 'src' folder) ---
current_path = fileparts(mfilename('fullpath'));
addpath(genpath(current_path)); % Adds src/functions, src/classes, etc.

%% 1. USER PARAMETERS (Configure your analysis here)

% --- Tool Geometry ---
% These are required to calculate the entry angle (theta_s)
tool_diameter_mm = 20.0;    
radial_depth_mm  = 1.8;    % ae
trim_percentages = [0.50, 0.495];  % Trim 10% start/end of steady state segments

% --- Tool Properties ---
num_teeth        = 1;      % Number of flutes/teeth

% --- Plotting ---
close_previous_plots = true;


%% 2. FILE SELECTION


if close_previous_plots
    close all;
end

fprintf('Please select a .tdms file...\n');
[file_name, file_path] = uigetfile({'*.tdms', 'LabVIEW TDMS Files (*.tdms)'}, ...
                                   'Select Force Data File');

if isequal(file_name, 0)
    fprintf('User canceled file selection.\n');
    return;
end

full_file_path = fullfile(file_path, file_name);

%% 3. EXECUTION


% Initialize the Analyzer Class
analyzer = ForceAnalyzer();

% Apply User Parameters to the Configuration
analyzer.update_config('tool',   'num_teeth',    num_teeth);
analyzer.update_config('stats', 'default_trim', trim_percentages);

% Prepare Geometry Struct
geometry.D  = tool_diameter_mm;
geometry.ae = radial_depth_mm;

% Run the Pipeline
success = analyzer.run_analysis(full_file_path, geometry);

if success
    fprintf('\nAnalysis Complete. Check the Dashboard figure.\n');
else
    fprintf('\nAnalysis Failed.\n');
end