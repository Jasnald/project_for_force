function [freq_vector, amplitude] = get_frequency_spectrum(data, dt)
    % GET_FREQUENCY_SPECTRUM Computes the single-sided amplitude spectrum of a signal.
    % Inputs:
    %   data: Vector containing the signal
    %   dt: Sampling period (seconds) (1/fs)
    
    L = length(data);             % Length of signal
    Y = fft(data);                % Compute FFT
    
    % Compute two-sided spectrum P2
    P2 = abs(Y / L);
    
    % Compute single-sided spectrum P1 based on P2 and even-valued signal length L
    P1 = P2(1 : floor(L/2)+1);
    
    % Scale P1 to conserve energy (double amplitudes except DC and Nyquist)
    P1(2:end-1) = 2 * P1(2:end-1);
    
    % Define outputs
    amplitude = P1;
    fs = 1 / dt;                  % Sampling frequency
    freq_vector = fs * (0 : floor(L/2)) / L;
    
    % Plot the spectrum
    figure('Name', 'Frequency Spectrum');
    plot(freq_vector, amplitude);
    title('Single-Sided Amplitude Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Amplitude |P1(f)|');
    grid on;
end