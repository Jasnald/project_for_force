function [relevant_tp] = find_peaks(data, trigger, est_int_length, sensitivity)
    max_data = movmax(abs(data),100);
    temp_tp1 = find(max_data > trigger,1);
    temp_max_data = max_data(temp_tp1 : temp_tp1 + est_int_length);
    all_tp = find(temp_max_data > trigger);
    relevant_tp = all_tp(1);
    for i = 2:length(all_tp)-1
        if(abs(all_tp(i) - all_tp(i-1)) > sensitivity || abs(all_tp(i) - all_tp(i+1)) > sensitivity)
            relevant_tp = [relevant_tp, all_tp(i)];
        end
    end
    relevant_tp = [relevant_tp, all_tp(end)];
    relevant_tp = relevant_tp + temp_tp1;
end