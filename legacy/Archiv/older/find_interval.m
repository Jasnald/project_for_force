%% Dimple- und Verzahnungsfräser
function [int_start,int_end] = find_interval(data, trigger, end_cut)
    max_f = movmax(data, 500);
    change_pts = findchangepts(max_f, MaxNumChanges = 1);
    data = data(1:change_pts-end_cut);
    indices_int = find(abs(data)>trigger);
    int_start = min(indices_int);
    int_end = max(indices_int);
end