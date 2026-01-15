%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File-Filterung aus Liste
% Jannis Jacob, WZL, RWTH Aachen University
% MATLAB Version 2021a
% Verwendete Addons:
% - Keine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example-Input:
% path = 'D:\users\jcj\Lokal\01_Projekte\Technologiekette\Zwischenversuche Inkubator\Testdaten Inkubator nach Versuchsende Batch 2 - 2022';
% datatype = 'dat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [filteredfiles] = jcj_filterforfiles(path,datatype)
files = cellstr(ls(path));
flags = [];

for i = 1 : length(files)
    if gt(length(char(files(i))),length(datatype))
        tempstartidx = length(char(files(i)))-length(datatype)+1;
        tempfile = char(files(i));
        
        if strcmp(lower(datatype),lower(tempfile(tempstartidx:end)))
            tempflag = 1;
            flags = [flags;tempflag];
            
        else
            tempflag = 0;
            flags = [flags;tempflag];
        end
        
    else
        tempflag = 0;
        flags = [flags;tempflag];
    end
end

filteredfiles = {};
for i = 1 : length(flags)
    if eq(flags(i),1)
        filteredfiles = [filteredfiles,files(i)];
    end
end

filteredfiles = filteredfiles';
end