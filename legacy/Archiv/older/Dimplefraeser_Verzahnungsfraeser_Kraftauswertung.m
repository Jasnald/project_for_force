%%Test Fourieranalyse

%%Testfunktion zum Plotten
close all
clear all
clc;
%% Diese Werte Vorher festlegen
    dt = 0.0001; % Zeitstep nach Messwerten ANPASSEN!!!!!!!!!!!!!!!!!!!
    n = 0.06;  % Zeit welche vor und nach Schnitt mit geplottet wird. Muss durch dt teilbar sein
    m = 0.025;  % Zeit welche vor und nach dem Schnittbeginn abgezogen wird für die Mittelwertbildung, wird nachher autom. geändert
    k = 0.04;   % Zeit welche vor und nach dem Plotbeginn für Offset-Korrektur betrachtet wird
    e = 1;      % Zeit welche vor der Tischrotation am Ende abgezogen wird
    trigger = 8; %Triggerwert zur Signalerkennung
    max_eingriffzeit = 0.1; %in Sekunden
    trigger_sensitivity = max_eingriffzeit/dt;
    num_cuts = 5;    %Anzahl an Eingriffen ins Material, hier Bohrungen oder Zahntäler
%%
%Dateienordner auswählen
path = uigetdir('..\..\',"Ordener der .tdms Dateien wählen");
path = append(path,'\');
datatype = 'tdms';
tdms_files = jcj_filterforfiles(path,datatype);   %Vector mit allen Pfaden der tdms Dateien

excel_path = append(path,'Exceldaten\');
if not(isfolder(excel_path))
    mkdir(excel_path);  %erstellen des Verzeichnis, falls noch nicht vorhanden
end

for i = 1:size(tdms_files)      %durchläuft die tdms Dateien im Ordner
    temp_fullpath = append(path,tdms_files{i});
    temp_tdms = TDMS_readTDMSFile(temp_fullpath);   % Einlesen der tdms-Datei
    temp_fx = temp_tdms.data{1,3};
    temp_fy = temp_tdms.data{1,4};
    temp_fz = temp_tdms.data{1,5};


    dimple_deep_mean = [];  %zur Fehlervermeidung
    dimple_flat_mean = [];
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
        filtered_f = noisefilter_Signal(temp_f, dt, 664);

        tp = find_peaks(filtered_f, trigger, trigger_sensitivity);

        filtered_f = offsetcorrection(filtered_f, tp(1));

        %ÄNDERN DAS EINHEITLICH VON MAX ODER MIN
        peaks_f = [];
        num_min = 0;
        num_max = 0;
        for d = 1:2:(num_cuts)*2-1
            if mean(filtered_f(tp(d):tp(d+1))) <= 0
                num_min = num_min + 1;
            elseif mean(filtered_f(tp(d):tp(d+1))) > 0
                num_max = num_max + 1;
            end
        end
        if num_min > num_max
            for d = 1:2:(num_cuts)*2-1
                peaks_f = [peaks_f, min(filtered_f(tp(d):tp(d+1)))]; %berechnet die min werte der Intervalle in ein Array
            end
        elseif num_min <= num_max
            for d = 1:2:(num_cuts)*2-1
                peaks_f = [peaks_f, max(filtered_f(tp(d):tp(d+1)))]; %berechnet die max werte der Intervalle in ein Array
            end
        end
        %Mittelwert für jeweils die tiefen und die flachen Dimple
        dimple_deep_mean(j) = mean(peaks_f(1:2:num_cuts));
        dimple_flat_mean(j) = mean(peaks_f(2:2:num_cuts-1));

        %Zuschneiden auf relevanten Bereich zum Plotten (excel)
        plot_filtered_f = filtered_f(tp(1)-n/dt:tp(num_cuts*2)+n/dt);
        
        %Zeitvektor zum Plotten
        S = length(plot_filtered_f);
        time = (0:dt:S*dt-dt)';

        figure;

        %subplot(2,1,1);
        plot(time, plot_filtered_f);
        yline(dimple_deep_mean,"--k");
        yline(dimple_flat_mean,"--k");
               
        % %Excelausgabe gefiltertes Signal --> aktuell Problem weil zu
        % wenig speicher frei
        % filtered_f_with_time = table(time, plot_filtered_f');
        % if j == 1
        %     f_direction = 'x';
        % elseif j == 2
        %     f_direction = 'y';
        % elseif j == 3
        %     f_direction = 'z';
        % end
        % writetable(filtered_f_with_time, append(excel_path,tdms_files{i}(1:end-5),'\F',f_direction,'_filtered.xlsx'));
    end
    %ab hier weiter neu machen-->
    mean_flat = mean_maxmin_f; %Mittelwerte (1:x 2:y 3:z)
    Fp_flat = mean_f(1);
    Fa = sqrt(mean_f(2)^2 + mean_f(3)^2);
    Fzer = sqrt(Fa^2 + Fp^2);
    processforces = table(["Fp", "Fa", "Fzer"]',[Fp, Fa, Fzer]');
    writetable(processforces, append(excel_path,tdms_files{i}(1:end-5),'\Prozesskräfte.xlsx'));
end


