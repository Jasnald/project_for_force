%%Zur Kraftauswertung für Dimplefräser
%
% Es muss EXTERN über die Funktion get_freq.m die gewünschte Grenzfrequenz
% ermittelt werden. Diese muss dann in der Variable filter_freq im Header
% des Programms gesetzt werden.
% Die Parameter im Programmheader müssen auch an die Messwerte angepaast
% werden.
%
% WICHTIG:  Wenn mehr als eine .tdms ausgewertet werden soll (sich allo
%           mehr als eine .tdms Datei im Ordner befindet), dann muss der Abschnitt
%           "gefilterte Daten plotten" und "prozesskräfte plotten" AUSKOMMENTIERT
%           werden, da sonst eine Flut an Figure-Fenstern ensteht!
%
% date: 21.05.2024
% @author: dgl_bd
%%

close all
clear all
clc;
%% Diese Werte Vorher festlegen
    dt = 0.0001; % Zeitstep nach Messwerten ANPASSEN!!!!!!!!!!!!!!!!!!!
    n = 0.06;  % Zeit welche vor und nach Schnitt mit geplottet wird. Muss durch dt teilbar sein
    m = 0.025;  % Zeit welche vor und nach dem Schnittbeginn abgezogen wird für die Mittelwertbildung, wird nachher autom. geändert
    k = 0.04;   % Zeit welche vor und nach dem Plotbeginn für Offset-Korrektur betrachtet wird
    e = 1;      % Zeit welche vor der Tischrotation am Ende abgezogen wird
    trigger = 5; %Triggerwert zur Signalerkennung
    est_total_cutting_time = 5; %Geschätzte gesamteingriffszeit für alle Dimple in Sekunden
    max_eingriffzeit_dimple = 0.1; %in Sekunden, beschreibt die Dauer, die z.B. ein einzelner Dimple oder Verzahnung gefräst wird. (Der Abstand zwischen zwei Fräsungen soll fertigungsbedingt größer sein, als die Eingriffszeit)
    trigger_sensitivity = max_eingriffzeit_dimple/dt;
    num_cuts = 3;    %Anzahl an Eingriffen ins Material, hier Bohrungen oder Zahntäler. Hierüber wird bestimmt wieviele Intervalle Analysiert werden.
%%
%Dateienordner auswählen
path = uigetdir('..\..\..\02_Kraftdaten\ISEO\PS_1\',"Ordener der .tdms Dateien wählen");
path = append(path,'\');
datatype = 'tdms';
tdms_files = jcj_filterforfiles(path,datatype);   %Vector mit allen Pfaden der tdms Dateien

excel_path = append(path,'Exceldaten\');
if not(isfolder(excel_path))
    mkdir(excel_path);  %erstellen des Verzeichnis, falls noch nicht vorhanden
end

for i = 1:size(tdms_files)      %durchläuft die tdms Dateien im Ordner
    temp_fullpath = append(path,tdms_files{i});
    tdms_name = tdms_files{i}(1:end-5);
    temp_tdms = TDMS_readTDMSFile(temp_fullpath);   % Einlesen der tdms-Datei
    temp_fx = temp_tdms.data{1,3};
    temp_fy = temp_tdms.data{1,4};
    temp_fz = temp_tdms.data{1,5};

    
    %Triggerpunkte bestimmen, damit es einheitlich ist
    temp_filtered_fx = movmean(temp_fx, 25);
    tp = find_peaks(temp_filtered_fx, trigger, est_total_cutting_time/dt, trigger_sensitivity);
    for j = 1:3     %durchläuft fx, fy und fz
        temp_f = 0;
        if j == 1
            temp_f = temp_fx;
        elseif j == 2
            temp_f = temp_fy;
        elseif j == 3
            temp_f = temp_fz;
        end
        
        %filter signal --> reduce noise and induced vibrations
        filtered_f = movmean(temp_f, 25);

        filtered_f = offsetcorrection(filtered_f, tp(1));

        %ÄNDERN DAS EINHEITLICH VON MAX ODER MIN
%         peaks_f = [];
%         num_min = 0;
%         num_max = 0;
%         for d = 1:2:(num_cuts)*2-1
%             if mean(filtered_f(tp(d):tp(d+1))) <= 0
%                 num_min = num_min + 1;
%             elseif mean(filtered_f(tp(d):tp(d+1))) > 0
%                 num_max = num_max + 1;
%             end
%         end
%         if num_min > num_max
%             for d = 1:2:(num_cuts)*2-1
%                 peaks_f = [peaks_f, min(filtered_f(tp(d):tp(d+1)))]; %berechnet die min werte der Intervalle in ein Array
%             end
%         elseif num_min <= num_max
%             for d = 1:2:(num_cuts)*2-1
%                 peaks_f = [peaks_f, max(filtered_f(tp(d):tp(d+1)))]; %berechnet die max werte der Intervalle in ein Array
%             end
%         end
        

        %Zuschneiden auf relevanten Bereich zum Plotten (excel)
        plot_filtered_f = filtered_f(tp(1)-n/dt:tp(num_cuts*2)+n/dt);
        
        %Zeitvektor zum Plotten
        S = length(plot_filtered_f);
        time = (0:dt:S*dt-dt)';

        if j == 1
            filtered_fx = plot_filtered_f;
        elseif j == 2
            filtered_fy = plot_filtered_f;
        elseif j == 3
            filtered_fz = plot_filtered_f;
        end
              
    end

    Fzer = sqrt(filtered_fx.^2 + filtered_fy.^2 + filtered_fz.^2);
    
    %zur Fehlervermeidung
    dimple_deep_mean = [];  
    dimple_flat_mean = [];
    peaks_f = [];
    plot_tp = tp - (tp(1)-n/dt);
    for d = 1:2:(num_cuts)*2-1
        peaks_f = [peaks_f max(Fzer(plot_tp(d) : plot_tp(d+1)))]; %berechnet die max werte der Intervalle in ein Array
    end
    %Mittelwert für die Dimple für F_zer
    dimple_mean = mean(peaks_f(1:num_cuts));
    
    figure;
    plot(time, Fzer);
    title("Zerspankraft Dimple");
    ylabel("F_z_e_r");
    xlabel("time");
    yline(dimple_mean,'--m', 'MW');


     %% Excelausgabe
    cur_excel_path = append(excel_path, tdms_name);
    if not(isfolder(cur_excel_path))
        mkdir(cur_excel_path);  %erstellen des Verzeichnis, falls noch nicht vorhanden
    end
   
    % Time
    filepath_excel = append(cur_excel_path,'\Time_Excel.csv');
    fileID = fopen(filepath_excel, 'w');
    formatSpec = '%.5f\n';
    pause(0.1);
    fprintf(fileID, formatSpec, time);
    pause(0.1);
    file_contents = fileread(filepath_excel);
    pause(0.1);
    file_contents = strrep(file_contents, '.', ',');
    fileID = fopen(filepath_excel, 'w');
    pause(0.1);
    fprintf(fileID, '%s', file_contents);
    pause(0.1);
    fclose(fileID);
    pause(0.1);

    % Fzer
    filepath_excel = append(cur_excel_path,'\Fzer_Excel.csv');
    fileID = fopen(filepath_excel, 'w');
    pause(0.1);
    formatSpec = '%.5f\n';
    fprintf(fileID, formatSpec, Fzer);
    pause(0.1);
    file_contents = fileread(filepath_excel);
    pause(0.1);
    file_contents = strrep(file_contents, '.', ',');
    fileID = fopen(filepath_excel, 'w');
    pause(0.1);
    fprintf(fileID, '%s', file_contents);
    pause(0.1);
    fclose(fileID);


end