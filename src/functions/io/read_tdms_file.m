function data = read_tdms_file(filePath)
    %READ_TDMS_FILE Load TDMS file and extract relevant data

    % Extract sampling rate from channel properties
    fs = 100000; % Default value
    
    % Load data
    rawCell = tdmsread(filePath);
    groupData = rawCell{1};
    
    data.fx = groupData.Fx;
    data.fy = groupData.Fy;

    data.fs = fs;
    data.dt = 1/fs;
    data.time = (0:length(data.fx)-1)' * data.dt;
    
    fprintf('\nLoaded: fs=%.0f Hz, duration=%.2f s\n', data.fs, data.time(end));
end