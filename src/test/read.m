path = "Z:\02_SHK\05_dgl_gm\16_Force Evaluation\01_Data\Parameter set 1\PS1_Probe3L.tdms";
data = load_tdms_data(path);


plot(data.time, data.fx);

title('Dados carregados com Fs automatico');