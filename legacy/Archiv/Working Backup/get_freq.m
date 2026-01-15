function [freq, ampl] = get_freq (data, timesteps)
    N = length(data);
    data_transformed = fft(data);
    % Berechnung der Amplituden
    P2 = abs(data_transformed/N);        % Zwei-seitiges Spektrum
    ampl = P2(1:N/2+1);     % Ein-seitiges Spektrum
    ampl(2:end-1) = 2*ampl(2:end-1); % Korrektur der Amplitude
    freq = (1/timesteps)*(0:(N/2))/N;
    
    % Plot der Amplituden über die Frequenzen
    figure;
    plot(freq, ampl);
    title('Amplitude Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Amplitude');
    grid on;

end