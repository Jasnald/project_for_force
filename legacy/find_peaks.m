function [relevant_tp] = find_peaks(data, est_int_length, sensitivity)
    sum_cut = 0;
    temp_offset = mean(data(end-10:end));
    data = data - temp_offset;
    max_data = movmax(abs(data),100);
    trigger = max(max_data)*2/4;    % im verlauf wird dieser temporäre trigger überschrieben
    temp_tp1 = find(max_data > trigger,1);
    if temp_tp1 < 10       %für den Fall, dass die Messwerte am Beginn nicht bei ca. 0 liegt
        %testweise auskommentiert!
        % real_start = find(round(max_data)<trigger, 1);   %schneidet Bereich vor der Nullung aus dem Signal heraus
        % sum_cut = sum_cut + real_start+1;
        % max_data = max_data(real_start+1:end);
        % temp_tp1 = find(abs(max_data)>trigger,1);
    end
    % if length(max_data)-(temp_tp1+est_int_length)>0
        max_data = max_data(round(temp_tp1) : end);
    % else
        % max_data = max_data(temp_tp1 : end);
    % end
    sum_cut = sum_cut + temp_tp1;
    trigger = max(max_data)*2/4;    % trigger bei 3/4 des höchsten peaks
    all_tp = find(max_data > trigger);

    % if max_data(all_tp(1))-max_data(all_tp(1)+1)>0  %falls erster tp kein anstieg der Kraft ist also keine Fräsoperation
    %     all_tp = all_tp(2:end);
    % end

    relevant_tp = all_tp(1);
    for i = 2:length(all_tp)-1
        if(abs(all_tp(i) - all_tp(i-1)) > sensitivity || abs(all_tp(i) - all_tp(i+1)) > sensitivity)
            relevant_tp = [relevant_tp, all_tp(i)];
        end
    end
    relevant_tp = [relevant_tp, all_tp(end)];
    relevant_tp = relevant_tp + sum_cut;
end