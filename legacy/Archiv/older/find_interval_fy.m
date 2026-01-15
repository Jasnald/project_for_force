%% Dimple- und Verzahnungsfräser
function [int_start,int_end] = find_interval_fy(data, trigger, add)
    max_f = movmax(data, 500);
    change_pts = findchangepts(max_f, MaxNumChanges = 4);
    int_start = change_pts(1);
    int_end = change_pts(2);
    data = data(int_start-add:int_end+add);
    indices_int = find(abs(data)>trigger);
    int_start = min(indices_int)+(change_pts(1)-add);
    int_end = max(indices_int)+(change_pts(1)-add);
end