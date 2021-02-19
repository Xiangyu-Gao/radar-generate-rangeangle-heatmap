%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For old data format (Tc = 120e-6 us)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear all;
close all;
%% parameter setting
% constant parameters
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9; % Center frequency (Hz)
lambda = c/fc;
Rx = 4;
Tx = 2;

% configuration parameters
Fs = 4*10^6;
sweepSlope = 21.0017e12;
samples = 128;
loop = 255;
set_frame_number = 900;
Tc = 120e-6; %us % previous 120us 
fft_Rang = 134; % 134=>128
fft_Vel = 256;
fft_Ang = 128;
num_crop = 3;
max_value = 1e+04; % data WITH 1843

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;

w = linspace(-1,1,fft_Ang); % angle_grid
agl_grid = asin(w)*180/pi; % [-1,1]->[-pi/2,pi/2]

% velocity_grid
dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]


% Algorithm parameters
frame_start = 1;
frame_end = set_frame_number;
option = 0; % option=0,only plot ang-range; option=1, 
% option=2,only record raw data in format of matrix; option=3,ran+dop+angle estimate;
IS_Plot_RD = 0; % 1 ==> plot the Range-Doppler heatmap
IS_SAVE_Data = 1;% 1 ==> save range-angle data and heatmap figure
Is_Det_Static = 1;% 1==> detection includes static objects (!!! MUST BE 1 WHEN OPYION = 1)
Is_Windowed = 1;% 1==> Windowing before doing range and angle fft
num_stored_figs = set_frame_number;% the number of figures that are going to be stored

%% file information
capture_date_list = ["2019_04_30", "2019_05_09", "2019_05_23", "2019_05_28", "2019_05_29"];

for ida = 1:length(capture_date_list)
capture_date = capture_date_list(ida);
folder_location = strcat('/mnt/nas_crdataset/', capture_date, '/');
store_folder_location = strcat('/media/admin-cmmb/Elements/CRdataset/', capture_date, '/');
files = dir(folder_location); % find all the files under the folder
n_files = length(files);

processed_files = [3:n_files]

% if contains(capture_date, '04_09')
%     processed_files = [3:14,18] %0409
% elseif contains(capture_date, '04_30')
%     processed_files = [3:7,9:14,16:21] %0430
% elseif contains(capture_date, '05_09')
%     processed_files = [3:5,7:16] %0509
% else
%     processed_files = [3:n_files] %0528,0529,0523
% end

for index = 1:length(processed_files)
    inum = processed_files(index);
    file_name = files(inum).name;
    % generate file name and folder
    file_location = strcat(folder_location,file_name,'/rad_reo_zerf/');
%     file_location = strcat(folder_location,file_name,'/rad_reo_zerf_h/');
    for ign = 1:1
        if option == 0 && Is_Windowed == 0

        elseif option == 0 && Is_Windowed == 1
            saved_folder_name = strcat(store_folder_location,file_name, ...
                '/WIN_R_MAT/');
%             saved_fig_folder_name = strcat(store_folder_location,file_name, ...
%                 '/WIN_RV_HEATMAP/');
        end
        
        if ~exist(saved_folder_name, 'dir') % check the folder exist
            mkdir(saved_folder_name);
        end
%         if ~exist(saved_fig_folder_name, 'dir') % check the folder exist
%             mkdir(saved_fig_folder_name);
%         end
    end
    
    %% read the data file
    data = readDCA1000(file_location, samples);
    data_length = length(data);
    data_each_frame = samples*loop*Tx;
    Frame_num = data_length/data_each_frame;
    
    % check whether Frame number is an integer
    if Frame_num == set_frame_number
        frame_end = Frame_num;
    elseif abs(Frame_num - set_frame_number) < 30
        fprintf('Error! Frame is not complete')
        frame_start = set_frame_number - fix(Frame_num) + 1;
        % zero fill the data
        num_zerochirp_fill = set_frame_number*data_each_frame - data_length;
        data = [zeros(4,num_zerochirp_fill), data];
    elseif abs(Frame_num - set_frame_number) >= 30 && Frame_num == fix(Frame_num)
        frame_end = Frame_num;
    else
    end
    
    for i = frame_start:frame_end
        % reshape data of each frame to the format [samples, Rx, chirp]
        data_frame = data(:,(i-1)*data_each_frame+1:i*data_each_frame);
        data_chirp = [];
        for cj=1:Tx*loop
            temp_data = data_frame(:,(cj-1)*samples+1:cj*samples);
            data_chirp(:,:,cj) = temp_data;
        end
        chirp_odd = data_chirp(:,:,1:2:end);
        chirp_even = data_chirp(:,:,2:2:end);
        chirp_odd = permute(chirp_odd, [2,1,3]);
        chirp_even = permute(chirp_even, [2,1,3]);
        
        if option == 0
            %% plot ang-range and find the location of objects
            % FOR CHIRP 1
            % Range FFT
            [Rangedata_odd] = fft_range(chirp_odd,fft_Rang,Is_Windowed);
                        
            % FOR CHIRP 2
            % Range FFT
            [Rangedata_even] = fft_range(chirp_even,fft_Rang,Is_Windowed);

            % Normalize Range-Velocity data cube ./e+05
            R_data = cat(2, Rangedata_odd(num_crop + 1:fft_Rang - num_crop,:,:),...
                Rangedata_even(num_crop + 1:fft_Rang - num_crop,:,:));
            R_data = R_data/1e+04;
            
            if IS_SAVE_Data
                % save range-angle heatmap to .mat file
                saved_file_name = strcat(saved_folder_name,'/', ...
                    file_name,'_',num2str(i-1,'%06d'),'.mat');
                
                save(saved_file_name,'R_data','-v6');
            end
            i % print index i
            
        elseif option == 1
          
        else
            
        end
    end
    clear data
end
end
