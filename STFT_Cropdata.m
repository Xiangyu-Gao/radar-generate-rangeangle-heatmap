clc
clear all
close all

%% parameter setting
% constant parameters
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9;% Center frequency (Hz)
lambda = c/fc;
Rx = 4;
Tx = 2;

% configuration parameters
Fs = 4*10^6;
sweepSlope = 21.0017e12;
samples = 128;
loop = 255;
Tc = 120e-6; %us
fft_Rang = 128;
fft_Vel = 256;
fft_Ang = 91;
WINDOW =  255; % STFT parameters
NOVEPLAP = 242; % STFT parameters

% size of bounding box
widthRec = 22.5;% degrees ==> pi/8
heigtRec = 2.5;% meters

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;

w = [-180:4:180]; % angle_grid
agl_grid = asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]

% velocity_grid
dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs],
                                % dopgrid = [-fs/2,fs/2]
% vel_grid=3.6*vel_grid;        % unit: km/h

%% read file information
capture_date_list = ["2019_04_09"];

for ida = 1:length(capture_date_list)
    capture_date = capture_date_list(ida);
    folder_location_data = strcat('F:/Assemble_CropedData/', capture_date, ...
        '/');
    folder_location_saveddata = strcat('F:/STFT_CropedData/', capture_date, ...
        '/');
    files = dir(folder_location_data); % find all the files under the folder
    n_files = length(files);
    
    for inum = 3:n_files
        file_name = files(inum).name;
        % generate file name and folder
        file_location_data = strcat(folder_location_data, file_name,'/');
        file_location_saveddata = strcat(folder_location_saveddata, ...
            file_name,'/');
        if ~exist(file_location_saveddata, 'dir') % check the folder exist
            mkdir(file_location_saveddata);
            end
        sub_files = dir(file_location_data);
        
        for ifa = 3:length(sub_files)
            sub_file_name = sub_files(ifa).name;
            sub_file_location = strcat(file_location_data, sub_file_name);

            %% read data
            data = load(sub_file_location);
            data = data.To_save_data;
            n_frame = size(data,3);
            n_rangbin = size(data,1);
%             n_anglebin = size(data,2);
            data_conca = [];
            STFT_data = [];
            
            % reshae data to the formta [rangebin*anglebin, frames]
            for j = 1:n_rangbin
                for i = 6:14
                    data_conca = [data_conca; squeeze(data(j,i,:))'];
                end
            end
            
            %% STFT
            for h = 1:n_rangbin*9
                [S,F,T] = spectrogram(data_conca(h,:), WINDOW, NOVEPLAP, ...
                256, 1/Tc, 'centered');
                v_grid_new = F*lambda/2;
                STFT_data = cat(3,STFT_data,S);
                
                %% plot figure
                if h == (1+n_rangbin*9)/2
                    figure()
                    axh = mesh(T-T(1),v_grid_new,abs(S));
                    view(0,90)
                    xlabel('time /s')
                    ylabel('velocity m/s')
                    title('SFFT heatmap')
                    colorbar
                else
                    h
                end
                
            end
            
            %% Normalize data
%             max_val = 5.4e+08;
%             STFT_data = STFT_data./max_val;
            STFT_data = single(STFT_data);
            
            %% store data
            interval = 50;
            stft_len = length(S);
            img_w = 256;
            index = 0;
            
            for L=1:interval:stft_len-img_w
                data_store = STFT_data(:,L:L+img_w-1,:);
                data_store_name = strcat(file_location_saveddata,'\', ...
                    sub_file_name(1:length(sub_file_name)-4), '_', ...
                    num2str(index,'%06d'),'.mat');
                index = index+1;
                save(data_store_name,'data_store','-v6');
                L
            end
            
            
%             data_all_store_name = strcat(file_store_loc,'\',file_name(1:19),'alldata.mat');
%             eval(['save(data_all_store_name,''STFT_data'',''-v6'');'])
            
            figure_store_name = strcat(file_location_saveddata,'\', ...
                sub_file_name(1:length(sub_file_name)-4),'_', ...
                'stftheatmap.png');
            saveas(axh,figure_store_name,'png');
            close
        end
    end
    
end

