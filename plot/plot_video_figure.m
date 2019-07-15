clc;
clear all;
close all;
% parameter setting
% constant parameters
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9;% Center frequency (Hz)
lambda = c/fc;
Rx = 4;
Tx = 2;

% configuration parameters
Fs = 4*10^6;
sweepSlope = 21.002e12;
samples = 128;
loop = 255;
Tc = 60e-6; %us
fft_Rang = 128;
fft_Vel = 256;
fft_Ang = 91;


folder_name = 'D:/tmp/2019_05_10_cc000/DATA'
data_name = '2019_05_10_cc000'

%read text(neural network result)
%Results = dlmread('D:\tmp\2019_04_09_bms1000_iter10.txt');

% Creat grid table
for ig = 1:1
    freq_res = Fs/fft_Rang;% range_grid
    freq_grid = (0:fft_Rang-1).'*freq_res;
    rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
    
    w = [-180:4:180]; % angle_grid
    agl_grid = asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]
    
    % velocity_grid
    dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
    vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]
    % vel_grid=3.6*vel_grid;        % unit: km/h
end

start_frame = 0;
% end_frame = length(Results)-1;
end_frame = 5;


for i = start_frame:1:end_frame
    file_name = strcat(folder_name,'/',data_name,'_',num2str(i,'%06d'),'.mat');
    tempdata = load(file_name);
    heatmap = tempdata.Angdata;
    axh = plot_rangeAng(heatmap,rng_grid,agl_grid);
    hold on
  
    Id = find(Results(:,1) == i);
    for j=1:length(Id)
        index = Id(j);
        if Results(index,4) == 0
            txt = 'pedestrian'
            filledCircle([agl_grid(1,Results(index,2)),rng_grid(Results(index,3),1)],0.5,1000,'r'); 
            text(agl_grid(1,Results(index,2))+5,rng_grid(Results(index,3),1)+1,1,txt,'Color','r');
        elseif Results(index,4) == 1
            txt = 'car';
            filledCircle([agl_grid(1,Results(index,2)),rng_grid(Results(index,3),1)],0.5,1000,'g'); 
            text(agl_grid(1,Results(index,2))-10,rng_grid(Results(index,3),1)+1,1,txt,'Color','r');
        elseif Results(index,4) == 2   
            txt = 'cyclist';
            filledCircle([agl_grid(1,Results(index,2)),rng_grid(Results(index,3),1)],0.5,1000,'g'); 
            text(agl_grid(1,Results(index,2))-10,rng_grid(Results(index,3),1)+1,1,txt,'Color','g');
        elseif Results(index,4) == -1
            saved_fig_file_name = strcat('D:/tmp/demo_figure/',data_name,'/',data_name,'_',num2str(i,'%3d'));
            eval(['saveas(axh,saved_fig_file_name,''png'');'])
            close
            continue
        else
        end
%         if strcmp(txt,'pedestrian')
%             filledCircle([agl_grid(1,Results(index,2)),rng_grid(Results(index,3),1)],0.5,1000,'r'); 
%             text(agl_grid(1,Results(index,2))+5,rng_grid(Results(index,3),1)+1,1,txt,'Color','r');
%         else
%             continue
%         end
        
    end
    
    saved_fig_file_name = strcat('D:/tmp/demo_figure/',data_name,'/',data_name,'_',num2str(i,'%3d'));
    eval(['saveas(axh,saved_fig_file_name,''png'');'])
    close
end