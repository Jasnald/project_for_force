%%% Bandpassfilter mit Frequenz in Hz
function [filtered_signal] = noisefilter_Signal(input_signal, timestep, frequency)
        %geplat: Automatische Erkennung der 4 ersten Peaks
        %spec_signal = abs(fft(input_signal));
        %a = length(spec_signal);
        %spec_signal = spec_signal(1:a/2);
        %left_spec_signal = spec_signal(1:a/2);
        %freq = (1/timestep)*(0:a/2-1)/a;
        % ampl = left_spec_signal/(a/2);
        %signal_frequency = findpeaks(spec_signal);

    %Bandpassfiltern
    filtered_signal = bandpass(input_signal, [frequency-10 frequency+10], 1/timestep);
end