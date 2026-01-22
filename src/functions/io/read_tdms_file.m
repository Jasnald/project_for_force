function data = read_tdms_file(filePath, io_params)
    %READ_TDMS_FILE Load TDMS file and extract relevant data

    arguments
        filePath  (1,:) char {mustBeFile} % Verifica se o ficheiro existe no disco!
        io_params (1,1) struct = config_processing().io
    end
    % Use configured default
    fs = io_params.default_fs;
    
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