function corrected = KSS_drift_correction(data, int_start, int_end)
    % Bestimme Start- und Endpunkte für die Korrektur
    x_start = max(int_start - 750, 1);  % Startpunkt vor int_start
    x_end = min(int_end + 450, length(data));      % Endpunkt nach int_end
    
    % Berechne den Mittelwert der Daten in den Bereichen vor und nach dem Intervall
    y_start = movmean(data(x_start),500);
    y_end = movmean(data(x_end),500);
    
    % Berechne die Steigung (m) und den y-Achsenabschnitt (b) der linearen Korrektur
    x_values = [x_start, x_end];  % x-Werte der beiden Punkte
    y_values = [y_start, y_end];  % y-Werte der beiden Punkte
    
    % Lineare Regression: m ist die Steigung, b ist der y-Achsenabschnitt
    p = polyfit(x_values, y_values, 1);  % polyfit gibt [m, b] zurück
    
    m = p(1);  % Steigung
    b = p(2);  % y-Achsenabschnitt
    
    % Erstelle eine Linie mit der gleichen Länge wie die Daten, die den Drift modelliert
    correction_line = m * (1:length(data)) + b;
    
    % Subtrahiere die Driftlinie von den Daten, um die Korrektur durchzuführen
    corrected = data - correction_line;
end
