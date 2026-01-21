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
radial_depth_mm  = 2.0;    % ae

% --- Tool Properties ---
num_teeth        = 1;      % Number of flutes/teeth

% --- Filter Settings ---
cutoff_freq_hz   = 2000;   % Lowpass filter frequency (Hz)
filter_order     = 4;      % Filter steepness   

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
analyzer.update_config('filter', 'cutoff_freq',  cutoff_freq_hz);
analyzer.update_config('filter', 'order',        filter_order);

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