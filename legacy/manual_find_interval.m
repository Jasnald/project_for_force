%Intervall kann grob vorher gesetzt werden --> bei WP2.2 essenziell, da die
%Daten nicht gut aufgenommen wurden

function [int_start,int_end,left_bndry] = manual_find_interval(data, trigger)
    fig = figure;
    plot(data);
    title(["Set interval (first left boundary, then right boundary)", "When data should not be used: click LEFT from the graph-area"]);
    [x,~] = ginput(2);
    close(fig);
    
    sum_cut = 0;    %Summe an "Verschnitt" am Anfang der Daten
    left_bndry = min(x);
    rough_int_length = max(x)-min(x);
    if not(left_bndry<0 || max(x)>length(data))
        data = data(round(min(x)):round(min(x)+rough_int_length));
        sum_cut = sum_cut + min(x);
        temp_offset = mean(data(1:10));
        data = data - temp_offset;
        indices_int = find(abs(data)>trigger);
        if isempty(indices_int)
            indices_int = find(abs(data)>max(data)*3/4);
        end
        %Intervall finden und auf alte Datengröße rücktransformieren (da Indexverschiebung durch kürzen den Intervalls)
        int_start = min(indices_int) + sum_cut;
        int_end = max(indices_int) + sum_cut;
    else
        int_start = NaN;
        int_end = NaN;
    end

end