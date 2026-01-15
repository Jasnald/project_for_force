function [relevant_tp] = find_peaks(data, trigger, est_int_length, sensitivity)
    sum_cut = 0;
    max_data = movmax(abs(data),100);
    temp_tp1 = find(max_data > trigger,1);
    if temp_tp1 < 10       %für den Fall, dass die Messwerte am Beginn nicht bei ca. 0 liegt
        real_start = find(round(max_data)<trigger, 1);   %schneidet Bereich vor der Nullung aus dem Signal heraus
        sum_cut = sum_cut + real_start+1;
        max_data = max_data(real_start+1:end);
        temp_tp1 = find(abs(max_data)>trigger,1);
    end
    if length(max_data)-(temp_tp1+est_int_length)>0
        max_data = max_data(temp_tp1 : temp_tp1+est_int_length);
    else
        max_data = max_data(temp_tp1 : end);
    end
    sum_cut = sum_cut + temp_tp1;
    all_tp = find(max_data > trigger);

    % if max_data(all_tp(1))-max_data(all_tp(1)+1)>0  %falls erster tp kein anstieg der Krtaft ist also keine Fräsoperation
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