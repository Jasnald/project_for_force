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
function fn_NS_Dimplefraeser_Kraftauswertung(path)
close all
% clear 
clc;
%% Diese Werte Vorher festlegen
    dt = 0.0001; % Zeitstep nach Messwerten ANPASSEN!!!!!!!!!!!!!!!!!!!
    n = 0.2;  % Zeit welche vor und nach Schnitt mit geplottet wird. Muss durch dt teilbar sein
    m = 0.025;  % Zeit welche vor und nach dem Schnittbeginn abgezogen wird für die Mittelwertbildung, wird nachher autom. geändert
    k = 0.04;   % Zeit welche vor und nach dem Plotbeginn für Offset-Korrektur betrachtet wird
    e = 1;      % Zeit welche vor der Tischrotation am Ende abgezogen wird
    trigger = 10; %Triggerwert zur Signalerkennung
    est_total_cutting_time = NaN; % Wird später gesetzt (hier)!!! Geschätzte gesamteingriffszeit für alle Dimple in Sekunden
    max_eingriffzeit_dimple = 0.5; %in Sekunden, beschreibt die Dauer, die z.B. ein einzelner Dimple oder Verzahnung gefräst wird. (Der Abstand zwischen zwei Fräsungen soll fertigungsbedingt größer sein, als die Eingriffszeit)
    trigger_sensitivity = max_eingriffzeit_dimple/dt;
    num_cuts = 5;    %Anzahl an Eingriffen ins Material, hier Bohrungen oder Zahntäler. Hierüber wird bestimmt wieviele Intervalle Analysiert werden.
    maxDimensionsTable = [8,3];
%%
%Dateienordner auswählen
%path = uigetdir('S:\02_SHK\02 dgl_bd\01_Arge\WP2.2\01_Kraftauswertung\02_Kraftdaten\Gegenlauf\ISEO - Messing\D\',"Ordener der .tdms Dateien wählen");
path = append(path,'\');
    disp("Current File:    " + path);
datatype = 'tdms';
tdms_files = jcj_filterforfiles(path,datatype);   %Vector mit allen Pfaden der tdms Dateien

excel_path = append(path,'Exceldaten\');
if not(isfolder(excel_path))
    mkdir(excel_path);  %erstellen des Verzeichnis, falls noch nicht vorhanden
end

filenames = [];
deep = [];
flat = [];

for i = 1:size(tdms_files)      %durchläuft die tdms Dateien im Ordner
    temp_fullpath = append(path,tdms_files{i});
    tdms_name = tdms_files{i}(1:end-5);
    temp_tdms = TDMS_readTDMSFile(temp_fullpath);   % Einlesen der tdms-Datei
    temp_fx = temp_tdms.data{1,3};
    temp_fy = temp_tdms.data{1,4};
    temp_fz = temp_tdms.data{1,5};

    
    %Triggerpunkte bestimmen, damit es einheitlich ist
    temp_filtered_fz = movmean(temp_fz, 25);
    disp(i + " -te tdms Datei des Durchlaufs!");
    [int_start, int_end, rought_left_boundry] = manual_find_interval(temp_filtered_fz, trigger);
    if (not(isnan(int_start))||not(isnan(int_end)))
        temp_fx = temp_fx(round(int_start-n/dt):round(int_end+n/dt));
        temp_fy = temp_fy(round(int_start-n/dt):round(int_end+n/dt));
        temp_fz = temp_fz(round(int_start-n/dt):round(int_end+n/dt));
        est_total_cutting_time = int_end - int_start;
        tp = find_peaks(temp_fz, est_total_cutting_time, trigger_sensitivity);
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
    
            filtered_f = offsetcorrectionV1(filtered_f, tp(2));
    
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
            plot_filtered_f = filtered_f; %(tp(1)-n/dt:tp(num_cuts*2)+n/dt);
            
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
        plot_tp = tp; %- tp(1);%(tp(1)-n/dt);
        for d = 1:2:(num_cuts)*2-1
            peaks_f = [peaks_f max(Fzer(tp(d) : tp(d+1)))]; %berechnet die max werte der Intervalle in ein Array
        end
        %Mittelwert für die Dimple für F_zer
        dimple_deep_mean = mean(peaks_f(1:2:num_cuts)); %tiefe Dimple
        dimple_flat_mean = mean(peaks_f(2:2:num_cuts-1)); %flache Dimple

        %für Tabellenausgabe
        
        pause(1);
        fig1 = figure;
        plot(time, Fzer);
        title("Zerspankraft Dimple");
        ylabel("F_z_e_r");
        xlabel("time");
        yline(dimple_flat_mean,'--m', 'MW flach');
        yline(dimple_deep_mean,'--r', 'MW tief');
        pause(2);
        close(fig1);
    
    
         %% Excelausgabe
        % cur_excel_path = append(excel_path, tdms_name);
        % if not(isfolder(cur_excel_path))
        %     mkdir(cur_excel_path);  %erstellen des Verzeichnis, falls noch nicht vorhanden
        % end
        % 
        % % Time
        % filepath_excel = append(cur_excel_path,'\Time_Excel.csv');
        % fileID = fopen(filepath_excel, 'w');
        % formatSpec = '%.5f\n';
        % pause(0.1);
        % fprintf(fileID, formatSpec, time);
        % pause(0.1);
        % file_contents = fileread(filepath_excel);
        % pause(0.1);
        % file_contents = strrep(file_contents, '.', ',');
        % fileID = fopen(filepath_excel, 'w');
        % pause(0.1);
        % fprintf(fileID, '%s', file_contents);
        % pause(0.1);
        % fclose(fileID);
        % pause(0.1);
        % 
        % % Fzer
        % filepath_excel = append(cur_excel_path,'\Fzer_Excel.csv');
        % fileID = fopen(filepath_excel, 'w');
        % pause(0.1);
        % formatSpec = '%.5f\n';
        % fprintf(fileID, formatSpec, Fzer);
        % pause(0.1);
        % file_contents = fileread(filepath_excel);
        % pause(0.1);
        % file_contents = strrep(file_contents, '.', ',');
        % fileID = fopen(filepath_excel, 'w');
        % pause(0.1);
        % fprintf(fileID, '%s', file_contents);
        % pause(0.1);
        % fclose(fileID);
        % 
        % % Fzer mean
        % filepath_excel = append(cur_excel_path,'\mean_Fzer_Excel.xlsx');
        % table_mean = table(dimple_mean);
        % writetable(table_mean,filepath_excel);
    else
        dimple_deep_mean = NaN;
        dimple_flat_mean = NaN;
    end
    filenames = [filenames; tdms_name];
    deep = [deep; dimple_deep_mean];
    flat = [flat; dimple_flat_mean];
    
end

%MW der Messungen bilden
mean_all_deep = mean(deep(~isnan(deep)));
mean_all_flat = mean(flat(~isnan(flat)));

filenames = [filenames; "Mittelwert"; "Standartabweichung"];
max_Fzer_deep = [deep; mean_all_deep; NaN];
max_Fzer_flat = [flat; mean_all_flat; NaN];
filepath_excel = append(excel_path,'\mean_Fzer_Excel.xlsx');
table_print = table(filenames, max_Fzer_flat, max_Fzer_deep);
writetable(table_print,filepath_excel);
pause(0.5);
clear;
end