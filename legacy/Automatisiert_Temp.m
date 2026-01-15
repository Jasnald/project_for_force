%%%
%   Benötigt: Natural-Order Filename SortVersion 3.4.7 (53.7 KB) by Stephen23
% 
%%%

close all
clear;
clc;

startVar = 1; %falls neu gestartet werden muss, damit mitten drinnen eingestiegen werden kann

path = uigetdir('D:\03_Versuchsdaten WP2.2\WP2.2.2 Standzeit\02_Kraftdaten\ASSA ABLOY - Neusilber',"Ordener der Parameterpunkte wählen");
path = append(path,'\');

% Vektor aller Ordner im Pfad, bis auf "." und ".." erstellen
folders = dir(path);
folders = folders([folders.isdir]); % Nur Verzeichnisse auswählen
folders = folders(~ismember({folders.name}, {'.', '..'})); % "." und ".." entfernen
folderNames = {folders.name}; % Cell-Array mit den Namen der Ordner
% Sortieren der Ordnernamen numerisch
folderNames = natsort(folderNames); % Nutze natsort für natürliche Sortierung

for i = startVar:1%length(folderNames)
    clc;
    fn_NS_Dimplefraeser_Kraftauswertung(path);
    pause(0.1);
end