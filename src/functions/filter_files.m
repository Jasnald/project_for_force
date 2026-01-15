% FILTER_FILES Lists files in a directory matching a specific extension.
% Refactored from 'jcj_filterforfiles.m' to use native MATLAB vectorization.

function [file_list] = filter_files(folder_path, file_extension) 
    % Create search pattern (e.g., 'D:/data/*.tdms')
    search_pattern = fullfile(folder_path, ['*.' file_extension]);
    
    % Get directory structure using built-in wildcard filtering
    files_struct = dir(search_pattern);
    
    % Extract just the names into a cell array (vertical vector)
    file_list = {files_struct.name}';
end