% APPLY_BANDPASS Isolates a frequency range around a center frequency.
% Refactored from 'noisefilter_Signal.m'.

function filtered_signal = apply_bandpass(input_signal, fs, center_freq, bandwidth)
    % WARNING: Narrow bandpass filtering can distort the physical shape 
    % of cutting force profiles. Use with caution for profile averaging.
    
    if nargin < 4
        bandwidth = 10; % Default bandwidth +/- 10 Hz (Legacy behavior)
    end
    
    % Define frequency limits
    freq_range = [center_freq - bandwidth, center_freq + bandwidth];
    
    % Apply MATLAB's built-in bandpass filter
    filtered_signal = bandpass(input_signal, freq_range, fs);
end